# Engineer Spreadsheets Acceptance — candidate-v29

## Decision and exact revision

**Implementation accepted by two independent automated reviews; final model promotion is BLOCKED.** The current package passed static checks and underwent real workbook qualification. It has no completed final-revision behavior, routing, or blind-comparison score. The artifact lane remains **FAIL**, with its runtime defects and destination-engine blocker retained below.

- Record date: 2026-10-22
- Sealed package: `candidate-v29`, byte-identical to the working installable package
- Skill tree SHA-256: `075f9881a19e03520c6188d79a9bf1510986fbafcf6f1fcfa7f952c1d0754d2f`
- Package: six files; core 199 lines and 3,316 words, with four conditionally loaded references and UI metadata
- Final `lab.rb` source SHA-256: `7a9154d276681291bcb813b4dd37d8a9f4f6f2ce3a1c7c00587bb05ae37c7811`

This record replaces the current acceptance page, not the evidence for earlier revisions. The original [v26 acceptance record](history/ACCEPTANCE-v26.md) is preserved separately. Its scores and publication status do not transfer to v29.

## Current evidence

| Gate | Result | Scope and evidence |
|---|---|---|
| Package and fixtures | PASS | `lab.rb verify`; package structure, metadata, reference routing, size, and deterministic fixtures |
| Official skill validator | PASS | Host `quick_validate.py` validated the sealed package |
| Harness regressions | PASS | 30 Ruby tests, 102 assertions; strict grading, evidence binding, complete result sets, subprocess handling, and failure cases |
| Artifact-reader regressions | PASS | 17 Python tests; typed values, stale caches, driver and formula checks, row preservation, and evidence integrity |
| Independent content review | PASS | `final_skill_acceptance` and `final_evidence_review` accepted the unchanged v29 hash in separate read-only reviews; these were automated reviews, not human maintainer adjudication |
| Final behavior evaluation | BLOCKED | No completed v29 score across the current 18 cases and 66 expectations |
| Final routing evaluation | BLOCKED | No completed v29 run satisfying the strengthened package, source, and submitted-prompt bindings |
| Final blind comparison | BLOCKED | No completed final comparison; interrupted intermediate judgments are not a passing result |
| Real workbook qualification | FAIL | `artifact-v29`: 14 gates, comprising 10 PASS, 3 FAIL, and 1 BLOCKED; all seven rendered PNGs were visually inspected |
| Artifact evidence integrity | PASS | Final skill, builder, reader, inputs, workbooks, and images are hash-bound; verification preserves the FAIL outcome |
| Destination engines | BLOCKED / NOT RUN | LibreOffice was explicitly skipped after an earlier resource failure; native Excel was not tested |

Automatic approval review rejected the escalated Codex CLI rerun because it would write protected session state. The companion process was stopped, and partial runs were excluded. This access limitation does not establish either a pass or a failure of the final skill's model behavior.

## Changes made

- Kept ordinary tasks proportional: start with the user's question and one useful primary view; add sheets and controls only when the workflow needs them.
- Strengthened data reasoning around row grain, populations, weighted rates, units, exact identifiers, missing values, and source reconciliation.
- Required independent expected results, meaningful input perturbations, deliberate failure checks for material controls, restoration of final inputs, and independent saved-file read-back.
- Reused established authority for ordinary editing and recalculation, allowed structural testing on disposable copies, and separated ordinary tracker statuses from controlled release decisions.
- Required exported report figures, units, periods, scenarios, and input states to reconcile to the final workbook; verification reports now use task-specific language.
- Hardened the lab against false positives: strict booleans and evidence, separate noncritical thresholds, exclusion-precedence routing gates, exclusive run directories, complete result sets, exact submitted-prompt bindings, package manifests, and execution-time source snapshots for new runs.

## Completed development evidence — earlier package only

The intermediate v27 package had tree SHA-256 `5c4de6260278fa85e9929ea5bd5cbfe7c9aa87889213b972d05b315aff560a83`. Its completed behavior run passed **63/63 expectations**: 47/47 across 13 development cases and 16/16 across four held-out cases. The original v26 package, rerun on the same 13 development cases, passed **43/47**. These response-only evaluations measure decisions and plans, not performed spreadsheet changes. The current v29 suite adds one development case and three expectations.

The current report command validates the available legacy behavior evidence, including case, response, and prompt bindings. Those runs lack execution-time runner source snapshots, however, so their source provenance remains unbound. The final source hash above must not be attached retroactively to them.

An intermediate routing run recorded **60/60 decisions**. It used schema 1 and lacks bindings now required by the strengthened verifier. It is a historical observation only, even though the skill description is unchanged. It is not a verified final-revision routing score or a test of a host's internal dispatcher.

The intermediate blind comparison was interrupted. On the board-report case, two recorded judges flagged a regression and one returned a tie. That finding prompted the final PDF reconciliation and plain-language verification changes. No completed comparison establishes that those repairs eliminate the regression.

## Real workbook findings

Artifact-tool 2.8.99 completed the final scripted lane. Typed OOXML values, saved formulas and caches, literal model drivers, five capacity input states, fixed actuals, and the bounded no-op and narrow-edit fixtures passed. The Python reader is independent of the workbook authoring runtime. These results qualify the tested runtime path; they do not establish agent efficacy or arbitrary workbook preservation.

Three failures remain deliberately visible:

1. **Identifier rendering:** XLSX cells preserve exact IDs as text, but the PNG renderer displays some IDs numerically or in scientific notation. The visual gate fails. Adding an apostrophe to canonical IDs was rejected because it changes their stored values.
2. **Solid-fill conditional formatting:** A no-op import/save removes `patternType="solid"` from the probe's differential fill. The separate font-only fixture passes; that does not waive the failed solid-fill probe.
3. **Zero versus missing:** The retained direct empty-string formula (`B11=""`) misclassifies zero volume as missing. The main model uses `ISBLANK` and passes Base, Peak, zero, missing-unselected, and missing-selected states. The original probe retains its own expected formula and fails on its numerical behavior.

LibreOffice read-back remains BLOCKED after being explicitly skipped following an earlier resource failure. No native Excel, macro, signature, external-link, pivot, slicer, complex opaque-feature, or live collaboration qualification is claimed.

## Independent forward task — v27 only

A fresh agent used v27 to build an actual two-sheet capacity workbook. Independent inspection verified exact stored IDs, 115 available slots, 81 booked slots, 34 unused slots, and weighted utilization of 81/115 (70.4348%). Input perturbation and restoration, fresh-process reload, and OOXML checks passed. The preview showed the same identifier-rendering limitation. This is one completed task on an earlier package, not a final v29 score or evidence of broad generalization.

## Evidence files and remaining work

Compact records are [iteration-evidence-v29.json](results/iteration-evidence-v29.json), [artifact-v29.json](results/artifact-v29.json), and [forward-capacity-v27.json](results/forward-capacity-v27.json). They distinguish current checks from legacy observations and retain source hashes and per-lane limitations. Raw model logs, generated workbooks, and sealed snapshots stay outside the installable package.

Use the [evaluation protocol](EVAL_PROTOCOL.md) and [artifact-lane commands](artifacts/README.md) to finish qualification in an authorized environment. A final behavior run must cover all 18 cases and 66 expectations; routing needs the current bindings, and blind comparison must complete before claiming its promotion gate. Destination-engine coverage and the three retained runtime failures require their own successful reruns. Until then, the implementation is reviewable, while full model and workbook promotion remain unproven.
