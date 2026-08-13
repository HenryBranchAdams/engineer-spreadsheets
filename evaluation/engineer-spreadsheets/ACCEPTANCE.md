# Engineer Spreadsheets Acceptance

## Objective and seal

Fine-tune `engineer-spreadsheets` against realistic spreadsheet-agent decisions without weakening authority, preservation, formula integrity, privacy, security, or honest verification boundaries.

- Sealed candidate: `candidate-v26`
- Skill tree SHA-256: `322dc96a80c7d85796885bad8e6c037604be594bfc91f883ad4a0beed1e747f6`
- Core size: 189 lines, 3,073 words, 22,148 bytes
- Original core: 192 lines, 2,991 words, 20,863 bytes
- Package: one core file, three directly routed references, and UI metadata

The working `engineer-spreadsheets/` package is byte-identical to the sealed snapshot.

## Research basis

The protocol combines current guidance from:

- Anthropic's public skill-creator workflow: realistic cases, baseline-versus-skill runs, separate grading, blind comparison, trigger cases, and iterative improvement without overfitting;
- OpenAI Evals and grader guidance: versioned eval data, task-specific graders, reproducible runs, and auditable results;
- Promptfoo's public evaluation architecture: declarative cases, assertions, repeatable execution, and regression comparison;
- DeepWiki-generated orientation for those exact public repositories, treated as navigation rather than authority and checked against current direct sources.

Primary links:

- <https://github.com/anthropics/skills/blob/main/skills/skill-creator/SKILL.md>
- <https://github.com/anthropics/skills/blob/main/skills/skill-creator/references/schemas.md>
- <https://github.com/openai/evals>
- <https://platform.openai.com/docs/api-reference/graders?api-mode=chat>
- <https://github.com/promptfoo/promptfoo>

## Acceptance evidence

| Gate | Result | Evidence |
|---|---|---|
| Package and fixtures | PASS | `lab.rb verify` binds the package hash, validates metadata/reference architecture, and executes the adversarial fixture assertions |
| Official validator | PASS | Current `quick_validate.py` executed through an isolated `uv` environment with PyYAML |
| Development and held-out behavior | PENDING | Predecessor v25 passed 48/49 expectations with every critical expectation; v26 must be rerun because its skill hash changed |
| Routing | PENDING | Predecessor v25 passed 60/60; v26 must be rebound to a fresh trigger report under the hardened definition-hash verifier |
| Baseline comparison | PENDING | Predecessor v25 passed 32/33 shared development expectations versus baseline 31/33; v26 requires a fresh exact-hash run |
| Blind comparison | PENDING | Predecessor v25 passed 27/27 judgments; v26 requires fresh file-isolated, prompt-injection-resistant comparisons |
| Evidence integrity | PASS (harness) | Harness now binds complete behavior and trigger definitions, persists trigger prompts, isolates untrusted comparison responses from judge instructions, checks staged and unstaged diffs, and rehashes reviewed skills after review |
| Context size | PASS | Core is 1.3% above the original word count and remains well below the 5,000-word limit; detailed rules still load conditionally from one-level references and the increase repaired measured critical omissions |
| Real-workbook artifact execution | BLOCKED | The mandatory spreadsheet runtime's `load_workspace_dependencies` capability is absent; runtime rules forbid guessing, installing, or substituting another authoring library |
| Independent review | PENDING | Fresh reviews must accept v26 after its regenerated evidence passes |
| Publication | BLOCKED | Exact GitHub repository, visibility, license, included evaluation evidence, and human publication review remain unspecified |

## Fine-tuning findings repaired

- Required a proven no-op preservation round trip before complex workbook edits.
- Made formula-cache diagnosis distinguish written formulas, cached values, and target-engine recalculation.
- Added destination read-back and reconciliation for CSV/TSV and connected spreadsheet changes.
- Kept canonical raw survey data outside Excel-facing CSVs when encoded recovery columns could exceed cell limits or create disclosure/use hazards.
- Made material controls binary and fail-closed; advisory states cannot silently satisfy release gates.
- Prevented workbook formulas or free-form selectors from assigning authoritative approval or issue status.
- Required formal outputs to expose material assumptions, limitations, units, period, and check state.
- Required PDF/image review to remain visual evidence rather than proof of workbook formula or hidden-content state.
- Required rendering and neighboring-pattern inspection before structural extensions.
- Added a distinct authorization checkpoint immediately before recalculation that can materially change volatile outputs.
- Required fresh cell and object read-back after connected-surface mutations and prohibited blind retry after unknown outcomes.
- Required shared/live mutations to bind the exact target and stable identities, prefer one mutation owner or an edit window, distinguish genuine atomic platform operations from batch-shaped connector calls, preserve unrelated work, and verify bypassable validation inputs.
- Required exact source-to-accepted-plus-rejected reconciliation and scalable exception storage for large imports.
- Required diagnosis plans to identify the first broken dependency with its cell, formula, period, and failure type.
- Required accessible inputs to combine labels and units, a visible fill or boundary, validation where useful, and unlocked state under protection.
- Required explicit CSV-quoting disclosure and complete hidden/very-hidden sensitive-residue inventories.

## Known limitations

- The behavior lane evaluates response decisions and plans in isolated read-only sessions; it does not substitute for target-engine workbook execution.
- The routing lane is explicitly a description-routing classifier, not instrumentation of a host product's internal dispatcher.
- One noncritical response omitted an explicit isolated candidate-copy or compatible-engine read-back when diagnosing a likely stale formula cache. The sealed skill still requires source-preserving recalculation/read-back and every critical calculation boundary passed.
- Generated raw runs and sealed snapshots remain local and ignored. The repository contains the protocol, cases, fixtures, and harness needed to reproduce them.

## Terminal rule

Checkpoint outcome: **STRUCTURALLY SEALED; BEHAVIORAL REQUALIFICATION PENDING, WITH AN EXPLICIT ARTIFACT-LANE BLOCKER.** Public or private GitHub publication additionally requires passing the fresh v26 evidence cycle and confirming the exact repository, visibility, license, included evidence, and acceptance of the explicitly blocked real-workbook lane.
