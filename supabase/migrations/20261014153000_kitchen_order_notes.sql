-- Kitchen receives the guest's overall QR request note as well as line-item notes.
alter table public.kitchen_tickets add column if not exists order_note text not null default '';

update public.kitchen_tickets ticket
set order_note = request.customer_note
from public.table_order_requests request
where request.request_id = ticket.request_id
  and coalesce(ticket.order_note, '') = ''
  and coalesce(request.customer_note, '') <> '';

create or replace function public.populate_kitchen_ticket_order_note()
returns trigger language plpgsql security definer set search_path=public as $$
begin
  if new.request_id is not null and coalesce(new.order_note, '') = '' then
    select customer_note into new.order_note from public.table_order_requests where request_id = new.request_id;
    new.order_note := coalesce(new.order_note, '');
  end if;
  return new;
end;
$$;

drop trigger if exists kitchen_ticket_order_note_trigger on public.kitchen_tickets;
create trigger kitchen_ticket_order_note_trigger
before insert or update of request_id on public.kitchen_tickets
for each row execute function public.populate_kitchen_ticket_order_note();
