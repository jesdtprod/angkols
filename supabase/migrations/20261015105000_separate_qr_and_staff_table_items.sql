-- Preserve the source of every table-tab line so the public QR page never
-- renders a customer QR request again in the staff/POS additions section.
alter table public.restaurant_order_items
  add column if not exists source_request_id text references public.table_order_requests(request_id) on delete set null;

create index if not exists restaurant_order_items_source_request_id_idx
  on public.restaurant_order_items(source_request_id)
  where source_request_id is not null;

-- Backfill existing QR-confirmed rows. QR confirmation writes one order line
-- per request line, immediately before setting confirmed_at.
with qr_lines as (
  select request.request_id, request.order_id, request_item.product_id, request_item.qty,
         coalesce(request_item.notes, '') as notes,
         row_number() over (
           partition by request.order_id, request_item.product_id, request_item.qty, coalesce(request_item.notes, '')
           order by request.confirmed_at, request.request_id
         ) as line_number
  from public.table_order_requests request
  join public.table_order_request_items request_item on request_item.request_id = request.request_id
  where request.status = 'Confirmed' and request.order_id is not null
), order_lines as (
  select order_item.item_id, order_item.order_id, order_item.product_id, order_item.qty,
         coalesce(order_item.notes, '') as notes,
         row_number() over (
           partition by order_item.order_id, order_item.product_id, order_item.qty, coalesce(order_item.notes, '')
           order by order_item.created_at, order_item.item_id
         ) as line_number
  from public.restaurant_order_items order_item
  where order_item.source_request_id is null
)
update public.restaurant_order_items order_item
set source_request_id = qr_line.request_id
from order_lines order_line
join qr_lines qr_line
  on qr_line.order_id = order_line.order_id
 and qr_line.product_id = order_line.product_id
 and qr_line.qty = order_line.qty
 and qr_line.notes = order_line.notes
 and qr_line.line_number = order_line.line_number
where order_item.item_id = order_line.item_id;

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
    insert into public.restaurant_order_items(order_id, product_id, qty, price, notes, source_request_id)
    values(order_id_value, line_row.product_id, line_row.qty, public.current_branch_product_menu_price(request_row.branch_id, line_row.product_id), line_row.notes, request_row.request_id);
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
    'currentOrder', (
      select jsonb_build_object(
        'orderId', active_order.order_id,
        'items', (
          select coalesce(jsonb_agg(jsonb_build_object(
            'name', product.name, 'qty', grouped_line.qty, 'total', grouped_line.total, 'notes', grouped_line.notes,
            'kitchenStatus', case
              when product.kitchen_enabled is not true then 'Confirmed'
              when exists(select 1 from public.kitchen_ticket_items kitchen_line join public.kitchen_tickets kitchen_ticket on kitchen_ticket.ticket_id = kitchen_line.ticket_id where kitchen_ticket.order_id = active_order.order_id and kitchen_line.product_id = grouped_line.product_id and kitchen_line.status = 'Served') and not exists(select 1 from public.kitchen_ticket_items kitchen_line join public.kitchen_tickets kitchen_ticket on kitchen_ticket.ticket_id = kitchen_line.ticket_id where kitchen_ticket.order_id = active_order.order_id and kitchen_line.product_id = grouped_line.product_id and kitchen_line.status <> 'Served') then 'Served'
              when exists(select 1 from public.kitchen_ticket_items kitchen_line join public.kitchen_tickets kitchen_ticket on kitchen_ticket.ticket_id = kitchen_line.ticket_id where kitchen_ticket.order_id = active_order.order_id and kitchen_line.product_id = grouped_line.product_id and kitchen_line.status = 'Served') then 'Partially served'
              when exists(select 1 from public.kitchen_ticket_items kitchen_line join public.kitchen_tickets kitchen_ticket on kitchen_ticket.ticket_id = kitchen_line.ticket_id where kitchen_ticket.order_id = active_order.order_id and kitchen_line.product_id = grouped_line.product_id and kitchen_line.status = 'Ready') then 'Ready to serve'
              when exists(select 1 from public.kitchen_ticket_items kitchen_line join public.kitchen_tickets kitchen_ticket on kitchen_ticket.ticket_id = kitchen_line.ticket_id where kitchen_ticket.order_id = active_order.order_id and kitchen_line.product_id = grouped_line.product_id and kitchen_line.status = 'Preparing') then 'Cooking'
              else 'Sent to kitchen'
            end
          ) order by product.name), '[]'::jsonb)
          from (
            select order_line.product_id, sum(order_line.qty) as qty, sum(order_line.qty * order_line.price) as total,
              string_agg(distinct nullif(order_line.notes, ''), ' â€¢ ') as notes
            from public.restaurant_order_items order_line
            where order_line.order_id = active_order.order_id and order_line.source_request_id is null
            group by order_line.product_id
          ) grouped_line
          join public.products product on product.product_id = grouped_line.product_id
        )
      )
      from public.restaurant_orders active_order
      where active_order.table_id = table_row.table_id and active_order.status = 'Open'
      limit 1
    ),
    'orderUpdates', (
      select coalesce(jsonb_agg(jsonb_build_object(
        'requestId', request.request_id, 'status', request.status, 'customerNotice', request.customer_notice, 'createdAt', request.created_at,
        'ticketStatus', (select ticket.status from public.kitchen_tickets ticket where ticket.request_id = request.request_id order by ticket.created_at desc limit 1),
        'items', (select coalesce(jsonb_agg(jsonb_build_object('productId', product.product_id, 'name', product.name, 'price', public.current_branch_product_menu_price(table_row.branch_id, product.product_id), 'qty', item.qty, 'notes', item.notes) order by product.name), '[]'::jsonb) from public.table_order_request_items item join public.products product on product.product_id = item.product_id where item.request_id = request.request_id)
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

grant execute on function public.confirm_table_order_request(text) to authenticated;
grant execute on function public.public_table_menu(uuid) to anon, authenticated;
