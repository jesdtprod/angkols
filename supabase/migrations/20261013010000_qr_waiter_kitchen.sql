alter table public.restaurant_tables add column if not exists qr_token uuid not null default gen_random_uuid();
create unique index if not exists restaurant_tables_qr_token_key on public.restaurant_tables(qr_token);
alter table public.products add column if not exists kitchen_enabled boolean not null default true;

create table public.table_order_requests (
  request_id text primary key, branch_id text not null references public.branches(branch_id), table_id text not null references public.restaurant_tables(table_id),
  status text not null default 'Pending' check(status in ('Pending','Claimed','Confirmed','Rejected')),
  customer_note text not null default '', claimed_by uuid references public.profiles(user_id), claimed_at timestamptz, confirmed_by uuid references public.profiles(user_id), confirmed_at timestamptz, created_at timestamptz not null default now()
);
create table public.table_order_request_items (
  item_id uuid primary key default gen_random_uuid(), request_id text not null references public.table_order_requests(request_id) on delete cascade,
  product_id text not null references public.products(product_id), qty numeric(12,3) not null check(qty>0), notes text not null default ''
);
create table public.kitchen_tickets (
  ticket_id text primary key, branch_id text not null references public.branches(branch_id), table_id text not null references public.restaurant_tables(table_id),
  request_id text references public.table_order_requests(request_id), order_id text references public.restaurant_orders(order_id), status text not null default 'New' check(status in ('New','Preparing','Ready')), created_at timestamptz not null default now(), ready_at timestamptz
);
create table public.kitchen_ticket_items (
  item_id uuid primary key default gen_random_uuid(), ticket_id text not null references public.kitchen_tickets(ticket_id) on delete cascade,
  product_id text not null references public.products(product_id), qty numeric(12,3) not null check(qty>0), notes text not null default '', status text not null default 'New' check(status in ('New','Preparing','Ready'))
);
alter table public.table_order_requests enable row level security; alter table public.table_order_request_items enable row level security; alter table public.kitchen_tickets enable row level security; alter table public.kitchen_ticket_items enable row level security;
create policy "staff read table requests" on public.table_order_requests for select to authenticated using(public.can_access_branch(branch_id));
create policy "staff read request items" on public.table_order_request_items for select to authenticated using(exists(select 1 from public.table_order_requests r where r.request_id=table_order_request_items.request_id and public.can_access_branch(r.branch_id)));
create policy "staff read kitchen tickets" on public.kitchen_tickets for select to authenticated using(public.can_access_branch(branch_id));
create policy "staff read kitchen items" on public.kitchen_ticket_items for select to authenticated using(exists(select 1 from public.kitchen_tickets t where t.ticket_id=kitchen_ticket_items.ticket_id and public.can_access_branch(t.branch_id)));

create or replace function public.public_table_menu(token_input uuid) returns jsonb language plpgsql security definer set search_path=public as $$ declare t public.restaurant_tables; begin
 select * into t from public.restaurant_tables where qr_token=token_input; if not found then raise exception 'Invalid table QR code.'; end if;
 return jsonb_build_object('tableId',t.table_id,'tableName',t.name,'status',t.status,'products',(select coalesce(jsonb_agg(jsonb_build_object('id',p.product_id,'name',p.name,'price',coalesce(bp.price_override,p.price),'category',p.category,'imagePath',p.image_path) order by p.name),'[]'::jsonb) from public.products p join public.branch_products bp on bp.product_id=p.product_id and bp.branch_id=t.branch_id where p.archived_at is null and p.status='Active' and bp.status='Active'));
end; $$;
create or replace function public.submit_table_order_request(token_input uuid, lines jsonb, note_input text default '') returns jsonb language plpgsql security definer set search_path=public as $$ declare t public.restaurant_tables; request_id_value text:=public.new_pos_id('QOR'); line jsonb; product_id_value text; qty_value numeric; begin
 select * into t from public.restaurant_tables where qr_token=token_input for update; if not found or t.status <> 'Occupied' then raise exception 'This table is not accepting mobile orders.'; end if;
 if jsonb_typeof(lines)<>'array' or jsonb_array_length(lines)=0 then raise exception 'Add at least one item.'; end if;
 insert into public.table_order_requests(request_id,branch_id,table_id,customer_note) values(request_id_value,t.branch_id,t.table_id,trim(coalesce(note_input,'')));
 for line in select value from jsonb_array_elements(lines) loop product_id_value:=line->>'productId'; qty_value:=(line->>'qty')::numeric; if qty_value is null or qty_value<=0 or not exists(select 1 from public.products p join public.branch_products bp on bp.product_id=p.product_id where p.product_id=product_id_value and p.archived_at is null and p.status='Active' and bp.branch_id=t.branch_id and bp.status='Active') then raise exception 'One or more menu items are unavailable.'; end if; insert into public.table_order_request_items(request_id,product_id,qty,notes) values(request_id_value,product_id_value,qty_value,coalesce(line->>'notes','')); end loop;
 return jsonb_build_object('requestId',request_id_value,'status','Pending'); end; $$;
create or replace function public.claim_table_order_request(target_request_id text) returns public.table_order_requests language plpgsql security definer set search_path=public as $$ declare result public.table_order_requests; begin
 update public.table_order_requests set status='Claimed',claimed_by=auth.uid(),claimed_at=now() where request_id=target_request_id and status='Pending' and public.has_permission('pos') and public.can_access_branch(branch_id) returning * into result; if not found then raise exception 'This request was already claimed by another waiter.'; end if; return result; end; $$;
create or replace function public.confirm_table_order_request(target_request_id text) returns jsonb language plpgsql security definer set search_path=public as $$ declare r public.table_order_requests; order_id_value text; ticket_id_value text:=public.new_pos_id('KOT'); item record; begin
 select * into r from public.table_order_requests where request_id=target_request_id for update; if not found or r.status not in ('Pending','Claimed') then raise exception 'This request cannot be confirmed.'; end if; if not public.has_permission('pos') or not public.can_access_branch(r.branch_id) then raise exception 'Access denied.'; end if;
 select order_id into order_id_value from public.restaurant_orders where table_id=r.table_id and status='Open' for update; if order_id_value is null then raise exception 'Open the table tab before confirming a customer order.'; end if;
 for item in select * from public.table_order_request_items where request_id=r.request_id loop insert into public.restaurant_order_items(order_id,product_id,qty,price,notes) select order_id_value,item.product_id,item.qty,coalesce(bp.price_override,p.price),item.notes from public.products p join public.branch_products bp on bp.product_id=p.product_id and bp.branch_id=r.branch_id where p.product_id=item.product_id; end loop;
 insert into public.kitchen_tickets(ticket_id,branch_id,table_id,request_id,order_id) values(ticket_id_value,r.branch_id,r.table_id,r.request_id,order_id_value);
 insert into public.kitchen_ticket_items(ticket_id,product_id,qty,notes) select ticket_id_value,i.product_id,i.qty,i.notes from public.table_order_request_items i join public.products p on p.product_id=i.product_id where i.request_id=r.request_id and p.kitchen_enabled;
 update public.table_order_requests set status='Confirmed',confirmed_by=auth.uid(),confirmed_at=now() where request_id=r.request_id;
 return jsonb_build_object('orderId',order_id_value,'ticketId',ticket_id_value); end; $$;
create or replace function public.update_kitchen_ticket_item(target_item_id uuid, status_input text) returns void language plpgsql security definer set search_path=public as $$ begin
 if status_input not in ('Preparing','Ready') or not public.has_permission('pos') then raise exception 'Invalid kitchen update.'; end if; update public.kitchen_ticket_items set status=status_input where item_id=target_item_id; update public.kitchen_tickets t set status=case when exists(select 1 from public.kitchen_ticket_items i where i.ticket_id=t.ticket_id and i.status='New') then 'New' when exists(select 1 from public.kitchen_ticket_items i where i.ticket_id=t.ticket_id and i.status='Preparing') then 'Preparing' else 'Ready' end, ready_at=case when not exists(select 1 from public.kitchen_ticket_items i where i.ticket_id=t.ticket_id and i.status<>'Ready') then now() else null end where t.ticket_id=(select ticket_id from public.kitchen_ticket_items where item_id=target_item_id); end; $$;
grant execute on function public.public_table_menu(uuid),public.submit_table_order_request(uuid,jsonb,text) to anon,authenticated;
grant execute on function public.claim_table_order_request(text),public.confirm_table_order_request(text),public.update_kitchen_ticket_item(uuid,text) to authenticated;
alter publication supabase_realtime add table public.table_order_requests, public.kitchen_tickets, public.kitchen_ticket_items;
