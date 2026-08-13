# Engineer Spreadsheets

`engineer-spreadsheets` is a preservation-first instruction skill for agents that create, edit, analyze, audit, debug, convert, and verify spreadsheets. It emphasizes typed data, auditable formulas, calculation truth, feature preservation, professional Excel design, security boundaries, accessibility, and evidence-backed delivery.

## What it covers

- New and existing `.xlsx`, `.xlsm`, `.xlsb`, `.xls`, `.ods`, CSV, and TSV work
- Formula engineering, calculation-state diagnosis, models, charts, pivots, tables, names, formatting, print, and PDF QA
- Large datasets, exact identifiers, dates, null semantics, joins, reconciliation, and formula-injection defense
- Preservation-sensitive edits, code-bearing workbooks, external links, connected Google Sheets, and concurrent mutation safety
- Professional inputs, scenarios, checks, management outputs, accessibility, and fail-closed release status

The skill routes platform operations to the active spreadsheet runtime. It does not claim that a writer-only library can safely round-trip any workbook, that formula text proves calculation, or that a successful save proves preservation.

## Package

```text
engineer-spreadsheets/
├── SKILL.md
├── agents/openai.yaml
└── references/
    ├── data-integrity.md
    ├── format-security.md
    └── formatting-print.md
```

Install by copying `engineer-spreadsheets/` into the skills directory used by your agent host. The folder name must remain `engineer-spreadsheets`.

## Evaluation lab

The repository includes a dependency-light Ruby harness, versioned behavior and routing cases, adversarial fixtures, a promotion protocol, and an acceptance manifest. Generated runs and sealed snapshots are ignored so the published repository contains the reproducible machinery without committing large model transcripts.

Prerequisites:

- Ruby
- Codex CLI for isolated response, grader, comparison, and review runs
- `uv` for running the official skill validator in an isolated Python environment

Validate the package and fixtures:

```sh
ruby evaluation/engineer-spreadsheets/scripts/lab.rb verify
```

Create a sealed snapshot and run the behavior suite:

```sh
ruby evaluation/engineer-spreadsheets/scripts/lab.rb snapshot candidate-v1 engineer-spreadsheets
ruby evaluation/engineer-spreadsheets/scripts/lab.rb run evaluation/engineer-spreadsheets/snapshots/candidate-v1/package candidate-v1 all
ruby evaluation/engineer-spreadsheets/scripts/lab.rb grade evaluation/engineer-spreadsheets/runs/<run-id>
ruby evaluation/engineer-spreadsheets/scripts/lab.rb report evaluation/engineer-spreadsheets/runs/<run-id>
```

Stress the skill-description routing decision and compare two behavior runs blindly:

```sh
EVAL_CONCURRENCY=4 ruby evaluation/engineer-spreadsheets/scripts/lab.rb triggers engineer-spreadsheets 3
ruby evaluation/engineer-spreadsheets/scripts/lab.rb trigger-report evaluation/engineer-spreadsheets/runs/<trigger-run-id>
EVAL_CONCURRENCY=3 ruby evaluation/engineer-spreadsheets/scripts/lab.rb compare <baseline-run> <candidate-run>
```

Generate hash-bound static evidence against a sealed package:

```sh
ruby evaluation/engineer-spreadsheets/scripts/lab.rb static-evidence \
  engineer-spreadsheets \
  evaluation/engineer-spreadsheets/snapshots/candidate-v1/package \
  evaluation/engineer-spreadsheets/runs/static-evidence.json
```

Set `EVAL_MODEL` to pin an evaluation model, `EVAL_CONCURRENCY` to control parallelism, `EVAL_TIMEOUT_SECONDS` to change process timeouts, `COMPARE_REPEATS` to change the default three blind judgments per case, `CODEX_HOME` to locate the standard validator, or `SKILL_VALIDATOR_PATH` to provide its exact path.

## Accepted local candidate

The current structurally sealed package is bound to tree SHA-256 `322dc96a80c7d85796885bad8e6c037604be594bfc91f883ad4a0beed1e747f6`. Its predecessor v25 passed every critical behavior expectation (48/49 total, 97.96%), 60 of 60 repeated routing trials, and 27 of 27 blind baseline judgments. V26 repairs two creation-scope defects found during pre-publication review and therefore awaits a fresh exact-hash behavior, routing, comparison, and independent-review cycle under the hardened evidence harness.

The real-workbook artifact lane remains explicitly blocked in this environment because the mandatory spreadsheet runtime dependency loader was unavailable. Response and decision evaluations do not substitute for target-engine workbook execution. See [the acceptance manifest](evaluation/engineer-spreadsheets/ACCEPTANCE.md) and [evaluation protocol](evaluation/engineer-spreadsheets/EVAL_PROTOCOL.md) for the exact evidence boundary.
