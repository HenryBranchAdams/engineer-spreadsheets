# Spreadsheet Data Integrity

Use these rules for imports, joins, cleaning, aggregation, large datasets, dates, exact identifiers, and reproducible data pipelines.

## Preserve semantic types

- Declare a schema for identifiers, dates, mixed columns, decimals, and locale-sensitive numbers. Sample type inference is not a control.
- Store ZIP codes, account numbers, SKUs, routing numbers, and other exact identifiers as text. Excel numeric cells retain only 15 significant digits.
- Store dates and times as typed values only after resolving source locale, timezone, and date basis. Spreadsheet datetime cells normally do not preserve timezone identity; retain the source timezone separately or normalize explicitly.
- Detect the 1900 or 1904 date system before copying serial dates between workbooks. Compare raw serials, displayed dates, number formats, and date-basis settings when dates are material.
- Preserve blank, zero, null, not-applicable, redacted, rejected, and not-yet-available as distinct states when meaning differs. Document any display mapping that makes two states look alike.
- Store money or high-precision values with a declared rounding and scaling policy. Keep source precision until the contractual rounding point.

## Guard application limits

Preflight destination limits before writing. Modern Excel allows 1,048,576 rows by 16,384 columns per worksheet, 32,767 characters per cell, and 8,192 characters in a formula. Memory, file size, unique styles, tables, charts, and renderer limits can fail earlier.

- Never silently truncate rows, columns, text, or formulas.
- For data beyond the useful worksheet surface, process at source grain in a query or dataframe engine and publish an auditable extract, summary, reconciliation, and access path to the canonical data.
- Avoid formatting large unused regions; inflated used ranges slow opening, calculation, saving, rendering, and navigation.
- Choose normal, streaming, or in-memory modes only after a feature and ordering audit. Streaming generation is not an editing mode and commonly requires row-major writes.

## Control imports

For each material import, record or retain:

- source identity, version or as-of time, checksum when useful, encoding, delimiter, locale, timezone, date basis, row count, column manifest, and declared schema;
- source, accepted, and rejected or quarantined counts with `source = accepted + rejected/quarantined`, distinct primary keys, duplicate keys, null keys, authoritative totals, and parse failures; keep the complete reject set in a scalable artifact when a worksheet exception report could exceed application limits;
- the transformation version and deterministic ordering rule.

Treat duplicate headers, blank headers, hidden whitespace, Unicode confusables, inconsistent signs, mixed units, and sentinel strings as explicit normalization decisions. Preserve original values or a reject record when normalization is not reversible.

## Make joins falsifiable

Before a join:

1. Assert null-key and duplicate-key counts on both sides.
2. Declare intended cardinality: one-to-one, one-to-many, many-to-one, or many-to-many.
3. Normalize key types without discarding significant zeros, spaces, case, or Unicode distinctions unless the business rule permits it.
4. State null-match semantics; SQL, dataframe, spreadsheet, and query engines do not all match null keys the same way.

After the join, reconcile matched and unmatched populations, output row count, duplicate expansion, and authoritative totals. Fail or surface exceptions when observed cardinality differs from the contract.

## Aggregate at the correct grain

- State what one row represents before summing. Separate transaction rows from subtotals and snapshots; summing repeated balances or a total alongside its components double-counts the result.
- Derive aggregate rates from matching numerators and denominators. Overall utilization is total used capacity divided by total available capacity; an unweighted average of row percentages answers a different question. Use a weighted mean only when its weight matches the measure.
- Keep currency, unit, period, and sign conventions consistent. Apply explicit conversion rules before combining unlike values; do not infer comparability from identical number formats.
- Define the population: all source rows, filtered visible rows, a reporting period, or an eligible subset. Choose formulas and controls that use that same population, and expose excluded records when material.
- Distinguish a zero denominator from a valid zero result. Use the agreed not-applicable or error state instead of silently reporting zero or suppressing an unexpected error.

## Make calculations reproducible

- Sort outputs explicitly; join, group, pivot, and aggregation order is not automatically stable.
- Pin or record locale, timezone, date basis, rounding mode, and engine version when they affect results.
- Separate nondeterministic values such as current time, random numbers, live rates, or refreshed queries from deterministic controls. Verify tolerances and invariants instead of byte equality.
- Keep one canonical transformation path. Manual cleanup that cannot be reproduced is an unresolved data-quality risk.

## Reconcile at every boundary

At source-to-engine, engine-to-workbook, and workbook-to-destination boundaries, check the smallest sufficient set of:

- row and column counts;
- primary-key uniqueness and unmatched populations;
- sums, balances, minima, maxima, ranges, and distinct counts;
- rejected or truncated records;
- identifiers, dates, precision, null states, and units;
- formulas or objects that depend on the imported range.

An import acknowledgement, file open, or nonempty range is not reconciliation evidence.
