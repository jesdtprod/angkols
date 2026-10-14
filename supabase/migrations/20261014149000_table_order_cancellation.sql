-- Table-tab items that reached the kitchen remain immutable. Ready-to-serve
-- items can still be removed before payment.
create or replace function public.remove_restaurant_order_item(target_item_id uuid)
returns void language plpgsql security definer set search_path=public as $$
declare order_row public.restaurant_orders; item_row public.restaurant_order_items;
begin
  select item.* into item_row from public.restaurant_order_items item where item.item_id = target_item_id for update;
  if not found then raise exception 'Order item was not found.'; end if;
  select * into order_row from public.restaurant_orders where order_id = item_row.order_id for update;
  if not found or order_row.status <> 'Open' or not public.has_permission('pos') or not public.can_access_branch(order_row.branch_id) then
    raise exception 'This table order cannot be changed.';
  end if;
  if exists (
    select 1 from public.kitchen_ticket_items kitchen_item
    join public.kitchen_tickets ticket on ticket.ticket_id = kitchen_item.ticket_id
    where ticket.order_id = order_row.order_id and kitchen_item.product_id = item_row.product_id
  ) then
    raise exception 'This item was already sent to kitchen and cannot be removed.';
  end if;
  delete from public.restaurant_order_items where item_id = item_row.item_id;
end;
$$;

create or replace function public.cancel_restaurant_order(target_order_id text)
returns void language plpgsql security definer set search_path=public as $$
declare order_row public.restaurant_orders;
begin
  select * into order_row from public.restaurant_orders where order_id = target_order_id for update;
  if not found or order_row.status <> 'Open' or not public.has_permission('pos') or not public.can_access_branch(order_row.branch_id) then
    raise exception 'This table order cannot be cancelled.';
  end if;
  if exists (select 1 from public.kitchen_tickets where order_id = order_row.order_id) then
    raise exception 'This order has items sent to kitchen and cannot be cancelled.';
  end if;
  update public.restaurant_orders set status = 'Cancelled', closed_at = now() where order_id = order_row.order_id;
  update public.restaurant_tables set status = 'Vacant' where table_id = order_row.table_id;
end;
$$;

grant execute on function public.remove_restaurant_order_item(uuid), public.cancel_restaurant_order(text) to authenticated;
