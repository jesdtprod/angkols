-- Guests may send the first QR order without a pre-opened waiter tab.
-- The waiter confirmation opens the table tab atomically, then records the order.
create or replace function public.submit_table_order_request(token_input uuid, lines jsonb, note_input text default '')
returns jsonb language plpgsql security definer set search_path = public as $$
declare t public.restaurant_tables; request_id_value text := public.new_pos_id('QOR'); line jsonb; product_id_value text; qty_value numeric;
begin
  select * into t from public.restaurant_tables where qr_token = token_input for update;
  if not found or t.status not in ('Vacant', 'Occupied') then raise exception 'This table is not accepting mobile orders.'; end if;
  if jsonb_typeof(lines) <> 'array' or jsonb_array_length(lines) = 0 then raise exception 'Add at least one item.'; end if;
  insert into public.table_order_requests(request_id, branch_id, table_id, customer_note)
  values(request_id_value, t.branch_id, t.table_id, trim(coalesce(note_input, '')));
  for line in select value from jsonb_array_elements(lines) loop
    product_id_value := line->>'productId'; qty_value := (line->>'qty')::numeric;
    if qty_value is null or qty_value <= 0 or not exists(
      select 1 from public.products p join public.branch_products bp on bp.product_id = p.product_id
      where p.product_id = product_id_value and p.archived_at is null and p.status = 'Active'
        and bp.branch_id = t.branch_id and bp.status = 'Active' and p.category <> 'Ingredients / Raw Materials'
    ) then raise exception 'One or more menu items are unavailable.'; end if;
    insert into public.table_order_request_items(request_id, product_id, qty, notes)
    values(request_id_value, product_id_value, qty_value, coalesce(line->>'notes', ''));
  end loop;
  return jsonb_build_object('requestId', request_id_value, 'status', 'Pending');
end;
$$;

create or replace function public.confirm_table_order_request(target_request_id text)
returns jsonb language plpgsql security definer set search_path = public as $$
declare r public.table_order_requests; order_id_value text; ticket_id_value text := public.new_pos_id('KOT'); item record; kitchen_line_count integer;
begin
  select * into r from public.table_order_requests where request_id = target_request_id for update;
  if not found or r.status <> 'Claimed' then raise exception 'This request must be claimed before it can be confirmed.'; end if;
  if r.claimed_by is distinct from auth.uid() then raise exception 'Only the waiter who claimed this request can confirm it.'; end if;
  if not (public.has_permission('pos') or public.has_permission('waiterQueue')) or not public.can_access_branch(r.branch_id) then raise exception 'Access denied.'; end if;

  select order_id into order_id_value from public.restaurant_orders where table_id = r.table_id and status = 'Open' for update;
  if order_id_value is null then
    insert into public.restaurant_orders(order_id, branch_id, table_id, guest_count, customer_name, opened_by)
    values(public.new_pos_id('TBO'), r.branch_id, r.table_id, 1, 'QR Guest', auth.uid())
    returning order_id into order_id_value;
    update public.restaurant_tables set status = 'Occupied', reservation_name = '', reservation_phone = '', reservation_at = null, reservation_guest_count = null, reservation_notes = '' where table_id = r.table_id;
  end if;
  for item in select * from public.table_order_request_items where request_id = r.request_id loop
    insert into public.restaurant_order_items(order_id, product_id, qty, price, notes)
    values(order_id_value, item.product_id, item.qty, public.current_branch_product_menu_price(r.branch_id, item.product_id), item.notes);
  end loop;
  select count(*) into kitchen_line_count from public.table_order_request_items i join public.products p on p.product_id = i.product_id where i.request_id = r.request_id and p.kitchen_enabled;
  if kitchen_line_count > 0 then
    insert into public.kitchen_tickets(ticket_id, branch_id, table_id, request_id, order_id) values(ticket_id_value, r.branch_id, r.table_id, r.request_id, order_id_value);
    insert into public.kitchen_ticket_items(ticket_id, product_id, qty, notes)
    select ticket_id_value, i.product_id, i.qty, i.notes from public.table_order_request_items i join public.products p on p.product_id = i.product_id where i.request_id = r.request_id and p.kitchen_enabled;
  else ticket_id_value := null; end if;
  update public.table_order_requests set status = 'Confirmed', confirmed_by = auth.uid(), confirmed_at = now() where request_id = r.request_id;
  return jsonb_build_object('orderId', order_id_value, 'ticketId', ticket_id_value);
end;
$$;

grant execute on function public.submit_table_order_request(uuid, jsonb, text) to anon, authenticated;
grant execute on function public.confirm_table_order_request(text) to authenticated;
