create table public.bank_statement_reconciliations (
  statement_id uuid primary key default gen_random_uuid(),
  branch_id text not null references public.branches(branch_id),
  date_from date not null, date_to date not null check (date_to >= date_from),
  opening_book_balance numeric(14,2) not null,
  statement_opening_balance numeric(14,2) not null,
  statement_closing_balance numeric(14,2) not null,
  notes text not null default '',
  updated_at timestamptz not null default now(),
  updated_by uuid references public.profiles(user_id),
  unique(branch_id, date_from, date_to)
);
create table public.bank_statement_lines (
  line_id uuid primary key default gen_random_uuid(),
  statement_id uuid not null references public.bank_statement_reconciliations(statement_id) on delete cascade,
  bank_date date not null, transaction_type text not null check (transaction_type in ('Deposit','Withdrawal')),
  amount numeric(14,2) not null check (amount > 0), reference text not null default '',
  bank_transaction_id uuid unique references public.bank_transactions(transaction_id)
);
alter table public.bank_statement_reconciliations enable row level security;
alter table public.bank_statement_lines enable row level security;
create policy "admins read branch bank statements" on public.bank_statement_reconciliations for select to authenticated
  using (public.is_admin() and public.can_access_branch(branch_id));
create policy "admins read branch bank statement lines" on public.bank_statement_lines for select to authenticated
  using (exists(select 1 from public.bank_statement_reconciliations s where s.statement_id = bank_statement_lines.statement_id and public.is_admin() and public.can_access_branch(s.branch_id)));

create or replace function public.save_bank_statement_reconciliation(
  target_branch_id text, date_from_input date, date_to_input date,
  opening_book_input numeric, statement_opening_input numeric, statement_closing_input numeric,
  lines_input jsonb, notes_input text default ''
) returns jsonb language plpgsql security definer set search_path = public as $$
declare statement_id_value uuid; entry jsonb; matched public.bank_transactions; matched_id uuid; amount_value numeric; date_value date; type_value text; previous_snapshot jsonb;
begin
  if not public.is_admin() or not public.can_access_branch(target_branch_id) then raise exception 'Only administrators can reconcile bank statements.'; end if;
  perform public.assert_active_branch(target_branch_id);
  if date_from_input is null or date_to_input is null or date_from_input > date_to_input
    or opening_book_input is null or statement_opening_input is null or statement_closing_input is null
    or opening_book_input::text in ('NaN','Infinity','-Infinity') or statement_opening_input::text in ('NaN','Infinity','-Infinity') or statement_closing_input::text in ('NaN','Infinity','-Infinity')
    or jsonb_typeof(lines_input) is distinct from 'array' then raise exception 'Complete the period, balances, and statement lines.'; end if;
  perform pg_advisory_xact_lock(hashtextextended('bank-statement:' || target_branch_id, 0));
  select statement_id into statement_id_value from public.bank_statement_reconciliations
    where branch_id = target_branch_id and date_from = date_from_input and date_to = date_to_input for update;
  if exists(select 1 from public.bank_statement_reconciliations where branch_id = target_branch_id and statement_id is distinct from statement_id_value
    and date_from <= date_to_input and date_to >= date_from_input) then raise exception 'This period overlaps an existing bank statement. Select its exact dates to edit it.'; end if;
  select jsonb_build_object('header', to_jsonb(s), 'lines', (select coalesce(jsonb_agg(l), '[]'::jsonb) from public.bank_statement_lines l where l.statement_id = s.statement_id))
    into previous_snapshot from public.bank_statement_reconciliations s where s.statement_id = statement_id_value;
  insert into public.bank_statement_reconciliations(branch_id, date_from, date_to, opening_book_balance, statement_opening_balance, statement_closing_balance, notes, updated_by)
    values(target_branch_id, date_from_input, date_to_input, opening_book_input, statement_opening_input, statement_closing_input, trim(coalesce(notes_input,'')), auth.uid())
    on conflict(branch_id,date_from,date_to) do update set opening_book_balance=excluded.opening_book_balance,
      statement_opening_balance=excluded.statement_opening_balance, statement_closing_balance=excluded.statement_closing_balance,
      notes=excluded.notes, updated_by=auth.uid(), updated_at=now() returning statement_id into statement_id_value;
  delete from public.bank_statement_lines where statement_id = statement_id_value;
  for entry in select value from jsonb_array_elements(lines_input) loop
    date_value := (entry->>'date')::date; type_value := entry->>'type'; amount_value := (entry->>'amount')::numeric;
    matched_id := nullif(entry->>'transactionId','')::uuid;
    if date_value is null or date_value < date_from_input or date_value > date_to_input
      or type_value is null or type_value not in ('Deposit','Withdrawal') or amount_value is null or amount_value <= 0
      or amount_value::text in ('NaN','Infinity','-Infinity') or amount_value <> round(amount_value,2) then raise exception 'Each bank line needs a valid date, type, and positive amount with at most two decimals.'; end if;
    if matched_id is not null then
      select * into matched from public.bank_transactions where transaction_id=matched_id and branch_id=target_branch_id and deleted_at is null for share;
      if not found or matched.business_date > date_to_input or matched.transaction_type <> type_value or matched.amount <> amount_value then
        raise exception 'Matched ledger entry must belong to this branch and match the type and amount, dated on/before the cutoff.';
      end if;
    end if;
    insert into public.bank_statement_lines(statement_id,bank_date,transaction_type,amount,reference,bank_transaction_id)
      values(statement_id_value,date_value,type_value,amount_value,trim(coalesce(entry->>'reference','')),matched_id);
  end loop;
  insert into public.account_audit(actor_id,action,target_id,details) values(auth.uid(),'Saved bank statement reconciliation',statement_id_value::text,coalesce(previous_snapshot::text,'New statement'));
  return jsonb_build_object('statementId',statement_id_value);
end;
$$;

create or replace function public.get_bank_statement_report(target_branch_id text)
returns jsonb language plpgsql stable security definer set search_path = public as $$
begin
  if not public.is_admin() or not public.can_access_branch(target_branch_id) then raise exception 'Only administrators can read bank reconciliation.'; end if;
  return jsonb_build_object(
    'statements',(select coalesce(jsonb_agg(s order by date_to), '[]'::jsonb) from public.bank_statement_reconciliations s where branch_id=target_branch_id),
    'lines',(select coalesce(jsonb_agg(l order by bank_date,line_id),'[]'::jsonb) from public.bank_statement_lines l join public.bank_statement_reconciliations s using(statement_id) where s.branch_id=target_branch_id),
    'transactions',(select coalesce(jsonb_agg(t order by business_date,created_at,transaction_id),'[]'::jsonb) from public.bank_transactions t where branch_id=target_branch_id and deleted_at is null));
end;
$$;

create or replace function public.protect_matched_bank_transaction()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  if (new.deleted_at is not null or new.amount is distinct from old.amount or new.transaction_type is distinct from old.transaction_type or new.business_date is distinct from old.business_date)
    and exists(select 1 from public.bank_statement_lines where bank_transaction_id=old.transaction_id) then
    raise exception 'Remove this entry from its bank statement match before changing or deleting it.';
  end if;
  return new;
end;
$$;
create trigger protect_matched_bank_transaction before update on public.bank_transactions
  for each row execute function public.protect_matched_bank_transaction();

-- Bank-only charges, interest, and transfers must not affect drawer cash.
do $$ declare constraint_row record; begin
  for constraint_row in select conname from pg_constraint where conrelid='public.bank_transactions'::regclass and contype='c' and pg_get_constraintdef(oid) like '%payment_method%' loop
    execute format('alter table public.bank_transactions drop constraint %I', constraint_row.conname);
  end loop;
end $$;
alter table public.bank_transactions add constraint bank_transactions_method_check check(payment_method in ('Cash','Cheque','Bank'));
alter table public.bank_transactions add constraint bank_transactions_payment_details_check check(
  (payment_method='Cash' and bank_name='' and cheque_number='') or (payment_method='Bank' and cheque_number='') or (payment_method='Cheque' and bank_name<>'' and cheque_number<>''));
create or replace function public.create_bank_transaction(target_branch_id text,target_business_date date,transaction_type_input text,payment_method_input text,amount_input numeric,bank_name_input text default '',cheque_number_input text default '',reference_input text default '',details_input text default '')
returns public.bank_transactions language plpgsql security definer set search_path=public as $$
declare result public.bank_transactions; normalized_type text:=initcap(trim(coalesce(transaction_type_input,''))); normalized_method text:=initcap(trim(coalesce(payment_method_input,''))); normalized_bank text:=trim(coalesce(bank_name_input,'')); normalized_cheque text:=trim(coalesce(cheque_number_input,''));
begin
  if not public.has_permission('dailyExpenses') or not public.can_access_branch(target_branch_id) then raise exception 'Your account does not have access to Bank Transactions.'; end if;
  perform public.assert_active_branch(target_branch_id);
  if target_business_date is null or normalized_type not in ('Deposit','Withdrawal') or normalized_method not in ('Cash','Cheque','Bank') or amount_input is null or amount_input<=0 or trim(coalesce(details_input,''))='' then raise exception 'Enter valid bank transaction details.'; end if;
  if normalized_method='Cheque' and (normalized_bank='' or normalized_cheque='') then raise exception 'Enter the bank name and cheque number.'; end if;
  if normalized_method<>'Cheque' then normalized_cheque:=''; end if;
  if normalized_method='Cash' then normalized_bank:=''; end if;
  insert into public.bank_transactions(branch_id,business_date,transaction_type,payment_method,amount,bank_name,cheque_number,reference,details,created_by)
    values(target_branch_id,target_business_date,normalized_type,normalized_method,amount_input,normalized_bank,normalized_cheque,trim(coalesce(reference_input,'')),trim(details_input),auth.uid()) returning * into result;
  insert into public.account_audit(actor_id,action,target_id,details) values(auth.uid(),'Created bank transaction',result.transaction_id::text,result.transaction_type||' / '||result.payment_method||' / '||result.amount::text);
  return result;
end;
$$;

create or replace function public.get_table_qr_performance_report(target_branch_id text,date_from_input date,date_to_input date)
returns jsonb language plpgsql stable security definer set search_path=public as $$
begin
  if not public.is_admin() or not public.can_access_branch(target_branch_id) then raise exception 'Only administrators can read table performance.'; end if;
  if date_from_input is null or date_to_input is null or date_from_input>date_to_input then raise exception 'Choose a valid report period.'; end if;
  return jsonb_build_object(
    'orders',(select coalesce(jsonb_agg(jsonb_build_object('id',o.order_id,'tableId',o.table_id,'tableName',t.name,'status',o.status,'openedAt',o.opened_at,'closedAt',o.closed_at,'discount',o.discount,
      'gross',coalesce(lines.gross,0),'qrGross',coalesce(lines.qr_gross,0),'qty',coalesce(lines.qty,0),'qrQty',coalesce(lines.qr_qty,0)) order by o.opened_at,o.order_id),'[]'::jsonb)
      from public.restaurant_orders o join public.restaurant_tables t on t.table_id=o.table_id
      left join lateral (select sum(i.qty*i.price) as gross,sum(i.qty*i.price) filter(where i.source_request_id is not null) as qr_gross,sum(i.qty) as qty,sum(i.qty) filter(where i.source_request_id is not null) as qr_qty from public.restaurant_order_items i where i.order_id=o.order_id) lines on true
      where o.branch_id=target_branch_id and ((o.opened_at at time zone 'Asia/Manila')::date between date_from_input and date_to_input or (o.closed_at at time zone 'Asia/Manila')::date between date_from_input and date_to_input)),
    'requests',(select coalesce(jsonb_agg(jsonb_build_object('id',r.request_id,'tableId',r.table_id,'tableName',t.name,'status',r.status,'createdAt',r.created_at,'claimedAt',r.claimed_at,'confirmedAt',r.confirmed_at) order by r.created_at,r.request_id),'[]'::jsonb)
      from public.table_order_requests r join public.restaurant_tables t on t.table_id=r.table_id where r.branch_id=target_branch_id and (r.created_at at time zone 'Asia/Manila')::date between date_from_input and date_to_input));
end;
$$;
revoke all on function public.save_bank_statement_reconciliation(text,date,date,numeric,numeric,numeric,jsonb,text),public.get_bank_statement_report(text),public.get_table_qr_performance_report(text,date,date),public.protect_matched_bank_transaction() from public;
grant execute on function public.save_bank_statement_reconciliation(text,date,date,numeric,numeric,numeric,jsonb,text),public.get_bank_statement_report(text),public.get_table_qr_performance_report(text,date,date) to authenticated;
