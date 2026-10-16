// Owner reports share the app's data, controls, tables, and PDF renderer.
let ownerDashboardRange = { from: '', to: '' };
const ownerReportCache = new Map();
let bankReportRenderId = 0;
let tableQrReportRenderId = 0;

function ownerDefaultRange_(prefix) {
  const today = new Date();
  const from = $(`#${prefix}DateFrom`), to = $(`#${prefix}DateTo`);
  if (from && !from.value) from.value = formatDateInput(new Date(today.getFullYear(), today.getMonth(), 1));
  if (to && !to.value) to.value = formatDateInput(today);
  if (from) syncCustomDatePicker(from);
  if (to) syncCustomDatePicker(to);
  return { from: from?.value || '', to: to?.value || '' };
}

function ownerKpisHtml_(cards) {
  return `<div class="std-kpi-grid">${cards.map(([label, value, sub = '']) => {
    const l = String(label).toUpperCase();
    let iconClass = 'icon-sky';
    let valColor = 'text-sky';
    let iconSvg = '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M3 3v18h18"/><path d="M18 17V9"/><path d="M13 17V5"/><path d="M8 17v-3"/></svg>';

    if (l.includes('SALES') || l.includes('REVENUE') || l.includes('PROFIT') || l.includes('COLLECTED') || l.includes('VALUE') || l.includes('COUNTED')) {
      iconClass = 'icon-emerald';
      valColor = 'text-emerald';
      iconSvg = '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M12 2v20M17 5H9.5a3.5 3.5 0 0 0 0 7h5a3.5 3.5 0 0 1 0 7H6"/></svg>';
    } else if (l.includes('COGS') || l.includes('EXPENSE') || l.includes('VARIANCE') || l.includes('OVER / (SHORT)') || l.includes('OUTSTANDING') || l.includes('DIFFERENCE')) {
      iconClass = 'icon-amber';
      valColor = 'text-amber';
      iconSvg = '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect width="20" height="14" x="2" y="5" rx="2"/><line x1="2" x2="22" y1="10" y2="10"/></svg>';
    } else if (l.includes('UNITS') || l.includes('TICKETS') || l.includes('TABS') || l.includes('TABLE') || l.includes('REQUEST') || l.includes('EXPECTED')) {
      iconClass = 'icon-sky';
      valColor = 'text-sky';
      iconSvg = '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect width="20" height="12" x="2" y="6" rx="2"/><circle cx="12" cy="12" r="2"/></svg>';
    }

    return `
      <div class="std-kpi-card">
        <div class="std-kpi-icon ${iconClass}">
          ${iconSvg}
        </div>
        <div class="std-kpi-content">
          <span class="std-kpi-label">${escapeHtml(label)}</span>
          <strong class="std-kpi-value ${valColor}">${escapeHtml(String(value))}</strong>
          <span class="std-kpi-sub">${escapeHtml(sub)}</span>
        </div>
      </div>
    `;
  }).join('')}</div>`;
}

function ownerTablesHtml_(sections) {
  return sections.map(({ title, headings, rows }) => `
    <h3>${escapeHtml(title)}</h3>
    <div class="std-table-shell">
      <div class="std-table-header" style="grid-template-columns:repeat(${headings.length},minmax(0,1fr));">
        ${headings.map((heading) => `<span>${escapeHtml(heading)}</span>`).join('')}
      </div>
      ${rows.map((row) => `
        <div class="std-table-row" style="grid-template-columns:repeat(${headings.length},minmax(0,1fr));">
          ${row.map((cell, index) => {
            const heading = headings[index];
            const isQty = /tabs|requests|confirmed|rejected|pending|units|qty|lines/i.test(heading);
            const isNumber = typeof cell === 'number' || (typeof cell === 'string' && /^\d+$/.test(cell.trim()));
            const content = isQty && isNumber && !String(cell).includes('%') && !String(cell).includes('PHP')
              ? `<span class="stock-pill stock-quantity">${escapeHtml(String(cell))}</span>`
              : escapeHtml(String(cell));
            return `<div data-label="${escapeHtml(heading)}">${content}</div>`;
          }).join('')}
        </div>
      `).join('') || `
        <div class="std-empty-state">
          <div class="std-empty-icon" style="color:#38bdf8;background:rgba(56,189,248,0.1);border-color:rgba(56,189,248,0.25);">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
              <path d="M3 3v18h18"/><path d="M18 17V9"/><path d="M13 17V5"/><path d="M8 17v-3"/>
            </svg>
          </div>
          <h4 class="std-empty-title">No Records</h4>
          <p class="std-empty-desc">No matching activity in this period.</p>
        </div>
      `}
    </div>
  `).join('');
}

function ownerReportPdf_(title, periodText, cards, sections, note = '') {
  const branch = branches.find((item) => item.id === activeBranchId)?.name || 'Main Branch';
  const generated = new Date().toLocaleString('en-PH', { dateStyle: 'medium', timeStyle: 'short' });
  const pages = sections.flatMap((section) => Array.from({ length: Math.max(1, Math.ceil(section.rows.length / 14)) }, (_, index) => ({ ...section, rows: section.rows.slice(index * 14, index * 14 + 14) })));
return pages.map((section, index) => `<div class="report-page"><div class="report-page-content">${renderReportRunningHeader(branch, periodText, title, index === 0, 'Executive management and financial operations audit', generated)}<section class="report-summary-grid">${cards.map(([label, value]) => `<div><span>${escapeHtml(label)}</span><strong>${escapeHtml(String(value))}</strong></div>`).join('')}</section>${note ? `<p class="report-note">${escapeHtml(note)}</p>` : ''}<div class="report-section-title-wrap"><h2 class="report-section-title">${escapeHtml(section.title)}</h2><span class="report-count-badge">${section.rows.length} records</span></div><table class="report-table"><thead><tr>${section.headings.map((heading) => `<th>${escapeHtml(heading)}</th>`).join('')}</tr></thead><tbody>${section.rows.map((row) => `<tr>${row.map((cell) => `<td>${escapeHtml(String(cell))}</td>`).join('')}</tr>`).join('') || `<tr><td colspan="${section.headings.length}">No matching records.</td></tr>`}</tbody></table>${index === pages.length - 1 ? '<div class="report-sign-block"><div class="sign-column"><div class="sign-line"></div><span class="sign-title">Prepared By (Cashier / Staff)</span><span class="sign-sub">Signature over printed name</span></div><div class="sign-column"><div class="sign-line"></div><span class="sign-title">Audited & Verified By</span><span class="sign-sub">Branch Manager / Operations</span></div></div><div class="report-disclaimer"><p>ANGKOL\'S GRILL &amp; RESTOBAR SYSTEM-GENERATED AUDIT REPORT &bull; CONFIDENTIAL &bull; ALL RIGHTS RESERVED</p></div>' : ''}</div>${renderReportPageFooter(index + 1, pages.length, generated, title)}</div>`).join('');
}

function getOwnerDashboardReport_(from, to) {
  const within = (value) => { const date = saleDateKey(value); return date && date >= from && date <= to; };
  const sales = salesHistory.filter((sale) => sale.status === 'completed' && within(sale.date));
  const refunds = saleReturns.filter((item) => item.refundResolvedAt && within(item.refundResolvedAt));
  const expenses = dailyExpenses.filter((item) => within(item.businessDate));
  const sum = (rows, field) => rows.reduce((total, row) => total + Number(row[field] || 0), 0);
  const netSales = sum(sales, 'total') - sum(refunds, 'refundAmount');
  const items = sales.flatMap((sale) => sale.items || []);
  const cogs = sum(items.filter((item) => item.costTotal != null), 'costTotal');
  const expenseTotal = sum(expenses, 'amount');
  const outstanding = calculateOutstandingCreditAccounts(
    salesHistory.filter((sale) => sale.status === 'completed' && saleDateKey(sale.date) <= to),
    creditPayments.filter((payment) => saleDateKey(payment.date) <= to),
    openingCreditAccounts.filter((account) => saleDateKey(account.date) <= to));
  const stockValue = inventoryCostBatches.reduce((total, batch) => total + (batch.unitCost == null ? 0 : Number(batch.qty) * Number(batch.unitCost)), 0);
  const lowStock = products.filter((item) => item.productType !== 'bundle' && item.status === 'Active' && Number(item.qty) <= Number(item.lowStockLevel || 0)).sort((a, b) => Number(a.qty) - Number(b.qty) || a.name.localeCompare(b.name));
  const days = new Map(), productSales = new Map();
  const day = (value) => { const date = saleDateKey(value); if (!days.has(date)) days.set(date, { date, sales: 0, cogs: 0, expenses: 0 }); return days.get(date); };
  sales.forEach((sale) => {
    const row = day(sale.date); row.sales += Number(sale.total || 0);
    (sale.items || []).forEach((item) => {
      row.cogs += Number(item.costTotal || 0);
      const product = productSales.get(item.productId) || { name: item.name || item.productId, qty: 0, sales: 0 };
      product.qty += Number(item.qty || 0); product.sales += Number(item.qty || 0) * Number(item.price || 0); productSales.set(item.productId, product);
    });
  });
  refunds.forEach((item) => { day(item.refundResolvedAt).sales -= Number(item.refundAmount || 0); });
  expenses.forEach((item) => { day(item.businessDate).expenses += Number(item.amount || 0); });
  const cashSales = sum(sales.filter((sale) => sale.paymentType === 'cash'), 'total');
  const collections = sum(creditPayments.filter((payment) => within(payment.date)), 'amount');
  const cashRefunds = sum(refunds.filter((item) => salesHistory.find((sale) => sale.saleId === item.saleId)?.paymentType === 'cash'), 'refundAmount');
  const unknown = items.filter((item) => item.costTotal == null).length;
  const note = `${unknown ? `${unknown} sold lines have missing cost; profit is estimated. ` : ''}${reportCostNotice_(sales)} Stock value and stock alerts show current inventory; credit balances are as of ${to}.`;
  const cards = [['NET SALES', money(netSales), 'Completed sales less resolved refunds'], ['COGS', money(cogs), unknown ? `${unknown} lines need cost review` : 'Recorded costs including bundle components'], ['GROSS PROFIT', money(netSales - cogs)], ['EST. NET PROFIT', money(netSales - cogs - expenseTotal), 'Net sales less COGS and recorded operating expenses'], ['OPERATING EXPENSES', money(expenseTotal)], ['CASH COLLECTED', money(cashSales + collections - cashRefunds), 'Cash sales + credit collections - cash refunds'], ['OUTSTANDING CREDIT', money(sum(outstanding, 'balance')), `As of ${to}`], ['CURRENT STOCK VALUE', money(stockValue), 'Known remaining FIFO costs; unknown costs excluded']];
  const sections = [
    { title: 'Daily Profitability', headings: ['Date', 'Net Sales', 'COGS', 'Expenses', 'Est. Net Profit'], rows: [...days.values()].sort((a, b) => b.date.localeCompare(a.date)).map((row) => [row.date, money(row.sales), money(row.cogs), money(row.expenses), money(row.sales - row.cogs - row.expenses)]) },
    { title: 'Product Sales (Before Discounts / Refunds)', headings: ['Product', 'Qty Sold', 'Gross Menu Sales'], rows: [...productSales.values()].sort((a, b) => b.sales - a.sales || a.name.localeCompare(b.name)).map((row) => [row.name, row.qty, money(row.sales)]) },
    { title: 'Current Stock Alerts', headings: ['Product', 'On Hand', 'Warning Level'], rows: lowStock.map((item) => [item.name, `${item.qty} ${item.unit || 'units'}`, item.lowStockLevel]) },
  ];
  return { from, to, netSales, cogs, expenses: expenseTotal, netProfit: netSales - cogs - expenseTotal, cards, sections, note };
}

function currentOwnerDashboardReport_() {
  const today = new Date();
  if (!ownerDashboardRange.from) ownerDashboardRange.from = formatDateInput(new Date(today.getFullYear(), today.getMonth(), 1));
  if (!ownerDashboardRange.to) ownerDashboardRange.to = formatDateInput(today);
  return getOwnerDashboardReport_(ownerDashboardRange.from, ownerDashboardRange.to);
}

function renderOwnerDashboard_() {
  const root = $('#dashboard'); if (!root) return;
  const report = currentOwnerDashboardReport_();
  root.innerHTML = `<div class="std-view theme-sky owner-dashboard-report"><div class="std-hero-card"><div class="std-hero-leading"><div class="std-hero-text"><span class="std-hero-kicker">OWNER REPORTING</span><strong class="std-hero-title">Owner Dashboard</strong><p class="std-hero-desc">Sales, recorded costs, profitability, collections, receivables, and current stock risks.</p></div></div><div class="std-hero-actions"><button class="button button-secondary std-record-btn" id="printOwnerDashboardButton" type="button"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" style="width:16px;height:16px;"><path d="M6 2h9l3 3v17H6z"/><path d="M14 2v4h4"/><path d="M8 15h8M8 18h6M8 12h3"/></svg><span>Print PDF</span></button><button class="button button-primary std-record-btn" id="exportOwnerDashboardButton" type="button"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" style="width:16px;height:16px;"><path d="M12 3v12"/><path d="m7 10 5 5 5-5"/><path d="M5 21h14"/><path d="M5 17v4h14v-4"/></svg><span>Export PDF</span></button></div></div><div class="sales-date-range" id="ownerDashboardDateRange"><div class="sales-date-control"><input id="ownerDashboardDateFrom" type="date" value="${report.from}" aria-label="Owner dashboard date from"></div><div class="sales-date-control"><input id="ownerDashboardDateTo" type="date" value="${report.to}" aria-label="Owner dashboard date to"></div></div>${ownerKpisHtml_(report.cards)}<div class="std-toolbar-strip"><span class="product-meta">${escapeHtml(report.note)}</span></div>${ownerTablesHtml_(report.sections)}</div>`;
  initCustomDatePickers(root);
  ['ownerDashboardDateFrom', 'ownerDashboardDateTo'].forEach((id) => $(`#${id}`).addEventListener('change', () => {
    const from = $('#ownerDashboardDateFrom').value, to = $('#ownerDashboardDateTo').value;
    ownerDashboardRange = { from, to };
    if (from && to && from > to) { if (id.endsWith('From')) ownerDashboardRange.to = from; else ownerDashboardRange.from = to; }
    renderOwnerDashboard_();
  }));
  $('#printOwnerDashboardButton').addEventListener('click', () => {
    const current = currentOwnerDashboardReport_();
    openReportInNewPage_(ownerReportPdf_('Owner Dashboard', `${current.from} to ${current.to}`, current.cards, current.sections, current.note), 'Owner Dashboard');
  });
  $('#exportOwnerDashboardButton').addEventListener('click', async () => {
    const current = currentOwnerDashboardReport_();
    await exportReportPagesPdf_(ownerReportPdf_('Owner Dashboard', `${current.from} to ${current.to}`, current.cards, current.sections, current.note), 'Owner Dashboard', `owner-dashboard_${current.from}_to_${current.to}.pdf`, $('#exportOwnerDashboardButton'));
  });
}

async function loadOwnerReportData_(kind, key, rpc, parameters, force = false) {
  if (currentSession?.account?.role !== 'admin') throw new Error('Only administrators can access this report.');
  const cacheKey = JSON.stringify([currentSession.account.id, key]);
  const previous = ownerReportCache.get(kind);
  if (!force && previous?.key === cacheKey && previous.data && Date.now() - previous.at < 30000) return previous.data;
  if (!force && previous?.key === cacheKey && previous.pending) return previous.pending;
  const entry = { key: cacheKey, data: null, at: 0 };
  ownerReportCache.set(kind, entry);
  entry.pending = (async () => {
    const { data, error } = await requireSupabase_().rpc(rpc, parameters);
    throwIfError_(error);
    if (ownerReportCache.get(kind) === entry) { entry.data = data; entry.at = Date.now(); entry.pending = null; }
    return data;
  })();
  try { return await entry.pending; } catch (error) { if (ownerReportCache.get(kind) === entry) ownerReportCache.delete(kind); throw error; }
}

function calculateBankStatement_(data, from, to) {
  const transactions = (data.transactions || []).filter((item) => !item.deleted_at && item.business_date <= to);
  const transactionMap = new Map(transactions.map((item) => [item.transaction_id, item]));
  const statement = (data.statements || []).find((item) => item.date_from === from && item.date_to === to);
  const lines = (data.lines || []).filter((item) => item.statement_id === statement?.statement_id);
  const validMatch = (line) => {
    const transaction = transactionMap.get(line.bank_transaction_id);
    return transaction && transaction.transaction_type === line.transaction_type && Number(transaction.amount) === Number(line.amount);
  };
  const cleared = new Set((data.lines || []).filter((line) => line.bank_date <= to && validMatch(line)).map((line) => line.bank_transaction_id));
  const outstanding = transactions.filter((item) => !cleared.has(item.transaction_id));
  const unmatched = lines.filter((line) => !validMatch(line));
  const signed = (item) => Number(item.amount) * (item.transaction_type === 'Deposit' ? 1 : -1);
  const sum = (items) => items.reduce((total, item) => total + signed(item), 0);
  if (!statement) return { statement: null, status: 'Not Started', transactions, lines, outstanding, unmatched, bookClose: null, adjustedStatement: null, difference: null, statementCheck: null };
  const bookClose = Number(statement.opening_book_balance) + sum(transactions.filter((item) => item.business_date >= from));
  const adjustedStatement = Number(statement.statement_closing_balance) + sum(outstanding);
  const difference = adjustedStatement - bookClose;
  const statementCheck = Number(statement.statement_opening_balance) + sum(lines) - Number(statement.statement_closing_balance);
  const status = Math.abs(difference) < 0.005 && Math.abs(statementCheck) < 0.005 && !unmatched.length ? 'Reconciled' : 'Needs Review';
  return { statement, status, transactions, lines, outstanding, unmatched, bookClose, adjustedStatement, difference, statementCheck };
}

function bankStatementSections_(bank) {
  const sections = [
    { title: 'Bank Statement Reconciliation', headings: ['Metric', 'Amount / Status'], rows: [
      ['Status', bank.status], ['Book closing balance', bank.bookClose === null ? 'Not entered' : money(bank.bookClose)],
      ['Statement closing balance', bank.statement ? money(bank.statement.statement_closing_balance) : 'Not entered'],
      ['Adjusted statement balance', bank.adjustedStatement === null ? 'Not entered' : money(bank.adjustedStatement)],
      ['Difference (adjusted statement - book)', bank.difference === null ? 'Not entered' : money(bank.difference)],
      ['Statement arithmetic difference', bank.statementCheck === null ? 'Not entered' : money(bank.statementCheck)], ['Unmatched bank lines', bank.unmatched.length],
    ] },
    { title: 'Statement Lines', headings: ['Bank Date', 'Type', 'Amount', 'Reference', 'Ledger Match'], rows: bank.lines.map((line) => [line.bank_date, line.transaction_type, money(line.amount), line.reference || '—', line.bank_transaction_id || 'Unmatched']) },
    { title: 'Outstanding / In-Transit Ledger Entries', headings: ['Book Date', 'Type', 'Amount', 'Reference'], rows: bank.outstanding.map((item) => [item.business_date, item.transaction_type, money(item.amount), item.reference || item.cheque_number || item.details]) },
  ];
  return sections;
}

function bankStatementNote_() {
  return 'Branch bank ledger: enter statement balances covering the same scope as these transactions. Adjusted statement = statement closing + uncleared deposits - uncleared withdrawals. Reconciled requires zero balance difference, correct statement arithmetic, and all statement lines matched. Bank-only charges/interest use the Bank method in Bank Transactions and do not change drawer cash.';
}

function renderCashBankReconciliation() {
  return renderFullCashBankReconciliation_();
}

async function renderFullCashBankReconciliation_(force = false) {
  const root = $('#inventoryTable'); if (!root) return;
  const sequence = ++bankReportRenderId;
  const branch = activeBranchId;
  ownerDefaultRange_('cashBankReconciliation');
  const from = $('#cashBankReconciliationDateFrom').value, to = $('#cashBankReconciliationDateTo').value;
  const key = JSON.stringify([branch, from, to]);
  [$('#generateCashBankReconciliationPdfButton'), $('#exportCashBankReconciliationPdfButton')].forEach((button) => { if (button) button.disabled = true; });

  // Render Cash Drawer and Bank Ledger Overview immediately
  renderCashBankOverview_();

  try {
    const data = await loadOwnerReportData_('bank', branch, 'get_bank_statement_report', { target_branch_id: branch }, force);
    if (sequence !== bankReportRenderId || activeView !== 'cashBankReconciliation' || key !== JSON.stringify([activeBranchId, $('#cashBankReconciliationDateFrom').value, $('#cashBankReconciliationDateTo').value])) return;
    const bank = calculateBankStatement_(data, from, to);
    root.querySelector('.std-view')?.insertAdjacentHTML('beforeend', `
      <div class="report-section-title-wrap" style="margin-top:20px;">
        <div style="display:flex;align-items:center;gap:10px;">
          <h3 class="report-section-title" style="margin:0;font-size:15px;color:#fff;">Bank Statement Matching</h3>
          <span class="report-count-badge ${bank.status === 'Reconciled' ? 'badge-emerald' : 'badge-amber'}">${escapeHtml(bank.status)}</span>
        </div>
        <div style="display:flex;align-items:center;gap:8px;">
          <button class="button button-primary" id="editBankStatementButton" type="button" style="height:32px;padding:0 12px;font-size:12px;">${bank.statement ? 'Edit' : 'Enter'} Bank Statement</button>
          <button class="button button-secondary" id="refreshBankStatementButton" type="button" style="height:32px;padding:0 12px;font-size:12px;">Refresh</button>
          <select id="savedBankStatementSelect" aria-label="Open saved bank statement" style="height:32px;padding:0 10px;font-size:12px;border-radius:6px;background:rgba(15,23,42,0.8);color:#fff;border:1px solid rgba(255,255,255,0.15);">
            <option value="">Open saved period...</option>
            ${(data.statements || []).map((item) => `<option value="${item.statement_id}">${item.date_from} to ${item.date_to}</option>`).join('')}
          </select>
        </div>
      </div>
      <p class="product-meta" style="margin:4px 0 12px;font-size:12px;color:#94a3b8;">${escapeHtml(bankStatementNote_())}</p>
      ${ownerTablesHtml_(bankStatementSections_(bank))}
    `);
    $('#editBankStatementButton')?.addEventListener('click', () => openBankStatementEditor_(data, from, to));
    $('#refreshBankStatementButton')?.addEventListener('click', () => renderFullCashBankReconciliation_(true));
    $('#savedBankStatementSelect')?.addEventListener('change', (event) => {
      const saved = data.statements.find((item) => item.statement_id === event.target.value); if (!saved) return;
      $('#cashBankReconciliationDateFrom').value = saved.date_from; $('#cashBankReconciliationDateTo').value = saved.date_to;
      syncCustomDatePicker($('#cashBankReconciliationDateFrom')); syncCustomDatePicker($('#cashBankReconciliationDateTo')); renderFullCashBankReconciliation_();
    });
    initCustomDropdowns(root);
    [$('#generateCashBankReconciliationPdfButton'), $('#exportCashBankReconciliationPdfButton')].forEach((button) => { if (button) button.disabled = false; });
  } catch (error) {
    console.warn('Bank statement data not loaded from server:', error);
    [$('#generateCashBankReconciliationPdfButton'), $('#exportCashBankReconciliationPdfButton')].forEach((button) => { if (button) button.disabled = false; });
  }
}

function buildFullCashBankPdf_() {
  const report = getCashBankReconciliationReport_();
  const cached = ownerReportCache.get('bank');
  const bankData = cached?.data || { statements: [], transactions: [], lines: [] };
  const bank = calculateBankStatement_(bankData, report.from, report.to);
  const periodText = `${report.from} to ${report.to}`;
  const sections = [
    { title: 'Daily Cash Reconciliation', headings: ['Date', 'Expected Cash', 'Counted Cash', 'Variance', 'Status'], rows: report.rows.map((row) => [row.date, money(row.expectedCash), row.countedCash === null ? 'Not counted' : money(row.countedCash), row.variance === null ? '—' : money(row.variance), row.countedCash === null ? 'Open' : Math.abs(row.variance) >= 0.005 ? 'Variance' : row.closed ? 'Reconciled' : 'Counted']) },
    { title: 'Bank Activity', headings: ['Date', 'Type', 'Method', 'Amount', 'Reference'], rows: (bank.transactions || []).filter((item) => item.business_date >= report.from).map((item) => [item.business_date, item.transaction_type, item.payment_method, money(item.amount), item.reference || item.details]) },
    ...bankStatementSections_(bank),
  ];
  const cards = [['EXPECTED CASH', money(report.totals.expectedCash)], ['COUNTED CASH', money(report.totals.countedCash)], ['CASH VARIANCE', money(report.totals.variance)], ['BANK STATUS', bank.status]];
  return { ...report, periodText, renderedPagesHtml: ownerReportPdf_('Cash & Bank Reconciliation', periodText, cards, sections, bankStatementNote_()) };
}

function openBankStatementEditor_(data, from, to) {
  let dialog = $('#bankStatementDialog');
  if (!dialog) { dialog = document.createElement('dialog'); dialog.id = 'bankStatementDialog'; dialog.className = 'pepsi-dialog'; document.body.appendChild(dialog); }
  const existing = (data.statements || []).find((item) => item.date_from === from && item.date_to === to);
  const oldLines = (data.lines || []).filter((item) => item.statement_id === existing?.statement_id);
  const matchedElsewhere = new Set((data.lines || []).filter((item) => item.statement_id !== existing?.statement_id).map((item) => item.bank_transaction_id));
  const options = (data.transactions || []).filter((item) => !item.deleted_at && item.business_date <= to && !matchedElsewhere.has(item.transaction_id));
  const balances = [['openingBook', 'Opening Book Balance', existing?.opening_book_balance], ['statementOpening', 'Statement Opening Balance', existing?.statement_opening_balance], ['statementClosing', 'Statement Closing Balance', existing?.statement_closing_balance]];
  dialog.innerHTML = `<form id="bankStatementForm"><div class="modal-head"><div class="modal-title-wrap"><div class="modal-icon-badge"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="2" y="5" width="20" height="14" rx="2"/><path d="M6 10h12M6 14h4"/></svg></div><div class="modal-title-content"><span class="modal-eyebrow">BANK RECONCILIATION</span><h2>Bank Statement Matching</h2><p class="modal-subtitle">${from} to ${to} &bull; One statement line per ledger match</p></div></div><button class="icon-button close-dialog-btn" type="button" data-statement-close aria-label="Close"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="m6 6 12 12M18 6 6 18"/></svg></button></div><div class="form-grid">${balances.map(([name,label,value]) => `<div class="form-field-group"><label for="bank-${name}">${label} (PHP) *</label><div class="input-with-prefix"><span class="input-prefix">PHP</span><input id="bank-${name}" name="${name}" type="number" step="0.01" value="${value ?? ''}" required></div></div>`).join('')}<div class="form-field-group full-field"><label for="bank-statement-notes">Notes</label><input id="bank-statement-notes" name="notes" value="${escapeHtml(existing?.notes || '')}" maxlength="500"></div></div><p class="product-meta">Opening book balance must include all ledger entries before ${from}. Enter every statement line. Unmatched entries can be saved for review; matching requires the same type and amount.</p><div id="bankStatementLineList"></div><button class="button button-secondary" id="addBankStatementLineButton" type="button">+ Add Statement Line</button><p class="form-error" id="bankStatementError" role="alert"></p><div class="modal-actions"><button class="button modal-cancel-btn" type="button" data-statement-close>Cancel</button><button class="button modal-save-btn" id="saveBankStatementButton" type="submit">Save Statement</button></div></form>`;
  const appendLine = (line = {}) => {
    const row = document.createElement('div'); row.className = 'bank-statement-line'; row.dataset.statementLine = '';
    row.innerHTML = `<div class="sales-date-control"><input name="date" type="date" min="${from}" max="${to}" value="${line.bank_date || from}" aria-label="Bank line date" required></div><select name="type" aria-label="Bank line type"><option value="Deposit">Deposit / Credit</option><option value="Withdrawal">Withdrawal / Debit</option></select><input name="amount" type="number" min="0.01" step="0.01" value="${line.amount ?? ''}" placeholder="Amount" aria-label="Bank line amount" required><input name="reference" value="${escapeHtml(line.reference || '')}" placeholder="Statement reference" aria-label="Statement reference"><select name="transactionId" aria-label="Matching ledger transaction"><option value="">Unmatched / needs book entry</option>${options.map((item) => `<option value="${item.transaction_id}">${escapeHtml(`${item.business_date} / ${item.transaction_type} / ${money(item.amount)} / ${item.reference || item.cheque_number || item.details}`)}</option>`).join('')}</select><button type="button" class="icon-button" aria-label="Remove statement line" title="Remove statement line"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="m6 6 12 12M18 6 6 18"/></svg></button>`;
    row.querySelector('[name=type]').value = line.transaction_type || 'Deposit'; row.querySelector('[name=transactionId]').value = line.bank_transaction_id || '';
    row.querySelector('button').addEventListener('click', () => row.remove());
    $('#bankStatementLineList').appendChild(row); initCustomDropdowns(row); initCustomDatePickers(row);
  };
  oldLines.forEach(appendLine);
  $('#addBankStatementLineButton').addEventListener('click', () => appendLine());
  dialog.querySelectorAll('[data-statement-close]').forEach((button) => button.addEventListener('click', () => dialog.close()));
  const branch = activeBranchId;
  $('#bankStatementForm').addEventListener('submit', async (event) => {
    event.preventDefault(); const form = event.target; if (!form.reportValidity()) return;
    const button = $('#saveBankStatementButton'); button.disabled = true;
    try {
      const values = new FormData(form);
      const lines = [...dialog.querySelectorAll('[data-statement-line]')].map((row) => Object.fromEntries(['date','type','amount','reference','transactionId'].map((name) => [name, row.querySelector(`[name=${name}]`).value])));
      const { error } = await requireSupabase_().rpc('save_bank_statement_reconciliation', { target_branch_id: branch, date_from_input: from, date_to_input: to, opening_book_input: Number(values.get('openingBook')), statement_opening_input: Number(values.get('statementOpening')), statement_closing_input: Number(values.get('statementClosing')), lines_input: lines, notes_input: values.get('notes') || '' });
      throwIfError_(error); ownerReportCache.delete('bank'); dialog.close(); showToast('Bank statement saved.', 'success');
      if (activeView === 'cashBankReconciliation' && activeBranchId === branch) await renderFullCashBankReconciliation_(true);
    } catch (error) { $('#bankStatementError').textContent = error.message; }
    finally { button.disabled = false; }
  });
  dialog.showModal();
}

function calculateTableQrPerformance_(data, from, to, term = '') {
  const inRange = (value) => { const date = saleDateKey(value); return date && date >= from && date <= to; };
  const tables = new Map();
  const tableFor = (item) => {
    if (!tables.has(item.tableId)) tables.set(item.tableId, { id: item.tableId, name: item.tableName || item.tableId, opened: 0, settled: 0, cancelled: 0, requests: 0, confirmed: 0, rejected: 0, pending: 0, sales: 0, tabMinutes: [], confirmationMinutes: [], qrGross: 0, staffGross: 0, qrQty: 0, staffQty: 0 });
    return tables.get(item.tableId);
  };
  // Tabs and QR requests are independent cohorts. Do not multiply a tab's
  // revenue by the number of requests or its joined kitchen-ticket rows.
  (data.orders || []).forEach((item) => {
    if (!inRange(item.openedAt) && !inRange(item.closedAt)) return;
    const row = tableFor(item);
    if (inRange(item.openedAt)) row.opened += 1;
    if (item.status === 'Cancelled' && inRange(item.closedAt)) row.cancelled += 1;
    if (item.status === 'Settled' && inRange(item.closedAt)) {
      row.settled += 1; row.sales += Number(item.gross || 0) - Number(item.discount || 0);
      row.qrGross += Number(item.qrGross || 0); row.staffGross += Number(item.gross || 0) - Number(item.qrGross || 0);
      row.qrQty += Number(item.qrQty || 0); row.staffQty += Number(item.qty || 0) - Number(item.qrQty || 0);
      const duration = performanceMinutes_(item.openedAt, item.closedAt); if (duration !== null) row.tabMinutes.push(duration);
    }
  });
  (data.requests || []).forEach((item) => {
    if (!inRange(item.createdAt)) return;
    const row = tableFor(item); row.requests += 1;
    if (item.status === 'Confirmed') {
      row.confirmed += 1;
      const duration = performanceMinutes_(item.createdAt, item.confirmedAt); if (duration !== null) row.confirmationMinutes.push(duration);
    } else if (['Rejected','Cancelled'].includes(item.status)) row.rejected += 1;
    else if (['Pending','Claimed'].includes(item.status)) row.pending += 1;
  });
  const rows = [...tables.values()].filter((row) => `${row.name} ${row.id}`.toLowerCase().includes(term.trim().toLowerCase()))
    .sort((a, b) => b.sales - a.sales || b.requests - a.requests || a.name.localeCompare(b.name));
  const totals = rows.reduce((sum, row) => {
    for (const field of ['opened','settled','cancelled','requests','confirmed','rejected','pending','sales','qrGross','staffGross','qrQty','staffQty']) sum[field] += row[field];
    sum.tabMinutes.push(...row.tabMinutes); sum.confirmationMinutes.push(...row.confirmationMinutes); return sum;
  }, { opened: 0, settled: 0, cancelled: 0, requests: 0, confirmed: 0, rejected: 0, pending: 0, sales: 0, qrGross: 0, staffGross: 0, qrQty: 0, staffQty: 0, tabMinutes: [], confirmationMinutes: [] });
  return { rows, totals, from, to };
}

function tableQrReportSections_(report) {
  return [
    { title: 'Table Activity and Settled Sales', headings: ['Table','Tabs Opened','Tabs Settled','QR Requests','QR Confirmed','Pending / Claimed','Settled Sales','Avg. Tab Time'], rows: report.rows.map((row) => [row.name,row.opened,row.settled,row.requests,row.confirmed,row.pending,money(row.sales),performanceAverage_(row.tabMinutes)]) },
    { title: 'QR Request Outcomes', headings: ['Table','Confirmed','Rejected / Cancelled','Pending / Claimed','Confirmation Rate','Avg. Confirmation'], rows: report.rows.map((row) => [row.name,row.confirmed,row.rejected,row.pending,row.requests ? `${(row.confirmed / row.requests * 100).toFixed(1)}%` : '—',performanceAverage_(row.confirmationMinutes)]) },
    { title: 'Item Sources in Tabs Settled During the Period', headings: ['Source','Units','Gross Item Value'], rows: [['QR-linked items',report.totals.qrQty,money(report.totals.qrGross)],['Staff / historically unlinked items',report.totals.staffQty,money(report.totals.staffGross)]] },
  ];
}

function tableQrReportNote_() {
  return 'Settled tab sales and QR request outcomes for the selected date range.';
}

function tableQrReportCards_(report) {
  return [['SETTLED TAB SALES',money(report.totals.sales),`${report.totals.settled} settled tabs`], ['TABLES WITH ACTIVITY',report.rows.length,`${report.totals.opened} tabs opened`], ['QR REQUESTS',report.totals.requests,`${report.totals.pending} awaiting confirmation`], ['QR CONFIRMATION RATE',report.totals.requests ? `${(report.totals.confirmed / report.totals.requests * 100).toFixed(1)}%` : '—',`${report.totals.confirmed} confirmed / ${report.totals.rejected} rejected or cancelled`]];
}

function tableQrReportKey_() {
  const range = ownerDefaultRange_('tableQrPerformance');
  return JSON.stringify([activeBranchId,range.from,range.to]);
}

function loadedTableQrReport_() {
  const key = tableQrReportKey_(), entry = ownerReportCache.get('tableQr');
  if (currentSession?.account?.role !== 'admin' || entry?.key !== JSON.stringify([currentSession.account.id,key]) || !entry.data) throw new Error('Wait for the table/QR report to finish loading.');
  const range = ownerDefaultRange_('tableQrPerformance');
  return calculateTableQrPerformance_(entry.data,range.from,range.to,$('#searchInput')?.value || '');
}

async function renderTableQrPerformance(force = false) {
  const root = $('#inventoryTable'); if (!root) return;
  const sequence = ++tableQrReportRenderId, key = tableQrReportKey_();
  const range = ownerDefaultRange_('tableQrPerformance');
  const actions = [$('#generateTableQrPerformancePdfButton'),$('#exportTableQrPerformancePdfButton')];
  actions.forEach((button) => { if (button) button.disabled = true; });
  root.innerHTML = '<div class="std-empty-state"><h4 class="std-empty-title">Loading Table / QR Performance...</h4></div>';
  try {
    await loadOwnerReportData_('tableQr',key,'get_table_qr_performance_report',{ target_branch_id: activeBranchId,date_from_input: range.from,date_to_input: range.to },force);
    if (sequence !== tableQrReportRenderId || activeView !== 'tableQrPerformance' || key !== tableQrReportKey_()) return;
    const report = loadedTableQrReport_();
    const activePreset = typeof getDatePresetState === 'function' ? getDatePresetState(range.from, range.to) : '';
    root.innerHTML = `<div class="std-view theme-sky">
      <div class="std-hero-card">
        <div class="std-hero-glow"></div>
        <div class="std-hero-leading">
          <div class="std-hero-icon" aria-hidden="true">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
              <path d="M4 10h16M6 10v10m12-10v10M8 5h8v5H8z"/>
            </svg>
          </div>
          <div class="std-hero-text">
            <span class="std-hero-kicker">OWNER REPORTING &bull; TABLE SERVICE</span>
            <strong class="std-hero-title">Table / QR Ordering Performance</strong>
            <p class="std-hero-desc">Table activity, settled sales, QR outcomes, and recorded service durations.</p>
          </div>
        </div>
        <div class="std-hero-actions">
          <button class="button button-secondary std-record-btn" type="button" id="tableQrPrintPdfHeroBtn">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" style="width:16px;height:16px;"><path d="M6 2h9l3 3v17H6z"/><path d="M14 2v4h4"/><path d="M8 15h8M8 18h6M8 12h3"/></svg>
            <span>Print PDF</span>
          </button>
          <button class="button button-primary std-record-btn" type="button" id="tableQrExportPdfHeroBtn">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" style="width:16px;height:16px;"><path d="M12 3v12"/><path d="m7 10 5 5 5-5"/><path d="M5 21h14"/><path d="M5 17v4h14v-4"/></svg>
            <span>Export PDF</span>
          </button>
        </div>
      </div>
      ${ownerKpisHtml_(tableQrReportCards_(report))}
      <div class="std-toolbar-strip">
        <span class="product-meta">${escapeHtml(tableQrReportNote_())}</span>
        ${typeof renderDatePresets === 'function' ? renderDatePresets(activePreset, 'data-table-qr-preset') : ''}
      </div>
      ${ownerTablesHtml_(tableQrReportSections_(report))}
    </div>`;
    root.querySelector('#tableQrPrintPdfHeroBtn')?.addEventListener('click', generateTableQrPerformancePdf);
    root.querySelector('#tableQrExportPdfHeroBtn')?.addEventListener('click', exportTableQrPerformancePdf);
    if (typeof bindDatePresets === 'function') {
      bindDatePresets(root, 'data-table-qr-preset', 'tableQrPerformanceDateFrom', 'tableQrPerformanceDateTo', () => renderTableQrPerformance(true));
    }
    actions.forEach((button) => { if (button) button.disabled = false; });
  } catch (error) {
    if (sequence === tableQrReportRenderId && activeView === 'tableQrPerformance') root.innerHTML = `<div class="std-empty-state"><h4 class="std-empty-title">Unable to Load Table / QR Performance</h4><p>${escapeHtml(error.message)}</p></div>`;
  }
}

function buildTableQrPerformancePdfReport_() {
  const report = loadedTableQrReport_();
  return { ...report,renderedPagesHtml: ownerReportPdf_('Table / QR Ordering Performance',`${report.from} to ${report.to}`,tableQrReportCards_(report),tableQrReportSections_(report),tableQrReportNote_()) };
}

function generateTableQrPerformancePdf() {
  try { const report = buildTableQrPerformancePdfReport_(); openReportInNewPage_(report.renderedPagesHtml,'Table / QR Ordering Performance'); }
  catch (error) { showToast(error.message,'error'); }
}

async function exportTableQrPerformancePdf() {
  try {
    const report = buildTableQrPerformancePdfReport_();
    await exportReportPagesPdf_(report.renderedPagesHtml,'Table / QR Ordering Performance',`table-qr-performance_${report.from}_to_${report.to}.pdf`,$('#exportTableQrPerformancePdfButton'));
  } catch (error) { showToast(error.message,'error'); }
}
