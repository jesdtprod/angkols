create or replace function public.add_restaurant_order_item_with_ticket(
  target_order_id text, target_product_id text, qty_input numeric, price_input numeric, notes_input text default ''
) returns jsonb language plpgsql security definer set search_path=public as $$
declare order_row public.restaurant_orders; order_item public.restaurant_order_items; ticket_id_value text;
begin
  select * into order_row from public.restaurant_orders where order_id=target_order_id for update;
  if not found or order_row.status <> 'Open' then raise exception 'This table tab is no longer open.'; end if;
  if not public.has_permission('pos') or not public.can_access_branch(order_row.branch_id) then raise exception 'Your account does not have access to this tab.'; end if;
  if qty_input is null or qty_input<=0 or price_input is null or price_input<0 then raise exception 'Enter a valid quantity and price.'; end if;
  if not exists(select 1 from public.products where product_id=target_product_id and archived_at is null) then raise exception 'Choose an active product.'; end if;
  insert into public.restaurant_order_items(order_id,product_id,qty,price,notes) values(target_order_id,target_product_id,qty_input,price_input,trim(coalesce(notes_input,''))) returning * into order_item;
  if exists(select 1 from public.products where product_id=target_product_id and kitchen_enabled) then
    ticket_id_value:=public.new_pos_id('KOT');
    insert into public.kitchen_tickets(ticket_id,branch_id,table_id,order_id) values(ticket_id_value,order_row.branch_id,order_row.table_id,order_row.order_id);
    insert into public.kitchen_ticket_items(ticket_id,product_id,qty,notes) values(ticket_id_value,target_product_id,qty_input,order_item.notes);
  end if;
  return jsonb_build_object('orderItemId',order_item.item_id,'ticketId',ticket_id_value);
end; $$;
grant execute on function public.add_restaurant_order_item_with_ticket(text,text,numeric,numeric,text) to authenticated;
