import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import vm from 'node:vm';

const source = readFileSync(new URL('../app.js', import.meta.url), 'utf8');
const fields = {
  foodCostMarginDateFrom: '2026-10-01', foodCostMarginDateTo: '2026-10-31',
  profitLossDateFrom: '2026-10-01', profitLossDateTo: '2026-10-31',
  inventoryValuationDateFrom: '2026-10-01', inventoryValuationDateTo: '2026-10-31', searchInput: '',
  productSalesPerformanceDateFrom: '2026-10-01', productSalesPerformanceDateTo: '2026-10-31',
  productSalesPerformanceType: 'all', productSalesPerformanceSort: 'best',
};
const table = { innerHTML: '' };
const context = vm.createContext({
  $: (selector) => selector === '#inventoryTable' ? table : { value: fields[selector.slice(1)] || '' },
  ensureFoodCostMarginDateDefaults() {}, ensureProfitLossDateDefaults() {}, ensureInventoryValuationDateDefaults() {},
  ensureProductSalesPerformanceDateDefaults() {},
  saleDateKey: (date) => date.slice(0, 10), money: (value) => `PHP ${value.toFixed(2)}`,
  escapeHtml: (value) => String(value), sortByName_: (rows) => rows,
  renderReportRunningHeader: () => '', renderReportPageFooter: () => '',
  products: [], stockInHistory: [], salesHistory: [], branches: [], activeBranchId: 'MAIN',
  saleReturns: [], dailyExpenses: [], inventoryLosses: [], transfers: [], inventoryCostBatches: [],
});
for (const name of ['resolveBundleReportCost_', 'reportCostNotice_', 'getCostPendingSaleLines_',
  'getFoodCostMarginReport_', 'buildFoodCostMarginPdfReport_', 'buildProfitLossPdfReport_',
  'renderProfitLoss', 'renderFoodCostMargin', 'getInventoryValuationReport_',
  'getProductSalesPerformanceReport_', 'productPerformanceNotes_', 'buildProductSalesPerformancePdfReport_', 'renderProductSalesPerformance']) {
  const declaration = source.match(new RegExp(`function ${name}\\([^]*?\\n}`))?.[0];
  assert.ok(declaration, name);
  vm.runInContext(declaration, context);
}

const item = { product_id: 'bucket', qty: 2, cost_total: null };
const sale = { branch_id: 'MAIN', occurred_at: '2026-10-15T12:00:00Z' };
const product = { product_type: 'bundle', components: [{ productId: 'beer', qty: 6 }] };
const receipt = { product_id: 'beer', branch_id: 'MAIN', status: 'Completed', occurred_at: '2026-10-12T12:00:00Z', unit_cost: 50 };
const resolve = (input = item, allocations = [], receipts = [receipt], recipe = product) =>
  context.resolveBundleReportCost_(input, sale, recipe, allocations, receipts);

assert.equal(resolve().costTotal, 600, '2 bundles x 6 bottles x PHP 50');
assert.equal(resolve().costEstimated, true, 'legacy recipe fallback must be disclosed');
assert.equal(resolve().componentUsage[0].qty, 12);
assert.equal(resolve(item, [], [{ ...receipt, branch_id: 'OTHER' }]).costTotal, null);
assert.equal(resolve(item, [], [{ ...receipt, occurred_at: '2026-10-16T12:00:00Z' }]).costTotal, null);
assert.equal(resolve(item, [], []).costTotal, null, 'missing costs are not zero');
assert.equal(resolve(item, [], [{ ...receipt, unit_cost: 0 }]).costTotal, 0, 'zero is a valid recorded cost');
assert.equal(resolve({ ...item, cost_total: 590 }).costTotal, 590, 'preserve saved historical COGS');
assert.equal(resolve(item, [], [receipt], { ...product, components: [] }).costTotal, null);
assert.equal(resolve(item, [], [receipt], { ...product, components: [...product.components, { productId: 'ice', qty: 1 }] }).costTotal, null, 'do not accept partial component cost');

const allocations = [
  { component_product_id: 'beer', qty: 4, cost_total: 180, unit_cost: 45, inventory_cost_batches: { unit_cost: 999 } },
  { component_product_id: 'beer', qty: 8, cost_total: null, unit_cost: null, inventory_cost_batches: { unit_cost: 50 } },
];
assert.equal(resolve(item, allocations).costTotal, 580, 'mixed FIFO batches and corrected receipt costs');
assert.equal(resolve(item, allocations).costEstimated, false);
assert.equal(resolve(item, allocations, [], { ...product, components: [{ productId: 'beer', qty: 99 }] }).costTotal, 580, 'recipe edits do not change recorded allocation cost');
assert.equal(resolve(item, [{ ...allocations[1], inventory_cost_batches: { unit_cost: null } }]).costTotal, null);
assert.equal(resolve({ cost_total: undefined }, [], [], { product_type: 'individual' }).costTotal, null);

const resolved = resolve();
context.products = [{ id: 'bucket', name: 'Beer Bucket', productType: 'bundle' }, { id: 'beer', name: 'Beer', qty: 8 }];
context.salesHistory = [{ saleId: 'sale', status: 'completed', date: sale.occurred_at, total: 800, items: [
  { productId: 'bucket', name: 'Beer Bucket', qty: 2, price: 400, ...resolved },
] }];
assert.equal(context.getFoodCostMarginReport_().totals.cogs, 600);
assert.equal(context.getFoodCostMarginReport_().totals.grossProfit, 200);
assert.equal(context.getFoodCostMarginReport_().totals.marginPercent, 25);
assert.match(context.buildFoodCostMarginPdfReport_().renderedPagesHtml, /estimated component cost/);
assert.match(context.buildProfitLossPdfReport_().renderedPagesHtml, /PHP 600.00/);
assert.match(context.buildProfitLossPdfReport_().renderedPagesHtml, /estimated component cost/);
context.renderProfitLoss();
assert.match(table.innerHTML, /PHP 600.00/);
assert.match(table.innerHTML, /estimated component cost/);
context.renderFoodCostMargin();
assert.match(table.innerHTML, /PHP 600.00/);
assert.match(table.innerHTML, /estimated component cost/);
assert.equal(context.getInventoryValuationReport_().rows[0].movement.sold, 12, 'physical movement counts bottles used by bundles');

context.salesHistory[0].items[0].costTotal = null;
context.salesHistory[0].items[0].costEstimated = false;
context.renderProfitLoss();
assert.match(table.innerHTML, /1 cost pending/);
assert.doesNotMatch(table.innerHTML, /2 cost pending/, 'pending counts must not be doubled');
fields.searchInput = 'unmatched';
assert.equal(context.getFoodCostMarginReport_().totals.cogs, 0);
assert.equal(context.getFoodCostMarginReport_().costNotice, '', 'export notice follows filtered products');
console.log('Bundle cost and report checks passed.');

fields.searchInput = '';
context.products = [
  { id: 'bucket', name: 'Beer Bucket', productType: 'bundle', status: 'Active' },
  { id: 'beer', name: 'Beer Bottle', productType: 'individual', status: 'Active' },
  { id: 'food', name: 'Sisig', productType: 'individual', status: 'Active' },
  { id: 'unsold', name: 'No Sales Item', productType: 'individual', status: 'Active' },
];
context.salesHistory = [{ status: 'completed', date: '2026-10-15T12:00:00Z', items: [
  { productId: 'bucket', name: 'Beer Bucket', qty: 2, price: 400, costTotal: 600, costEstimated: true },
  { productId: 'beer', name: 'Beer Bottle', qty: 4, price: 75, costTotal: 200 },
  { productId: 'food', name: 'Sisig', qty: 1, price: 180, costTotal: null },
] },
{ status: 'cancelled', date: '2026-10-15', items: [{ productId: 'beer', qty: 900, price: 75, costTotal: 1 }] },
{ status: 'completed', date: '2026-09-30', items: [{ productId: 'beer', qty: 900, price: 75, costTotal: 1 }] }];
let performance = context.getProductSalesPerformanceReport_();
assert.equal(performance.totals.sales, 1280);
assert.equal(performance.totals.qty, 7, 'bundles counted as sold products, not additional bottles');
assert.equal(performance.totals.cogs, 800);
assert.equal(performance.totals.grossProfit, 480);
assert.equal(performance.totals.unsold, 1);
assert.equal(performance.totals.pendingLines, 1);
assert.equal(performance.rows[0].id, 'beer', 'best selling is ranked by quantity');
fields.productSalesPerformanceSort = 'slow';
assert.equal(context.getProductSalesPerformanceReport_().rows[0].id, 'unsold');
fields.productSalesPerformanceSort = 'sales';
assert.equal(context.getProductSalesPerformanceReport_().rows[0].id, 'bucket');
fields.productSalesPerformanceType = 'bundle';
performance = context.getProductSalesPerformanceReport_();
assert.equal(performance.rows.length, 1);
assert.equal(performance.rows[0].share, 62.5, 'sales share keeps branch denominator after filtering');
assert.equal(performance.totals.sales, 800);
const pdf = context.buildProductSalesPerformancePdfReport_().renderedPagesHtml;
assert.match(pdf, /Beer Bucket/);
assert.doesNotMatch(pdf, /Beer Bottle/);
assert.match(pdf, /estimated component cost/);
assert.match(pdf, /62.5%/);
context.renderProductSalesPerformance();
assert.match(table.innerHTML, /Beer Bucket/);
assert.doesNotMatch(table.innerHTML, /Beer Bottle/);
fields.productSalesPerformanceType = 'all';
fields.searchInput = 'Bottle';
performance = context.getProductSalesPerformanceReport_();
assert.equal(performance.rows.length, 1);
assert.equal(performance.costNotice, '', 'estimated bundle warning follows visible products');
fields.searchInput = '';
context.products.push(...Array.from({ length: 20 }, (_, i) => ({ id: `unused-${i}`, name: `Unused ${i}`, status: 'Active' })));
assert.equal((context.buildProductSalesPerformancePdfReport_().renderedPagesHtml.match(/class="report-page"/g) || []).length, 2);
console.log('Product sales performance calculations, filtering, ranking, and PDF pagination passed.');
