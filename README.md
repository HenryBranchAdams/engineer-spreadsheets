# Engineer Spreadsheets

A skill for agents that build, edit, analyze, audit, and verify spreadsheets. It treats a workbook as a working model: the numbers must reconcile, the inputs must remain editable, updates must work, and existing features must survive.

The skill supplies engineering judgment. Your host supplies the spreadsheet runtime, calculation engine, rendering tools, and output rules.

## What it improves

- **Useful workbooks:** start with the question and a clear primary view; add tabs only when a separate source, calculation, audience, or workflow needs one.
- **Correct data:** preserve exact identifiers, date and null semantics, row grain, units, and source totals. Aggregate rates from matching numerators and denominators.
- **Working models:** retain formulas, exercise input changes, check the expected downstream effect, restore final inputs, and independently read the exported file.
- **Safe edits:** inventory existing features, qualify the editor, make the smallest coherent change, and compare the result with the original.
- **Honest verification:** distinguish formula text, cached values, actual recalculation, rendered appearance, and target-application compatibility.
- **Appropriate authority:** use authorization already provided; ask when essential meaning or a consequential action is unresolved.

Use it when an actual workbook or sheet is the authoritative input or requested output: Excel, ODS, spreadsheet-oriented CSV/TSV, or Google Sheets. It also covers formulas, models, charts, pivots, reconciliation, accessibility, printing, and conversion. It does not apply merely because a code, database, document, or web-app task mentions a spreadsheet.

## Install

Copy the **inner** `engineer-spreadsheets/` directory into the skills directory used by your agent host. Keep that directory name unchanged. The evaluation lab is development tooling; it is not part of the installed skill.

```text
engineer-spreadsheets/
├── SKILL.md
├── agents/openai.yaml
└── references/
    ├── data-integrity.md
    ├── format-security.md
    ├── formatting-print.md
    └── testing-and-evidence.md
```

Example request:

> Use $engineer-spreadsheets to turn these transactions into a formula-driven monthly report. Preserve the account IDs, reconcile the totals, test the update path, and verify the saved workbook.

A writer-only library is not a qualified editor for every existing workbook. A compatible third-party calculation engine does not establish native Excel behavior. The skill requires agents to report those boundaries.

## Evaluation lab

The lab separates evidence that is often conflated:

| Lane | Measures | Does not establish |
|---|---|---|
| Package and fixture checks | Metadata, reference routing, size, case validity, deterministic fixtures | Agent quality or workbook correctness |
| Harness regression tests | Failure handling, evidence binding, grading thresholds, isolation, timeouts | Model performance |
| Behavior evaluations | Responses and decisions against versioned expectations | Performed workbook changes |
| Routing trials | Description-based trigger decisions | The host's internal skill dispatcher |
| Scripted workbook qualification | Real formulas, types, input perturbations, export read-back, bounded preservation | Agent efficacy or universal Excel compatibility |
| Forward task | An independent agent's actual workbook, inspected separately | Broad generalization from one task |

The behavior suite contains 18 cases and 66 expectations: 14 development cases
with 50 expectations, plus four held-out cases with 16 expectations. The routing
suite contains 20 queries; three trials per query produce 60 decisions.

### Fast local checks

Requires Ruby 3.2+ with Minitest, plus Python 3.10+ for the independent workbook-reader tests. These checks do not call a model or require a spreadsheet authoring library.

```sh
ruby evaluation/engineer-spreadsheets/scripts/lab.rb verify
ruby evaluation/engineer-spreadsheets/tests/lab_test.rb
python3 evaluation/engineer-spreadsheets/artifacts/test_artifacts.py -v
```

GitHub Actions runs these deterministic checks on pull requests and pushes to `main`. A green workflow is not a replacement for the model or workbook lanes.

### Behavioral evaluation

Requires an authenticated Codex CLI. Seal a candidate before running it:

```sh
ruby evaluation/engineer-spreadsheets/scripts/lab.rb snapshot candidate-v29 engineer-spreadsheets
ruby evaluation/engineer-spreadsheets/scripts/lab.rb run evaluation/engineer-spreadsheets/snapshots/candidate-v29/package candidate-v29 all
ruby evaluation/engineer-spreadsheets/scripts/lab.rb grade evaluation/engineer-spreadsheets/runs/<run-id>
ruby evaluation/engineer-spreadsheets/scripts/lab.rb report evaluation/engineer-spreadsheets/runs/<run-id>
```

For an explicit no-skill control:

```sh
ruby evaluation/engineer-spreadsheets/scripts/lab.rb run --without-skill no-skill development
```

For routing and blind comparison:

```sh
EVAL_CONCURRENCY=3 ruby evaluation/engineer-spreadsheets/scripts/lab.rb triggers engineer-spreadsheets 3
ruby evaluation/engineer-spreadsheets/scripts/lab.rb trigger-report evaluation/engineer-spreadsheets/runs/<trigger-run-id>
EVAL_CONCURRENCY=3 ruby evaluation/engineer-spreadsheets/scripts/lab.rb compare <baseline-run> <candidate-run>
```

Runs use unique directories and refuse to overwrite model outputs. Behavior agents receive the task and the sealed package, not expected answers. Graders receive the versioned rubric and a separate untrusted response file. Temporary working directories reduce context leakage; they are not an operating-system filesystem isolation boundary.

New behavior and routing runs save the exact loaded runner source as
`lab-source.rb` and bind it by hash in schema 2 metadata. Reports verify the
submitted prompts, staged package or response, case definitions, and recorded
outputs. Routing evidence also binds the description to the saved skill core
and package manifest. Older records without a source snapshot remain explicitly
unbound to their execution-time runner; current source code cannot supply that
missing provenance retroactively.

### Real workbook qualification

See [the artifact lane](evaluation/engineer-spreadsheets/artifacts/README.md) for its runtime requirements, commands, exact feature scope, and known limitations. Its canonical builder uses the host-mandated authoring runtime; an independent Python ZIP/XML reader verifies saved files. Missing required tools produce `BLOCKED`, not `PASS`.

### Runtime configuration

| Variable | Purpose |
|---|---|
| `CODEX_BIN` | Exact Codex executable when it is not on `PATH` |
| `EVAL_MODEL` | Pin the model intentionally; otherwise the CLI default is recorded |
| `EVAL_CONCURRENCY` | Concurrent model calls, default 1 |
| `EVAL_TIMEOUT_SECONDS` | Subprocess timeout, default 300 seconds |
| `COMPARE_REPEATS` | Blind judgments per case, default 3 |
| `SKILL_VALIDATOR_PATH` | Exact path to the host's official `quick_validate.py` |
| `SKILL_VALIDATOR_PYTHON` | Existing Python with PyYAML for offline official validation; otherwise the lab uses `uv` |

## Evidence and limits

See [the acceptance record](evaluation/engineer-spreadsheets/ACCEPTANCE.md) for the current revision's results and [the evaluation protocol](evaluation/engineer-spreadsheets/EVAL_PROTOCOL.md) for promotion rules. Historical v26 results apply only to its recorded package hash; they do not transfer to changed skill text or evaluation code.

Generated workbooks, images, full model logs, and sealed snapshots stay outside the installable package. Compact evidence summaries are published with their package and source hashes. Native Excel, macro execution, complex opaque-feature preservation, and live collaboration require their own target environments and cannot be inferred from a passing local fixture.

## License

MIT. See [LICENSE](LICENSE).
