# Graph Report - angkols  (2026-10-27)

## Corpus Check
- 127 files · ~184,321 words
- Verdict: corpus is large enough that graph structure adds value.
- Unclassified: 17 file(s) not represented in the graph (top: .log 4, .css 4, (none) 2)

## Summary
- 602 nodes · 1635 edges · 42 communities (30 shown, 12 thin omitted)
- Extraction: 95% EXTRACTED · 5% INFERRED · 0% AMBIGUOUS · INFERRED: 88 edges (avg confidence: 0.86)
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `921dab21`
- Run `git rev-parse HEAD` and compare to check if the graph is stale.
- Run `graphify update .` after code changes (no API cost).

## Community Hubs (Navigation)
- app.js
- escapeHtml
- initCustomDropdowns
- escapeHtml
- showToast
- FR Merchandise POS
- exportReportPagesPdf_
- alignTableBadges
- index.ts
- check-bundle-report-costs.mjs
- isMobileScreen
- compilerOptions
- renderInventoryReports
- service-worker.js
- openReportInNewPage_
- renderServicePerformance
- Daily Spot Cash Design
- owner-reports.js
- wA
- te
- gs
- UA
- xB
- an
- Be
- dA
- Kr
- Lr
- Analyze → Edit → Verify
- Review Focus
- check-owner-bank-table-reports.mjs
- check-service-performance.mjs
- check-losses-wastage.mjs
- check-credit-aging.mjs
- check-daily-cash-columns.mjs
- ref_node_fs
- UI Design Standard

## God Nodes (most connected - your core abstractions)
1. `escapeHtml()` - 76 edges
2. `renderInventory()` - 53 edges
3. `money()` - 49 edges
4. `showToast()` - 40 edges
5. `renderPageHeader_()` - 32 edges
6. `renderPaginationControls_()` - 31 edges
7. `formatDateInput()` - 29 edges
8. `api()` - 28 edges
9. `bindPaginationEvents_()` - 27 edges
10. `openForm()` - 27 edges

## Surprising Connections (you probably didn't know these)
- `Task 2: Branch-scoped Daily Spot Cash UI` --references--> `askConfirmation()`  [INFERRED]
  docs/superpowers/plans/2026-09-29-daily-spot-cash.md → app.js
- `Approved page header rollout` --references--> `renderPageHeader_()`  [INFERRED]
  docs/page-header-coverage.md → app.js
- `Task 2: Branch-scoped Daily Spot Cash UI` --references--> `renderDailySpotCash()`  [INFERRED]
  docs/superpowers/plans/2026-09-29-daily-spot-cash.md → app.js
- `Table column alignment` --references--> `alignTableColumns()`  [INFERRED]
  docs/table-column-coverage.md → app.js
- `Approved page header rollout` --references--> `renderPageHeaderSkeleton_()`  [INFERRED]
  docs/page-header-coverage.md → app.js

## Import Cycles
- None detected.

## Hyperedges (group relationships)
- **FIFO Auditability Workflow** — readme_fifo_selling_price_batches, tasks_bundle_sales, docs_operations_backup_and_restore [INFERRED 0.75]

## Communities (42 total, 12 thin omitted)

### Community 0 - "app.js"
Cohesion: 0.02
Nodes (76): actionConfirmDialog, actionConfirmSubmitBtn, adminAccounts, allProducts, amountContentObserver, appShell, backdrop, bankTransactions (+68 more)

### Community 1 - "escapeHtml"
Cohesion: 0.11
Nodes (44): askConfirmation(), backgroundRefresh(), buildCashBankReconciliationPdfReport_(), buildCreditAgingPdfReport_(), buildFoodCostMarginPdfReport_(), buildInventoryValuationPdfReport_(), buildLossesWastagePdfReport_(), buildProductSalesPerformancePdfReport_() (+36 more)

### Community 2 - "initCustomDropdowns"
Cohesion: 0.25
Nodes (8): closeDatePicker(), closeDropdown(), initCustomDatePickers(), initSidebarBranchSwitcher(), openDatePicker(), openDropdown(), positionDropdownMenu(), repositionOpenDropdowns()

### Community 3 - "escapeHtml"
Cohesion: 0.12
Nodes (73): bindDatePresets(), bindPaginationEvents_(), dailyCashPosition_(), dateTimeLocalValue_(), displayedSellingPrice(), ensureBankTransactionsDateDefaults(), ensureCashBankReconciliationDateDefaults(), ensureCreditAgingDateDefaults() (+65 more)

### Community 4 - "showToast"
Cohesion: 0.06
Nodes (67): addToCart(), api(), applySession(), beginRestaurantPayment_(), calculateOutstandingCreditAccounts(), cartItemTotal(), changeOwnPassword(), completeRequiredPasswordChange() (+59 more)

### Community 5 - "FR Merchandise POS"
Cohesion: 0.20
Nodes (6): FR Merchandise POS, Google Apps Script Web App, Google Sheets, Bundle Sales, Individual Item Returns, Returns Replacements and Bundles

### Community 6 - "exportReportPagesPdf_"
Cohesion: 0.22
Nodes (11): exportCreditAgingPdf(), exportFoodCostMarginPdf(), exportInventoryValuationPdf(), exportLossesWastagePdf(), exportProductSalesPerformancePdf(), exportProfitLossPdf(), exportQuarantinePdf(), exportReportPagesPdf_() (+3 more)

### Community 7 - "alignTableBadges"
Cohesion: 0.22
Nodes (10): alignTableBadges(), alignTableColumns(), amountTone_(), applyAmountTone_(), colorAmountReadouts_(), tableColumnCells_(), Browser coverage, Product performance and filter toolbar follow-up (+2 more)

### Community 9 - "index.ts"
Cohesion: 0.40
Nodes (4): allowedPermissions, corsHeaders, fail(), json()

### Community 10 - "check-bundle-report-costs.mjs"
Cohesion: 0.15
Nodes (11): allocations, context, fields, item, performance, product, receipt, resolved (+3 more)

### Community 11 - "isMobileScreen"
Cohesion: 0.50
Nodes (4): handleMenuToggle(), handleSidebarCollapse(), initSidebarState(), isMobileScreen()

### Community 13 - "renderInventoryReports"
Cohesion: 0.33
Nodes (9): bundleMovementNotice_(), exportInventoryReportPdf(), formatTransferQuantity(), generateInventoryReportPdf(), getInventoryReportMovement(), getInventoryReportRows(), getInventoryReportStatus(), renderInventoryReports() (+1 more)

### Community 17 - "openReportInNewPage_"
Cohesion: 0.18
Nodes (11): buildCashBankReconciliationPdfReportV2_(), exportCashBankReconciliationPdf(), generateCashBankReconciliationPdf(), generateCreditAgingPdf(), generateFoodCostMarginPdf(), generateInventoryValuationPdf(), generateLossesWastagePdf(), generateProductSalesPerformancePdf() (+3 more)

### Community 18 - "renderServicePerformance"
Cohesion: 0.31
Nodes (11): buildServicePerformancePdfReport_(), calculateServicePerformance_(), exportServicePerformancePdf(), generateServicePerformancePdf(), loadedServicePerformanceReport_(), performanceAverage_(), performanceMinutes_(), renderServicePerformance() (+3 more)

### Community 19 - "Daily Spot Cash Design"
Cohesion: 0.22
Nodes (8): Acceptance criteria, Access and audit, Daily Spot Cash Design, Data flow, Goal, Record model, Scope, User interface

### Community 26 - "owner-reports.js"
Cohesion: 0.17
Nodes (27): bankStatementNote_(), bankStatementSections_(), buildFullCashBankPdf_(), buildTableQrPerformancePdfReport_(), calculateBankStatement_(), calculateTableQrPerformance_(), currentOwnerDashboardReport_(), exportTableQrPerformancePdf() (+19 more)

### Community 27 - "wA"
Cohesion: 0.20
Nodes (17): A(), B(), n(), r(), B(), cn(), E(), H() (+9 more)

### Community 29 - "te"
Cohesion: 0.50
Nodes (4): ee(), He(), te(), ye()

### Community 30 - "gs"
Cohesion: 0.50
Nodes (4): gs(), ns(), rs(), ts()

### Community 31 - "UA"
Cohesion: 0.67
Nodes (3): FA(), lA(), UA()

### Community 32 - "xB"
Cohesion: 0.67
Nodes (3): fe(), oe(), xB()

### Community 40 - "Analyze → Edit → Verify"
Cohesion: 0.29
Nodes (6): 1. Analyze, 2. Edit, 3. Verify, 4. Deliver, Analyze → Edit → Verify, Strict requirements

### Community 42 - "Review Focus"
Cohesion: 0.29
Nodes (6): Daily Spot Cash Implementation Plan, Global Constraints, Review Focus, Task 1: Database and permission contract, Task 2: Branch-scoped Daily Spot Cash UI, Task 3: Deployment and acceptance verification

### Community 44 - "check-owner-bank-table-reports.mjs"
Cohesion: 0.14
Nodes (11): app, bank, bankData, context, data, fields, html, owner (+3 more)

### Community 45 - "check-service-performance.mjs"
Cohesion: 0.18
Nodes (9): base, context, data, fields, migration, pending, report, source (+1 more)

### Community 46 - "check-losses-wastage.mjs"
Cohesion: 0.22
Nodes (8): allocations, context, fields, migration, record, report, source, table

### Community 47 - "check-credit-aging.mjs"
Cohesion: 0.25
Nodes (5): context, fields, report, source, table

### Community 48 - "check-daily-cash-columns.mjs"
Cohesion: 0.29
Nodes (5): context, css, listeners, source, table

### Community 49 - "ref_node_fs"
Cohesion: 0.20
Nodes (6): checks, failures, files, appJs, quarantinedItemsMatch, quarantineReportMatch

### Community 50 - "UI Design Standard"
Cohesion: 0.08
Nodes (24): renderKitchenDisplaySkeletonHtml_(), renderPageHeaderSkeleton_(), renderSkeletonTable(), renderWaiterQueueSkeletonHtml_(), Approved page header rollout, Coverage, Validation, 10. Structure-based skeleton loading (+16 more)

## Knowledge Gaps
- **2 isolated node(s):** `Google Sheets`, `Individual Item Returns`
  These have ≤1 connection - possible missing edges or undocumented components. (Counts symbols only; 249 node(s) total have ≤1 connection when file, concept and rationale nodes are included.)
- **12 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `1. Visual reference and implementation approach` connect `UI Design Standard` to `escapeHtml`?**
  _High betweenness centrality (0.035) - this node is a cross-community bridge._
- **Are the 2 inferred relationships involving `renderPageHeader_()` (e.g. with `Approved page header rollout` and `1. Visual reference and implementation approach`) actually correct?**
  _`renderPageHeader_()` has 2 INFERRED edges - model-reasoned connections that need verification._
- **What connects `Google Sheets`, `Individual Item Returns` to the rest of the system?**
  _2 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `app.js` be split into smaller, more focused modules?**
  _Cohesion score 0.024096385542168676 - nodes in this community are weakly interconnected._
- **Why does `renderPageHeader_()` connect `escapeHtml` to `app.js`, `escapeHtml`, `showToast`, `renderInventoryReports`, `renderServicePerformance`, `UI Design Standard`?**
  _High betweenness centrality (0.029) - this node is a cross-community bridge._
- **Should `escapeHtml` be split into smaller, more focused modules?**
  _Cohesion score 0.11416490486257928 - nodes in this community are weakly interconnected._
- **Should `escapeHtml` be split into smaller, more focused modules?**
  _Cohesion score 0.11910197869101978 - nodes in this community are weakly interconnected._