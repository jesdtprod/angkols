-- QR order history belongs to the current table tab, not to the physical table forever.
alter table public.table_order_requests
  add column if not exists order_id text references public.restaurant_orders(order_id);

create index if not exists table_order_requests_order_id_idx on public.table_order_requests(order_id);

-- Preserve the association for prior kitchen-routed requests and any current table tab.
update public.table_order_requests request
set order_id = ticket.order_id
from public.kitchen_tickets ticket
where ticket.request_id = request.request_id
  and request.order_id is null
  and ticket.order_id is not null;

update public.table_order_requests request
set order_id = table_order.order_id
from public.restaurant_orders table_order
where table_order.table_id = request.table_id
  and table_order.status = 'Open'
  and request.status = 'Confirmed'
  and request.order_id is null;

create or replace function public.submit_table_order_request(token_input uuid, lines jsonb, note_input text default '')
returns jsonb language plpgsql security definer set search_path = public as $$
declare table_row public.restaurant_tables; request_id_value text := public.new_pos_id('QOR'); line jsonb; product_id_value text; qty_value numeric; open_order_id text;
begin
  select * into table_row from public.restaurant_tables where qr_token = token_input for update;
  if not found or table_row.status not in ('Vacant', 'Occupied') then raise exception 'This table is not accepting mobile orders.'; end if;
  if jsonb_typeof(lines) <> 'array' or jsonb_array_length(lines) = 0 then raise exception 'Add at least one item.'; end if;
  select order_id into open_order_id from public.restaurant_orders where table_id = table_row.table_id and status = 'Open';
  insert into public.table_order_requests(request_id, branch_id, table_id, order_id, customer_note)
  values(request_id_value, table_row.branch_id, table_row.table_id, open_order_id, trim(coalesce(note_input, '')));
  for line in select value from jsonb_array_elements(lines) loop
    product_id_value := line->>'productId'; qty_value := (line->>'qty')::numeric;
    if qty_value is null or qty_value <= 0 or not exists(
      select 1 from public.products product join public.branch_products branch_product on branch_product.product_id = product.product_id
      where product.product_id = product_id_value and product.archived_at is null and product.status = 'Active'
        and branch_product.branch_id = table_row.branch_id and branch_product.status = 'Active' and product.category <> 'Ingredients / Raw Materials'
    ) then raise exception 'One or more menu items are unavailable.'; end if;
    insert into public.table_order_request_items(request_id, product_id, qty, notes)
    values(request_id_value, product_id_value, qty_value, coalesce(line->>'notes', ''));
  end loop;
  return jsonb_build_object('requestId', request_id_value, 'status', 'Pending');
end;
$$;

create or replace function public.confirm_table_order_request(target_request_id text)
returns jsonb language plpgsql security definer set search_path = public as $$
declare request_row public.table_order_requests; order_id_value text; ticket_id_value text := public.new_pos_id('KOT'); item record; kitchen_line_count integer;
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
  for item in select * from public.table_order_request_items where request_id = request_row.request_id loop
    insert into public.restaurant_order_items(order_id, product_id, qty, price, notes)
    values(order_id_value, item.product_id, item.qty, public.current_branch_product_menu_price(request_row.branch_id, item.product_id), item.notes);
  end loop;
  select count(*) into kitchen_line_count from public.table_order_request_items item join public.products product on product.product_id = item.product_id where item.request_id = request_row.request_id and product.kitchen_enabled;
  if kitchen_line_count > 0 then
    insert into public.kitchen_tickets(ticket_id, branch_id, table_id, request_id, order_id) values(ticket_id_value, request_row.branch_id, request_row.table_id, request_row.request_id, order_id_value);
    insert into public.kitchen_ticket_items(ticket_id, product_id, qty, notes)
    select ticket_id_value, item.product_id, item.qty, item.notes from public.table_order_request_items item join public.products product on product.product_id = item.product_id where item.request_id = request_row.request_id and product.kitchen_enabled;
  else ticket_id_value := null; end if;
  update public.table_order_requests set status = 'Confirmed', order_id = order_id_value, confirmed_by = auth.uid(), confirmed_at = now() where request_id = request_row.request_id;
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
    'tableId', table_row.table_id, 'tableName', table_row.name, 'status', table_row.status,
    'products', (
      select coalesce(jsonb_agg(jsonb_build_object(
        'id', product.product_id, 'name', product.name, 'price', public.current_branch_product_menu_price(table_row.branch_id, product.product_id),
        'category', product.category, 'imagePath', product.image_path,
        'stock', case when product.product_type = 'bundle' then coalesce((select min(floor(coalesce(inventory_row.qty, 0) / nullif(component.qty, 0)))::numeric from public.product_bundle_components component left join public.inventory inventory_row on inventory_row.branch_id = table_row.branch_id and inventory_row.product_id = component.component_product_id where component.bundle_product_id = product.product_id), 0) else coalesce((select inventory_row.qty from public.inventory inventory_row where inventory_row.branch_id = table_row.branch_id and inventory_row.product_id = product.product_id), 0) end
      ) order by product.name), '[]'::jsonb)
      from public.products product join public.branch_products branch_product on branch_product.product_id = product.product_id and branch_product.branch_id = table_row.branch_id
      where product.archived_at is null and product.status = 'Active' and branch_product.status = 'Active' and product.category <> 'Ingredients / Raw Materials'
    ),
    'orderUpdates', (
      select coalesce(jsonb_agg(jsonb_build_object(
        'requestId', request.request_id, 'status', request.status, 'customerNotice', request.customer_notice, 'createdAt', request.created_at,
        'ticketStatus', (select ticket.status from public.kitchen_tickets ticket where ticket.request_id = request.request_id order by ticket.created_at desc limit 1),
        'items', (select coalesce(jsonb_agg(jsonb_build_object('name', product.name, 'qty', item.qty, 'notes', item.notes) order by product.name), '[]'::jsonb) from public.table_order_request_items item join public.products product on product.product_id = item.product_id where item.request_id = request.request_id)
      ) order by request.created_at desc), '[]'::jsonb)
      from (
        select * from public.table_order_requests request
        where request.table_id = table_row.table_id
          and (request.status in ('Pending', 'Claimed') or exists(select 1 from public.restaurant_orders table_order where table_order.order_id = request.order_id and table_order.status = 'Open'))
        order by request.created_at desc limit 12
      ) request
    ),
    'recentOrders', '[]'::jsonb
  );
end;
$$;

grant execute on function public.public_table_menu(uuid), public.submit_table_order_request(uuid, jsonb, text) to anon, authenticated;
grant execute on function public.confirm_table_order_request(text) to authenticated;
