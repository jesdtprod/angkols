alter table public.table_order_requests drop constraint if exists table_order_requests_status_check;
alter table public.table_order_requests add constraint table_order_requests_status_check check (status in ('Pending', 'Claimed', 'Confirmed', 'Rejected', 'Cancelled'));

create or replace function public.cancel_table_order_request(target_request_id text)
returns public.table_order_requests language plpgsql security definer set search_path = public as $$
declare request_row public.table_order_requests;
begin
  select * into request_row from public.table_order_requests where request_id = target_request_id for update;
  if not found then raise exception 'This request was not found.'; end if;
  if request_row.status not in ('Pending', 'Claimed') then raise exception 'Only unconfirmed requests can be cancelled.'; end if;
  if not (public.has_permission('pos') or public.has_permission('waiterQueue')) or not public.can_access_branch(request_row.branch_id) then raise exception 'Access denied.'; end if;
  if request_row.status = 'Claimed' and request_row.claimed_by is distinct from auth.uid() then raise exception 'Only the waiter who claimed this request can cancel it.'; end if;
  update public.table_order_requests set status = 'Cancelled' where request_id = request_row.request_id returning * into request_row;
  return request_row;
end;
$$;

create or replace function public.cancel_table_order_request_item(target_request_id text, target_item_id uuid)
returns jsonb language plpgsql security definer set search_path = public as $$
declare request_row public.table_order_requests; remaining_count integer;
begin
  select * into request_row from public.table_order_requests where request_id = target_request_id for update;
  if not found or request_row.status not in ('Pending', 'Claimed') then raise exception 'Only unconfirmed request items can be cancelled.'; end if;
  if not (public.has_permission('pos') or public.has_permission('waiterQueue')) or not public.can_access_branch(request_row.branch_id) then raise exception 'Access denied.'; end if;
  if request_row.status = 'Claimed' and request_row.claimed_by is distinct from auth.uid() then raise exception 'Only the waiter who claimed this request can cancel an item.'; end if;
  delete from public.table_order_request_items where request_id = target_request_id and item_id = target_item_id;
  if not found then raise exception 'Order item was not found.'; end if;
  select count(*) into remaining_count from public.table_order_request_items where request_id = target_request_id;
  if remaining_count = 0 then update public.table_order_requests set status = 'Cancelled' where request_id = target_request_id; end if;
  return jsonb_build_object('remainingItems', remaining_count, 'cancelledRequest', remaining_count = 0);
end;
$$;

grant execute on function public.cancel_table_order_request(text), public.cancel_table_order_request_item(text, uuid) to authenticated;
