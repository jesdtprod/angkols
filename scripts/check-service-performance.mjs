import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import vm from 'node:vm';

const source = readFileSync(new URL('../app.js', import.meta.url), 'utf8');
const migration = readFileSync(new URL('../supabase/migrations/20261016170000_kitchen_waiter_performance.sql', import.meta.url), 'utf8');
const fields = { servicePerformanceDateFrom: { value: '2026-10-01' }, servicePerformanceDateTo: { value: '2026-10-31' }, searchInput: { value: '' }, generateServicePerformancePdfButton: {}, exportServicePerformancePdfButton: {} };
const table = { innerHTML: '' };
let printed, downloaded, calls = 0, response;
const context = vm.createContext({
  $: (selector) => selector === '#inventoryTable' ? table : fields[selector.slice(1)],
  formatDateInput: (date) => `${date.getFullYear()}-${String(date.getMonth() + 1).padStart(2, '0')}-${String(date.getDate()).padStart(2, '0')}`,
  syncCustomDatePicker() {}, escapeHtml: (value) => String(value).replaceAll('&', '&amp;').replaceAll('<', '&lt;'),
  renderSkeletonTable() {},
  renderReportRunningHeader: () => '', renderReportPageFooter: () => '',
  openReportInNewPage_: (html) => { printed = html; }, exportReportPagesPdf_: async (html, title, filename) => { downloaded = { html, filename }; },
  showToast: (message) => { throw new Error(message); }, throwIfError_: (error) => { if (error) throw new Error(error.message); },
  requireSupabase_: () => ({ rpc: async (name, args) => { calls++; assert.equal(name, 'get_service_performance_report'); assert.equal(args.target_branch_id, context.activeBranchId); return response; } }),
  currentSession: { account: { id: 'owner', role: 'admin' } }, activeBranchId: 'MAIN', activeView: 'servicePerformance',
  servicePerformanceCache: { key: '', data: null, loadedAt: 0 }, servicePerformanceRenderId: 0, branches: [],
});
for (const name of ['renderPageHeader_', 'ensureServicePerformanceDateDefaults', 'servicePerformanceKey_', 'performanceMinutes_', 'performanceAverage_',
  'calculateServicePerformance_', 'servicePerformanceNote_', 'servicePerformanceTables_', 'loadedServicePerformanceReport_',
  'buildServicePerformancePdfReport_', 'generateServicePerformancePdf', 'exportServicePerformancePdf', 'renderServicePerformance']) {
  const declaration = source.match(new RegExp(`(?:async )?function ${name}\\([^]*?\\n}`))?.[0];
  assert.ok(declaration, name); vm.runInContext(declaration, context);
}
const time = (minute) => `2026-10-16T10:${String(minute).padStart(2, '0')}:00+08:00`;
const base = { ticketId: 't1', requiresKitchen: true, status: 'Served', qty: 1, startedAt: time(0), readyAt: time(10), servedAt: time(12), startedBy: 'cook1', startedName: 'Chef A', readyBy: 'cook1', readyName: 'Chef A', servedBy: 'waiter1', servedName: 'Waiter A' };
const data = { items: [
  { ...base, id: 'one', qty: 2 },
  { ...base, id: 'two', status: 'Ready', readyAt: time(20), servedAt: null, servedBy: null },
  { ...base, id: 'drink', ticketId: 't2', requiresKitchen: false, qty: 3, readyAt: time(2), servedAt: time(3), servedBy: 'waiter2', servedName: 'Waiter B' },
  { id: 'legacy', ticketId: 't3', requiresKitchen: true, status: 'Served', qty: 1, legacy: true },
  { ...base, id: 'invalid', ticketId: 't4', status: 'Ready', startedBy: 'cook2', startedName: 'Chef B', readyBy: 'cook2', readyName: 'Chef B', startedAt: time(10), readyAt: time(5) },
  { ...base, id: 'zero', startedAt: time(0), readyAt: time(0), servedAt: time(0) },
], requests: [
  { id: 'r1', createdAt: time(0), claimedAt: time(2), claimedBy: 'waiter1', claimedName: 'Waiter A', confirmedAt: time(3), confirmedBy: 'waiter1', confirmedName: 'Waiter A' },
  { id: 'r2', createdAt: time(0), claimedAt: time(6), claimedBy: 'waiter2', claimedName: 'Waiter B', confirmedAt: time(7), confirmedBy: 'waiter1', confirmedName: 'Waiter A' },
  { id: 'r3', createdAt: time(10), claimedAt: time(5), claimedBy: 'waiter2', claimedName: 'Waiter B' },
  { id: 'pending', createdAt: time(0), status: 'Pending' },
] };
let report = context.calculateServicePerformance_(data);
assert.equal(report.totals.readyQty, 6, 'automatic non-kitchen readiness is excluded');
assert.equal(report.totals.servedQty, 7, 'serving includes food and drinks');
assert.equal(report.totals.tickets, 4);
assert.equal(report.totals.requests, 4);
assert.equal(report.totals.legacy, 1);
assert.equal(context.performanceAverage_(report.totals.prep), '10.0 min (3)');
assert.equal(context.performanceAverage_(report.totals.pickup), '1.0 min (3)');
assert.equal(context.performanceMinutes_(time(5), time(0)), null);
assert.equal(context.performanceMinutes_(null, time(0)), null);
assert.equal(context.performanceAverage_([]), '—', 'unknown timing must not be zero');
assert.equal(report.waiterRows.find((row) => row.id === 'waiter1').confirmed, 2);
assert.equal(report.waiterRows.find((row) => row.id === 'waiter2').claimed, 2);
assert.equal(report.waiterRows.find((row) => row.id === 'waiter2').claim.length, 1, 'invalid sample excluded');
assert.equal(report.kitchenRows.find((row) => row.id === 'unattributed').prep.length, 0);
report = context.calculateServicePerformance_(data, 'Chef A');
assert.equal(report.totals.readyQty, 4); assert.equal(report.totals.servedQty, 0);
assert.equal(context.calculateServicePerformance_({}).kitchenRows.length, 0);

response = { data, error: null };
await context.renderServicePerformance();
assert.equal(calls, 1);
assert.match(table.innerHTML, /Chef A/); assert.match(table.innerHTML, /Unattributed/);
assert.equal(fields.generateServicePerformancePdfButton.disabled, false);
context.generateServicePerformancePdf(); await context.exportServicePerformancePdf();
assert.equal(printed, downloaded.html);
assert.equal(downloaded.filename, 'service-performance_2026-10-01_to_2026-10-31.pdf');
fields.searchInput.value = 'Chef A';
await context.renderServicePerformance();
assert.equal(calls, 1, 'staff search reuses loaded branch/date snapshot');
const filtered = context.buildServicePerformancePdfReport_().renderedPagesHtml;
assert.match(filtered, /Chef A/); assert.doesNotMatch(filtered, /Waiter A/);
fields.servicePerformanceDateTo.value = '2026-10-30';
assert.throws(() => context.loadedServicePerformanceReport_(), /finish loading/, 'never export stale date selection');
response = { data: null, error: { message: 'Connection failed' } };
await context.renderServicePerformance();
assert.match(table.innerHTML, /Connection failed/);
assert.equal(fields.generateServicePerformancePdfButton.disabled, true);
assert.equal(context.servicePerformanceCache.data, null);
context.currentSession.account.role = 'staff';
assert.throws(() => context.loadedServicePerformanceReport_(), /finish loading/);
context.currentSession.account.role = 'admin'; fields.searchInput.value = '';
let release;
response = new Promise((resolve) => { release = resolve; });
const pending = context.renderServicePerformance(true);
context.activeView = 'pos'; table.innerHTML = 'Other page';
release({ data, error: null }); await pending;
assert.equal(table.innerHTML, 'Other page', 'late report response must not overwrite another page');
context.activeView = 'servicePerformance'; response = { data, error: null };
await context.renderServicePerformance(true);
fields.servicePerformanceDateFrom.value = ''; fields.servicePerformanceDateTo.value = '';
context.ensureServicePerformanceDateDefaults(); assert.match(fields.servicePerformanceDateFrom.value, /-01$/);
assert.match(migration, /not public.is_admin\(\)/);
assert.match(migration, /t.branch_id = target_branch_id/);
assert.match(migration, /at time zone 'Asia\/Manila'/);
assert.doesNotMatch(migration, /update public.kitchen_ticket_items set.*started_at/i, 'no fabricated historical timing backfill');
console.log('Service metrics, timing samples, staff attribution/search, PDF wiring, access checks, cache/race handling, and defaults passed.');
