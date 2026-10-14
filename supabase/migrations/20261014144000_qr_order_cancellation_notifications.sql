-- Notify the guest's active QR page when a waiter edits or cancels a request.
alter table public.table_order_requests add column if not exists customer_notice text not null default '';
alter table public.table_order_requests add column if not exists customer_notice_at timestamptz;

create or replace function public.cancel_table_order_request(target_request_id text)
returns public.table_order_requests language plpgsql security definer set search_path = public as $$
declare request_row public.table_order_requests;
begin
  select * into request_row from public.table_order_requests where request_id = target_request_id for update;
  if not found then raise exception 'This request was not found.'; end if;
  if request_row.status not in ('Pending', 'Claimed') then raise exception 'Only unconfirmed requests can be cancelled.'; end if;
  if not (public.has_permission('pos') or public.has_permission('waiterQueue')) or not public.can_access_branch(request_row.branch_id) then raise exception 'Access denied.'; end if;
  if request_row.status = 'Claimed' and request_row.claimed_by is distinct from auth.uid() then raise exception 'Only the waiter who claimed this request can cancel it.'; end if;
  update public.table_order_requests
  set status = 'Cancelled', customer_notice = 'Your order was cancelled by the waiter.', customer_notice_at = now()
  where request_id = request_row.request_id returning * into request_row;
  return request_row;
end;
$$;

create or replace function public.cancel_table_order_request_item(target_request_id text, target_item_id uuid)
returns jsonb language plpgsql security definer set search_path = public as $$
declare request_row public.table_order_requests; remaining_count integer; item_name text;
begin
  select * into request_row from public.table_order_requests where request_id = target_request_id for update;
  if not found or request_row.status not in ('Pending', 'Claimed') then raise exception 'Only unconfirmed request items can be cancelled.'; end if;
  if not (public.has_permission('pos') or public.has_permission('waiterQueue')) or not public.can_access_branch(request_row.branch_id) then raise exception 'Access denied.'; end if;
  if request_row.status = 'Claimed' and request_row.claimed_by is distinct from auth.uid() then raise exception 'Only the waiter who claimed this request can cancel an item.'; end if;
  select p.name into item_name from public.table_order_request_items i join public.products p on p.product_id = i.product_id where i.request_id = target_request_id and i.item_id = target_item_id;
  if item_name is null then raise exception 'Order item was not found.'; end if;
  delete from public.table_order_request_items where request_id = target_request_id and item_id = target_item_id;
  select count(*) into remaining_count from public.table_order_request_items where request_id = target_request_id;
  if remaining_count = 0 then
    update public.table_order_requests set status = 'Cancelled', customer_notice = 'Your order was cancelled because all items were removed by the waiter.', customer_notice_at = now() where request_id = target_request_id;
  else
    update public.table_order_requests set customer_notice = item_name || ' was removed from your order by the waiter.', customer_notice_at = now() where request_id = target_request_id;
  end if;
  return jsonb_build_object('remainingItems', remaining_count, 'cancelledRequest', remaining_count = 0);
end;
$$;
