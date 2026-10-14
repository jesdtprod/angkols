-- Keep every operational order screen synchronized after order, item, and status changes.
do $$ begin
  alter publication supabase_realtime add table public.restaurant_tables;
exception when duplicate_object then null;
end $$;

do $$ begin
  alter publication supabase_realtime add table public.restaurant_orders;
exception when duplicate_object then null;
end $$;

do $$ begin
  alter publication supabase_realtime add table public.restaurant_order_items;
exception when duplicate_object then null;
end $$;

do $$ begin
  alter publication supabase_realtime add table public.table_order_request_items;
exception when duplicate_object then null;
end $$;
