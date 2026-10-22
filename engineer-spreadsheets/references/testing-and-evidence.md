# Test Spreadsheet Behavior and Evidence

Use targeted tests to prove the requested result and its update behavior. Follow the active runtime's authoring, calculation, rendering, and preservation requirements. Never substitute a testing library for a mandatory authoring runtime.

## Define what success means

Choose observable conditions from the request before writing formulas. Bind each condition to its source, affected cells or objects, expected result, tolerance, and verification method. For a small workbook, nearby notes and a compact verification log suffice; do not add a testing tab by default.

Distinguish three questions:

- **Correct now:** do the delivered values reconcile to the authoritative inputs?
- **Works when updated:** do intended edits recalculate formulas, summaries, checks, and charts correctly?
- **Preserves the contract:** are unrelated data, features, formatting, and business meanings unchanged?

## Use an independent expected result

Recompute material outputs directly from raw inputs with a simpler method or independent identity. For example, reconcile a monthly revenue summary to independently grouped transactions, or a closing cash balance to opening cash plus independently classified receipts less payments. Copying the workbook's formula into a script is a useful cross-engine check, but can repeat the same business error.

Do not infer correctness from a green check, a nonempty cell, formula presence, or agreement between two references to the same result. Include a known failing case for a material control and confirm that it fails. Record why an accepted discrepancy is within tolerance. Choose absolute and relative tolerances appropriate to the units and near-zero values; formatting precision is not automatically a calculation tolerance.

## Exercise the intended update path

Use a disposable file candidate or an explicitly authorized test surface. Freeze the intended final input state first. Select representative tests for the actual feature set:

| Feature | Behavioral check |
|---|---|
| Editable rate or quantity | Change one driver and verify the numerical downstream effect; unrelated periods and historical actuals stay unchanged. |
| Scenario selector | Change to another valid case, check active assumptions and outputs, then try an invalid value; it must not silently select a valid case. |
| Row-growing data | Append a record through the intended update path and check calculated columns, totals, filters, validation, chart sources, and print range where applicable. |
| Lookup or join | Try an unmatched key and a duplicate; confirm the declared rule and surface unexpected exceptions. |
| Material check | Deliberately break the tested invariant and confirm FAIL; repair it and confirm PASS. |
| Input-dependent ranking or action list | Change an input that should change inclusion or order and confirm the displayed result updates. |

Test boundaries that can change the decision, not every imaginable combination. Use expected values or defensible invariants, such as a one-unit price change increasing revenue by quantity when all else is fixed. Do not assume monotonicity where caps, tiers, signs, or other business rules invalidate it.

Restore final inputs, remove test records, recalculate, save when applicable, and freshly read back the final artifact. Confirm that temporary values and deliberately introduced errors are absent. Testing a disposable copy does not authorize edits to the original or a live shared workbook.

## Match the claim to the evidence

| Evidence | What it supports | What it does not prove |
|---|---|---|
| Formula and type inspection | Intended formulas and native data representations exist. | Formulas have evaluated correctly. |
| Independent source reconciliation | Tested outputs agree with an external expectation. | Untested branches or edit behavior work. |
| Input change plus fresh calculation/read-back | The exercised dependency path responds in the named engine. | Equivalent behavior in every spreadsheet application. |
| Independent saved-file inspection | The inspected properties survived export. | Unsupported opaque features survived unless separately checked. |
| Rendered comparison | The inspected surface is readable and visually stable. | Hidden data, formula correctness, or calculation freshness. |

Keep a compact evidence record for material work: source/output identity, engine and version when available, actual checks and results, selected cells/ranges, and unresolved limitations. Retain hashes when needed to bind an artifact to its evidence. Do not claim a check ran merely because the script contains it.

Mark unavailable required gates BLOCKED and describe the next concrete verification step. Distinguish a failed result from unavailable evidence and an inapplicable check. A passed deterministic fixture or instruction-following evaluation is not proof that an agent produced a correct, preserved, usable workbook.
