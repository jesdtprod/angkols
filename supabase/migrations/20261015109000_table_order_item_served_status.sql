-- Return a status for each product line in a QR order so partial delivery is visible.
create or replace function public.table_request_product_status(target_request_id text, target_product_id text)
returns text language sql stable security definer set search_path = public as $function$
  select case
    when count(kitchen_line.item_id) = 0 then null
    when bool_or(kitchen_line.status = 'Served') and bool_or(kitchen_line.status <> 'Served') then 'Partially served'
    when bool_and(kitchen_line.status = 'Served') then 'Served'
    when bool_or(kitchen_line.status = 'Ready') then 'Ready'
    when bool_or(kitchen_line.status = 'Preparing') then 'Preparing'
    else 'New'
  end
  from public.kitchen_tickets kitchen_ticket
  join public.kitchen_ticket_items kitchen_line on kitchen_line.ticket_id = kitchen_ticket.ticket_id
  where kitchen_ticket.request_id = target_request_id
    and kitchen_line.product_id = target_product_id;
$function$;

-- Add the per-line status to the already-deployed QR menu function without
-- changing its pricing, stock, or table-session behavior.
do $migration$
declare function_sql text;
begin
  select pg_get_functiondef('public.public_table_menu(uuid)'::regprocedure) into function_sql;
  if position($match$'notes', item.notes) order by product.name)$match$ in function_sql) = 0 then
    raise exception 'Could not locate the QR order item payload.';
  end if;
  function_sql := replace(
    function_sql,
    $match$'notes', item.notes) order by product.name)$match$,
    $replacement$'notes', item.notes, 'kitchenStatus', public.table_request_product_status(request.request_id, item.product_id)) order by product.name)$replacement$
  );
  execute function_sql;
end;
$migration$;

grant execute on function public.table_request_product_status(text, text) to anon, authenticated;
