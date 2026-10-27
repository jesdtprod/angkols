import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import vm from 'node:vm';

const source = readFileSync(new URL('../app.js', import.meta.url), 'utf8');
const listeners = new Map();
const table = { innerHTML: '', querySelector: () => null, querySelectorAll: (selector) => selector === '[data-close-cash-date]' ? [{ dataset: { closeCashDate: '2026-10-15' }, addEventListener: (name, callback) => listeners.set(name, callback) }] : [] };
let opened;
const context = vm.createContext({
  $: (selector) => selector === '#inventoryTable' ? table : { value: '' },
  ensureDailySpotCashDateDefaults() {}, saleDateKey: (value) => String(value || '').slice(0, 10),
  money: (value) => `PHP ${Number(value).toFixed(2)}`, escapeHtml: (value) => String(value).replaceAll('&', '&amp;').replaceAll('<', '&lt;').replaceAll('"', '&quot;'),
  dailySpotCash: [{ businessDate: '2026-10-15', openingCash: 1500, notes: '<test note>' }],
  salesHistory: [{ status: 'completed', paymentType: 'cash', date: '2026-10-15', total: 3690 }],
  dailyCashReconciliations: [], creditPayments: [], saleReturns: [], dailyExpenses: [], bankTransactions: [], activeSpotCashFilter: 'all',
  paginateItems_: (items) => ({ pagedItems: items }), renderPaginationControls_: () => '', bindPaginationEvents_() {},
  openForm: (...args) => { opened = args; },
});
for (const name of ['renderPageHeader_', 'dailyCashPosition_', 'renderDailySpotCash']) vm.runInContext(source.match(new RegExp(`function ${name}\\([^]*?\\n}`))[0], context);
context.renderDailySpotCash();
for (const label of ['Business Date', 'Opening Float', 'Expected Cash', 'Counted Cash', 'Over / (Short)', 'Close Status', 'Action']) assert.match(table.innerHTML, new RegExp(`data-label="${label.replace(/[.*+?^${}()|[\]\\]/g, '\\$&')}"`));
assert.match(table.innerHTML, /PHP 5190.00/);
assert.match(table.innerHTML, /Not counted/);
assert.doesNotMatch(table.innerHTML, /data-label="Notes"|data-label="Updated"/);
assert.match(table.innerHTML, /&lt;test note>/, 'notes escaped');
assert.match(table.innerHTML, /class="icon-button"[^>]*title="Close Day"/);
listeners.get('click')();
assert.deepEqual(opened, ['cashReconciliation', '2026-10-15'], 'icon preserves the existing close-day flow');
for (const [countedCash, expected, status] of [[5190, 'Balanced', 'Closed'], [5100, 'Short', 'Closed'], [5300, 'Over', 'Closed']]) {
  context.dailyCashReconciliations = [{ businessDate: '2026-10-15', countedCash, closedAt: '2026-10-15T20:00:00Z' }];
  context.renderDailySpotCash();
  assert.match(table.innerHTML, new RegExp(`>${expected}<`));
  assert.match(table.innerHTML, new RegExp(`>${status}<`));
  assert.match(table.innerHTML, /title="Update Close"/);
}
context.dailyCashReconciliations[0].closedAt = null;
context.renderDailySpotCash();
assert.match(table.innerHTML, />Counted<\/span>/, 'saved count is not assumed closed');
const css = readFileSync(new URL('../styles.css', import.meta.url), 'utf8');
assert.match(css, /\.spotcash-table-shell \{ overflow-x: auto; \}/, 'narrow desktop columns remain reachable');
assert.match(css, /font-variant-numeric: tabular-nums/);
console.log('Daily cash columns, labels, amounts, open/closed/variance states, escaping and action wiring passed.');
