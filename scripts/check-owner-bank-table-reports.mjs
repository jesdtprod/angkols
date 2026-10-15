import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import vm from 'node:vm';

const source = readFileSync(new URL('../owner-reports.js', import.meta.url), 'utf8');
const app = readFileSync(new URL('../app.js', import.meta.url), 'utf8');
const fields = { tableQrPerformanceDateFrom: { value: '2026-10-01' }, tableQrPerformanceDateTo: { value: '2026-10-31' }, searchInput: { value: '' } };
let calls = 0, printed, downloaded;
const context = vm.createContext({
  $: (selector) => fields[selector.slice(1)], syncCustomDatePicker() {},
  saleDateKey: (value) => String(value || '').slice(0, 10), money: (value) => `PHP ${Number(value).toFixed(2)}`,
  escapeHtml: (value) => String(value).replaceAll('&', '&amp;').replaceAll('<', '&lt;'),
  renderReportRunningHeader: () => '', renderReportPageFooter: () => '', branches: [], activeBranchId: 'MAIN',
  currentSession: { account: { id: 'owner', role: 'admin' } },
  reportCostNotice_: () => '', calculateOutstandingCreditAccounts: () => [],
  salesHistory: [], saleReturns: [], dailyExpenses: [], creditPayments: [], openingCreditAccounts: [], inventoryCostBatches: [], products: [],
  requireSupabase_: () => ({ rpc: async () => { calls++; return { data: { marker: calls } }; } }),
  throwIfError_: (error) => { if (error) throw new Error(error.message); },
  openReportInNewPage_: (html) => { printed = html; },
  exportReportPagesPdf_: async (html) => { downloaded = html; },
  showToast: (message) => { throw new Error(message); },
});
vm.runInContext(source, context);
for (const name of ['performanceMinutes_', 'performanceAverage_']) {
  vm.runInContext(app.match(new RegExp(`function ${name}\\([^]*?\\n}`))[0], context);
}
context.salesHistory = [
  { status: 'completed', date: '2026-10-15', total: 1000, paymentType: 'cash', saleId: 's1', items: [{ productId: 'a', name: 'Product A', qty: 2, price: 500, costTotal: 300 }] },
  { status: 'cancelled', date: '2026-10-15', total: 900, items: [{ costTotal: 700 }] },
  { status: 'completed', date: '2026-09-30', total: 500, items: [{ costTotal: 100 }] },
];
context.saleReturns = [{ saleId: 's1', refundResolvedAt: '2026-10-16', refundAmount: 100 }];
context.dailyExpenses = [{ businessDate: '2026-10-15', amount: 200 }];
context.inventoryCostBatches = [{ qty: 10, unitCost: 30 }, { qty: 20, unitCost: null }];
let owner = context.getOwnerDashboardReport_('2026-10-01', '2026-10-31');
assert.equal(owner.netSales, 900);
assert.equal(owner.cogs, 300);
assert.equal(owner.expenses, 200);
assert.equal(owner.netProfit, 400, 'actual costs and expenses, not a fixed margin');
assert.equal(owner.cards[7][1], 'PHP 300.00', 'unknown inventory costs excluded');
context.salesHistory[0].items.push({ productId: 'b', name: 'Unknown cost', qty: 1, price: 0, costTotal: null });
owner = context.getOwnerDashboardReport_('2026-10-01', '2026-10-31');
assert.match(owner.note, /1 sold lines have missing cost/);

const transaction = (id, date, type, amount) => ({ transaction_id: id, business_date: date, transaction_type: type, amount });
const bankData = {
  statements: [{ statement_id: 'st', date_from: '2026-10-01', date_to: '2026-10-31', opening_book_balance: 1000, statement_opening_balance: 1000, statement_closing_balance: 1200 }],
  transactions: [transaction('cleared', '2026-10-02', 'Deposit', 200), transaction('pending', '2026-10-20', 'Withdrawal', 100)],
  lines: [{ statement_id: 'st', bank_date: '2026-10-03', transaction_type: 'Deposit', amount: 200, bank_transaction_id: 'cleared' }],
};
let bank = context.calculateBankStatement_(bankData, '2026-10-01', '2026-10-31');
assert.equal(bank.status, 'Reconciled');
assert.equal(bank.bookClose, 1100);
assert.equal(bank.adjustedStatement, 1100);
assert.equal(bank.outstanding.length, 1, 'uncleared cheque is allowed and adjusts balance');
bankData.lines.push({ statement_id: 'future', bank_date: '2026-11-02', transaction_type: 'Withdrawal', amount: 100, bank_transaction_id: 'pending' });
assert.equal(context.calculateBankStatement_(bankData, '2026-10-01', '2026-10-31').outstanding.length, 1, 'future clearance cannot rewrite past cutoff');
bankData.lines[0].bank_transaction_id = null;
assert.equal(context.calculateBankStatement_(bankData, '2026-10-01', '2026-10-31').status, 'Needs Review');
bankData.lines[0].bank_transaction_id = 'cleared';
bankData.statements[0].statement_closing_balance = 1201;
assert.equal(context.calculateBankStatement_(bankData, '2026-10-01', '2026-10-31').statementCheck, -1);
bank = context.calculateBankStatement_({}, '2026-10-01', '2026-10-31');
assert.equal(bank.status, 'Not Started');
assert.equal(bank.bookClose, null, 'missing statement is not a reconciled zero');
bankData.statements[0].statement_closing_balance = 1200;
bankData.statements[0].opening_book_balance = 950;
bankData.transactions.push(transaction('prior', '2026-09-29', 'Withdrawal', 50));
assert.equal(context.calculateBankStatement_(bankData, '2026-10-01', '2026-10-31').status, 'Reconciled', 'prior uncleared ledger movement carried into adjustment');

const time = (day, minute = 0) => `2026-10-${day}T10:${String(minute).padStart(2, '0')}:00+08:00`;
const data = {
  orders: [
    { tableId: 'a', tableName: 'Table A', status: 'Settled', openedAt: time(15), closedAt: time(15, 30), gross: 1000, discount: 100, qrGross: 600, qty: 5, qrQty: 3 },
    { tableId: 'a', tableName: 'Table A', status: 'Open', openedAt: time(16), gross: 700 },
    { tableId: 'b', tableName: 'Table B', status: 'Cancelled', openedAt: time(16), closedAt: time(16, 20), gross: 500 },
    { tableId: 'b', tableName: 'Table B', status: 'Settled', openedAt: '2026-09-30', closedAt: time(1), gross: 200, discount: 0, qty: 1 },
  ],
  requests: [
    { tableId: 'a', tableName: 'Table A', status: 'Confirmed', createdAt: time(15), confirmedAt: time(15, 5) },
    { tableId: 'a', tableName: 'Table A', status: 'Confirmed', createdAt: time(15, 10), confirmedAt: time(15, 20) },
    { tableId: 'b', tableName: 'Table B', status: 'Claimed', createdAt: time(16) },
    { tableId: 'b', tableName: 'Table B', status: 'Rejected', createdAt: time(16) },
  ],
};
let qr = context.calculateTableQrPerformance_(data, '2026-10-01', '2026-10-31');
assert.equal(qr.totals.sales, 1100, 'tab revenue counted once despite multiple QR requests');
assert.equal(qr.totals.settled, 2);
assert.equal(qr.totals.cancelled, 1);
assert.equal(qr.totals.opened, 3);
assert.equal(qr.totals.qrGross, 600);
assert.equal(qr.totals.staffGross, 600, 'unlinked historical items remain explicitly unlinked');
assert.equal(qr.totals.pending, 1);
assert.equal(qr.totals.rejected, 1);
assert.equal(qr.totals.confirmationMinutes.length, 2);
qr = context.calculateTableQrPerformance_(data, '2026-10-01', '2026-10-31', 'table a');
assert.equal(qr.rows.length, 1);
assert.equal(qr.totals.sales, 900, 'search applies to totals and export scope');
assert.equal(context.performanceMinutes_(time(15, 10), time(15, 5)), null);

const [first, second] = await Promise.all([
  context.loadOwnerReportData_('test', 'MAIN', 'test_rpc', {}),
  context.loadOwnerReportData_('test', 'MAIN', 'test_rpc', {}),
]);
assert.equal(first, second);
assert.equal(calls, 1, 'concurrent loads deduplicated');
await context.loadOwnerReportData_('test', 'MAIN', 'test_rpc', {});
assert.equal(calls, 1, 'fresh cache reused');
await context.loadOwnerReportData_('test', 'OTHER', 'test_rpc', {});
assert.equal(calls, 2, 'branch cannot reuse another branch snapshot');
context.currentSession.account.role = 'staff';
await assert.rejects(context.loadOwnerReportData_('test', 'MAIN', 'test_rpc', {}), /Only administrators/);
context.currentSession.account.role = 'admin';
context.fixture = data;
vm.runInContext(`ownerReportCache.set('tableQr', { key: JSON.stringify(['owner', tableQrReportKey_()]), data: fixture });`, context);
fields.searchInput.value = 'Table A';
context.generateTableQrPerformancePdf();
await context.exportTableQrPerformancePdf();
assert.equal(printed, downloaded, 'print and export share exactly the same filtered report');
assert.match(printed, /Table A/);
assert.doesNotMatch(printed, /Table B/);
fields.tableQrPerformanceDateTo.value = '2026-10-20';
assert.throws(() => context.loadedTableQrReport_(), /finish loading/, 'stale date range cannot export');
const html = context.ownerReportPdf_('Test', 'October', [], [{ title: 'Rows', headings: ['Name'], rows: Array.from({ length: 29 }, (_, i) => [`Item ${i}`]) }]);
assert.equal((html.match(/class="report-page"/g) || []).length, 3, 'PDF paginates long reports');
const sql = readFileSync(new URL('../supabase/migrations/20261016180000_bank_statement_and_table_reporting.sql', import.meta.url), 'utf8');
assert.match(sql, /pg_advisory_xact_lock/);
assert.match(sql, /bank_transaction_id uuid unique/);
assert.match(sql, /protect_matched_bank_transaction/);
assert.match(sql, /get_table_qr_performance_report/);
console.log('Owner dashboard, bank reconciliation, table/QR calculations, access/cache guards and PDF parity checks passed.');
