-- A request with both served and unfinished ticket items is partially served.
-- The preceding migration owns the full QR-menu function; update only this
-- status branch so it remains identical to that current function otherwise.
do $migration$
declare function_sql text;
begin
  select pg_get_functiondef('public.public_table_menu(uuid)'::regprocedure) into function_sql;
  if position($match$when bool_or(kitchen_line.status = 'Ready') then 'Ready'
            when bool_and(kitchen_line.status = 'Served') then 'Served'$match$ in function_sql) = 0 then
    raise exception 'Could not locate the table-order ready/served status branch.';
  end if;
  function_sql := replace(
    function_sql,
    $match$when bool_or(kitchen_line.status = 'Ready') then 'Ready'
            when bool_and(kitchen_line.status = 'Served') then 'Served'$match$,
    $replacement$when bool_or(kitchen_line.status = 'Served') and bool_or(kitchen_line.status <> 'Served') then 'Partially served'
            when bool_or(kitchen_line.status = 'Ready') then 'Ready'
            when bool_and(kitchen_line.status = 'Served') then 'Served'$replacement$
  );
  execute function_sql;
end;
$migration$;
