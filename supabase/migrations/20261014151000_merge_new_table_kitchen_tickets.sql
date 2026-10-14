-- Keep one editable KOT per active table tab. Once preparation starts, a new
-- add-on remains a separate ticket so the kitchen never loses in-progress work.
create or replace function public.add_restaurant_order_item_with_ticket(
  target_order_id text, target_product_id text, qty_input numeric, price_input numeric, notes_input text default ''
) returns jsonb language plpgsql security definer set search_path=public as $$
declare order_row public.restaurant_orders; order_item public.restaurant_order_items; ticket_id_value text; kitchen_item_id uuid;
begin
  select * into order_row from public.restaurant_orders where order_id = target_order_id for update;
  if not found or order_row.status <> 'Open' then raise exception 'This table tab is no longer open.'; end if;
  if not public.has_permission('pos') or not public.can_access_branch(order_row.branch_id) then raise exception 'Your account does not have access to this tab.'; end if;
  if qty_input is null or qty_input <= 0 or price_input is null or price_input < 0 then raise exception 'Enter a valid quantity and price.'; end if;
  if not exists(select 1 from public.products where product_id = target_product_id and archived_at is null) then raise exception 'Choose an active product.'; end if;

  insert into public.restaurant_order_items(order_id, product_id, qty, price, notes)
  values(target_order_id, target_product_id, qty_input, price_input, trim(coalesce(notes_input, '')))
  returning * into order_item;

  if exists(select 1 from public.products where product_id = target_product_id and kitchen_enabled) then
    select ticket_id into ticket_id_value from public.kitchen_tickets
    where order_id = order_row.order_id and status = 'New'
    order by created_at asc limit 1 for update;

    if ticket_id_value is null then
      ticket_id_value := public.new_pos_id('KOT');
      insert into public.kitchen_tickets(ticket_id, branch_id, table_id, order_id)
      values(ticket_id_value, order_row.branch_id, order_row.table_id, order_row.order_id);
    end if;

    select item_id into kitchen_item_id from public.kitchen_ticket_items
    where ticket_id = ticket_id_value and product_id = target_product_id and notes = order_item.notes and status = 'New'
    limit 1 for update;
    if kitchen_item_id is null then
      insert into public.kitchen_ticket_items(ticket_id, product_id, qty, notes)
      values(ticket_id_value, target_product_id, qty_input, order_item.notes);
    else
      update public.kitchen_ticket_items set qty = qty + qty_input where item_id = kitchen_item_id;
    end if;
  end if;

  return jsonb_build_object('orderItemId', order_item.item_id, 'ticketId', ticket_id_value);
end;
$$;

-- Consolidate existing unstarted tickets, including the duplicate Pork Sisig tickets.
do $$
declare ticket_group record; target_ticket_id text; source_ticket_id text; source_item record; target_item_id uuid;
begin
  for ticket_group in
    select order_id from public.kitchen_tickets
    where order_id is not null and status = 'New'
    group by order_id having count(*) > 1
  loop
    select ticket_id into target_ticket_id from public.kitchen_tickets
    where order_id = ticket_group.order_id and status = 'New'
    order by created_at asc limit 1;

    for source_ticket_id in
      select ticket_id from public.kitchen_tickets
      where order_id = ticket_group.order_id and status = 'New' and ticket_id <> target_ticket_id
    loop
      for source_item in select * from public.kitchen_ticket_items where ticket_id = source_ticket_id loop
        select item_id into target_item_id from public.kitchen_ticket_items
        where ticket_id = target_ticket_id and product_id = source_item.product_id and notes = source_item.notes and status = 'New'
        limit 1;
        if target_item_id is null then
          update public.kitchen_ticket_items set ticket_id = target_ticket_id where item_id = source_item.item_id;
        else
          update public.kitchen_ticket_items set qty = qty + source_item.qty where item_id = target_item_id;
          delete from public.kitchen_ticket_items where item_id = source_item.item_id;
        end if;
      end loop;
      delete from public.kitchen_tickets where ticket_id = source_ticket_id;
    end loop;
  end loop;
end;
$$;

grant execute on function public.add_restaurant_order_item_with_ticket(text, text, numeric, numeric, text) to authenticated;
