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
      where p.archived_at is null and p.status = 'Active' and bp.status = 'Active' and p.category <> 'Ingredients / Raw Materials'
    ),
    'recentOrders', (
      select coalesce(jsonb_agg(jsonb_build_object(
        'ticketId', ticket.ticket_id,
        'status', ticket.status,
        'createdAt', ticket.created_at,
        'servedAt', ticket.served_at,
        'items', (select coalesce(jsonb_agg(jsonb_build_object('name', product.name, 'qty', item.qty, 'notes', item.notes) order by product.name), '[]'::jsonb) from public.kitchen_ticket_items item join public.products product on product.product_id = item.product_id where item.ticket_id = ticket.ticket_id and product.category <> 'Ingredients / Raw Materials')
      ) order by ticket.created_at desc), '[]'::jsonb)
      from public.kitchen_tickets ticket
      join public.restaurant_orders restaurant_order on restaurant_order.order_id = ticket.order_id
      where ticket.table_id = table_row.table_id and restaurant_order.status = 'Open'
    )
  );
end;
$$;

create or replace function public.submit_table_order_request(token_input uuid, lines jsonb, note_input text default '')
returns jsonb language plpgsql security definer set search_path = public as $$
declare t public.restaurant_tables; request_id_value text := public.new_pos_id('QOR'); line jsonb; product_id_value text; qty_value numeric;
begin
  select * into t from public.restaurant_tables where qr_token = token_input for update;
  if not found or t.status <> 'Occupied' then raise exception 'This table is not accepting mobile orders.'; end if;
  if jsonb_typeof(lines) <> 'array' or jsonb_array_length(lines) = 0 then raise exception 'Add at least one item.'; end if;
  insert into public.table_order_requests(request_id, branch_id, table_id, customer_note) values(request_id_value, t.branch_id, t.table_id, trim(coalesce(note_input, '')));
  for line in select value from jsonb_array_elements(lines) loop
    product_id_value := line->>'productId'; qty_value := (line->>'qty')::numeric;
    if qty_value is null or qty_value <= 0 or not exists(
      select 1 from public.products p join public.branch_products bp on bp.product_id = p.product_id
      where p.product_id = product_id_value and p.archived_at is null and p.status = 'Active' and bp.branch_id = t.branch_id and bp.status = 'Active' and p.category <> 'Ingredients / Raw Materials'
    ) then raise exception 'One or more menu items are unavailable.'; end if;
    insert into public.table_order_request_items(request_id, product_id, qty, notes) values(request_id_value, product_id_value, qty_value, coalesce(line->>'notes', ''));
  end loop;
  return jsonb_build_object('requestId', request_id_value, 'status', 'Pending');
end;
$$;

grant execute on function public.public_table_menu(uuid), public.submit_table_order_request(uuid, jsonb, text) to anon, authenticated;
