# Trigger and Routing Regression Cases

Score each case on four fields: activation, execution surface, mutation boundary, and named invariant. A case passes only when all four match.

## Positive activation

| ID | Prompt | Activate | Surface | Required invariant |
|---|---|---:|---|---|
| P1 | Create an `.xlsx` monthly budget with assumptions, formulas, variance checks, and a summary chart. | Yes | Local Spreadsheets runtime | Derived values stay formula-driven; reconcile totals and render every visible sheet. |
| P2 | Build a three-statement financial model in Excel from these historical figures. | Yes | Local Spreadsheets plus applicable finance guidance | Link statements through auditable formulas and balance checks. |
| P3 | In `Forecast.xlsx`, add FY2028 beside FY2027 and extend formulas, formatting, charts, and print ranges. | Yes | Local Spreadsheets editor | Inventory first; preserve unrelated features and every affected dependency. |
| P4 | Change only the commission assumption in this `.xlsm`; preserve everything else. | Yes | Qualified macro-capable editor | Preserve VBA without execution and retain `.xlsm`. |
| P5 | Which assumptions in this workbook drive the EBITDA decline, and by how much? | Yes | Read-only spreadsheet inspection | Cite exact cells, periods, units, formulas, and traced precedents; do not mutate. |
| P6 | Reconcile this sales workbook to the attached source totals and explain every variance. | Yes | Spreadsheet reader plus data engine as needed | Preserve source grain and reconcile rows, keys, totals, and rejects. |
| P7 | Audit this loan model for hardcodes, broken references, hidden assumptions, and weak controls. | Yes | Read-only inspection plus compatible calculator | Separate findings from repair; independently recompute material outputs. |
| P8 | Why does the dashboard show `#REF!` after I inserted a column? Diagnose it but don't fix it. | Yes | Read-only spreadsheet inspection | Reproduce and trace the failure; do not save or repair. |
| P9 | Convert this `.ods` workbook to `.xlsx` and tell me what changed. | Yes | ODS-capable source engine plus Excel-compatible destination | Declare loss and verify formulas, objects, and layout in destination. |
| P10 | Clean this vendor CSV, preserve leading-zero IDs, neutralize formula injection, and return a validated CSV. | Yes | Typed CSV/data workflow | Preserve text-format contract and reconcile input and output rows. |
| P11 | Convert these three TSV extracts into one auditable workbook with source tabs, mappings, and control totals. | Yes | Data engine plus local Spreadsheets writer | Use deterministic manifest and ordering; reconcile every source. |
| P12 | Add a validated Status column and summary chart to this existing Google Sheet. | Yes | Google Sheets connector | Read metadata and ranges first; write narrowly and freshly read back formulas, values, and objects. |

## Negative activation

| ID | Prompt | Activate | Surface | Required invariant |
|---|---|---:|---|---|
| N1 | Write a Python library that parses CSV into domain objects and exposes a REST API. | No | General coding | CSV is interchange only; the deliverable is code. |
| N2 | Design PostgreSQL tables and indexes for transaction data currently shown in this spreadsheet screenshot. | No | Database design | The authoritative output is a schema, not a workbook. |
| N3 | Turn this table of survey results into a polished board memo in `.docx`. | No | Documents | Do not create or edit a spreadsheet unless requested. |
| N4 | Build a React dashboard from this CSV with filters and interactive charts. | No | Web app | Acceptance belongs to the running app. |
| N5 | Debug the TypeScript function that exports database rows to CSV. | No | General coding and tests | Verify serialization in code; no workbook contract applies. |
| N6 | Summarize the table in this PDF and draft an executive briefing. | No | PDF plus Documents | Tabular content is incidental to prose output. |

## Routing and cross-skill behavior

| ID | Prompt | Activate | Surface | Required invariant |
|---|---|---:|---|---|
| R1 | Create `headcount-plan.xlsx` and save it locally. | Yes | Local Spreadsheets | Obey that runtime's library and output rules; this skill governs design and QA. |
| R2 | In the workbook currently open in Microsoft Excel, update the selected assumptions and show me the result. | Yes | Excel live control | Confirm active workbook and selection; do not silently edit a copy or another workbook. |
| R3 | Update cells F12:F20 in this existing Google Sheet and preserve its dropdowns. | Yes | Google Sheets connector | Resolve file, tab, range, formulas, and validations before writing; read back afterward. |
| R4 | Use the figures in `Results.xlsx` to create an audit committee memo in Word; leave the workbook unchanged. | No | Spreadsheet read for evidence, then Documents primary | The `.docx` is the deliverable; workbook access stays subordinate and read-only. |
| R5 | Analyze this 20-million-row Parquet dataset and return a statistical report; no spreadsheet needed. | No | Data analysis/report | Preserve source grain and reproducibility; do not force worksheet output. |
| R6 | Analyze `Operations.xlsx`, identify duplicate orders, and answer in chat without producing a new file. | Yes | Read-only local Spreadsheets, optional data engine | Spreadsheet is authoritative input; do not mutate or export. |
