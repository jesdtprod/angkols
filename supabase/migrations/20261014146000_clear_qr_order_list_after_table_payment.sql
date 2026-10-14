-- Paid tables return to a clean QR page. Pending requests stay visible so they are not lost.
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
        'id', p.product_id, 'name', p.name, 'price', public.current_branch_product_menu_price(table_row.branch_id, p.product_id),
        'category', p.category, 'imagePath', p.image_path,
        'stock', case when p.product_type = 'bundle' then coalesce((select min(floor(coalesce(inv.qty, 0) / nullif(bc.qty, 0)))::numeric from public.product_bundle_components bc left join public.inventory inv on inv.branch_id = table_row.branch_id and inv.product_id = bc.component_product_id where bc.bundle_product_id = p.product_id), 0) else coalesce((select inv.qty from public.inventory inv where inv.branch_id = table_row.branch_id and inv.product_id = p.product_id), 0) end
      ) order by p.name), '[]'::jsonb)
      from public.products p join public.branch_products bp on bp.product_id = p.product_id and bp.branch_id = table_row.branch_id
      where p.archived_at is null and p.status = 'Active' and bp.status = 'Active' and p.category <> 'Ingredients / Raw Materials'
    ),
    'orderUpdates', (
      select coalesce(jsonb_agg(jsonb_build_object(
        'requestId', r.request_id, 'status', r.status, 'customerNotice', r.customer_notice, 'createdAt', r.created_at,
        'ticketStatus', (select t.status from public.kitchen_tickets t where t.request_id = r.request_id order by t.created_at desc limit 1),
        'items', (select coalesce(jsonb_agg(jsonb_build_object('name', p.name, 'qty', i.qty, 'notes', i.notes) order by p.name), '[]'::jsonb) from public.table_order_request_items i join public.products p on p.product_id = i.product_id where i.request_id = r.request_id)
      ) order by r.created_at desc), '[]'::jsonb)
      from (select * from public.table_order_requests where table_id = table_row.table_id and (table_row.status = 'Occupied' or status in ('Pending', 'Claimed')) order by created_at desc limit 12) r
    ),
    'recentOrders', '[]'::jsonb
  );
end;
$$;

grant execute on function public.public_table_menu(uuid) to anon, authenticated;
