-- A waiter may safely press Accept again after a realtime redraw. The same
-- waiter keeps the claim; another waiter remains blocked.
create or replace function public.claim_table_order_request(target_request_id text)
returns public.table_order_requests language plpgsql security definer set search_path = public as $$
declare request_row public.table_order_requests;
begin
  select * into request_row from public.table_order_requests where request_id = target_request_id for update;
  if not found then raise exception 'This request was not found.'; end if;
  if not (public.has_permission('pos') or public.has_permission('waiterQueue')) or not public.can_access_branch(request_row.branch_id) then
    raise exception 'Access denied.';
  end if;
  if request_row.status = 'Pending' then
    update public.table_order_requests
    set status = 'Claimed', claimed_by = auth.uid(), claimed_at = now()
    where request_id = request_row.request_id
    returning * into request_row;
  elsif request_row.status <> 'Claimed' then
    raise exception 'This request can no longer be accepted.';
  elsif request_row.claimed_by is distinct from auth.uid() then
    raise exception 'This request was already claimed by another waiter.';
  end if;
  return request_row;
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
  if order_id_value is null then raise exception 'Open the table tab before confirming a customer order.'; end if;
  for item in select * from public.table_order_request_items where request_id = r.request_id loop
    insert into public.restaurant_order_items(order_id, product_id, qty, price, notes)
    values (order_id_value, item.product_id, item.qty, public.current_branch_product_menu_price(r.branch_id, item.product_id), item.notes);
  end loop;
  select count(*) into kitchen_line_count from public.table_order_request_items i join public.products p on p.product_id = i.product_id where i.request_id = r.request_id and p.kitchen_enabled;
  if kitchen_line_count > 0 then
    insert into public.kitchen_tickets(ticket_id, branch_id, table_id, request_id, order_id) values(ticket_id_value, r.branch_id, r.table_id, r.request_id, order_id_value);
    insert into public.kitchen_ticket_items(ticket_id, product_id, qty, notes)
    select ticket_id_value, i.product_id, i.qty, i.notes from public.table_order_request_items i join public.products p on p.product_id = i.product_id where i.request_id = r.request_id and p.kitchen_enabled;
  else
    ticket_id_value := null;
  end if;
  update public.table_order_requests set status = 'Confirmed', confirmed_by = auth.uid(), confirmed_at = now() where request_id = r.request_id;
  return jsonb_build_object('orderId', order_id_value, 'ticketId', ticket_id_value);
end;
$$;

create or replace function public.public_table_menu(token_input uuid)
returns jsonb language plpgsql security definer set search_path = public as $$
declare table_row public.restaurant_tables;
begin
  select * into table_row from public.restaurant_tables where qr_token = token_input;
  if not found then raise exception 'Invalid table QR code.'; end if;
  return jsonb_build_object(
    'tableId', table_row.table_id,
    'tableName', table_row.name,
    'status', table_row.status,
    'products', (
      select coalesce(jsonb_agg(jsonb_build_object('id', p.product_id, 'name', p.name, 'price', public.current_branch_product_menu_price(table_row.branch_id, p.product_id), 'category', p.category, 'imagePath', p.image_path) order by p.name), '[]'::jsonb)
      from public.products p join public.branch_products bp on bp.product_id = p.product_id and bp.branch_id = table_row.branch_id
      where p.archived_at is null and p.status = 'Active' and bp.status = 'Active'
    ),
    'recentOrders', (
      select coalesce(jsonb_agg(jsonb_build_object(
        'ticketId', ticket.ticket_id,
        'status', ticket.status,
        'createdAt', ticket.created_at,
        'servedAt', ticket.served_at,
        'items', (select coalesce(jsonb_agg(jsonb_build_object('name', product.name, 'qty', item.qty, 'notes', item.notes) order by product.name), '[]'::jsonb) from public.kitchen_ticket_items item join public.products product on product.product_id = item.product_id where item.ticket_id = ticket.ticket_id)
      ) order by ticket.created_at desc), '[]'::jsonb)
      from public.kitchen_tickets ticket
      join public.restaurant_orders restaurant_order on restaurant_order.order_id = ticket.order_id
      where ticket.table_id = table_row.table_id and restaurant_order.status = 'Open'
    )
  );
end;
$$;

grant execute on function public.claim_table_order_request(text), public.confirm_table_order_request(text) to authenticated;
grant execute on function public.public_table_menu(uuid) to anon, authenticated;
