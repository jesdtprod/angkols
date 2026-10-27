import { readFileSync } from 'node:fs';

const appJs = readFileSync('./app.js', 'utf8');

function assert(condition, message) {
  if (!condition) {
    console.error(`FAILED: ${message}`);
    process.exit(1);
  }
}

// 1. Check stdViewThemes
assert(/quarantine:\s*'theme-sky'/.test(appJs), "stdViewThemes.quarantine must be 'theme-sky'");
assert(/quarantineReport:\s*'theme-sky'/.test(appJs), "stdViewThemes.quarantineReport must be 'theme-sky'");

// 2. Check renderQuarantinedItems
assert(/function renderQuarantinedItems\(\)/.test(appJs), 'renderQuarantinedItems must exist');
const quarantinedItemsMatch = appJs.match(/function renderQuarantinedItems\(\)[\s\S]*?\n\}/);
assert(quarantinedItemsMatch, 'renderQuarantinedItems function body extracted');
const quarantinedItemsBody = quarantinedItemsMatch[0];

assert(quarantinedItemsBody.includes('class="std-view theme-sky"'), 'renderQuarantinedItems must use .std-view.theme-sky');
assert(quarantinedItemsBody.includes('renderPageHeader_({'), 'renderQuarantinedItems must use the shared page header');
assert(quarantinedItemsBody.includes('class="std-empty-state"'), 'renderQuarantinedItems must use .std-empty-state');
assert(quarantinedItemsBody.includes('id="quarantineResetFiltersBtn"'), 'renderQuarantinedItems must have quarantineResetFiltersBtn');
assert(quarantinedItemsBody.includes('id="quarantineReportNavBtn"'), 'renderQuarantinedItems must have quarantineReportNavBtn');
assert(quarantinedItemsBody.includes('std-kpi-icon icon-amber'), 'renderQuarantinedItems must have standard KPI icon badges');
assert(quarantinedItemsBody.includes('std-kpi-icon icon-rose'), 'renderQuarantinedItems must have rose KPI icon badge');
assert(quarantinedItemsBody.includes('std-kpi-icon icon-sky'), 'renderQuarantinedItems must have sky KPI icon badge');
assert(quarantinedItemsBody.includes('std-kpi-icon icon-purple'), 'renderQuarantinedItems must have purple KPI icon badge');

// 3. Check renderQuarantineReport
assert(/function renderQuarantineReport\(\)/.test(appJs), 'renderQuarantineReport must exist');
const quarantineReportMatch = appJs.match(/function renderQuarantineReport\(\)[\s\S]*?\n\}/);
assert(quarantineReportMatch, 'renderQuarantineReport function body extracted');
const quarantineReportBody = quarantineReportMatch[0];

assert(quarantineReportBody.includes('class="std-view theme-sky"'), 'renderQuarantineReport must use .std-view.theme-sky');
assert(quarantineReportBody.includes('renderPageHeader_({'), 'renderQuarantineReport must use the shared page header');
assert(quarantinedItemsBody.includes('class="std-empty-state"'), 'renderQuarantineReport must use .std-empty-state');
assert(quarantineReportBody.includes('id="quarantineReportPrintPdfHeroBtn"'), 'renderQuarantineReport must have Print PDF button');
assert(quarantineReportBody.includes('id="quarantineReportExportPdfHeroBtn"'), 'renderQuarantineReport must have Export PDF button');
assert(quarantineReportBody.includes('data-quarantine-preset="thisMonth"'), 'renderQuarantineReport must have quick date presets');
assert(quarantineReportBody.includes('grid-cols-quarantinereport'), 'renderQuarantineReport must have grid-cols-quarantinereport');
assert(quarantineReportBody.includes('bindDatePresets'), 'renderQuarantineReport must bind date presets');

// 4. Check exportQuarantinePdf
assert(/exportQuarantinePdf/.test(appJs), 'exportQuarantinePdf must exist');
assert(/#quarantineReportExportPdfHeroBtn/.test(appJs), 'exportQuarantinePdf must check #quarantineReportExportPdfHeroBtn');

console.log('All Quarantine report standard styling, hero buttons, KPIs, date presets, and empty state checks passed!');
