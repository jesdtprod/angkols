import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import vm from 'node:vm';

const source = readFileSync(new URL('../app.js', import.meta.url), 'utf8');
const fields = {
  creditAgingDateFrom: { value: '2026-10-01' }, creditAgingDateTo: { value: '2026-10-31' }, searchInput: { value: '' },
};
const table = { innerHTML: '' };
let printed, downloaded;
const context = vm.createContext({
  $: (selector) => selector === '#inventoryTable' ? table : fields[selector.slice(1)],
  formatDateInput: (date) => `${date.getFullYear()}-${String(date.getMonth() + 1).padStart(2, '0')}-${String(date.getDate()).padStart(2, '0')}`,
  syncCustomDatePicker() {}, saleDateKey: (date) => date ? date.slice(0, 10) : '',
  money: (value) => `PHP ${Number(value).toFixed(2)}`, escapeHtml: (value) => String(value).replaceAll('&', '&amp;').replaceAll('<', '&lt;'),
  renderReportRunningHeader: () => '', renderReportPageFooter: () => '',
  openReportInNewPage_: (html) => { printed = html; },
  exportReportPagesPdf_: async (html, title, filename) => { downloaded = { html, title, filename }; },
  customers: [{ id: 'A', name: 'Alice' }, { id: 'B', name: 'Bob', phone: '091234' }],
  salesHistory: [], creditPayments: [], openingCreditAccounts: [], branches: [], activeBranchId: 'MAIN',
});
for (const name of ['renderPageHeader_', 'calculateOutstandingCreditAccounts', 'ensureCreditAgingDateDefaults', 'getCreditAgingReport_', 'creditAgingNote_',
  'creditAgingCells_', 'buildCreditAgingPdfReport_', 'generateCreditAgingPdf', 'exportCreditAgingPdf', 'renderCreditAging']) {
  const declaration = source.match(new RegExp(`(?:async )?function ${name}\\([^]*?\\n}`))?.[0];
  assert.ok(declaration, name);
  vm.runInContext(declaration, context);
}
const dated = (age) => new Date(Date.UTC(2026, 9, 31 - age)).toISOString().slice(0, 10);
context.salesHistory = [0, 30, 31, 60, 61, 90, 91].map((age) => ({ saleId: `age-${age}`, customerId: 'A', customerName: 'Alice', status: 'completed', paymentType: 'credit', date: dated(age), total: 100 }));
context.salesHistory.push(
  { saleId: 'settled', customerId: 'C', customerName: 'Settled', status: 'completed', paymentType: 'credit', date: '2026-09-01', total: 200 },
  { saleId: 'cancelled', customerId: 'D', status: 'cancelled', paymentType: 'credit', date: '2026-10-01', total: 999 },
  { saleId: 'cash', customerId: 'D', status: 'completed', paymentType: 'cash', date: '2026-10-01', total: 999 },
  { saleId: 'future', customerId: 'D', status: 'completed', paymentType: 'credit', date: '2026-11-01', total: 999 },
);
context.openingCreditAccounts = [{ creditId: 'opening-B', customerId: 'B', customerName: 'Bob', date: '2026-06-01', total: 500 }];
context.creditPayments = [
  { creditId: 'age-31', date: '2026-10-01', amount: 25 },
  { creditId: 'age-31', date: '2026-11-01', amount: 75 },
  { creditId: 'opening-B', date: '2026-09-30', amount: 100 },
  { creditId: 'opening-B', date: '2026-10-31', amount: 50 },
  { creditId: 'settled', date: '2026-10-01', amount: 200 },
  { creditId: 'other-branch-not-loaded', date: '2026-10-01', amount: 999 },
];
let report = context.getCreditAgingReport_();
assert.equal(report.totals.balance, 1025);
assert.deepEqual(Array.from(report.totals.buckets), [200, 175, 200, 450], 'exact 30/31, 60/61, 90/91 day boundaries');
assert.equal(report.openingBalance, 1100, 'older unpaid balances survive month-start filter');
assert.equal(report.added, 200);
assert.equal(report.collected, 275, 'includes period collection on fully settled accounts');
assert.equal(report.openingBalance + report.added - report.collected, report.totals.balance);
assert.equal(report.rows.length, 2);
assert.equal(report.rows[0].name, 'Bob', 'oldest debt first');
assert.equal(report.totals.accounts, 8);
context.renderCreditAging();
assert.match(table.innerHTML, /Alice/);
assert.match(table.innerHTML, /PHP 1025.00/);
context.generateCreditAgingPdf();
await context.exportCreditAgingPdf();
assert.equal(printed, downloaded.html);
assert.equal(downloaded.filename, 'credit-aging_2026-10-01_to_2026-10-31.pdf');
fields.searchInput.value = '091234';
report = context.getCreditAgingReport_();
assert.equal(report.totals.balance, 350);
assert.equal(report.openingBalance, 400);
assert.equal(report.collected, 50);
assert.equal(report.rows.length, 1);
const filtered = context.buildCreditAgingPdfReport_().renderedPagesHtml;
assert.match(filtered, /Bob/); assert.doesNotMatch(filtered, /Alice/);
fields.searchInput.value = 'unknown';
assert.equal(context.getCreditAgingReport_().totals.balance, 0);
assert.match(context.buildCreditAgingPdfReport_().renderedPagesHtml, /No outstanding credit/);
fields.searchInput.value = '';
context.salesHistory.push(...Array.from({ length: 20 }, (_, index) => ({ saleId: `extra-${index}`, customerId: `extra-${index}`, customerName: `Extra ${index}`, status: 'completed', paymentType: 'credit', date: '2026-10-31', total: 1 })));
assert.equal((context.buildCreditAgingPdfReport_().renderedPagesHtml.match(/class="report-page"/g) || []).length, 2);
fields.creditAgingDateFrom.value = ''; fields.creditAgingDateTo.value = '';
context.ensureCreditAgingDateDefaults();
assert.match(fields.creditAgingDateFrom.value, /-01$/);
assert.equal(fields.creditAgingDateTo.value, context.formatDateInput(new Date()));
console.log('Credit aging balances, age boundaries, historical cutoff, period collections, search, PDF wiring/pagination, and date defaults passed.');
