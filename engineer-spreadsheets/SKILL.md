---
name: engineer-spreadsheets
description: Create, edit, analyze, audit, debug, reverse-engineer, visualize, convert, and verify spreadsheet work with preservation-first engineering, typed data, auditable formulas, model controls, source lineage, recalculation, round-trip fidelity, accessibility, and visual QA. Use when an actual spreadsheet is the authoritative input to inspect or the requested output to create or change, including .xlsx, .xlsm, .xlsb, .xls, .ods, spreadsheet-oriented .csv or .tsv work, and Google Sheets. Also use for values, formulas, charts, pivots, formatting, cleanup, reconciliation, models, workbook dashboards, or spreadsheet errors in an actual workbook or sheet. Pair it with the active platform-specific runtime for local files, live Microsoft Excel, or Google Sheets. Do not use merely because data is tabular or a spreadsheet format is mentioned when the primary deliverable is code, a database, a document, or a web app; this exclusion takes precedence.
---

# Engineer Spreadsheets

Treat a workbook as an executable, collaborative document. Correctness includes numbers, formulas, types, lineage, controls, interaction, package fidelity, and the rendered surface—not merely a successful save.

## Respect the active runtime

- Follow the active spreadsheet runtime for mandatory libraries, dependency loading, output paths, live-application routing, privacy, and citations. This skill supplies engineering and QA judgment.
- Inspect capabilities before choosing a workflow. Do not install substitute libraries, bypass a required runtime, or use a tool outside its preservation envelope.
- Distinguish writers, editors, formula evaluators, spreadsheet applications, and renderers. One tool rarely proves every acceptance property.
- Keep private workbooks and their contents out of public services unless the user explicitly authorizes disclosure.

## Route the request

- **Question or analysis:** inspect without mutating. Ground the answer in exact labels, cells, formulas, units, periods, precedents, and reconciled source data.
- **Create or edit:** design or inventory first, keep derived values formula-driven, preserve the governing template and affected dependencies, and verify the resulting file or live surface.
- **Audit or debug:** reproduce the issue, trace dependencies, classify the root cause, and separate diagnosis from authorized repair.
- **Convert or export:** state destination losses before mutation and verify the result in the destination engine.

Do not edit merely because a workbook is available. Do not repair when the user requested diagnosis only.

## Establish the contract

Before mutation, resolve or safely infer:

- the authoritative input, output, target application, audience, locale, reporting period, and governing template;
- the working risk profile: impact, recurrence, complexity, users, sensitivity, automation or manual inputs, and reproducibility;
- required sheets, outputs, units, signs, precision, update workflow, compatibility target, and acceptable loss;
- whether macros, external links, connections, pivots, slicers, protected content, hidden sheets, signatures, or custom package parts must survive;
- whether overwriting, recalculating, refreshing external data, executing code, or changing protection is authorized.

Scale controls, review, release evidence, and polish to this profile; do not invent an organizational rating.

Treat recalculation as authorized when needed to verify an explicitly requested create or edit, but disable macros and block external updates. For file work, calculate a candidate copy and preserve the source unless in-place editing is explicit; for connected work, use only the active runtime's advertised calculation and read-back behavior and do not save, export, or duplicate unless requested and supported. Ask before recalculation could run custom code, refresh data, materially change volatile outputs, or affect the source.

## Inventory before editing

Perform one compact preflight and retain enough evidence for comparison:

- file type, size, sheet order and visibility, used ranges, print areas, freezes, calculation mode, date system, and locale-sensitive formats;
- formulas and caches, arrays or spills, names, tables, totals, references, validations, conditional formatting, comments, merges, hyperlinks, and protections;
- charts, images, pivots, slicers, VBA or other code, signatures, connections, queries, external links, custom XML, and unsupported extensions.

Treat hidden and very-hidden content as real. If the selected tool cannot preserve a material feature, switch tools or stop before mutating a connected/native surface or before saving a file candidate, and report the limitation.

## Select tools by capability

| Work | Required capability |
|---|---|
| Read-only Q&A | Read formulas, cached or displayed values, types, names, and relevant objects without saving. |
| New file workbook | Write typed values, formulas, styles and objects; export, inspect, and render. |
| New connected/native surface | Follow the active runtime's creation route; verify the result through fresh values, formulas, object metadata, and applicable visual review without requiring an extra export. |
| Existing workbook | Preserve every material existing feature and update dependencies affected by structural edits. |
| Formula-dependent result | Use a compatible engine's calculation behavior and surface-appropriate fresh read-back; reopen independently when the deliverable is a file. |
| Macro-enabled workbook | Preserve the macro package without executing it and retain the correct extension. |
| Large data | Process at source grain outside the grid, then publish an auditable extract, summary, and reconciliation. |

Apply these truths:

- Writer-only and streaming-generation libraries are not safe read-modify-write editors.
- Fixed-model editors can delete unsupported package parts even when no cell edit fails. Require qualified pass-through behavior for the actual feature set.
- Writing a formula is not calculating it. A cached value proves only the last calculation state.
- Opening, converting, or saving is not necessarily full recalculation. Use the engine's documented calculation behavior when available. For files, save the candidate and reopen it in a fresh process; for live surfaces, freshly read formulas and results without requiring persistence.
- Internal evaluators commonly implement only part of Excel semantics. Important models require the target application or a declared compatible engine.
- Cross-application behavior proves that application only; LibreOffice, Google Sheets, and third-party engines are not exact Excel proof.

## Design for auditability

For new or materially reworked workbooks:

1. Define source grain, keys, units, time axis, scenarios, and authoritative totals.
2. Separate raw data, assumptions, calculations, outputs, and checks when complexity warrants it. Keep one source of truth for each input.
3. Separate working logic, formal presentation, and accessible reuse when their needs conflict; do not force one region to serve incompatible audiences.
4. Make the main user path obvious. For complex workbooks, add a concise Overview with purpose, owner, as-of date, audience, sources, units, date basis, refresh procedure, calculation mode, compatibility target, assumptions, and limitations.
5. Put assumptions and mapping rules in visible labeled cells or tables; reference them instead of embedding magic numbers.
6. Add visible controls near the tested logic. Material checks show purpose, expected, actual, tolerance, PASS/FAIL, and action; a master check must not mask failures.
7. Keep transformations reproducible through one canonical builder or mutation path.

Match existing conventions before applying defaults. User instructions override the reference workbook; the reference overrides generic guidance.

## Write semantically correct data

- Store numbers, dates, times, booleans, percentages, and errors as native types; use formats only for display.
- Store identifiers as text when leading zeros or exact digits matter. Treat values beyond the target application's exact numeric precision as text.
- Keep blank, zero, null, not-applicable, and not-yet-available distinct when their business meanings differ.
- Specify risky import types rather than trusting inference. Reconcile row counts, keys, totals, and rejects; never silently truncate.

Read [data-integrity.md](references/data-integrity.md) completely when importing, joining, cleaning, or aggregating data; handling dates, timezones, long identifiers, mixed or locale-sensitive columns; working near application limits; or building a material or deterministic data pipeline.

## Engineer formulas deliberately

- Keep user-updatable or auditable derived values as formulas. Reference labeled inputs, tables, or names instead of hardcoded constants.
- Apply relative, absolute, mixed, structured, and cross-sheet references correctly. Use invariant English function names and comma separators for OOXML unless the active API translates locale syntax.
- Prefer short consistent patterns and helper cells over opaque mega-formulas. Calculate repeated logic once.
- Avoid volatile functions, unnecessary full-column references, repeated lookups, single-threaded constructs, and inflated used ranges when performance matters.
- Define behavior for blanks, zeros, negatives, duplicates, missing matches, date boundaries, rounding, and large values before filling formulas.
- Do not use `IFERROR` or blank strings to hide defects. Use fallbacks only when they express the business rule, and expose unexpected errors.
- Preserve full calculation precision unless a rule requires rounding; reconcile displayed rounded totals when needed.
- Treat spills, legacy arrays, data tables, circular references, custom functions, cube formulas, external links, and volatile formulas as compatibility-sensitive.
- Comment complex formulas and key assumptions. Put source identifiers or URLs beside researched hardcodes.

## Make preservation-first edits

- Render and inspect relevant sheets before editing an established workbook. Read neighboring values, formulas, styles, and objects to infer the local pattern.
- Change the smallest coherent range. Avoid sheet-wide autofit, wrapping, restyling, or normalization for a local request.
- Update every affected formula, name, table, chart series, pivot source, validation, conditional format, print area, and merge after structural changes.
- Extend from the correct adjacent pattern; totals and section breaks can make the nearest row misleading.
- Preserve formulas as formulas. Never write cached values back over them.
- Preserve file type, sheet order, visibility, properties, macro package, and external-link metadata unless change is intentional.
- Clone shared style objects before local mutation when the API deduplicates them.
- For file artifacts, develop to a distinct output. Overwrite only with explicit authority and after verification. For connected or native live surfaces, mutate only the selected target and do not duplicate it unless requested.

## Build a usable surface

- Follow the active runtime's visual rules and the governing template. Use restrained hierarchy, consistent alignment and formats, readable contrast, and semantic color that is never the only cue.
- Make editable inputs recognizable before selection through redundant cues: a consistent fill or boundary, clear label and unit, validation where appropriate, and unlocked state when protection is used. Do not rely on font color alone.
- Keep data rectangular with one header row when practical. Avoid merges, blank separators, and nested tables in data regions.
- Use meaningful sheet names, useful content in A1, filters and frozen context where helpful, unclipped dimensions, explicit units, and accessible labels or alt text where supported.
- Use charts only to clarify a question. Verify source ranges, series, labels, units, periods, placement, and rendered output.
- Configure print layout when printing or PDF output is part of the contract.

Read [formatting-print.md](references/formatting-print.md) completely for professional creation or restyling; editable-input, scenario, Table-versus-range, name, or annotation design; formal, shared, accessible, executive, print, or PDF outputs; or controlled or issued workbooks.

## Enforce format and trust boundaries

Never execute embedded code, refresh external data, follow external links, or weaken protection merely to inspect or preserve a workbook. Do not call worksheet protection encryption or access control, and never claim hidden content is secured. Treat validation as an entry aid, not an integrity control. Neutralize formula-like untrusted text for the target application while preserving the original when required.

Read [format-security.md](references/format-security.md) completely for `.xlsm`, `.xlsb`, `.xls`, encrypted files, `.ods`, Google Sheets, `.csv` or `.tsv`; conversions; signed workbooks; custom or unsupported package parts; preservation-sensitive edits to existing OOXML workbooks; macro or code preservation; external links or connections; protection claims; or untrusted text exports.

## Answer workbook questions rigorously

- Ground answers in the exact labeled output, displayed or cached value, formula, calculation status, units, and period; trace through intermediate totals to authoritative inputs.
- Resolve stale caches without mutating the source: recalculate a copy for file Q&A; on connected or native surfaces, use fresh read-back and disclose staleness if refresh would require mutation.
- Explain with workbook-displayed values, preserving sign, unit, precision, and period conversions. Rank drivers by dependency or sensitivity, not proximity.
- State ambiguity, stale data, broken links, hidden assumptions, and engine differences instead of inventing certainty.

## Verify by risk tier

Apply the active runtime's required inspection, formula-error scan, rendering, and any applicable export checks, then add the applicable engineering tier.

### Tier 1 — every mutation

- Reopen file artifacts independently and confirm format, sheets, dimensions, objects, formulas, and representative values. For connected or native surfaces, freshly read mutated ranges, formulas, unformatted values, dimensions, and object metadata; never export solely for this gate.
- Reconcile row counts, keys, subtotals, cross-sheet totals, and visible check cells. Require zero unexpected formula errors.
- Inspect every changed user-facing surface and repair material clipping, overlap, illegibility, broken chart ranges, or misleading number formats.

### Tier 2 — formula models and material analysis

- Use a compatible engine's documented calculation behavior. For files, save and reopen the candidate in a fresh process. For connected or native surfaces, freshly read formulas, unformatted results, settings, and objects; never save or export unless requested and advertised.
- Independently recompute the most important outputs outside their own formula chain.
- Test relevant zero, blank, negative, duplicate, missing-match, boundary-date, and large-value cases.
- Record unsupported functions, macros, external dependencies, volatile outputs, iteration settings, stale caches, and tolerance assumptions.

### Tier 3 — existing, converted, complex, or sensitive workbooks

- Compare the preflight inventory with the final artifact. Confirm unrelated formulas, styles, names, validations, conditional formatting, charts, pivots, links, visibility, protection, and code packages survived.
- When round-trip preservation is material, render and review every visible sheet and every changed hidden sheet so shared-style or package reconstruction damage cannot hide outside the edited range.
- Open conversions in the destination application when compatibility matters.
- Before privacy or cleanup claims, inspect hidden content, comments, names, connections, links, properties, and embedded code. Use a copy for file artifacts; inspect connected or native surfaces read-only and do not duplicate them unless authorized.
- For a complex file artifact, require a second save and reload when the editor's round-trip stability is material.

Classify intentional error sentinels rather than deleting them. If an applicable calculation, destination, preservation, or rendering engine required by the selected file or live surface is unavailable, complete safe checks but mark that gate blocked. Never describe an unevaluated or unrendered result as fully verified.

## Finish cleanly

Deliver one canonical final workbook unless variants were requested. Follow the active runtime's output and citation rules. Report:

- what changed or what the analysis established;
- the artifact location;
- the calculation, reader, renderer, and destination engines actually used;
- checks passed, skipped, or blocked and any compatibility limitation;
- whether the result is saved, recalculated, visually verified, destination-verified, or only prepared for a later live step.

Do not assign or claim `Reviewed`, `Approved`, `Issued`, or an equivalent business status without evidence and authority. Do not silently issue a workbook with unresolved substantive failures; disclose accepted exceptions and their owner.

Do not mention support scripts or previews unless asked. Do not claim publication, upload, refresh, protection, or live collaboration beyond evidence.
