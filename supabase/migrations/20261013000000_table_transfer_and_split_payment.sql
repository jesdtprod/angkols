create or replace function public.transfer_restaurant_table(target_order_id text, destination_table_id text)
returns public.restaurant_orders language plpgsql security definer set search_path = public as $$
declare source_order public.restaurant_orders; destination_table public.restaurant_tables; result public.restaurant_orders;
begin
  select * into source_order from public.restaurant_orders where order_id=target_order_id for update;
  if not found or source_order.status <> 'Open' then raise exception 'This table tab is no longer open.'; end if;
  select * into destination_table from public.restaurant_tables where table_id=destination_table_id for update;
  if not found or destination_table.branch_id <> source_order.branch_id then raise exception 'Choose a table in the same branch.'; end if;
  if not public.has_permission('pos') or not public.can_access_branch(source_order.branch_id) then raise exception 'Your account does not have access to this table.'; end if;
  if destination_table.status <> 'Vacant' then raise exception 'The destination table must be vacant.'; end if;
  update public.restaurant_orders set table_id=destination_table_id where order_id=target_order_id returning * into result;
  update public.restaurant_tables set status='Vacant' where table_id=source_order.table_id;
  update public.restaurant_tables set status='Occupied' where table_id=destination_table_id;
  return result;
end; $$;

create or replace function public.record_split_sale_with_service(target_branch_id text, sale_lines jsonb, customer_id_input text, cash_received_input numeric, discount_input numeric default 0, service_type_input text default 'Takeout', restaurant_table_id_input text default null, service_recipient_input text default '', service_phone_input text default '', service_address_input text default '')
returns jsonb language plpgsql security definer set search_path=public as $$
declare sale_result jsonb; sale_id_value text; total_value numeric; payment_id_value text;
begin
  if customer_id_input is null then raise exception 'Select the customer who will receive the remaining credit.'; end if;
  sale_result := public.record_sale_with_service(target_branch_id,sale_lines,'credit',customer_id_input,discount_input,0,service_type_input,restaurant_table_id_input,service_recipient_input,service_phone_input,service_address_input);
  sale_id_value := sale_result->>'saleId'; total_value := (sale_result->>'total')::numeric;
  if cash_received_input is null or cash_received_input <= 0 or cash_received_input >= total_value then raise exception 'Cash received must be greater than zero and less than the total.'; end if;
  payment_id_value := public.new_pos_id('CPY');
  insert into public.credit_payments(payment_id,branch_id,sale_id,customer_id,amount,notes,created_by) values(payment_id_value,target_branch_id,sale_id_value,customer_id_input,cash_received_input,'Initial split-payment cash',auth.uid());
  update public.sales set cash_tendered=cash_received_input where sale_id=sale_id_value;
  return sale_result || jsonb_build_object('paymentType','split','cashReceived',cash_received_input,'creditBalance',total_value-cash_received_input,'paymentId',payment_id_value);
end; $$;

revoke all on function public.transfer_restaurant_table(text,text) from public;
revoke all on function public.record_split_sale_with_service(text,jsonb,text,numeric,numeric,text,text,text,text,text) from public;
grant execute on function public.transfer_restaurant_table(text,text) to authenticated;
grant execute on function public.record_split_sale_with_service(text,jsonb,text,numeric,numeric,text,text,text,text,text) to authenticated;
