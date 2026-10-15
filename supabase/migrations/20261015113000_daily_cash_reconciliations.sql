-- One auditable cashier close per branch and business date. Expected cash stays
-- derived from the source transactions, while the counted drawer cash is stored.
create table if not exists public.daily_cash_reconciliations (
  reconciliation_id uuid primary key default gen_random_uuid(),
  branch_id text not null references public.branches(branch_id),
  business_date date not null,
  counted_cash numeric(12,2) not null check (counted_cash >= 0),
  notes text not null default '',
  closed_at timestamptz not null default now(),
  closed_by uuid not null references public.profiles(user_id),
  updated_at timestamptz not null default now(),
  updated_by uuid not null references public.profiles(user_id),
  unique(branch_id, business_date)
);

alter table public.daily_cash_reconciliations enable row level security;
create policy "daily cash reconciliation users read permitted branch" on public.daily_cash_reconciliations for select to authenticated
  using (public.has_permission('dailySpotCash') and public.can_access_branch(branch_id));

create or replace function public.upsert_daily_cash_reconciliation(
  target_branch_id text,
  target_business_date date,
  counted_cash_input numeric,
  notes_input text default ''
)
returns public.daily_cash_reconciliations language plpgsql security definer set search_path = public as $function$
declare result public.daily_cash_reconciliations;
begin
  if not public.has_permission('dailySpotCash') or not public.can_access_branch(target_branch_id) then
    raise exception 'Your account does not have access to Daily Cash Reconciliation.';
  end if;
  perform public.assert_active_branch(target_branch_id);
  if target_business_date is null or counted_cash_input is null or counted_cash_input < 0 then
    raise exception 'Enter a valid business date and non-negative counted cash.';
  end if;

  insert into public.daily_cash_reconciliations(branch_id, business_date, counted_cash, notes, closed_by, updated_by)
  values(target_branch_id, target_business_date, counted_cash_input, trim(coalesce(notes_input, '')), auth.uid(), auth.uid())
  on conflict(branch_id, business_date) do update set
    counted_cash = excluded.counted_cash,
    notes = excluded.notes,
    updated_at = now(),
    updated_by = auth.uid()
  returning * into result;

  insert into public.account_audit(actor_id, action, target_id, details)
  values(auth.uid(), 'Closed daily cash reconciliation', result.reconciliation_id::text, result.branch_id || ' / ' || result.business_date::text || ' / ' || result.counted_cash::text);
  return result;
end;
$function$;

revoke all on function public.upsert_daily_cash_reconciliation(text,date,numeric,text) from public;
grant execute on function public.upsert_daily_cash_reconciliation(text,date,numeric,text) to authenticated;
