-- Append-only branch bank ledger.  The browser derives the running balance
-- chronologically so all deposit and withdrawal entries remain auditable.
create table if not exists public.bank_transactions (
  transaction_id uuid primary key default gen_random_uuid(),
  branch_id text not null references public.branches(branch_id),
  business_date date not null,
  transaction_type text not null check (transaction_type in ('Deposit', 'Withdrawal')),
  payment_method text not null check (payment_method in ('Cash', 'Cheque')),
  amount numeric(12,2) not null check (amount > 0),
  bank_name text not null default '',
  cheque_number text not null default '',
  reference text not null default '',
  details text not null,
  created_at timestamptz not null default now(),
  created_by uuid not null references public.profiles(user_id),
  deleted_at timestamptz,
  deleted_by uuid references public.profiles(user_id),
  check ((payment_method = 'Cash' and bank_name = '' and cheque_number = '') or (payment_method = 'Cheque' and bank_name <> '' and cheque_number <> ''))
);

create index if not exists bank_transactions_branch_date_idx on public.bank_transactions(branch_id, business_date, created_at) where deleted_at is null;
alter table public.bank_transactions enable row level security;
create policy "bank transactions read permitted branch" on public.bank_transactions for select to authenticated
  using (deleted_at is null and public.has_permission('dailyExpenses') and public.can_access_branch(branch_id));

create or replace function public.create_bank_transaction(
  target_branch_id text,
  target_business_date date,
  transaction_type_input text,
  payment_method_input text,
  amount_input numeric,
  bank_name_input text default '',
  cheque_number_input text default '',
  reference_input text default '',
  details_input text default ''
)
returns public.bank_transactions language plpgsql security definer set search_path = public as $function$
declare result public.bank_transactions; normalized_type text := initcap(trim(coalesce(transaction_type_input, ''))); normalized_method text := initcap(trim(coalesce(payment_method_input, ''))); normalized_bank text := trim(coalesce(bank_name_input, '')); normalized_cheque text := trim(coalesce(cheque_number_input, ''));
begin
  if not public.has_permission('dailyExpenses') or not public.can_access_branch(target_branch_id) then raise exception 'Your account does not have access to Bank Transactions.'; end if;
  perform public.assert_active_branch(target_branch_id);
  if target_business_date is null or normalized_type not in ('Deposit', 'Withdrawal') or normalized_method not in ('Cash', 'Cheque') or amount_input is null or amount_input <= 0 or trim(coalesce(details_input, '')) = '' then raise exception 'Enter a valid date, type, method, amount, and details.'; end if;
  if normalized_method = 'Cheque' and (normalized_bank = '' or normalized_cheque = '') then raise exception 'Enter the bank name and cheque number.'; end if;
  if normalized_method = 'Cash' then normalized_bank := ''; normalized_cheque := ''; end if;
  insert into public.bank_transactions(branch_id,business_date,transaction_type,payment_method,amount,bank_name,cheque_number,reference,details,created_by)
  values(target_branch_id,target_business_date,normalized_type,normalized_method,amount_input,normalized_bank,normalized_cheque,trim(coalesce(reference_input,'')),trim(details_input),auth.uid()) returning * into result;
  insert into public.account_audit(actor_id,action,target_id,details) values(auth.uid(),'Created bank transaction',result.transaction_id::text,result.transaction_type || ' / ' || result.payment_method || ' / ' || result.amount::text);
  return result;
end;
$function$;

revoke all on function public.create_bank_transaction(text,date,text,text,numeric,text,text,text,text) from public;
grant execute on function public.create_bank_transaction(text,date,text,text,numeric,text,text,text,text) to authenticated;
