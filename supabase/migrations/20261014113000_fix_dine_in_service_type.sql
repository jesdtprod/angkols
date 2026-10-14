create or replace function public.record_sale_with_service(
  target_branch_id text, sale_lines jsonb, payment_type_input text,
  customer_id_input text default null, discount_input numeric default 0, cash_tendered_input numeric default 0,
  service_type_input text default 'Takeout', restaurant_table_id_input text default null,
  service_recipient_input text default '', service_phone_input text default '', service_address_input text default ''
) returns jsonb language plpgsql security definer set search_path = public as $$
declare
  sale_result jsonb;
  sale_id_value text;
  normalized_service_type text := case lower(trim(coalesce(service_type_input, 'Takeout')))
    when 'dine-in' then 'Dine-in'
    when 'takeout' then 'Takeout'
    when 'delivery' then 'Delivery'
    else trim(coalesce(service_type_input, ''))
  end;
begin
  if normalized_service_type not in ('Dine-in', 'Takeout', 'Delivery') then raise exception 'Choose Dine-in, Takeout, or Delivery.'; end if;
  if normalized_service_type = 'Dine-in' then
    if restaurant_table_id_input is null or not exists(select 1 from public.restaurant_tables where table_id = restaurant_table_id_input and branch_id = target_branch_id) then raise exception 'Choose a dining table for a dine-in sale.'; end if;
  elsif restaurant_table_id_input is not null then restaurant_table_id_input := null;
  end if;
  if normalized_service_type = 'Delivery' and nullif(trim(coalesce(service_address_input, '')), '') is null then raise exception 'Enter the delivery address.'; end if;
  sale_result := public.record_sale(target_branch_id, sale_lines, payment_type_input, customer_id_input, discount_input, cash_tendered_input);
  sale_id_value := sale_result ->> 'saleId';
  update public.sales set service_type = normalized_service_type, restaurant_table_id = restaurant_table_id_input,
    service_recipient = trim(coalesce(service_recipient_input, '')), service_phone = trim(coalesce(service_phone_input, '')), service_address = trim(coalesce(service_address_input, ''))
  where sale_id = sale_id_value;
  return sale_result || jsonb_build_object('serviceType', normalized_service_type, 'tableId', restaurant_table_id_input, 'recipient', trim(coalesce(service_recipient_input, '')), 'phone', trim(coalesce(service_phone_input, '')), 'address', trim(coalesce(service_address_input, '')));
end;
$$;

revoke all on function public.record_sale_with_service(text, jsonb, text, text, numeric, numeric, text, text, text, text, text) from public;
grant execute on function public.record_sale_with_service(text, jsonb, text, text, numeric, numeric, text, text, text, text, text) to authenticated;
