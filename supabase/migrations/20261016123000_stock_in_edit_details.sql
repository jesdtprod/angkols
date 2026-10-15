-- Correct receipt cost and supplier/invoice details without changing posted stock quantities.
create or replace function public.update_stock_in_details(target_branch_id text, target_stock_in_id text, unit_cost_input numeric, supplier_reference_input text default '')
returns jsonb language plpgsql security definer set search_path = public as $$
declare normalized_reference text := coalesce(trim(supplier_reference_input), '');
begin
  if not public.has_permission('inventory') or not public.can_access_branch(target_branch_id) then raise exception 'Your account does not have access to this action.'; end if;
  if unit_cost_input is null or unit_cost_input < 0 then raise exception 'Enter a valid unit cost.'; end if;
  if not exists (select 1 from public.stock_ins where stock_in_id = target_stock_in_id and branch_id = target_branch_id) then raise exception 'Stock-in receipt was not found in the selected branch.'; end if;
  update public.stock_ins set unit_cost = unit_cost_input, supplier_reference = normalized_reference where stock_in_id = target_stock_in_id;
  update public.inventory_cost_batches set unit_cost = unit_cost_input where branch_id = target_branch_id and stock_in_id = target_stock_in_id;
  insert into public.account_audit (actor_id, action, target_id, details) values (auth.uid(), 'Updated stock-in details', target_stock_in_id, 'Unit cost: ' || unit_cost_input::text || '; reference: ' || coalesce(nullif(normalized_reference, ''), 'none'));
  return jsonb_build_object('stockInId', target_stock_in_id, 'unitCost', unit_cost_input, 'supplierReference', normalized_reference);
end;
$$;
grant execute on function public.update_stock_in_details(text, text, numeric, text) to authenticated;
