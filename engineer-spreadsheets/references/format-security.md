# Spreadsheet Formats and Trust Boundaries

Use these rules for binary or macro-enabled workbooks, encrypted files, cross-format conversion, Google Sheets, delimited text, external content, protection claims, and untrusted text.

## Classify the format before opening

- `.xlsx` is an OOXML package with relationships and independent parts, not a flat cell table. Editing requires preservation of all material package parts.
- `.xlsm`, modern binary `.xlsb`, and legacy BIFF `.xls` are code-capable. Disable macros, ActiveX, custom functions, add-ins, embedded-object activation, and external refresh during inspection and preservation.
- `.xls`, `.xlsb`, and encrypted workbooks require an engine demonstrably capable of that exact format. Do not force them through an OOXML-only library or silently convert them.
- Keep macro-enabled outputs in a macro-capable extension. A transplanted macro project or opaque blob is preservation only, not macro parsing, editing, safety review, or functional proof.
- Treat digital signatures as fragile. Any package mutation can invalidate them; preserve or remove only under an explicit contract and verify the final signature state.

Never execute workbook code to prove that it was preserved. If functional macro testing is required, isolate it behind explicit user authority, a controlled target application, and a separate security boundary.

## Qualify editors against actual features

Before editing an existing workbook, inventory charts, shapes, images, comments, legacy VML, names, tables, validations, conditional formats, pivots, slicers, macros, external links, connections, Power Query, custom XML, signatures, and embedded objects.

- Prefer an editor with qualified pass-through behavior for every material unsupported part.
- Reject a read-write path that reconstructs only a fixed subset when omitted parts must survive.
- For preservation-sensitive file edits, write to a new file, compare package-part and relationship manifests, semantically compare modeled features, hash opaque high-risk parts when appropriate, and reopen in the target application without a repair warning.
- Do not infer file preservation from a same-library reload or a successful save.

## Convert across spreadsheet environments

`.ods`, Google Sheets, XLSX, XLSB, XLS, and delimited text differ in formulas, chart types, tables, validations, names, styles, protections, external links, date behavior, and limits.

1. State unsupported destination features before conversion.
2. Preserve the source and convert to a distinct output.
3. Reopen the converted artifact in the destination application.
4. Reconcile key values and formulas, inspect object metadata, and visually review every populated visible sheet.
5. Record any normalized, dropped, substituted, or destination-specific behavior.

A conversion command with a zero exit code proves neither recalculation nor fidelity.

## Use Google Sheets deliberately

- Inspect spreadsheet locale, timezone, calculation settings, sheet IDs, and object metadata before mutation.
- Use `RAW` for literal values. Use `USER_ENTERED` only when formula or locale-aware parsing is intended, then read back the parsed formulas and unformatted values.
- Batch related operations when the active connector supports a trustworthy batch contract. Google guarantees atomic validation/application for one `spreadsheets.batchUpdate` request; do not extend that guarantee to every batch-shaped connector call or a sequence of requests.
- Prefer one mutation owner, stable object IDs, narrow field masks, and conflict-aware read-back. Other humans or automations can race with read-compare-write.
- Do not blindly retry append, table creation, or other non-idempotent operations after an unknown outcome.
- After mutation, freshly read formula text, unformatted results, dimensions, and relevant table, chart, validation, or formatting metadata. Updated-cell counts are acknowledgements only.

## Treat CSV and TSV as text formats

Delimited files have one table and no workbook formulas-as-model, styles, charts, objects, types, multiple sheets, or protection.

- Preserve or explicitly choose delimiter, quoting, encoding, byte-order mark, line endings, header rules, decimal convention, and date convention.
- Preserve leading zeros, long identifiers, exact decimals, null states, and timezone information through an explicit schema.
- A field beginning with `=`, `+`, `-`, `@`, tab, carriage return, or line feed can become a formula or command when opened in a spreadsheet application. Quoting alone is not a security boundary.
- For untrusted outward-facing exports, neutralize formula-like values for the declared target application and retain the canonical original separately when required. No neutralization rule is universal across all spreadsheet applications.
- Reopen with the intended importer and settings, then reconcile rows, columns, headers, types, identifiers, and totals.

## Do not confuse convenience with security

- Worksheet or workbook protection is an editing deterrent, not encryption or access control.
- Hidden and very-hidden sheets, hidden names, comments, metadata, and embedded objects can disclose sensitive content.
- Data validation guides entry but paste, fill, import, formulas, scripts, and APIs can bypass it. Independently validate final values.
- Remove hidden content, links, comments, properties, connections, code, or custom XML only after reviewing whether it is required functionality.
- For sensitive file delivery, inspect a copy for hidden cells and sheets, names, comments, links, connections, properties, embedded code, and package attachments before making a privacy claim. For connected or native surfaces, inspect the selected target read-only and do not duplicate it without explicit authority.
