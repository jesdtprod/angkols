alter table public.kitchen_tickets drop constraint if exists kitchen_tickets_status_check;
alter table public.kitchen_tickets add constraint kitchen_tickets_status_check check(status in ('New','Preparing','Ready','Served'));
alter table public.kitchen_tickets add column if not exists served_at timestamptz;

create or replace function public.update_kitchen_ticket_item(target_item_id uuid, status_input text) returns jsonb language plpgsql security definer set search_path=public as $$
declare ticket_id_value text; ticket_status_value text;
begin
  if status_input not in ('Preparing','Ready') or not (public.has_permission('pos') or public.has_permission('kitchenDisplay')) then raise exception 'Invalid kitchen update.'; end if;
  select ticket_id into ticket_id_value from public.kitchen_ticket_items where item_id=target_item_id;
  if ticket_id_value is null then raise exception 'Kitchen item not found.'; end if;
  update public.kitchen_ticket_items set status=status_input where item_id=target_item_id;
  update public.kitchen_tickets t set status=case when exists(select 1 from public.kitchen_ticket_items i where i.ticket_id=t.ticket_id and i.status='New') then 'New' when exists(select 1 from public.kitchen_ticket_items i where i.ticket_id=t.ticket_id and i.status='Preparing') then 'Preparing' else 'Ready' end, ready_at=case when not exists(select 1 from public.kitchen_ticket_items i where i.ticket_id=t.ticket_id and i.status<>'Ready') then now() else null end where t.ticket_id=ticket_id_value returning status into ticket_status_value;
  return jsonb_build_object('ticketId',ticket_id_value,'ticketStatus',ticket_status_value);
end; $$;

create or replace function public.mark_kitchen_ticket_served(target_ticket_id text) returns public.kitchen_tickets language plpgsql security definer set search_path=public as $$
declare result public.kitchen_tickets;
begin
  update public.kitchen_tickets set status='Served',served_at=now() where ticket_id=target_ticket_id and status='Ready' and (public.has_permission('pos') or public.has_permission('kitchenDisplay')) and public.can_access_branch(branch_id) returning * into result;
  if not found then raise exception 'Only a ready ticket in your branch can be marked served.'; end if;
  return result;
end; $$;
grant execute on function public.update_kitchen_ticket_item(uuid,text),public.mark_kitchen_ticket_served(text) to authenticated;
