-- Do not timestamp existing lines: historical staff/timing must remain unknown.
alter table public.kitchen_ticket_items
  add column if not exists created_at timestamptz,
  add column if not exists started_at timestamptz,
  add column if not exists ready_at timestamptz,
  add column if not exists served_at timestamptz,
  add column if not exists started_by uuid references public.profiles(user_id) on delete set null,
  add column if not exists ready_by uuid references public.profiles(user_id) on delete set null,
  add column if not exists served_by uuid references public.profiles(user_id) on delete set null,
  add column if not exists requires_kitchen boolean;
alter table public.kitchen_tickets
  add column if not exists served_by uuid references public.profiles(user_id) on delete set null;

create or replace function public.track_kitchen_item_performance()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  if tg_op = 'INSERT' then
    new.created_at := now();
    select kitchen_enabled into new.requires_kitchen from public.products where product_id = new.product_id;
    new.started_at := null; new.started_by := null;
    new.ready_at := null; new.ready_by := null;
    new.served_at := null; new.served_by := null;
  else
    new.created_at := old.created_at;
    new.requires_kitchen := old.requires_kitchen;
    new.started_at := old.started_at; new.started_by := old.started_by;
    new.ready_at := old.ready_at; new.ready_by := old.ready_by;
    new.served_at := old.served_at; new.served_by := old.served_by;
    if new.status is not distinct from old.status then return new; end if;
  end if;
  if new.status = 'Preparing' and new.started_at is null then
    new.started_at := now(); new.started_by := auth.uid();
  elsif new.status = 'Ready' and new.ready_at is null then
    new.ready_at := now();
    -- Automatic readiness for drinks/packaged goods is not kitchen output.
    if coalesce(new.requires_kitchen, true) then new.ready_by := auth.uid(); end if;
  elsif new.status = 'Served' and new.served_at is null then
    new.served_at := now(); new.served_by := auth.uid();
  end if;
  return new;
end;
$$;
drop trigger if exists track_kitchen_item_performance on public.kitchen_ticket_items;
create trigger track_kitchen_item_performance before insert or update on public.kitchen_ticket_items
  for each row execute function public.track_kitchen_item_performance();

create or replace function public.track_kitchen_ticket_server()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  new.served_by := old.served_by;
  if new.status = 'Served' and old.status is distinct from 'Served' and new.served_by is null then
    new.served_by := auth.uid();
  end if;
  return new;
end;
$$;
drop trigger if exists track_kitchen_ticket_server on public.kitchen_tickets;
create trigger track_kitchen_ticket_server before update on public.kitchen_tickets
  for each row execute function public.track_kitchen_ticket_server();

create or replace function public.get_service_performance_report(target_branch_id text, date_from_input date, date_to_input date)
returns jsonb language plpgsql stable security definer set search_path = public as $$
begin
  if not public.is_admin() or not public.can_access_branch(target_branch_id) then
    raise exception 'Only administrators can access performance reports.';
  end if;
  if date_from_input is null or date_to_input is null or date_from_input > date_to_input then
    raise exception 'Choose a valid report date range.';
  end if;
  return jsonb_build_object(
    'items', (select coalesce(jsonb_agg(jsonb_build_object(
      'id', i.item_id, 'ticketId', t.ticket_id, 'tableName', tables.name, 'productName', p.name, 'qty', i.qty,
      'status', case when i.status = 'Ready' and t.status = 'Served' then 'Served' else i.status end,
      'requiresKitchen', coalesce(i.requires_kitchen, p.kitchen_enabled, true), 'legacy', i.created_at is null,
      'createdAt', coalesce(i.created_at, t.created_at), 'startedAt', i.started_at, 'readyAt', i.ready_at,
      'servedAt', case when i.status = 'Ready' and t.status = 'Served' and t.served_by is not null then t.served_at else i.served_at end,
      'startedBy', i.started_by, 'startedName', starter.full_name,
      'readyBy', i.ready_by, 'readyName', preparer.full_name,
      'servedBy', case when i.status = 'Ready' and t.status = 'Served' then t.served_by else i.served_by end,
      'servedName', case when i.status = 'Ready' and t.status = 'Served' then ticket_server.full_name else server.full_name end
    ) order by coalesce(i.created_at, t.created_at), i.item_id), '[]'::jsonb)
      from public.kitchen_ticket_items i join public.kitchen_tickets t on t.ticket_id = i.ticket_id
      join public.products p on p.product_id = i.product_id
      join public.restaurant_tables tables on tables.table_id = t.table_id
      left join public.profiles starter on starter.user_id = i.started_by
      left join public.profiles preparer on preparer.user_id = i.ready_by
      left join public.profiles server on server.user_id = i.served_by
      left join public.profiles ticket_server on ticket_server.user_id = t.served_by
      where t.branch_id = target_branch_id
        and (coalesce(i.created_at, t.created_at) at time zone 'Asia/Manila')::date between date_from_input and date_to_input),
    'requests', (select coalesce(jsonb_agg(jsonb_build_object(
      'id', r.request_id, 'status', r.status, 'tableName', tables.name, 'createdAt', r.created_at,
      'claimedAt', r.claimed_at, 'claimedBy', r.claimed_by, 'claimedName', claimer.full_name,
      'confirmedAt', r.confirmed_at, 'confirmedBy', r.confirmed_by, 'confirmedName', confirmer.full_name
    ) order by r.created_at, r.request_id), '[]'::jsonb)
      from public.table_order_requests r join public.restaurant_tables tables on tables.table_id = r.table_id
      left join public.profiles claimer on claimer.user_id = r.claimed_by
      left join public.profiles confirmer on confirmer.user_id = r.confirmed_by
      where r.branch_id = target_branch_id and (r.created_at at time zone 'Asia/Manila')::date between date_from_input and date_to_input)
  );
end;
$$;
revoke all on function public.track_kitchen_item_performance(), public.track_kitchen_ticket_server() from public;
revoke all on function public.get_service_performance_report(text, date, date) from public;
grant execute on function public.get_service_performance_report(text, date, date) to authenticated;
