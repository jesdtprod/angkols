-- Do not reuse the PL/pgSQL record variable as an SQL table alias.
create or replace function public.confirm_table_order_request(target_request_id text)
returns jsonb language plpgsql security definer set search_path = public as $$
declare request_row public.table_order_requests; order_id_value text; ticket_id_value text := public.new_pos_id('KOT'); line_row record; kitchen_line_count integer;
begin
  select * into request_row from public.table_order_requests where request_id = target_request_id for update;
  if not found or request_row.status <> 'Claimed' then raise exception 'This request must be claimed before it can be confirmed.'; end if;
  if request_row.claimed_by is distinct from auth.uid() then raise exception 'Only the waiter who claimed this request can confirm it.'; end if;
  if not (public.has_permission('pos') or public.has_permission('waiterQueue')) or not public.can_access_branch(request_row.branch_id) then raise exception 'Access denied.'; end if;

  select order_id into order_id_value from public.restaurant_orders where table_id = request_row.table_id and status = 'Open' for update;
  if order_id_value is null then
    insert into public.restaurant_orders(order_id, branch_id, table_id, guest_count, customer_name, opened_by)
    values(public.new_pos_id('TBO'), request_row.branch_id, request_row.table_id, 1, 'QR Guest', auth.uid())
    returning order_id into order_id_value;
    update public.restaurant_tables set status = 'Occupied', reservation_name = '', reservation_phone = '', reservation_at = null, reservation_guest_count = null, reservation_notes = '' where table_id = request_row.table_id;
  end if;

  for line_row in select * from public.table_order_request_items where request_id = request_row.request_id loop
    insert into public.restaurant_order_items(order_id, product_id, qty, price, notes)
    values(order_id_value, line_row.product_id, line_row.qty, public.current_branch_product_menu_price(request_row.branch_id, line_row.product_id), line_row.notes);
  end loop;

  select count(*) into kitchen_line_count
  from public.table_order_request_items request_line
  join public.products menu_product on menu_product.product_id = request_line.product_id
  where request_line.request_id = request_row.request_id and menu_product.kitchen_enabled;

  if kitchen_line_count > 0 then
    insert into public.kitchen_tickets(ticket_id, branch_id, table_id, request_id, order_id)
    values(ticket_id_value, request_row.branch_id, request_row.table_id, request_row.request_id, order_id_value);
    insert into public.kitchen_ticket_items(ticket_id, product_id, qty, notes)
    select ticket_id_value, request_line.product_id, request_line.qty, request_line.notes
    from public.table_order_request_items request_line
    join public.products menu_product on menu_product.product_id = request_line.product_id
    where request_line.request_id = request_row.request_id and menu_product.kitchen_enabled;
  else
    ticket_id_value := null;
  end if;

  update public.table_order_requests
  set status = 'Confirmed', order_id = order_id_value, confirmed_by = auth.uid(), confirmed_at = now()
  where request_id = request_row.request_id;
  return jsonb_build_object('orderId', order_id_value, 'ticketId', ticket_id_value);
end;
$$;

grant execute on function public.confirm_table_order_request(text) to authenticated;
