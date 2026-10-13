-- QR diners must see the same sell price that POS uses for stocked products.
-- A catalog product starts at PHP 0.00; its actual price normally comes from
-- the oldest available FIFO stock batch unless a branch override is set.
create or replace function public.current_branch_product_menu_price(target_branch_id text, target_product_id text)
returns numeric
language sql
stable
security definer
set search_path = public
as $$
  select coalesce(
    bp.selling_price_override,
    (
      select batch.selling_price
      from public.inventory_cost_batches batch
      where batch.branch_id = bp.branch_id
        and batch.product_id = bp.product_id
        and batch.qty_remaining > 0
        and batch.selling_price is not null
      order by batch.is_opening desc, batch.received_at, batch.batch_id
      limit 1
    ),
    nullif(bp.price_override, 0),
    nullif(p.price, 0),
    0
  )
  from public.products p
  join public.branch_products bp on bp.product_id = p.product_id
  where bp.branch_id = target_branch_id
    and p.product_id = target_product_id;
$$;

create or replace function public.public_table_menu(token_input uuid)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare t public.restaurant_tables;
begin
  select * into t from public.restaurant_tables where qr_token = token_input;
  if not found then raise exception 'Invalid table QR code.'; end if;

  return jsonb_build_object(
    'tableId', t.table_id,
    'tableName', t.name,
    'status', t.status,
    'products', (
      select coalesce(jsonb_agg(jsonb_build_object(
        'id', p.product_id,
        'name', p.name,
        'price', public.current_branch_product_menu_price(t.branch_id, p.product_id),
        'category', p.category,
        'imagePath', p.image_path
      ) order by p.name), '[]'::jsonb)
      from public.products p
      join public.branch_products bp on bp.product_id = p.product_id and bp.branch_id = t.branch_id
      where p.archived_at is null and p.status = 'Active' and bp.status = 'Active'
    )
  );
end;
$$;

create or replace function public.confirm_table_order_request(target_request_id text)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare r public.table_order_requests; order_id_value text; ticket_id_value text := public.new_pos_id('KOT'); item record; kitchen_line_count integer;
begin
  select * into r from public.table_order_requests where request_id = target_request_id for update;
  if not found or r.status <> 'Claimed' then raise exception 'This request must be claimed before it can be confirmed.'; end if;
  if r.claimed_by is distinct from auth.uid() then raise exception 'Only the waiter who claimed this request can confirm it.'; end if;
  if not public.has_permission('pos') or not public.can_access_branch(r.branch_id) then raise exception 'Access denied.'; end if;

  select order_id into order_id_value from public.restaurant_orders where table_id = r.table_id and status = 'Open' for update;
  if order_id_value is null then raise exception 'Open the table tab before confirming a customer order.'; end if;

  for item in select * from public.table_order_request_items where request_id = r.request_id loop
    insert into public.restaurant_order_items(order_id, product_id, qty, price, notes)
    values (order_id_value, item.product_id, item.qty, public.current_branch_product_menu_price(r.branch_id, item.product_id), item.notes);
  end loop;

  select count(*) into kitchen_line_count
  from public.table_order_request_items i
  join public.products p on p.product_id = i.product_id
  where i.request_id = r.request_id and p.kitchen_enabled;
  if kitchen_line_count > 0 then
    insert into public.kitchen_tickets(ticket_id, branch_id, table_id, request_id, order_id)
    values(ticket_id_value, r.branch_id, r.table_id, r.request_id, order_id_value);
    insert into public.kitchen_ticket_items(ticket_id, product_id, qty, notes)
    select ticket_id_value, i.product_id, i.qty, i.notes
    from public.table_order_request_items i
    join public.products p on p.product_id = i.product_id
    where i.request_id = r.request_id and p.kitchen_enabled;
  else
    ticket_id_value := null;
  end if;

  update public.table_order_requests set status = 'Confirmed', confirmed_by = auth.uid(), confirmed_at = now() where request_id = r.request_id;
  return jsonb_build_object('orderId', order_id_value, 'ticketId', ticket_id_value);
end;
$$;

grant execute on function public.current_branch_product_menu_price(text, text) to anon, authenticated;
grant execute on function public.public_table_menu(uuid) to anon, authenticated;
