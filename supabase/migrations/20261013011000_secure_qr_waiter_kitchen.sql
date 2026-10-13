create or replace function public.confirm_table_order_request(target_request_id text) returns jsonb language plpgsql security definer set search_path=public as $$
declare r public.table_order_requests; order_id_value text; ticket_id_value text:=public.new_pos_id('KOT'); item record; kitchen_line_count integer;
begin
  select * into r from public.table_order_requests where request_id=target_request_id for update;
  if not found or r.status <> 'Claimed' then raise exception 'This request must be claimed before it can be confirmed.'; end if;
  if r.claimed_by is distinct from auth.uid() then raise exception 'Only the waiter who claimed this request can confirm it.'; end if;
  if not public.has_permission('pos') or not public.can_access_branch(r.branch_id) then raise exception 'Access denied.'; end if;
  select order_id into order_id_value from public.restaurant_orders where table_id=r.table_id and status='Open' for update;
  if order_id_value is null then raise exception 'Open the table tab before confirming a customer order.'; end if;
  for item in select * from public.table_order_request_items where request_id=r.request_id loop
    insert into public.restaurant_order_items(order_id,product_id,qty,price,notes)
    select order_id_value,item.product_id,item.qty,coalesce(bp.price_override,p.price),item.notes from public.products p join public.branch_products bp on bp.product_id=p.product_id and bp.branch_id=r.branch_id where p.product_id=item.product_id;
  end loop;
  select count(*) into kitchen_line_count from public.table_order_request_items i join public.products p on p.product_id=i.product_id where i.request_id=r.request_id and p.kitchen_enabled;
  if kitchen_line_count > 0 then
    insert into public.kitchen_tickets(ticket_id,branch_id,table_id,request_id,order_id) values(ticket_id_value,r.branch_id,r.table_id,r.request_id,order_id_value);
    insert into public.kitchen_ticket_items(ticket_id,product_id,qty,notes) select ticket_id_value,i.product_id,i.qty,i.notes from public.table_order_request_items i join public.products p on p.product_id=i.product_id where i.request_id=r.request_id and p.kitchen_enabled;
  else ticket_id_value := null; end if;
  update public.table_order_requests set status='Confirmed',confirmed_by=auth.uid(),confirmed_at=now() where request_id=r.request_id;
  return jsonb_build_object('orderId',order_id_value,'ticketId',ticket_id_value);
end; $$;

drop function if exists public.update_kitchen_ticket_item(uuid,text);
create function public.update_kitchen_ticket_item(target_item_id uuid, status_input text) returns jsonb language plpgsql security definer set search_path=public as $$
declare ticket_id_value text; ticket_status_value text;
begin
  if status_input not in ('Preparing','Ready') or not public.has_permission('pos') then raise exception 'Invalid kitchen update.'; end if;
  select ticket_id into ticket_id_value from public.kitchen_ticket_items where item_id=target_item_id;
  if ticket_id_value is null then raise exception 'Kitchen item not found.'; end if;
  update public.kitchen_ticket_items set status=status_input where item_id=target_item_id;
  update public.kitchen_tickets t set status=case when exists(select 1 from public.kitchen_ticket_items i where i.ticket_id=t.ticket_id and i.status='New') then 'New' when exists(select 1 from public.kitchen_ticket_items i where i.ticket_id=t.ticket_id and i.status='Preparing') then 'Preparing' else 'Ready' end, ready_at=case when not exists(select 1 from public.kitchen_ticket_items i where i.ticket_id=t.ticket_id and i.status<>'Ready') then now() else null end where t.ticket_id=ticket_id_value returning status into ticket_status_value;
  return jsonb_build_object('ticketId',ticket_id_value,'ticketStatus',ticket_status_value);
end; $$;
grant execute on function public.update_kitchen_ticket_item(uuid,text) to authenticated;
