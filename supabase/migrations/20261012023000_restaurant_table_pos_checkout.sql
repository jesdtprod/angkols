create or replace function public.update_restaurant_table(target_table_id text, table_name_input text, area_input text, capacity_input integer, status_input text)
returns public.restaurant_tables language plpgsql security definer set search_path = public as $$
declare result public.restaurant_tables;
begin
  if not public.is_admin() then raise exception 'Only administrators can update tables.'; end if;
  if nullif(trim(table_name_input), '') is null or capacity_input is null or capacity_input < 1 or status_input not in ('Vacant','Occupied','Reserved','Cleaning') then raise exception 'Enter valid table details.'; end if;
  if exists(select 1 from public.restaurant_orders where table_id = target_table_id and status = 'Open') and status_input <> 'Occupied' then raise exception 'Settle the open table tab before changing its status.'; end if;
  update public.restaurant_tables set name=trim(table_name_input), area=trim(coalesce(area_input,'')), capacity=capacity_input, status=status_input where table_id=target_table_id returning * into result;
  if not found then raise exception 'Table was not found.'; end if; return result;
end; $$;

create or replace function public.delete_restaurant_table(target_table_id text)
returns void language plpgsql security definer set search_path = public as $$
begin
  if not public.is_admin() then raise exception 'Only administrators can delete tables.'; end if;
  if exists(select 1 from public.restaurant_orders where table_id=target_table_id and status='Open') then raise exception 'Settle the open table tab before deleting this table.'; end if;
  delete from public.restaurant_tables where table_id=target_table_id;
  if not found then raise exception 'Table was not found.'; end if;
end; $$;

create or replace function public.settle_restaurant_order_through_pos(
  target_order_id text, payment_type_input text, customer_id_input text default null, discount_input numeric default 0, cash_tendered_input numeric default 0
) returns jsonb language plpgsql security definer set search_path = public as $$
declare order_row public.restaurant_orders; sale_lines jsonb; sale_result jsonb;
begin
  select * into order_row from public.restaurant_orders where order_id=target_order_id for update;
  if not found or order_row.status <> 'Open' then raise exception 'This table tab is no longer open.'; end if;
  if not public.has_permission('pos') or not public.can_access_branch(order_row.branch_id) then raise exception 'Your account does not have access to this tab.'; end if;
  select jsonb_agg(jsonb_build_object('productId', product_id, 'qty', qty, 'price', price) order by created_at) into sale_lines from public.restaurant_order_items where order_id=order_row.order_id;
  if sale_lines is null then raise exception 'Add at least one item before payment.'; end if;
  sale_result := public.record_sale_with_service(order_row.branch_id, sale_lines, payment_type_input, customer_id_input, discount_input, cash_tendered_input, 'Dine-in', order_row.table_id, order_row.customer_name, '', '');
  update public.restaurant_orders set status='Settled', discount=discount_input, payment_method=initcap(lower(payment_type_input)), closed_at=now() where order_id=order_row.order_id;
  update public.restaurant_tables set status='Vacant' where table_id=order_row.table_id;
  return sale_result || jsonb_build_object('orderId', order_row.order_id, 'tableId', order_row.table_id);
end; $$;

revoke all on function public.update_restaurant_table(text,text,text,integer,text) from public;
revoke all on function public.delete_restaurant_table(text) from public;
revoke all on function public.settle_restaurant_order_through_pos(text,text,text,numeric,numeric) from public;
grant execute on function public.update_restaurant_table(text,text,text,integer,text) to authenticated;
grant execute on function public.delete_restaurant_table(text) to authenticated;
grant execute on function public.settle_restaurant_order_through_pos(text,text,text,numeric,numeric) to authenticated;
