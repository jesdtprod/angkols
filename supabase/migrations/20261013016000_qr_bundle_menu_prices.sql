-- Bundles are virtual products, so they do not have their own FIFO stock rows.
-- Their configured bundle price must take precedence over the individual-item
-- FIFO fallback used by the QR table menu.
create or replace function public.current_branch_product_menu_price(target_branch_id text, target_product_id text)
returns numeric
language sql
stable
security definer
set search_path = public
as $$
  select coalesce(
    bp.selling_price_override,
    case when p.product_type = 'bundle' then p.bundle_price end,
    (
      select batch.selling_price
      from public.inventory_cost_batches batch
      where batch.branch_id = bp.branch_id
        and batch.product_id = bp.product_id
        and batch.qty_remaining > 0
        and batch.selling_price is not null
      order by batch.is_opening desc, batch.received_at, batch.batch_id
      limit 1
    ),
    nullif(bp.price_override, 0),
    nullif(p.price, 0),
    0
  )
  from public.products p
  join public.branch_products bp on bp.product_id = p.product_id
  where bp.branch_id = target_branch_id
    and p.product_id = target_product_id;
$$;
