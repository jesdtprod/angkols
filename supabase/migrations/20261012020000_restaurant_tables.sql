create table public.restaurant_tables (
  table_id text primary key,
  branch_id text not null references public.branches(branch_id),
  name text not null, area text not null default '', capacity integer not null default 2 check (capacity > 0),
  status text not null default 'Vacant' check (status in ('Vacant','Occupied','Reserved','Cleaning')),
  created_at timestamptz not null default now(), unique (branch_id, name)
);
create table public.restaurant_orders (
  order_id text primary key, branch_id text not null references public.branches(branch_id),
  table_id text not null references public.restaurant_tables(table_id), status text not null default 'Open' check (status in ('Open','Settled','Cancelled')),
  guest_count integer not null default 1 check (guest_count > 0), customer_name text not null default '', discount numeric(12,2) not null default 0 check (discount >= 0),
  payment_method text, opened_at timestamptz not null default now(), closed_at timestamptz, opened_by uuid references public.profiles(user_id)
);
create unique index restaurant_orders_one_open_table on public.restaurant_orders(table_id) where status = 'Open';
create table public.restaurant_order_items (
  item_id uuid primary key default gen_random_uuid(), order_id text not null references public.restaurant_orders(order_id) on delete restrict,
  product_id text not null references public.products(product_id), qty numeric(12,3) not null check (qty > 0), price numeric(12,2) not null check (price >= 0), notes text not null default '', created_at timestamptz not null default now()
);
alter table public.restaurant_tables enable row level security;
alter table public.restaurant_orders enable row level security;
alter table public.restaurant_order_items enable row level security;
create policy "pos users read restaurant tables" on public.restaurant_tables for select to authenticated using (public.can_access_branch(branch_id));
create policy "admins manage restaurant tables" on public.restaurant_tables for all to authenticated using (public.is_admin()) with check (public.is_admin());
create policy "pos users read restaurant orders" on public.restaurant_orders for select to authenticated using (public.can_access_branch(branch_id));
create policy "pos users manage restaurant orders" on public.restaurant_orders for all to authenticated using (public.has_permission('pos') and public.can_access_branch(branch_id)) with check (public.has_permission('pos') and public.can_access_branch(branch_id));
create policy "pos users read restaurant order items" on public.restaurant_order_items for select to authenticated using (exists(select 1 from public.restaurant_orders o where o.order_id=restaurant_order_items.order_id and public.can_access_branch(o.branch_id)));
create policy "pos users manage restaurant order items" on public.restaurant_order_items for all to authenticated using (exists(select 1 from public.restaurant_orders o where o.order_id=restaurant_order_items.order_id and o.status='Open' and public.has_permission('pos') and public.can_access_branch(o.branch_id))) with check (exists(select 1 from public.restaurant_orders o where o.order_id=restaurant_order_items.order_id and o.status='Open' and public.has_permission('pos') and public.can_access_branch(o.branch_id)));
