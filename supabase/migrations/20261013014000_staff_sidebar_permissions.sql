alter table public.profiles drop constraint if exists profiles_permissions_check;
alter table public.profiles add constraint profiles_permissions_check check (
  permissions <@ array[
    'pos',
    'tableService',
    'waiterQueue',
    'kitchenDisplay',
    'products',
    'bundleMonitoring',
    'inventory',
    'quarantine',
    'transfers',
    'dailySpotCash',
    'dailyExpenses',
    'customers',
    'credits',
    'sales',
    'inventoryReports',
    'quarantineReport'
  ]
);
