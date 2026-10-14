-- Kitchen marks food Ready; only the waiter who delivers it can mark it Served.
create or replace function public.mark_kitchen_ticket_served(target_ticket_id text)
returns public.kitchen_tickets language plpgsql security definer set search_path=public as $$
declare result public.kitchen_tickets;
begin
  update public.kitchen_tickets
  set status = 'Served', served_at = now()
  where ticket_id = target_ticket_id and status = 'Ready'
    and (public.has_permission('pos') or public.has_permission('waiterQueue'))
    and public.can_access_branch(branch_id)
  returning * into result;
  if not found then raise exception 'Only a ready ticket in your branch can be marked served.'; end if;
  return result;
end;
$$;

grant execute on function public.mark_kitchen_ticket_served(text) to authenticated;
