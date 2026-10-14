-- A waiter can hand off ready items one at a time. The ticket is served only
-- after its final ready item is delivered.
alter table public.kitchen_ticket_items drop constraint if exists kitchen_ticket_items_status_check;
alter table public.kitchen_ticket_items add constraint kitchen_ticket_items_status_check check(status in ('New', 'Preparing', 'Ready', 'Served'));

create or replace function public.mark_kitchen_ticket_item_served(target_item_id uuid)
returns jsonb language plpgsql security definer set search_path=public as $$
declare ticket_id_value text; remaining_ready_count integer;
begin
  update public.kitchen_ticket_items item
  set status = 'Served'
  from public.kitchen_tickets ticket
  where item.item_id = target_item_id
    and item.ticket_id = ticket.ticket_id
    and item.status = 'Ready'
    and ticket.status = 'Ready'
    and (public.has_permission('pos') or public.has_permission('waiterQueue'))
    and public.can_access_branch(ticket.branch_id)
  returning item.ticket_id into ticket_id_value;

  if ticket_id_value is null then
    raise exception 'Only a ready item in your branch can be marked served.';
  end if;

  select count(*) into remaining_ready_count
  from public.kitchen_ticket_items
  where ticket_id = ticket_id_value and status <> 'Served';

  if remaining_ready_count = 0 then
    update public.kitchen_tickets set status = 'Served', served_at = now() where ticket_id = ticket_id_value;
  end if;

  return jsonb_build_object('ticketId', ticket_id_value, 'ticketServed', remaining_ready_count = 0);
end;
$$;

grant execute on function public.mark_kitchen_ticket_item_served(uuid) to authenticated;
