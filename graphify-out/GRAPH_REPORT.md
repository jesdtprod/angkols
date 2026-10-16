# Graph Report - angkols  (2026-10-17)

## Corpus Check
- 133 files · ~212,330 words
- Verdict: corpus is large enough that graph structure adds value.
- Unclassified: 18 file(s) not represented in the graph (top: .log 4, .css 4, (none) 3)

## Summary
- 647 nodes · 1616 edges · 52 communities (35 shown, 17 thin omitted)
- Extraction: 95% EXTRACTED · 5% INFERRED · 0% AMBIGUOUS · INFERRED: 85 edges (avg confidence: 0.85)
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `f6faa5b2`
- Run `git rev-parse HEAD` and compare to check if the graph is stale.
- Run `graphify update .` after code changes (no API cost).

## Community Hubs (Navigation)
- app.js
- renderInventoryReports
- initCustomDropdowns
- escapeHtml
- showToast
- FR Merchandise POS
- renderServicePerformance
- What You Must Do When Invoked
- index.ts
- check-bundle-report-costs.mjs
- isMobileScreen
- compilerOptions
- renderCart
- exportCashBankReconciliationPdf
- service-worker.js
- graphify reference: extra exports and benchmark
- graphify reference: query, path, explain
- Daily Spot Cash Design
- graphify reference: add a URL and watch a folder
- graphify reference: commit hook and native CLAUDE.md integration
- graphify reference: incremental update and cluster-only
- graphify reference: GitHub clone and cross-repo merge
- graphify reference: transcribe video and audio
- extraction-spec.md
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
- ref_node_child_process
- Analyze → Edit → Verify
- Review Focus
- formatDateInput
- check-owner-bank-table-reports.mjs
- check-service-performance.mjs
- check-losses-wastage.mjs
- check-credit-aging.mjs
- check-daily-cash-columns.mjs
- ref_node_fs
- UI Design Standard
- calculateServicePerformance_

## God Nodes (most connected - your core abstractions)
1. `escapeHtml()` - 74 edges
2. `renderInventory()` - 53 edges
3. `money()` - 48 edges
4. `showToast()` - 39 edges
5. `renderPaginationControls_()` - 30 edges
6. `formatDateInput()` - 28 edges
7. `api()` - 28 edges
8. `bindPaginationEvents_()` - 27 edges
9. `syncCustomDatePicker()` - 26 edges
10. `paginateItems_()` - 26 edges

## Surprising Connections (you probably didn't know these)
- `Task 2: Branch-scoped Daily Spot Cash UI` --references--> `askConfirmation()`  [INFERRED]
  docs/superpowers/plans/2026-09-29-daily-spot-cash.md → app.js
- `Task 2: Branch-scoped Daily Spot Cash UI` --references--> `renderDailySpotCash()`  [INFERRED]
  docs/superpowers/plans/2026-09-29-daily-spot-cash.md → app.js
- `Graphify Workflow` --references--> `FR Merchandise POS`  [INFERRED]
  AGENTS.md → README.md
- `Backup and Restore` --rationale_for--> `FR Merchandise POS`  [INFERRED]
  docs/OPERATIONS.md → README.md
- `Release Procedure` --rationale_for--> `FR Merchandise POS`  [INFERRED]
  docs/OPERATIONS.md → README.md

## Import Cycles
- None detected.

## Hyperedges (group relationships)
- **FIFO Auditability Workflow** — readme_fifo_selling_price_batches, tasks_bundle_sales, docs_operations_backup_and_restore [INFERRED 0.75]

## Communities (52 total, 17 thin omitted)

### Community 0 - "app.js"
Cohesion: 0.02
Nodes (80): actionConfirmDialog, actionConfirmSubmitBtn, adminAccounts, alignTableBadges(), allProducts, appShell, backdrop, bankTransactions (+72 more)

### Community 1 - "renderInventoryReports"
Cohesion: 0.07
Nodes (48): buildCashBankReconciliationPdfReport_(), buildCreditAgingPdfReport_(), buildFoodCostMarginPdfReport_(), buildInventoryValuationPdfReport_(), buildLossesWastagePdfReport_(), buildProductSalesPerformancePdfReport_(), buildProfitLossPdfReport_(), bundleMovementNotice_() (+40 more)

### Community 2 - "initCustomDropdowns"
Cohesion: 0.19
Nodes (14): closeDatePicker(), closeDropdown(), initCustomDatePickers(), initCustomDropdowns(), initSidebarBranchSwitcher(), openDatePicker(), openDropdown(), positionDropdownMenu() (+6 more)

### Community 3 - "escapeHtml"
Cohesion: 0.16
Nodes (59): bindDatePresets(), bindPaginationEvents_(), creditAgingCells_(), dailyCashPosition_(), displayCustomerName(), displayedSellingPrice(), escapeHtml(), formatDateTime() (+51 more)

### Community 4 - "showToast"
Cohesion: 0.08
Nodes (64): api(), applySession(), askConfirmation(), backgroundRefresh(), calculateOutstandingCreditAccounts(), changeOwnPassword(), completeRequiredPasswordChange(), deleteCreditPayment() (+56 more)

### Community 5 - "FR Merchandise POS"
Cohesion: 0.20
Nodes (10): Graphify Workflow, Backup and Restore, Release Procedure, FIFO Selling Price Batches, FR Merchandise POS, Google Apps Script Web App, Google Sheets, Bundle Sales (+2 more)

### Community 6 - "renderServicePerformance"
Cohesion: 0.42
Nodes (9): buildServicePerformancePdfReport_(), exportServicePerformancePdf(), generateServicePerformancePdf(), loadedServicePerformanceReport_(), performanceAverage_(), renderServicePerformance(), servicePerformanceKey_(), servicePerformanceNote_() (+1 more)

### Community 7 - "What You Must Do When Invoked"
Cohesion: 0.08
Nodes (24): For /graphify add and --watch, For /graphify query, For the commit hook and native CLAUDE.md integration, For --update and --cluster-only, /graphify, Honesty Rules, Interpreter guard for subcommands, Part A - Structural extraction for code files (+16 more)

### Community 9 - "index.ts"
Cohesion: 0.40
Nodes (5): ref_npm_supabase, allowedPermissions, corsHeaders, fail(), json()

### Community 10 - "check-bundle-report-costs.mjs"
Cohesion: 0.15
Nodes (11): allocations, context, fields, item, performance, product, receipt, resolved (+3 more)

### Community 11 - "isMobileScreen"
Cohesion: 0.50
Nodes (4): handleMenuToggle(), handleSidebarCollapse(), initSidebarState(), isMobileScreen()

### Community 13 - "renderCart"
Cohesion: 0.25
Nodes (11): addToCart(), beginRestaurantPayment_(), cartItemTotal(), openSaleCheckout(), renderCart(), saleSubtotal(), setSaleDiscountMode(), syncSaleServiceFields() (+3 more)

### Community 14 - "exportCashBankReconciliationPdf"
Cohesion: 0.67
Nodes (3): buildCashBankReconciliationPdfReportV2_(), exportCashBankReconciliationPdf(), generateCashBankReconciliationPdf()

### Community 17 - "graphify reference: extra exports and benchmark"
Cohesion: 0.22
Nodes (8): graphify reference: extra exports and benchmark, Step 6b - Wiki (only if --wiki flag), Step 7 - Neo4j export (only if --neo4j or --neo4j-push flag), Step 7a - FalkorDB export (only if --falkordb or --falkordb-push flag), Step 7b - SVG export (only if --svg flag), Step 7c - GraphML export (only if --graphml flag), Step 7d - MCP server (only if --mcp flag), Step 8 - Token reduction benchmark (only if total_words > 5000)

### Community 18 - "graphify reference: query, path, explain"
Cohesion: 0.33
Nodes (5): For /graphify explain, For /graphify path, graphify reference: query, path, explain, Step 0 — Constrained query expansion (REQUIRED before traversal), Step 1 — Traversal

### Community 19 - "Daily Spot Cash Design"
Cohesion: 0.22
Nodes (8): Acceptance criteria, Access and audit, Daily Spot Cash Design, Data flow, Goal, Record model, Scope, User interface

### Community 20 - "graphify reference: add a URL and watch a folder"
Cohesion: 0.50
Nodes (3): For /graphify add, For --watch, graphify reference: add a URL and watch a folder

### Community 21 - "graphify reference: commit hook and native CLAUDE.md integration"
Cohesion: 0.50
Nodes (3): For git commit hook, For native CLAUDE.md integration, graphify reference: commit hook and native CLAUDE.md integration

### Community 22 - "graphify reference: incremental update and cluster-only"
Cohesion: 0.50
Nodes (3): For --cluster-only, For --update (incremental re-extraction), graphify reference: incremental update and cluster-only

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

### Community 43 - "formatDateInput"
Cohesion: 0.21
Nodes (23): buildSalesPdfReport_(), ensureBankTransactionsDateDefaults(), ensureCashBankReconciliationDateDefaults(), ensureCreditAgingDateDefaults(), ensureCreditsDateDefaults(), ensureDailyExpensesDateDefaults(), ensureDailySpotCashDateDefaults(), ensureFoodCostMarginDateDefaults() (+15 more)

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
Nodes (6): ref_node_vm, context, fields, report, source, table

### Community 48 - "check-daily-cash-columns.mjs"
Cohesion: 0.29
Nodes (6): ref_node_assert, context, css, listeners, source, table

### Community 49 - "ref_node_fs"
Cohesion: 0.20
Nodes (7): ref_node_fs, checks, failures, files, appJs, quarantinedItemsMatch, quarantineReportMatch

### Community 50 - "UI Design Standard"
Cohesion: 0.11
Nodes (17): 10. Structure-based skeleton loading, 11. Responsive and accessible interaction, 12. Strict implementation and acceptance checklist, 1. Visual reference and implementation approach, 2. Design tokens, 3. Color, hierarchy, and readability, 4. Page composition, 5. Buttons, inputs, dropdowns, and badges (+9 more)

## Knowledge Gaps
- **204 isolated node(s):** `products`, `allProducts`, `branches`, `customers`, `transfers` (+199 more)
  These have ≤1 connection - possible missing edges or undocumented components. (Counts symbols only; 294 node(s) total have ≤1 connection when file, concept and rationale nodes are included.)
- **17 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `generateTableQrPerformancePdf()` connect `owner-reports.js` to `app.js`?**
  _High betweenness centrality (0.021) - this node is a cross-community bridge._
- **Why does `exportTableQrPerformancePdf()` connect `owner-reports.js` to `app.js`?**
  _High betweenness centrality (0.021) - this node is a cross-community bridge._
- **Why does `Task 2: Branch-scoped Daily Spot Cash UI` connect `Review Focus` to `escapeHtml`, `showToast`?**
  _High betweenness centrality (0.010) - this node is a cross-community bridge._
- **What connects `products`, `allProducts`, `branches` to the rest of the system?**
  _204 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `app.js` be split into smaller, more focused modules?**
  _Cohesion score 0.022988505747126436 - nodes in this community are weakly interconnected._
- **Should `renderInventoryReports` be split into smaller, more focused modules?**
  _Cohesion score 0.07092198581560284 - nodes in this community are weakly interconnected._
- **Should `showToast` be split into smaller, more focused modules?**
  _Cohesion score 0.07738095238095238 - nodes in this community are weakly interconnected._