-- Atomic table-tab operations. Cash settlement uses the existing FIFO sale transaction.
create or replace function public.create_restaurant_table(
  target_branch_id text, table_name_input text, area_input text default '', capacity_input integer default 2
) returns public.restaurant_tables language plpgsql security definer set search_path = public as $$
declare result public.restaurant_tables;
begin
  if not public.is_admin() then raise exception 'Only administrators can register tables.'; end if;
  perform public.assert_active_branch(target_branch_id);
  if nullif(trim(table_name_input), '') is null or capacity_input is null or capacity_input < 1 then raise exception 'Enter a table name and valid capacity.'; end if;
  insert into public.restaurant_tables(table_id, branch_id, name, area, capacity)
  values(public.new_pos_id('TBL'), target_branch_id, trim(table_name_input), trim(coalesce(area_input, '')), capacity_input)
  returning * into result;
  return result;
end;
$$;

create or replace function public.open_restaurant_table(
  target_table_id text, guest_count_input integer default 1, customer_name_input text default ''
) returns public.restaurant_orders language plpgsql security definer set search_path = public as $$
declare table_row public.restaurant_tables; result public.restaurant_orders;
begin
  select * into table_row from public.restaurant_tables where table_id = target_table_id for update;
  if not found then raise exception 'Table was not found.'; end if;
  if not public.has_permission('pos') or not public.can_access_branch(table_row.branch_id) then raise exception 'Your account does not have access to this table.'; end if;
  if table_row.status not in ('Vacant', 'Reserved') then raise exception 'This table is not available.'; end if;
  if guest_count_input is null or guest_count_input < 1 then raise exception 'Enter at least one guest.'; end if;
  insert into public.restaurant_orders(order_id, branch_id, table_id, guest_count, customer_name, opened_by)
  values(public.new_pos_id('TBO'), table_row.branch_id, table_row.table_id, guest_count_input, trim(coalesce(customer_name_input, '')), auth.uid())
  returning * into result;
  update public.restaurant_tables set status = 'Occupied' where table_id = table_row.table_id;
  return result;
end;
$$;

create or replace function public.add_restaurant_order_item(
  target_order_id text, target_product_id text, qty_input numeric, price_input numeric, notes_input text default ''
) returns public.restaurant_order_items language plpgsql security definer set search_path = public as $$
declare order_row public.restaurant_orders; result public.restaurant_order_items;
begin
  select * into order_row from public.restaurant_orders where order_id = target_order_id for update;
  if not found or order_row.status <> 'Open' then raise exception 'This table tab is no longer open.'; end if;
  if not public.has_permission('pos') or not public.can_access_branch(order_row.branch_id) then raise exception 'Your account does not have access to this tab.'; end if;
  if qty_input is null or qty_input <= 0 or price_input is null or price_input < 0 then raise exception 'Enter a valid quantity and price.'; end if;
  if not exists(select 1 from public.products where product_id = target_product_id and archived_at is null) then raise exception 'Choose an active product.'; end if;
  insert into public.restaurant_order_items(order_id, product_id, qty, price, notes)
  values(target_order_id, target_product_id, qty_input, price_input, trim(coalesce(notes_input, '')))
  returning * into result;
  return result;
end;
$$;

create or replace function public.settle_restaurant_table_cash(
  target_order_id text, discount_input numeric default 0, cash_tendered_input numeric default 0
) returns jsonb language plpgsql security definer set search_path = public as $$
declare order_row public.restaurant_orders; sale_result jsonb; sale_lines jsonb;
begin
  select * into order_row from public.restaurant_orders where order_id = target_order_id for update;
  if not found or order_row.status <> 'Open' then raise exception 'This table tab is no longer open.'; end if;
  if not public.has_permission('pos') or not public.can_access_branch(order_row.branch_id) then raise exception 'Your account does not have access to this tab.'; end if;
  if discount_input is null or discount_input < 0 then raise exception 'Enter a valid discount.'; end if;
  select jsonb_agg(jsonb_build_object('productId', product_id, 'qty', qty, 'price', price) order by created_at)
    into sale_lines from public.restaurant_order_items where order_id = order_row.order_id;
  if sale_lines is null then raise exception 'Add at least one order item before settlement.'; end if;
  sale_result := public.record_sale(order_row.branch_id, sale_lines, 'cash', null, discount_input, cash_tendered_input);
  update public.restaurant_orders set status = 'Settled', discount = discount_input, payment_method = 'Cash', closed_at = now()
    where order_id = order_row.order_id;
  update public.restaurant_tables set status = 'Vacant' where table_id = order_row.table_id;
  return sale_result || jsonb_build_object('orderId', order_row.order_id, 'tableId', order_row.table_id);
end;
$$;

revoke all on function public.create_restaurant_table(text, text, text, integer) from public;
revoke all on function public.open_restaurant_table(text, integer, text) from public;
revoke all on function public.add_restaurant_order_item(text, text, numeric, numeric, text) from public;
revoke all on function public.settle_restaurant_table_cash(text, numeric, numeric) from public;
grant execute on function public.create_restaurant_table(text, text, text, integer) to authenticated;
grant execute on function public.open_restaurant_table(text, integer, text) to authenticated;
grant execute on function public.add_restaurant_order_item(text, text, numeric, numeric, text) to authenticated;
grant execute on function public.settle_restaurant_table_cash(text, numeric, numeric) to authenticated;
