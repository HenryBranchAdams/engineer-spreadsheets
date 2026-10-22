// Canonical disposable fixture builder. Authoring uses only the advertised API.
import fs from 'node:fs/promises';
import path from 'node:path';
import {FileBlob, SpreadsheetFile, Workbook} from '@oai/artifact-tool';

const [mode, inputPath, outputDir, editValue] = process.argv.slice(2);
if (!['build', 'roundtrip', 'edit', 'cf-probe', 'cf-probe-roundtrip'].includes(mode) || !inputPath || !outputDir) {
  throw new Error('Usage: build.mjs build inputs.json output-dir | roundtrip/edit source.xlsx output-dir [value]');
}
await fs.mkdir(outputDir, {recursive: true});

function style(sheet, area) {
  sheet.showGridLines = false;
  sheet.getRange(area).format.font = {name: 'Arial', size: 10, color: '#17233A'};
  sheet.getRange(area).format.rowHeight = 22;
  sheet.getRange(area).format.verticalAlignment = 'center';
  sheet.getRange('A2').format.font = {name: 'Arial', size: 14, bold: true};
}

async function render(wb, sheetName, range, name) {
  const preview = await wb.render({sheetName, range, scale: 1.5, format: 'png'});
  await fs.writeFile(path.join(outputDir, name + '.png'), new Uint8Array(await preview.arrayBuffer()));
}

async function save(wb, name) {
  wb.recalculate();
  const output = await SpreadsheetFile.exportXlsx(wb);
  await output.save(path.join(outputDir, name + '.xlsx'));
}

if (mode === 'build') {
  const data = JSON.parse(await fs.readFile(inputPath, 'utf8'));
  const records = Workbook.create();
  const sheet = records.worksheets.add('Records');
  style(sheet, 'A1:E12');
  sheet.getRange('A2').values = [['Typed import records']];
  sheet.getRange('A4:E4').values = [['Record ID', 'Amount', 'Date', 'Active', 'Literal note']];
  sheet.getRange('A5:E8').values = data.records.map(row => [row.id, row.amount,
    new Date(row.date + 'T00:00:00Z'), row.active, row.note.startsWith('=') ? "'" + row.note : row.note]);
  sheet.getRange('A5:A8').setNumberFormat('@');
  sheet.getRange('B5:B10').setNumberFormat('#,##0.000');
  sheet.getRange('C5:C8').setNumberFormat('yyyy-mm-dd');
  sheet.getRange('A:A').format.columnWidth = 28;
  sheet.getRange('B:D').format.columnWidth = 14;
  sheet.getRange('E:E').format.columnWidth = 32;
  sheet.getRange('A10:A11').values = [['Total amount'], ['Numeric records']];
  sheet.getRange('B10:B11').formulas = [['=SUM(B5:B8)'], ['=COUNT(B5:B8)']];
  sheet.getRange('B11').setNumberFormat('0');
  sheet.tables.add('A4:E8', true, 'SourceRecords');
  sheet.getRange('A4:E4').format = {fill: '#20334D', font: {color: '#FFFFFF', bold: true}, horizontalAlignment: 'center'};
  sheet.getRange('B5:B8').dataValidation = {rule: {type: 'decimal', operator: 'between', formula1: -1000000, formula2: 1000000}};
  // A fill-based differential style failed no-op qualification in 2.8.99
  // (patternType="solid" was lost). This lane qualifies font-only CF instead.
  sheet.getRange('B5:B8').conditionalFormats.add('cellIs', {operator: 'lessThan', formula: 0, format: {font: {color: '#9B2020', bold: true}}});
  sheet.freezePanes.freezeRows(4);
  records.recalculate();
  await render(records, 'Records', 'A1:E12', 'typed-records');
  await save(records, 'typed-records');

  const model = Workbook.create();
  const capacity = model.worksheets.add('Capacity');
  style(capacity, 'A1:C18');
  capacity.getRange('A:A').format.columnWidth = 30;
  capacity.getRange('B:B').format.columnWidth = 23;
  capacity.getRange('C:C').format.columnWidth = 18;
  capacity.getRange('A2').values = [['Capacity plan']];
  capacity.getRange('A3:A9').values = [['People required'], ['Work minutes'], ['Case number'], ['Case selected'], ['Active volume (items)'], ['Minutes per item'], ['Minutes per person']];
  capacity.getRange('A11:A12').values = [['Base volume (items)'], ['Peak volume (items)']];
  capacity.getRange('A16:B18').values = [['Actuals (fixed)', 'Value'], ['Prior volume (items)', data.capacity.actual_volume], ['Prior work minutes', data.capacity.actual_minutes]];
  capacity.getRange('B8:B9').values = [[data.capacity.minutes_per_item], [data.capacity.minutes_per_person]];
  capacity.getRange('B3:B4').formulas = [
    ['=IF(ISNUMBER(B7),ROUNDUP(B4/B9,0),"Missing volume")'],
    ['=IF(ISNUMBER(B7),B7*B8,"Missing volume")']
  ];
  capacity.getRange('B6:B7').formulas = [
    ['=CHOOSE($B$5,"Base","Peak")'],
    ['=IF(CHOOSE($B$5,ISBLANK(B11),ISBLANK(B12)),"Missing volume",CHOOSE($B$5,B11,B12))']
  ];
  capacity.getRange('B5').dataValidation = {rule: {type: 'whole', operator: 'between', formula1: 1, formula2: 2}};
  capacity.getRange('B5').format.fill = '#FFF1C2';
  capacity.getRange('B11:B12').format.fill = '#FFF1C2';
  capacity.getRange('A3:B4').format.font = {bold: true};
  capacity.getRange('B3:B18').setNumberFormat('#,##0');
  capacity.getRange('A16:B16').format = {fill: '#20334D', font: {color: '#FFFFFF', bold: true}};
  const observations = [];
  for (const state of data.capacity.states) {
    capacity.getRange('B5').values = [[state.selector]];
    capacity.getRange('B11:B12').values = [[state.base_volume], [state.peak_volume]];
    model.recalculate();
    observations.push({id: state.id, values: capacity.getRange('B3:B12').values, formulas: capacity.getRange('B3:B12').formulas});
    await save(model, 'capacity-' + state.id);
    if (state.id === 'base' || state.id === 'missing-selected') {
      await render(model, 'Capacity', 'A1:C19', 'capacity-' + state.id);
    }
  }
  await fs.writeFile(path.join(outputDir, 'runtime-observations.json'), JSON.stringify(observations, null, 2) + '\n');
  // Retain the original failing boundary as a qualification probe. The supported
  // model above uses ISBLANK; this probe must not be silently dropped or softened.
  capacity.getRange('B5').values = [[1]];
  capacity.getRange('B11:B12').values = [[0], [1700]];
  capacity.getRange('B7').formulas = [['=IF(CHOOSE($B$5,B11="",B12=""),"Missing volume",CHOOSE($B$5,B11,B12))']];
  await save(model, 'capacity-zero-empty-string-probe');
} else {
  // Each import runs in a new process. The source is never overwritten.
  const wb = await SpreadsheetFile.importXlsx(await FileBlob.load(inputPath));
  const sheet = wb.worksheets.getItem('Records');
  if (mode === 'edit') {
    const amount = Number(editValue);
    if (!Number.isFinite(amount)) throw new Error('edit amount must be finite');
    sheet.getRange('B6').values = [[amount]];
  }
  if (mode === 'cf-probe') {
    sheet.getRange('B5:B8').conditionalFormats.clear();
    sheet.getRange('B5:B8').conditionalFormats.add('cellIs', {operator: 'lessThan', formula: 0, format: {fill: '#FCE7E7', font: {color: '#9B2020'}}});
  }
  wb.recalculate();
  await render(wb, 'Records', 'A1:E12', mode);
  await save(wb, mode);
}
