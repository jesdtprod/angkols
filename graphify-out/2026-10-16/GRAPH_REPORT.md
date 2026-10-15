# Graph Report - angkols  (2026-10-16)

## Corpus Check
- 129 files · ~200,762 words
- Verdict: corpus is large enough that graph structure adds value.
- Unclassified: 18 file(s) not represented in the graph (top: .log 4, .css 4, (none) 3)

## Summary
- 592 nodes · 1457 edges · 44 communities (27 shown, 17 thin omitted)
- Extraction: 95% EXTRACTED · 5% INFERRED · 0% AMBIGUOUS · INFERRED: 67 edges (avg confidence: 0.85)
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `25dc1e57`
- Run `git rev-parse HEAD` and compare to check if the graph is stale.
- Run `graphify update .` after code changes (no API cost).

## Community Hubs (Navigation)
- app.js
- openReportInNewPage_
- initCustomDatePickers
- formatDateInput
- showToast
- FR Merchandise POS
- buildServicePerformancePdfReport_
- What You Must Do When Invoked
- index.ts
- check-bundle-report-costs.mjs
- isMobileScreen
- compilerOptions
- initCustomDropdowns
- escapeHtml
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
- Review Focus
- renderInventoryReports

## God Nodes (most connected - your core abstractions)
1. `escapeHtml()` - 73 edges
2. `renderInventory()` - 51 edges
3. `money()` - 48 edges
4. `showToast()` - 39 edges
5. `api()` - 28 edges
6. `formatDateInput()` - 26 edges
7. `openForm()` - 26 edges
8. `setView()` - 26 edges
9. `syncCustomDatePicker()` - 24 edges
10. `renderPaginationControls_()` - 23 edges

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

## Communities (44 total, 17 thin omitted)

### Community 0 - "app.js"
Cohesion: 0.02
Nodes (80): actionConfirmDialog, actionConfirmSubmitBtn, adminAccounts, alignTableBadges(), allProducts, appShell, backdrop, bankTransactions (+72 more)

### Community 1 - "openReportInNewPage_"
Cohesion: 0.11
Nodes (22): buildCashBankReconciliationPdfReportV2_(), buildCreditAgingPdfReport_(), buildProductSalesPerformancePdfReport_(), creditAgingNote_(), exportCashBankReconciliationPdf(), exportCreditAgingPdf(), exportFoodCostMarginPdf(), exportProductSalesPerformancePdf() (+14 more)

### Community 2 - "initCustomDatePickers"
Cohesion: 0.25
Nodes (8): closeDatePicker(), closeDropdown(), initCustomDatePickers(), initSidebarBranchSwitcher(), openDatePicker(), openDropdown(), positionDropdownMenu(), repositionOpenDropdowns()

### Community 3 - "formatDateInput"
Cohesion: 0.09
Nodes (48): buildCashBankReconciliationPdfReport_(), buildFoodCostMarginPdfReport_(), buildLossesWastagePdfReport_(), buildProfitLossPdfReport_(), buildSalesPdfReport_(), calculateOutstandingCreditAccounts(), ensureBankTransactionsDateDefaults(), ensureCashBankReconciliationDateDefaults() (+40 more)

### Community 4 - "showToast"
Cohesion: 0.08
Nodes (57): api(), applySession(), askConfirmation(), changeOwnPassword(), completeRequiredPasswordChange(), downloadOperationalBackup(), enforcePasswordResetLogout_(), formatAlertMessage() (+49 more)

### Community 5 - "FR Merchandise POS"
Cohesion: 0.20
Nodes (10): Graphify Workflow, Backup and Restore, Release Procedure, FIFO Selling Price Batches, FR Merchandise POS, Google Apps Script Web App, Google Sheets, Bundle Sales (+2 more)

### Community 6 - "buildServicePerformancePdfReport_"
Cohesion: 0.36
Nodes (9): buildServicePerformancePdfReport_(), calculateServicePerformance_(), loadedServicePerformanceReport_(), performanceAverage_(), performanceMinutes_(), renderServicePerformance(), servicePerformanceKey_(), servicePerformanceNote_() (+1 more)

### Community 7 - "What You Must Do When Invoked"
Cohesion: 0.08
Nodes (24): For /graphify add and --watch, For /graphify query, For the commit hook and native CLAUDE.md integration, For --update and --cluster-only, /graphify, Honesty Rules, Interpreter guard for subcommands, Part A - Structural extraction for code files (+16 more)

### Community 9 - "index.ts"
Cohesion: 0.40
Nodes (5): ref_npm_supabase, allowedPermissions, corsHeaders, fail(), json()

### Community 10 - "check-bundle-report-costs.mjs"
Cohesion: 0.05
Nodes (39): ref_node_assert, ref_node_fs, ref_node_vm, allocations, context, fields, item, performance (+31 more)

### Community 11 - "isMobileScreen"
Cohesion: 0.50
Nodes (4): handleMenuToggle(), handleSidebarCollapse(), initSidebarState(), isMobileScreen()

### Community 13 - "initCustomDropdowns"
Cohesion: 0.31
Nodes (10): beginRestaurantPayment_(), initCustomDropdowns(), openSaleCheckout(), saleSubtotal(), setSaleDiscountMode(), sortSelectOptionsAtoZ_(), syncSaleCustomerOptions(), syncSaleServiceFields() (+2 more)

### Community 14 - "escapeHtml"
Cohesion: 0.13
Nodes (61): addToCart(), backgroundRefresh(), bindPaginationEvents_(), cartItemTotal(), creditAgingCells_(), dailyCashPosition_(), deleteCreditPayment(), deleteDailyExpense() (+53 more)

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

### Community 42 - "Review Focus"
Cohesion: 0.29
Nodes (6): Daily Spot Cash Implementation Plan, Global Constraints, Review Focus, Task 1: Database and permission contract, Task 2: Branch-scoped Daily Spot Cash UI, Task 3: Deployment and acceptance verification

### Community 43 - "renderInventoryReports"
Cohesion: 0.19
Nodes (13): buildInventoryValuationPdfReport_(), bundleMovementNotice_(), exportInventoryReportPdf(), exportInventoryValuationPdf(), formatTransferQuantity(), generateInventoryReportPdf(), generateInventoryValuationPdf(), getInventoryReportMovement() (+5 more)

## Knowledge Gaps
- **166 isolated node(s):** `products`, `allProducts`, `branches`, `customers`, `transfers` (+161 more)
  These have ≤1 connection - possible missing edges or undocumented components. (Counts symbols only; 251 node(s) total have ≤1 connection when file, concept and rationale nodes are included.)
- **17 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `generateTableQrPerformancePdf()` connect `owner-reports.js` to `app.js`?**
  _High betweenness centrality (0.024) - this node is a cross-community bridge._
- **Why does `exportTableQrPerformancePdf()` connect `owner-reports.js` to `app.js`?**
  _High betweenness centrality (0.024) - this node is a cross-community bridge._
- **Why does `Task 2: Branch-scoped Daily Spot Cash UI` connect `Review Focus` to `showToast`, `escapeHtml`?**
  _High betweenness centrality (0.012) - this node is a cross-community bridge._
- **What connects `products`, `allProducts`, `branches` to the rest of the system?**
  _166 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `app.js` be split into smaller, more focused modules?**
  _Cohesion score 0.023255813953488372 - nodes in this community are weakly interconnected._
- **Should `openReportInNewPage_` be split into smaller, more focused modules?**
  _Cohesion score 0.11255411255411256 - nodes in this community are weakly interconnected._
- **Should `formatDateInput` be split into smaller, more focused modules?**
  _Cohesion score 0.09397163120567376 - nodes in this community are weakly interconnected._