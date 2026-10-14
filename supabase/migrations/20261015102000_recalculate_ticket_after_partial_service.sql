-- A partially served ticket resumes the state of its remaining kitchen items.
create or replace function public.mark_kitchen_ticket_item_served(target_item_id uuid)
returns jsonb language plpgsql security definer set search_path=public as $$
declare ticket_id_value text; remaining_count integer;
begin
  update public.kitchen_ticket_items kitchen_item
  set status = 'Served'
  from public.kitchen_tickets ticket
  where kitchen_item.item_id = target_item_id
    and kitchen_item.ticket_id = ticket.ticket_id
    and kitchen_item.status = 'Ready'
    and (public.has_permission('pos') or public.has_permission('waiterQueue'))
    and public.can_access_branch(ticket.branch_id)
  returning kitchen_item.ticket_id into ticket_id_value;

  if ticket_id_value is null then raise exception 'Only a ready item in your branch can be marked served.'; end if;

  select count(*) into remaining_count
  from public.kitchen_ticket_items
  where ticket_id = ticket_id_value and status <> 'Served';

  update public.kitchen_tickets ticket
  set status = case
    when not exists(select 1 from public.kitchen_ticket_items line where line.ticket_id = ticket.ticket_id and line.status <> 'Served') then 'Served'
    when exists(select 1 from public.kitchen_ticket_items line where line.ticket_id = ticket.ticket_id and line.status = 'New') then 'New'
    when exists(select 1 from public.kitchen_ticket_items line where line.ticket_id = ticket.ticket_id and line.status = 'Preparing') then 'Preparing'
    else 'Ready'
  end,
  served_at = case when remaining_count = 0 then coalesce(ticket.served_at, now()) else null end
  where ticket.ticket_id = ticket_id_value;

  return jsonb_build_object('ticketId', ticket_id_value, 'ticketServed', remaining_count = 0);
end;
$$;

-- Repair tickets created before partial serving recalculated the ticket state.
update public.kitchen_tickets ticket
set status = case
  when not exists(select 1 from public.kitchen_ticket_items line where line.ticket_id = ticket.ticket_id and line.status <> 'Served') then 'Served'
  when exists(select 1 from public.kitchen_ticket_items line where line.ticket_id = ticket.ticket_id and line.status = 'New') then 'New'
  when exists(select 1 from public.kitchen_ticket_items line where line.ticket_id = ticket.ticket_id and line.status = 'Preparing') then 'Preparing'
  else 'Ready'
end,
served_at = case when not exists(select 1 from public.kitchen_ticket_items line where line.ticket_id = ticket.ticket_id and line.status <> 'Served') then coalesce(ticket.served_at, now()) else null end
where exists(select 1 from public.kitchen_ticket_items line where line.ticket_id = ticket.ticket_id);

grant execute on function public.mark_kitchen_ticket_item_served(uuid) to authenticated;
