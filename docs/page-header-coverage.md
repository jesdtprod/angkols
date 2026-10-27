# Approved page header rollout

The Table Service reference is shared through `renderPageHeader_()` and
`renderPageHeaderSkeleton_()` in `app.js`. The banner uses the existing dashboard
styles, a green operations pill, the current date in Asia/Manila, a cyan page
icon before the title, a muted description, and the page's original actions.
Search has 14px above and below. Search and date ranges share one desktop row
with 42px controls, and wrap on smaller screens.

## Coverage

| Pages | Status |
| --- | --- |
| Product Registration, Inventory Stock, Bundle Monitoring | Updated; shared header layout verified |
| Loss & Damages, Quarantine, Quarantine Report, Stock Transfers | Updated; shared header layout verified |
| Branch Management, Customers, Staff Accounts, Administrator Directory | Updated; shared header layout verified |
| Credit Sales, Daily Cash Reconciliation, Daily Expenses, Bank Transactions, Sales History | Updated; shared header layout verified |
| Active Branch Stock Report, Daily Profit & Loss, Food Cost & Margin | Updated; shared header layout verified |
| Product Sales Performance, Credit Aging, Losses & Wastage | Updated; shared header layout verified |
| Service Performance, Table / QR Performance, Inventory Valuation, Cash & Bank Reconciliation | Updated; shared header layout verified |
| Table Service | Updated to the shared renderer; equal search gaps retained |
| Waiter Queue, Kitchen Display | Updated; actual header templates and counters rendered with sample values |
| Owner Dashboard report renderer | Updated; shared header layout verified |
| Standard, loss, bank, expense, Table Service, waiter and kitchen loading headers | Updated to the shared skeleton |
| Operational dashboard | Approved design, selected-date controls and sales graph retained |

## Validation

- JavaScript syntax checks for `app.js` and `owner-reports.js`, and `git diff --check` passed.
- Source comparison confirmed all existing element IDs and dashboard action/navigation bindings were retained.
- Browser layout previews covered all 30 migrated titles at 1440px and 390px.
- Desktop previews confirmed 14px search gaps, a single search/date row, equal 42px heights, and no horizontal overflow.
- Mobile previews confirmed wrapping, visible action buttons, equal search gaps, and no horizontal overflow.
- The application's actual custom datepicker initializer was run against the previews; all 60 datepicker triggers measured 42px.
- Kitchen and waiter header templates were evaluated with sample counters; their original controls fit at mobile width.
- Follow-up ordering check: the complete Kitchen and Waiter empty-state templates were rendered with the real catalog/table-container hierarchy at 1440px and 390px. Their headers are now siblings before the content shells, above search and filters. Both gaps around search measured 14px. Loading headers use the same top-level slot. Shared headers sort before other page sections.
- Follow-up stacking check: the real topbar markup and shared page banner were rendered together at 1440px and 390px. Hit testing while scrolled confirmed navigation stays in front of the banner in both closed and open-datepicker styling states. Banners use levels 10/11 beneath the topbar's 15; the earlier 30/200 levels caused the overlap.

These checks cover header/filter presentation. Authenticated data loading, live
updates, and report exports were not exercised in the previews. No data queries,
calculations, permissions, or action handlers were changed by this rollout.

`graphify update .` completed after the ordering correction. SQL extraction was
skipped because the optional `tree_sitter_sql` dependency is missing.
