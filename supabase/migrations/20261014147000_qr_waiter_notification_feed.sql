-- Public, token-scoped notification feed for an active QR page.
create or replace function public.public_table_order_notifications(token_input uuid)
returns jsonb language plpgsql security definer set search_path = public as $$
declare table_row public.restaurant_tables;
begin
  select * into table_row from public.restaurant_tables where qr_token = token_input;
  if not found then raise exception 'Invalid table QR code.'; end if;
  return (
    select coalesce(jsonb_agg(jsonb_build_object(
      'requestId', request_id, 'message', customer_notice, 'createdAt', customer_notice_at
    ) order by customer_notice_at desc), '[]'::jsonb)
    from (
      select request_id, customer_notice, customer_notice_at
      from public.table_order_requests
      where table_id = table_row.table_id and customer_notice <> '' and customer_notice_at is not null
      order by customer_notice_at desc limit 12
    ) notices
  );
end;
$$;

grant execute on function public.public_table_order_notifications(uuid) to anon, authenticated;
