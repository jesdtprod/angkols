-- Preserve write-off cost at posting time. Legacy rows remain unknown until
-- report-time estimation; do not invent allocations or deduct stock again.
alter table public.inventory_losses
  add column if not exists cost_total numeric(14,2) check (cost_total is null or cost_total >= 0),
  add column if not exists cost_allocations jsonb not null default '[]'::jsonb check (jsonb_typeof(cost_allocations) = 'array');

create or replace function public.record_inventory_loss(
  target_branch_id text, target_product_id text, quantity_input numeric,
  reason_input text, notes_input text default '', occurred_at_input timestamptz default now()
) returns jsonb language plpgsql security definer set search_path = public as $function$
declare
  loss_id_value text := public.new_pos_id('LOS');
  product_row public.products;
  batch_row public.inventory_cost_batches;
  on_hand_qty numeric;
  remaining_qty numeric;
  allocated_qty numeric;
  total_cost numeric := 0;
  cost_known boolean := true;
  allocations jsonb := '[]'::jsonb;
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
  for batch_row in select * from public.inventory_cost_batches
    where branch_id = target_branch_id and product_id = target_product_id and qty_remaining > 0
    order by is_opening desc, received_at, batch_id for update
  loop
    allocated_qty := least(remaining_qty, batch_row.qty_remaining);
    update public.inventory_cost_batches set qty_remaining = qty_remaining - allocated_qty where batch_id = batch_row.batch_id;
    allocations := allocations || jsonb_build_array(jsonb_build_object(
      'batchId', batch_row.batch_id, 'stockInId', batch_row.stock_in_id,
      'qty', allocated_qty, 'unitCost', batch_row.unit_cost));
    if batch_row.unit_cost is null then cost_known := false;
    else total_cost := total_cost + allocated_qty * batch_row.unit_cost; end if;
    remaining_qty := remaining_qty - allocated_qty;
    exit when remaining_qty <= 0;
  end loop;
  if remaining_qty > 0 then raise exception 'Inventory batches do not cover this write-off. Refresh stock and try again.'; end if;
  update public.inventory set qty = qty - quantity_input, updated_at = now()
  where branch_id = target_branch_id and product_id = target_product_id;
  insert into public.inventory_losses(loss_id, branch_id, product_id, qty, reason, notes, occurred_at, created_by, cost_total, cost_allocations)
  values(loss_id_value, target_branch_id, target_product_id, quantity_input, normalized_reason, normalized_notes,
    coalesce(occurred_at_input, now()), auth.uid(), case when cost_known then round(total_cost, 2) else null end, allocations);
  insert into public.account_audit(actor_id, action, target_id, details)
  values(auth.uid(), 'Recorded inventory loss', loss_id_value, target_product_id || ': ' || quantity_input::text || ' (' || normalized_reason || ')');
  return jsonb_build_object('lossId', loss_id_value, 'productId', target_product_id, 'qty', quantity_input,
    'reason', normalized_reason, 'costTotal', case when cost_known then round(total_cost, 2) else null end);
end;
$function$;

revoke all on function public.record_inventory_loss(text, text, numeric, text, text, timestamptz) from public;
grant execute on function public.record_inventory_loss(text, text, numeric, text, text, timestamptz) to authenticated;
