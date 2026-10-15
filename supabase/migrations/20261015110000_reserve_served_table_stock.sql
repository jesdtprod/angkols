-- Served table items reserve stock immediately. The sale payment remains the
-- sole physical inventory deduction, and releases this reservation afterward.
create table if not exists public.restaurant_inventory_reservations (
  ticket_item_id uuid not null references public.kitchen_ticket_items(item_id) on delete cascade,
  order_id text not null references public.restaurant_orders(order_id) on delete cascade,
  branch_id text not null references public.branches(branch_id),
  product_id text not null references public.products(product_id),
  qty numeric(12,3) not null check (qty > 0),
  reserved_at timestamptz not null default now(),
  primary key (ticket_item_id, product_id)
);

create index if not exists restaurant_inventory_reservations_branch_product_idx
  on public.restaurant_inventory_reservations(branch_id, product_id);

alter table public.restaurant_inventory_reservations enable row level security;
create policy "staff read served stock reservations" on public.restaurant_inventory_reservations
  for select to authenticated using (public.can_access_branch(branch_id));

create or replace function public.available_inventory_qty(target_branch_id text, target_product_id text)
returns numeric language sql stable security definer set search_path = public as $function$
  select greatest(
    coalesce((select inventory.qty from public.inventory where inventory.branch_id = target_branch_id and inventory.product_id = target_product_id), 0)
    - coalesce((select sum(reservation.qty) from public.restaurant_inventory_reservations reservation where reservation.branch_id = target_branch_id and reservation.product_id = target_product_id), 0),
    0
  );
$function$;

create or replace function public.available_orderable_qty(target_branch_id text, target_product_id text)
returns numeric language plpgsql stable security definer set search_path = public as $function$
declare product_row public.products;
begin
  select * into product_row from public.products where product_id = target_product_id;
  if not found then return 0; end if;
  if product_row.product_type = 'bundle' then
    return coalesce((
      select min(floor(public.available_inventory_qty(target_branch_id, component.component_product_id) / nullif(component.qty, 0)))::numeric
      from public.product_bundle_components component
      where component.bundle_product_id = target_product_id
    ), 0);
  end if;
  return public.available_inventory_qty(target_branch_id, target_product_id);
end;
$function$;

create or replace function public.reserve_served_table_stock()
returns trigger language plpgsql security definer set search_path = public as $trigger$
declare ticket_row public.kitchen_tickets; product_row public.products; component record; required_qty numeric;
begin
  if new.status <> 'Served' or old.status = 'Served' then return new; end if;
  select * into ticket_row from public.kitchen_tickets where ticket_id = new.ticket_id;
  if not found or ticket_row.order_id is null then return new; end if;
  select * into product_row from public.products where product_id = new.product_id;
  if product_row.product_type = 'bundle' then
    for component in select * from public.product_bundle_components where bundle_product_id = new.product_id loop
      required_qty := new.qty * component.qty;
      perform 1 from public.inventory where branch_id = ticket_row.branch_id and product_id = component.component_product_id for update;
      if public.available_inventory_qty(ticket_row.branch_id, component.component_product_id) < required_qty then
        raise exception 'Insufficient available stock to serve this item.';
      end if;
      insert into public.restaurant_inventory_reservations(ticket_item_id, order_id, branch_id, product_id, qty)
      values(new.item_id, ticket_row.order_id, ticket_row.branch_id, component.component_product_id, required_qty)
      on conflict (ticket_item_id, product_id) do nothing;
    end loop;
  else
    perform 1 from public.inventory where branch_id = ticket_row.branch_id and product_id = new.product_id for update;
    if public.available_inventory_qty(ticket_row.branch_id, new.product_id) < new.qty then
      raise exception 'Insufficient available stock to serve this item.';
    end if;
    insert into public.restaurant_inventory_reservations(ticket_item_id, order_id, branch_id, product_id, qty)
    values(new.item_id, ticket_row.order_id, ticket_row.branch_id, new.product_id, new.qty)
    on conflict (ticket_item_id, product_id) do nothing;
  end if;
  return new;
end;
$trigger$;

drop trigger if exists reserve_served_table_stock on public.kitchen_ticket_items;
create trigger reserve_served_table_stock
  after update of status on public.kitchen_ticket_items
  for each row execute function public.reserve_served_table_stock();

create or replace function public.release_settled_table_stock_reservations()
returns trigger language plpgsql security definer set search_path = public as $trigger$
begin
  if new.status = 'Settled' and old.status is distinct from 'Settled' then
    delete from public.restaurant_inventory_reservations where order_id = new.order_id;
  end if;
  return new;
end;
$trigger$;

drop trigger if exists release_settled_table_stock_reservations on public.restaurant_orders;
create trigger release_settled_table_stock_reservations
  after update of status on public.restaurant_orders
  for each row execute function public.release_settled_table_stock_reservations();

-- Existing served-but-unpaid items become reservations immediately.
insert into public.restaurant_inventory_reservations(ticket_item_id, order_id, branch_id, product_id, qty)
select kitchen_line.item_id, ticket.order_id, ticket.branch_id, product.product_id, kitchen_line.qty
from public.kitchen_ticket_items kitchen_line
join public.kitchen_tickets ticket on ticket.ticket_id = kitchen_line.ticket_id
join public.restaurant_orders table_order on table_order.order_id = ticket.order_id and table_order.status = 'Open'
join public.products product on product.product_id = kitchen_line.product_id
where kitchen_line.status = 'Served' and product.product_type <> 'bundle'
on conflict (ticket_item_id, product_id) do nothing;

insert into public.restaurant_inventory_reservations(ticket_item_id, order_id, branch_id, product_id, qty)
select kitchen_line.item_id, ticket.order_id, ticket.branch_id, component.component_product_id, kitchen_line.qty * component.qty
from public.kitchen_ticket_items kitchen_line
join public.kitchen_tickets ticket on ticket.ticket_id = kitchen_line.ticket_id
join public.restaurant_orders table_order on table_order.order_id = ticket.order_id and table_order.status = 'Open'
join public.products product on product.product_id = kitchen_line.product_id and product.product_type = 'bundle'
join public.product_bundle_components component on component.bundle_product_id = product.product_id
where kitchen_line.status = 'Served'
on conflict (ticket_item_id, product_id) do nothing;

create or replace function public.submit_table_order_request(token_input uuid, lines jsonb, note_input text default '')
returns jsonb language plpgsql security definer set search_path = public as $function$
declare table_row public.restaurant_tables; request_id_value text := public.new_pos_id('QOR'); line record; open_order_id text;
begin
  select * into table_row from public.restaurant_tables where qr_token = token_input for update;
  if not found or table_row.status not in ('Vacant', 'Occupied') then raise exception 'This table is not accepting mobile orders.'; end if;
  if jsonb_typeof(lines) <> 'array' or jsonb_array_length(lines) = 0 then raise exception 'Add at least one item.'; end if;
  for line in
    select value->>'productId' as product_id, sum((value->>'qty')::numeric) as qty
    from jsonb_array_elements(lines)
    group by value->>'productId'
  loop
    if line.product_id is null or line.qty is null or line.qty <= 0 or not exists(
      select 1 from public.products product join public.branch_products branch_product on branch_product.product_id = product.product_id
      where product.product_id = line.product_id and product.archived_at is null and product.status = 'Active'
        and branch_product.branch_id = table_row.branch_id and branch_product.status = 'Active' and product.category <> 'Ingredients / Raw Materials'
    ) or public.available_orderable_qty(table_row.branch_id, line.product_id) < line.qty then
      raise exception 'One or more menu items are unavailable or no longer have enough stock.';
    end if;
  end loop;
  select order_id into open_order_id from public.restaurant_orders where table_id = table_row.table_id and status = 'Open';
  insert into public.table_order_requests(request_id, branch_id, table_id, order_id, customer_note)
  values(request_id_value, table_row.branch_id, table_row.table_id, open_order_id, trim(coalesce(note_input, '')));
  for line in select value->>'productId' as product_id, (value->>'qty')::numeric as qty, coalesce(value->>'notes', '') as notes from jsonb_array_elements(lines) loop
    insert into public.table_order_request_items(request_id, product_id, qty, notes)
    values(request_id_value, line.product_id, line.qty, line.notes);
  end loop;
  return jsonb_build_object('requestId', request_id_value, 'status', 'Pending');
end;
$function$;

-- Make the QR menu show inventory minus quantities already served on open tabs.
do $migration$
declare function_sql text;
begin
  select pg_get_functiondef('public.public_table_menu(uuid)'::regprocedure) into function_sql;
  if position($bundle$coalesce(inventory_row.qty, 0) / nullif(component.qty, 0)$bundle$ in function_sql) = 0
    or position($individual$coalesce((select inventory_row.qty from public.inventory inventory_row where inventory_row.branch_id = table_row.branch_id and inventory_row.product_id = product.product_id), 0)$individual$ in function_sql) = 0 then
    raise exception 'Could not locate the QR menu stock calculation.';
  end if;
  function_sql := replace(function_sql, $bundle$coalesce(inventory_row.qty, 0) / nullif(component.qty, 0)$bundle$, $replacement$public.available_inventory_qty(table_row.branch_id, component.component_product_id) / nullif(component.qty, 0)$replacement$);
  function_sql := replace(function_sql, $individual$coalesce((select inventory_row.qty from public.inventory inventory_row where inventory_row.branch_id = table_row.branch_id and inventory_row.product_id = product.product_id), 0)$individual$, $replacement$public.available_inventory_qty(table_row.branch_id, product.product_id)$replacement$);
  execute function_sql;
end;
$migration$;

grant execute on function public.available_inventory_qty(text, text), public.available_orderable_qty(text, text), public.submit_table_order_request(uuid, jsonb, text) to anon, authenticated;
