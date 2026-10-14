alter table public.restaurant_tables
  add column if not exists reservation_name text not null default '',
  add column if not exists reservation_phone text not null default '',
  add column if not exists reservation_at timestamptz,
  add column if not exists reservation_guest_count integer,
  add column if not exists reservation_notes text not null default '';

create function public.update_restaurant_table(
  target_table_id text, table_name_input text, area_input text, capacity_input integer, status_input text,
  reservation_name_input text default '', reservation_phone_input text default '', reservation_at_input timestamptz default null,
  reservation_guest_count_input integer default null, reservation_notes_input text default ''
) returns public.restaurant_tables language plpgsql security definer set search_path = public as $$
declare result public.restaurant_tables;
begin
  if not public.is_admin() then raise exception 'Only administrators can update tables.'; end if;
  if nullif(trim(table_name_input), '') is null or capacity_input is null or capacity_input < 1 or status_input not in ('Vacant','Occupied','Reserved','Cleaning') then raise exception 'Enter valid table details.'; end if;
  if exists(select 1 from public.restaurant_orders where table_id = target_table_id and status = 'Open') and status_input <> 'Occupied' then raise exception 'Settle the open table tab before changing its status.'; end if;
  if status_input = 'Reserved' and (nullif(trim(coalesce(reservation_name_input, '')), '') is null or reservation_at_input is null or reservation_guest_count_input is null or reservation_guest_count_input < 1) then
    raise exception 'Enter the guest name, party size, and reservation date and time.';
  end if;
  update public.restaurant_tables set
    name = trim(table_name_input), area = trim(coalesce(area_input, '')), capacity = capacity_input, status = status_input,
    reservation_name = case when status_input = 'Reserved' then trim(reservation_name_input) else '' end,
    reservation_phone = case when status_input = 'Reserved' then trim(coalesce(reservation_phone_input, '')) else '' end,
    reservation_at = case when status_input = 'Reserved' then reservation_at_input else null end,
    reservation_guest_count = case when status_input = 'Reserved' then reservation_guest_count_input else null end,
    reservation_notes = case when status_input = 'Reserved' then trim(coalesce(reservation_notes_input, '')) else '' end
  where table_id = target_table_id returning * into result;
  if not found then raise exception 'Table was not found.'; end if;
  return result;
end;
$$;

create or replace function public.open_restaurant_table(
  target_table_id text, guest_count_input integer default 1, customer_name_input text default ''
) returns public.restaurant_orders language plpgsql security definer set search_path = public as $$
declare table_row public.restaurant_tables; result public.restaurant_orders;
begin
  select * into table_row from public.restaurant_tables where table_id = target_table_id for update;
  if not found then raise exception 'Table was not found.'; end if;
  if not public.has_permission('pos') or not public.can_access_branch(table_row.branch_id) then raise exception 'Your account does not have access to this table.'; end if;
  if table_row.status not in ('Vacant', 'Reserved') then raise exception 'This table is not available.'; end if;
  if guest_count_input is null or guest_count_input < 1 then raise exception 'Enter at least one guest.'; end if;
  insert into public.restaurant_orders(order_id, branch_id, table_id, guest_count, customer_name, opened_by)
  values(public.new_pos_id('TBO'), table_row.branch_id, table_row.table_id, guest_count_input, trim(coalesce(customer_name_input, '')), auth.uid())
  returning * into result;
  update public.restaurant_tables set status = 'Occupied', reservation_name = '', reservation_phone = '', reservation_at = null, reservation_guest_count = null, reservation_notes = '' where table_id = table_row.table_id;
  return result;
end;
$$;

revoke all on function public.update_restaurant_table(text, text, text, integer, text, text, text, timestamptz, integer, text) from public;
grant execute on function public.update_restaurant_table(text, text, text, integer, text, text, text, timestamptz, integer, text) to authenticated;
