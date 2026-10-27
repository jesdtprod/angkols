# Table column alignment

Headers and cells use the same alignment through `alignTableColumns()`, called
by the existing render/resize alignment scheduler. Status, action, method and
type columns center their content; numerical and monetary columns align right;
ordinary text aligns left. Composite product/type cells remain left aligned.
Mobile rows keep their existing label/value layout.

Shared fractional tracks use `minmax(0, ...)` in the common CSS definitions,
including their skeleton rows. Long text no longer changes the widths of each
row independently. The generic last-heading centering rule was removed.

## Browser coverage

The browser checks used the actual CSS and application header templates, with
representative long-text, ordinary and skeleton rows. Header/cell left edges
and widths matched within 1px for all 27 layouts at desktop widths of 1440px
and 1024px.

| Layouts | Result |
| --- | --- |
| Products, inventory, bundles, stock-in history, inventory report | Aligned |
| Loss register, losses/wastage, quarantine report | Aligned |
| Branches, customers, staff, administrators | Aligned |
| Credit ledger, credit aging, sales, transfers, daily cash | Aligned |
| Profit/loss, food cost, product performance, inventory valuation, reconciliation, bank activity | Aligned |
| Expense register and bank register | Aligned |
| Legacy grid and dynamic report grid | Aligned |

The inventory status badges were centered within their cells with zero measured
center offset. All 27 layouts also passed mobile checks at 390px:
label/value rows remained visible and no table extended outside the viewport.

Existing cash-column, credit-aging, losses/wastage, service-performance,
quarantine, owner/bank/table-report, and bundle-cost checks passed. Their test
harnesses now load the shared header renderer introduced by the preceding
header rollout. These checks retain their calculation and action assertions.

This is presentation validation with representative rows, not an authenticated
end-to-end exercise of every page's live data or export workflow.

## Product performance and filter toolbar follow-up

- Product Sales Performance now has six columns; Rank was removed from both the page and PDF, including the empty PDF row's column span. Sorting and calculations remain available.
- The actual toolbar markup from `index.html`, enhanced by the application's custom datepicker and dropdown initializers, was checked for all 17 date-range configurations.
- At 1440px and 1024px, search, dates and additional filters shared a row with 42px control heights and a search width of at least 240px.
- At 390px, search filled its row and dates/type/sort controls formed a two-column grid. No tested configuration overflowed the viewport.
- Report-specific full-width filter overrides were removed; shared controls now have the same sizing rules. The existing report tests and new Rank-removal assertions passed.

## Shared amount colors

Monetary table cells now share the palette recorded in `UI DESIGN.md` with KPI
cards, dashboard amounts, table tabs, stock-in summaries and POS readouts.
Ordinary native tables use the same heading-based rules. Negative values are
red; dates, quantities and percentages keep their existing styling. Displayed
values and all underlying calculations remain unchanged.

Browser checks covered the six-column profitability layout, eight KPI amount
categories, zero and negative values, and POS/stock-in/credit readouts. Changing
a displayed value refreshed its color automatically, with one mutation callback
and no observer loop. The mobile layout retained its label/value rows without
horizontal overflow. Existing report calculation and export parity checks passed.

Grouped POS rows are flattened into their logical Product, Selling Price, Stock
and Action cells before formatting. Stale amount coloring is removed from the
group wrapper, preventing cyan price colors from leaking into stock badges.
Browser checks using that nested structure confirmed a zero stock/header center
offset on desktop, independent green/amber/red stock colors, and no mobile
overflow. The legacy `check-pos.mjs` suite still reports three unrelated stale
dashboard/version assertions (an old bundle tag, today-only dashboard names,
and pre-pagination list names); no POS calculations were changed for this fix.
