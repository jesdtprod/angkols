insert into public.branches (branch_id, name, type, address, status)
values ('MAIN', 'Main Branch', 'Main', '', 'Active')
on conflict (branch_id) do nothing;
