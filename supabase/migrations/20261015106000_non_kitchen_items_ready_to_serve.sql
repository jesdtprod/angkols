-- Products not routed to the kitchen still need a waiter delivery/served state.
-- They use Ready tickets, which the KDS excludes because their products are not kitchen-enabled.
create or replace function public.add_restaurant_order_item_with_ticket(
  target_order_id text, target_product_id text, qty_input numeric, price_input numeric, notes_input text default ''
) returns jsonb language plpgsql security definer set search_path=public as $$
declare order_row public.restaurant_orders; order_item public.restaurant_order_items; ticket_id_value text; kitchen_item_id uuid; is_kitchen_item boolean;
begin
  select * into order_row from public.restaurant_orders where order_id = target_order_id for update;
  if not found or order_row.status <> 'Open' then raise exception 'This table tab is no longer open.'; end if;
  if not public.has_permission('pos') or not public.can_access_branch(order_row.branch_id) then raise exception 'Your account does not have access to this tab.'; end if;
  if qty_input is null or qty_input <= 0 or price_input is null or price_input < 0 then raise exception 'Enter a valid quantity and price.'; end if;
  select kitchen_enabled into is_kitchen_item from public.products where product_id = target_product_id and archived_at is null;
  if is_kitchen_item is null then raise exception 'Choose an active product.'; end if;

  insert into public.restaurant_order_items(order_id, product_id, qty, price, notes)
  values(target_order_id, target_product_id, qty_input, price_input, trim(coalesce(notes_input, '')))
  returning * into order_item;

  if is_kitchen_item then
    select ticket_id into ticket_id_value from public.kitchen_tickets where order_id = order_row.order_id and status = 'New' order by created_at asc limit 1 for update;
    if ticket_id_value is null then
      ticket_id_value := public.new_pos_id('KOT');
      insert into public.kitchen_tickets(ticket_id, branch_id, table_id, order_id) values(ticket_id_value, order_row.branch_id, order_row.table_id, order_row.order_id);
    end if;
    select item_id into kitchen_item_id from public.kitchen_ticket_items where ticket_id = ticket_id_value and product_id = target_product_id and notes = order_item.notes and status = 'New' limit 1 for update;
    if kitchen_item_id is null then
      insert into public.kitchen_ticket_items(ticket_id, product_id, qty, notes) values(ticket_id_value, target_product_id, qty_input, order_item.notes);
    else
      update public.kitchen_ticket_items set qty = qty + qty_input where item_id = kitchen_item_id;
    end if;
  else
    ticket_id_value := public.new_pos_id('KOT');
    insert into public.kitchen_tickets(ticket_id, branch_id, table_id, order_id, status, ready_at)
    values(ticket_id_value, order_row.branch_id, order_row.table_id, order_row.order_id, 'Ready', now());
    insert into public.kitchen_ticket_items(ticket_id, product_id, qty, notes, status)
    values(ticket_id_value, target_product_id, qty_input, order_item.notes, 'Ready');
  end if;
  return jsonb_build_object('orderItemId', order_item.item_id, 'ticketId', ticket_id_value);
end;
$$;

create or replace function public.confirm_table_order_request(target_request_id text)
returns jsonb language plpgsql security definer set search_path = public as $$
declare request_row public.table_order_requests; order_id_value text; ticket_id_value text := public.new_pos_id('KOT'); ready_ticket_id_value text; line_row record; kitchen_line_count integer; ready_line_count integer;
begin
  select * into request_row from public.table_order_requests where request_id = target_request_id for update;
  if not found or request_row.status <> 'Claimed' then raise exception 'This request must be claimed before it can be confirmed.'; end if;
  if request_row.claimed_by is distinct from auth.uid() then raise exception 'Only the waiter who claimed this request can confirm it.'; end if;
  if not (public.has_permission('pos') or public.has_permission('waiterQueue')) or not public.can_access_branch(request_row.branch_id) then raise exception 'Access denied.'; end if;
  select order_id into order_id_value from public.restaurant_orders where table_id = request_row.table_id and status = 'Open' for update;
  if order_id_value is null then
    insert into public.restaurant_orders(order_id, branch_id, table_id, guest_count, customer_name, opened_by) values(public.new_pos_id('TBO'), request_row.branch_id, request_row.table_id, 1, 'QR Guest', auth.uid()) returning order_id into order_id_value;
    update public.restaurant_tables set status = 'Occupied', reservation_name = '', reservation_phone = '', reservation_at = null, reservation_guest_count = null, reservation_notes = '' where table_id = request_row.table_id;
  end if;
  for line_row in select * from public.table_order_request_items where request_id = request_row.request_id loop
    insert into public.restaurant_order_items(order_id, product_id, qty, price, notes, source_request_id)
    values(order_id_value, line_row.product_id, line_row.qty, public.current_branch_product_menu_price(request_row.branch_id, line_row.product_id), line_row.notes, request_row.request_id);
  end loop;
  select count(*) filter (where menu_product.kitchen_enabled), count(*) filter (where not menu_product.kitchen_enabled) into kitchen_line_count, ready_line_count
  from public.table_order_request_items request_line join public.products menu_product on menu_product.product_id = request_line.product_id where request_line.request_id = request_row.request_id;
  if kitchen_line_count > 0 then
    insert into public.kitchen_tickets(ticket_id, branch_id, table_id, request_id, order_id) values(ticket_id_value, request_row.branch_id, request_row.table_id, request_row.request_id, order_id_value);
    insert into public.kitchen_ticket_items(ticket_id, product_id, qty, notes)
    select ticket_id_value, request_line.product_id, request_line.qty, request_line.notes from public.table_order_request_items request_line join public.products menu_product on menu_product.product_id = request_line.product_id where request_line.request_id = request_row.request_id and menu_product.kitchen_enabled;
  else ticket_id_value := null; end if;
  if ready_line_count > 0 then
    ready_ticket_id_value := public.new_pos_id('KOT');
    insert into public.kitchen_tickets(ticket_id, branch_id, table_id, request_id, order_id, status, ready_at) values(ready_ticket_id_value, request_row.branch_id, request_row.table_id, request_row.request_id, order_id_value, 'Ready', now());
    insert into public.kitchen_ticket_items(ticket_id, product_id, qty, notes, status)
    select ready_ticket_id_value, request_line.product_id, request_line.qty, request_line.notes, 'Ready' from public.table_order_request_items request_line join public.products menu_product on menu_product.product_id = request_line.product_id where request_line.request_id = request_row.request_id and not menu_product.kitchen_enabled;
  end if;
  update public.table_order_requests set status = 'Confirmed', order_id = order_id_value, confirmed_by = auth.uid(), confirmed_at = now() where request_id = request_row.request_id;
  return jsonb_build_object('orderId', order_id_value, 'ticketId', coalesce(ticket_id_value, ready_ticket_id_value), 'readyTicketId', ready_ticket_id_value);
end;
$$;

-- Make existing open-tab non-kitchen lines available to serve as well.
with missing_lines as (
  select order_row.order_id, order_row.branch_id, order_row.table_id, order_line.product_id, order_line.qty, order_line.notes
  from public.restaurant_orders order_row
  join public.restaurant_order_items order_line on order_line.order_id = order_row.order_id
  join public.products product on product.product_id = order_line.product_id
  where order_row.status = 'Open' and product.kitchen_enabled is not true
    and not exists (select 1 from public.kitchen_ticket_items kitchen_line join public.kitchen_tickets ticket on ticket.ticket_id = kitchen_line.ticket_id where ticket.order_id = order_row.order_id and kitchen_line.product_id = order_line.product_id and kitchen_line.notes = order_line.notes)
), ready_tickets as (
  insert into public.kitchen_tickets(ticket_id, branch_id, table_id, order_id, status, ready_at)
  select public.new_pos_id('KOT'), branch_id, table_id, order_id, 'Ready', now() from missing_lines group by branch_id, table_id, order_id
  returning ticket_id, order_id
)
insert into public.kitchen_ticket_items(ticket_id, product_id, qty, notes, status)
select ticket.ticket_id, line.product_id, sum(line.qty), line.notes, 'Ready'
from missing_lines line join ready_tickets ticket on ticket.order_id = line.order_id
group by ticket.ticket_id, line.product_id, line.notes;

grant execute on function public.add_restaurant_order_item_with_ticket(text, text, numeric, numeric, text), public.confirm_table_order_request(text) to authenticated;
