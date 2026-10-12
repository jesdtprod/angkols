create or replace function public.settle_restaurant_order_split_through_pos(target_order_id text, customer_id_input text, cash_received_input numeric, discount_input numeric default 0)
returns jsonb language plpgsql security definer set search_path=public as $$
declare order_row public.restaurant_orders; sale_lines jsonb; sale_result jsonb;
begin
  select * into order_row from public.restaurant_orders where order_id=target_order_id for update;
  if not found or order_row.status <> 'Open' then raise exception 'This table tab is no longer open.'; end if;
  select jsonb_agg(jsonb_build_object('productId',product_id,'qty',qty,'price',price) order by created_at) into sale_lines from public.restaurant_order_items where order_id=order_row.order_id;
  sale_result := public.record_split_sale_with_service(order_row.branch_id,sale_lines,customer_id_input,cash_received_input,discount_input,'Dine-in',order_row.table_id,order_row.customer_name,'','');
  update public.restaurant_orders set status='Settled',discount=discount_input,payment_method='Cash + Credit',closed_at=now() where order_id=order_row.order_id;
  update public.restaurant_tables set status='Vacant' where table_id=order_row.table_id;
  return sale_result || jsonb_build_object('orderId',order_row.order_id,'tableId',order_row.table_id);
end; $$;
revoke all on function public.settle_restaurant_order_split_through_pos(text,text,numeric,numeric) from public;
grant execute on function public.settle_restaurant_order_split_through_pos(text,text,numeric,numeric) to authenticated;
