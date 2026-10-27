import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import vm from 'node:vm';

const source = readFileSync(new URL('../app.js', import.meta.url), 'utf8');
const migration = readFileSync(new URL('../supabase/migrations/20261016160000_inventory_loss_cost_snapshots.sql', import.meta.url), 'utf8');
const fields = { lossesWastageDateFrom: { value: '2026-10-01' }, lossesWastageDateTo: { value: '2026-10-31' }, searchInput: { value: '' }, lossesWastageSource: { value: 'all' } };
const table = { innerHTML: '' };
let printed, downloaded;
const context = vm.createContext({
  $: (selector) => selector === '#inventoryTable' ? table : fields[selector.slice(1)],
  formatDateInput: (date) => `${date.getFullYear()}-${String(date.getMonth() + 1).padStart(2, '0')}-${String(date.getDate()).padStart(2, '0')}`,
  syncCustomDatePicker() {}, saleDateKey: (date) => date ? date.slice(0, 10) : '', money: (value) => `PHP ${Number(value).toFixed(2)}`,
  escapeHtml: (value) => String(value).replaceAll('&', '&amp;').replaceAll('<', '&lt;'),
  renderReportRunningHeader: () => '', renderReportPageFooter: () => '',
  openReportInNewPage_: (html) => { printed = html; },
  exportReportPagesPdf_: async (html, title, filename) => { downloaded = { html, filename }; },
  stockInHistory: [], inventoryLosses: [], inventoryQuarantineCases: [], inventoryQuarantineItems: [], inventoryReturnLots: [],
  allProducts: [{ id: 'beer', name: 'Beer', unit: 'bottle', price: 900 }], saleReturnItems: [], saleReturns: [], branches: [], activeBranchId: 'MAIN',
});
for (const name of ['renderPageHeader_', 'ensureLossesWastageDateDefaults', 'resolveLossReportCost_', 'getLossesWastageReport_', 'lossesWastageNote_',
  'lossesWastageCells_', 'buildLossesWastagePdfReport_', 'generateLossesWastagePdf', 'exportLossesWastagePdf', 'renderLossesWastage']) {
  const declaration = source.match(new RegExp(`(?:async )?function ${name}\\([^]*?\\n}`))?.[0];
  assert.ok(declaration, name); vm.runInContext(declaration, context);
}
const record = { id: 'legacy', productId: 'beer', productName: 'Beer', qty: 2, occurredAt: '2026-10-15', reason: 'Damaged', unit: 'bottle' };
context.stockInHistory = [{ id: 'receipt', productId: 'beer', status: 'Completed', date: '2026-10-01', unitCost: 50 }];
assert.equal(context.resolveLossReportCost_(record).cost, 100, 'purchase cost, never selling price');
assert.equal(context.resolveLossReportCost_(record).basis, 'Estimated');
assert.equal(context.resolveLossReportCost_({ ...record, costTotal: 80 }).cost, 80, 'saved historical total takes priority');
assert.equal(context.resolveLossReportCost_({ ...record, unitCost: 0 }).cost, 0, 'zero is a valid purchase cost');
assert.equal(context.resolveLossReportCost_({ ...record, receiptId: 'receipt' }).basis, 'Recorded');
assert.equal(context.resolveLossReportCost_(record, [{ ...context.stockInHistory[0], date: '2026-10-16' }]).cost, null, 'future cost is not historical cost');
assert.equal(context.resolveLossReportCost_({ ...record, productId: 'unknown' }).cost, null);
const allocations = [{ qty: 1, unitCost: 40 }, { qty: 1, unitCost: null, stockInId: 'receipt' }];
assert.equal(context.resolveLossReportCost_({ ...record, costAllocations: allocations }).cost, 90);
assert.equal(context.resolveLossReportCost_({ ...record, costAllocations: [{ qty: 2, unitCost: null }] }).cost, null, 'unknown allocation is not replaced by unrelated estimated cost');
assert.equal(context.resolveLossReportCost_({ ...record, costAllocations: [{ qty: 1, unitCost: 40 }] }).cost, null, 'incomplete quantities are not a complete cost');

context.inventoryLosses = [record, { ...record, id: 'recorded', costTotal: 80 }, { ...record, id: 'unknown', productId: 'unknown', qty: 1 }, { ...record, id: 'outside', occurredAt: '2026-09-30' }];
context.inventoryQuarantineCases = [{ id: 'case', reason: 'Spoiled', createdAt: '2026-09-01', sourceType: 'stock_in', reference: 'receipt' }];
context.inventoryQuarantineItems = [
  { id: 'disposed', caseId: 'case', productId: 'beer', productName: 'Beer', qty: 3, unitCost: 10, resolution: 'disposed', resolvedAt: '2026-10-31' },
  { id: 'held', caseId: 'case', productId: 'beer', qty: 999, resolution: 'quarantine' },
  { id: 'restocked', caseId: 'case', productId: 'beer', qty: 999, resolution: 'restocked', resolvedAt: '2026-10-15' },
  { id: 'supplier', caseId: 'case', productId: 'beer', qty: 999, resolution: 'supplier_return', resolvedAt: '2026-10-15' },
];
context.saleReturnItems = [{ id: 'return-item', returnId: 'return' }];
context.saleReturns = [{ id: 'return', saleId: 'original-sale', reason: 'Broken' }];
context.inventoryReturnLots = [{ id: 'lot', returnItemId: 'return-item', productId: 'beer', qty: 1, unitCost: 20, state: 'disposed', createdAt: '2026-09-01', resolvedAt: '2026-10-01' }];
let report = context.getLossesWastageReport_();
assert.equal(report.rows.length, 5, 'only write-offs and disposed items, by disposal date');
assert.equal(report.totals.qty, 9);
assert.equal(report.totals.recorded, 130);
assert.equal(report.totals.estimated, 100);
assert.equal(report.totals.pendingQty, 1);
assert.equal(report.totals.pendingRecords, 1);
assert.equal(report.reasons.find((item) => item.reason === 'Damaged').qty, 5);
assert.equal(new Set(report.rows.map((row) => row.key)).size, report.rows.length);
context.renderLossesWastage(); assert.match(table.innerHTML, /PHP 130.00/);
context.generateLossesWastagePdf(); await context.exportLossesWastagePdf();
assert.equal(printed, downloaded.html);
assert.equal(downloaded.filename, 'losses-wastage_2026-10-01_to_2026-10-31.pdf');
assert.match(printed, /Not recorded/); assert.match(printed, /Estimated/); assert.match(printed, /Recorded/);
fields.lossesWastageSource.value = 'quarantine';
assert.equal(context.getLossesWastageReport_().rows.length, 1);
assert.doesNotMatch(context.buildLossesWastagePdfReport_().renderedPagesHtml, /Stock Write-off/);
fields.lossesWastageSource.value = 'all'; fields.searchInput.value = 'original-sale';
assert.equal(context.getLossesWastageReport_().totals.recorded, 20);
fields.searchInput.value = 'no match';
assert.equal(context.getLossesWastageReport_().rows.length, 0);
assert.match(context.buildLossesWastagePdfReport_().renderedPagesHtml, /No losses or disposals/);
fields.searchInput.value = '';
context.inventoryLosses.push(...Array.from({ length: 25 }, (_, index) => ({ ...record, id: `extra-${index}` })));
assert.equal((context.buildLossesWastagePdfReport_().renderedPagesHtml.match(/class="report-page"/g) || []).length, 3);
fields.lossesWastageDateFrom.value = ''; fields.lossesWastageDateTo.value = '';
context.ensureLossesWastageDateDefaults();
assert.match(fields.lossesWastageDateFrom.value, /-01$/);
assert.match(migration, /available_inventory_qty/);
assert.match(migration, /order by is_opening desc, received_at, batch_id for update/);
assert.match(migration, /'qty', allocated_qty, 'unitCost', batch_row.unit_cost/);
console.log('Losses/wastage costing, disposal selection, date/source/search filters, PDF wiring/pagination and snapshot guards passed.');
