-- Permanent write-offs for physical individual products.  The FIFO batch
-- deduction keeps later sales and transfer costing consistent with on-hand stock.
create table if not exists public.inventory_losses (
  loss_id text primary key,
  branch_id text not null references public.branches(branch_id) on delete cascade,
  product_id text not null references public.products(product_id) on delete restrict,
  qty numeric(12,3) not null check (qty > 0),
  reason text not null check (reason in ('Damaged', 'Expired', 'Spoiled', 'Broken', 'Missing', 'Other')),
  notes text not null default '',
  occurred_at timestamptz not null default now(),
  created_by uuid references public.profiles(user_id) on delete set null,
  created_at timestamptz not null default now()
);

create index if not exists inventory_losses_branch_occurred_idx
  on public.inventory_losses(branch_id, occurred_at desc);

alter table public.inventory_losses enable row level security;
drop policy if exists "read permitted inventory losses" on public.inventory_losses;
create policy "read permitted inventory losses" on public.inventory_losses
  for select to authenticated using (public.can_access_branch(branch_id));

create or replace function public.record_inventory_loss(
  target_branch_id text,
  target_product_id text,
  quantity_input numeric,
  reason_input text,
  notes_input text default '',
  occurred_at_input timestamptz default now()
)
returns jsonb language plpgsql security definer set search_path = public as $function$
declare
  loss_id_value text := public.new_pos_id('LOS');
  product_row public.products;
  batch_row public.inventory_cost_batches;
  on_hand_qty numeric;
  remaining_qty numeric;
  allocated_qty numeric;
  normalized_reason text := initcap(trim(coalesce(reason_input, '')));
  normalized_notes text := trim(coalesce(notes_input, ''));
begin
  if not public.has_permission('inventory') or not public.can_access_branch(target_branch_id) then
    raise exception 'Your account does not have access to this action.';
  end if;
  perform public.assert_active_branch(target_branch_id);
  if quantity_input is null or quantity_input <= 0 then raise exception 'Quantity must be greater than zero.'; end if;
  if normalized_reason not in ('Damaged', 'Expired', 'Spoiled', 'Broken', 'Missing', 'Other') then raise exception 'Choose a valid loss reason.'; end if;
  if normalized_reason = 'Other' and normalized_notes = '' then raise exception 'Notes are required when the reason is Other.'; end if;

  select * into product_row from public.products where product_id = target_product_id for share;
  if not found or product_row.archived_at is not null or product_row.product_type = 'bundle' then
    raise exception 'Only active individual products can be written off.';
  end if;

  select qty into on_hand_qty from public.inventory
  where branch_id = target_branch_id and product_id = target_product_id for update;
  if not found or on_hand_qty < quantity_input or public.available_inventory_qty(target_branch_id, target_product_id) < quantity_input then
    raise exception 'Write-off quantity exceeds the available inventory.';
  end if;

  remaining_qty := quantity_input;
  for batch_row in
    select * from public.inventory_cost_batches
    where branch_id = target_branch_id and product_id = target_product_id and qty_remaining > 0
    order by is_opening desc, received_at, batch_id for update
  loop
    allocated_qty := least(remaining_qty, batch_row.qty_remaining);
    update public.inventory_cost_batches set qty_remaining = qty_remaining - allocated_qty where batch_id = batch_row.batch_id;
    remaining_qty := remaining_qty - allocated_qty;
    exit when remaining_qty <= 0;
  end loop;
  if remaining_qty > 0 then raise exception 'Inventory batches do not cover this write-off. Refresh stock and try again.'; end if;

  update public.inventory set qty = qty - quantity_input, updated_at = now()
  where branch_id = target_branch_id and product_id = target_product_id;
  insert into public.inventory_losses(loss_id, branch_id, product_id, qty, reason, notes, occurred_at, created_by)
  values (loss_id_value, target_branch_id, target_product_id, quantity_input, normalized_reason, normalized_notes, coalesce(occurred_at_input, now()), auth.uid());
  insert into public.account_audit(actor_id, action, target_id, details)
  values (auth.uid(), 'Recorded inventory loss', loss_id_value, target_product_id || ': ' || quantity_input::text || ' (' || normalized_reason || ')');
  return jsonb_build_object('lossId', loss_id_value, 'productId', target_product_id, 'qty', quantity_input, 'reason', normalized_reason);
end;
$function$;

revoke all on function public.record_inventory_loss(text, text, numeric, text, text, timestamptz) from public;
grant execute on function public.record_inventory_loss(text, text, numeric, text, text, timestamptz) to authenticated;
