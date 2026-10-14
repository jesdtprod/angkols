-- The QR page shows the whole current table tab, including staff/POS/admin orders.
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
              when exists(select 1 from public.kitchen_ticket_items kitchen_line join public.kitchen_tickets kitchen_ticket on kitchen_ticket.ticket_id = kitchen_line.ticket_id where kitchen_ticket.order_id = active_order.order_id and kitchen_line.product_id = grouped_line.product_id and kitchen_line.status = 'Served')
                and not exists(select 1 from public.kitchen_ticket_items kitchen_line join public.kitchen_tickets kitchen_ticket on kitchen_ticket.ticket_id = kitchen_line.ticket_id where kitchen_ticket.order_id = active_order.order_id and kitchen_line.product_id = grouped_line.product_id and kitchen_line.status <> 'Served') then 'Served'
              when exists(select 1 from public.kitchen_ticket_items kitchen_line join public.kitchen_tickets kitchen_ticket on kitchen_ticket.ticket_id = kitchen_line.ticket_id where kitchen_ticket.order_id = active_order.order_id and kitchen_line.product_id = grouped_line.product_id and kitchen_line.status = 'Served') then 'Partially served'
              when exists(select 1 from public.kitchen_ticket_items kitchen_line join public.kitchen_tickets kitchen_ticket on kitchen_ticket.ticket_id = kitchen_line.ticket_id where kitchen_ticket.order_id = active_order.order_id and kitchen_line.product_id = grouped_line.product_id and kitchen_line.status = 'Ready') then 'Ready to serve'
              when exists(select 1 from public.kitchen_ticket_items kitchen_line join public.kitchen_tickets kitchen_ticket on kitchen_ticket.ticket_id = kitchen_line.ticket_id where kitchen_ticket.order_id = active_order.order_id and kitchen_line.product_id = grouped_line.product_id and kitchen_line.status = 'Preparing') then 'Cooking'
              else 'Sent to kitchen'
            end
          ) order by product.name), '[]'::jsonb)
          from (
            select order_line.product_id, sum(order_line.qty) as qty, sum(order_line.qty * order_line.price) as total,
              string_agg(distinct nullif(order_line.notes, ''), ' • ') as notes
            from public.restaurant_order_items order_line
            where order_line.order_id = active_order.order_id
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

grant execute on function public.public_table_menu(uuid) to anon, authenticated;
