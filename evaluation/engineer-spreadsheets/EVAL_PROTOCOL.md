# Engineer Spreadsheets Evaluation Protocol

## Purpose

Measure whether the skill improves real spreadsheet-agent decisions without weakening authority, preservation, correctness, or runtime routing. Keep evaluation artifacts outside the skill package so installation does not load benchmark machinery.

## Evidence layers

1. **Package checks:** metadata, reference routing, context size, forbidden nesting, and deterministic fixtures.
2. **Trigger checks:** realistic positive prompts and difficult adjacent-domain negatives, with a development/held-out split.
3. **Behavior checks:** isolated Codex runs receive either a sealed skill snapshot or no skill, never the expected answers. A separate grader receives the output and preregistered expectations.
4. **Scripted artifact qualification:** use the mandatory authoring runtime to create or edit disposable workbooks, then independently inspect formulas, types, cached values, input perturbations, and bounded preservation. Record rendering and destination-engine evidence separately. Keep known failing probes; do not delete a feature from a fixture and transfer its prior coverage claim. A missing required runtime is BLOCKED, never PASS.
5. **Agent artifact tasks:** a fresh agent receives only the skill, raw inputs, and a user task. Inspect its actual workbook independently. Scripted fixture success is runtime qualification, not evidence that the skill improves agent output. A single forward task does not establish generalization.
6. **Blind comparison:** compare old and candidate outputs without revealing their identities when a change affects subjective judgment.
7. **Human review:** inspect representative outputs and adjudicate rubric quality before publication.

## Splits and leakage control

- Development cases may guide repairs.
- Held-out cases are run only after a candidate is sealed. Do not tune wording to individual held-out answers.
- Benchmark tasks and rubrics are never placed in the skill package. Behavior-run agents receive their user task, but never its expected answer or grading rubric.
- A changed case receives a new ID or version; historical results remain bound to their original case bytes and skill hash.
- Synthetic cases may expand coverage but cannot replace realistic user tasks or human adjudication.
- Stage only the needed skill or response files in a fresh temporary working directory for each model call. This reduces incidental context leakage; read-only Codex still has broader filesystem visibility, so this is not an OS isolation guarantee.
- A no-skill control uses `run --without-skill`; a sealed older skill is a different, explicitly labeled comparison condition. Do not describe one as the other.
- Keep candidate responses in separate untrusted evidence files for graders and comparison judges. Record the actual submitted prompt and staged input bindings.

The current behavior suite has 18 cases and 66 expectations: 14 development
cases with 50 expectations and four held-out cases with 16 expectations. The
routing suite has 20 queries. Report the split and selected case IDs with every
score; a subset is not evidence for the full suite.

## Grading

- Prefer deterministic assertions for file structure, hashes, formulas, values, types, relationships, and required status fields.
- Use rubric graders only for context-dependent decisions. Rubric results must include evidence and are calibrated against human review.
- Critical expectations are hard gates. Weighted averages cannot compensate for a failed authority, privacy, preservation, formula-integrity, or honest-block expectation. Require actual JSON booleans and nonempty supporting evidence. Calculate the noncritical pass rate separately; passing critical cases cannot inflate it above the 0.90 gate.
- Exclusion-precedence routing cases must have zero false positives, independently of aggregate specificity. Version changed query definitions and bind each result to the complete definition.
- Use exclusive, collision-resistant run directories. Never overwrite completed model evidence. A complete old result can be reused only after its exact inputs, outputs, and successful execution are verified; incomplete evidence is not a pass.
- Record the Codex CLI version, model setting, duration, exit status, prompt hash, skill tree hash, output, and grader result for every run.
- New behavior, routing, and blind-comparison runs use schema 2 metadata with a hash-bound copy of the runner source loaded at execution. Verify that source snapshot before interpreting its claims. A source hash calculated after an older run does not establish which code executed it.
- Reconstruct submitted behavior, grading, and routing prompts from their bound inputs during verification. For routing, verify that the evaluated description came from the saved skill core and its package manifest; a description hash alone does not bind the trial to a skill version.
- Repeat stochastic cases three times when variance matters. Do not spend repeated trials on deterministic static checks.

## Promotion gates

A candidate may replace the baseline only when all apply:

- package and fixture checks pass;
- every critical development and held-out expectation passes;
- trigger specificity and recall are each at least 0.90, with zero false positives on explicit exclusion-precedence cases;
- noncritical behavioral pass rate is at least 0.90 and no lower than the baseline;
- no material regression appears in blind comparison, context size, runtime routing, or preservation behavior;
- artifact lanes pass in their required target engines, or publication explicitly states that those lanes are blocked and does not claim them;
- two fresh read-only reviews accept one unchanged skill hash; identify automated review separately from maintainer/human adjudication;
- the publication target, visibility, license, and included evaluation evidence are explicit.

Stop iterating when the sealed candidate clears every applicable gate and another full run produces no material repair, or when the same external blocker prevents meaningful progress and is reported honestly.

## Commands

```sh
ruby evaluation/engineer-spreadsheets/scripts/lab.rb verify
ruby evaluation/engineer-spreadsheets/scripts/lab.rb snapshot candidate-v29 engineer-spreadsheets
ruby evaluation/engineer-spreadsheets/scripts/lab.rb run evaluation/engineer-spreadsheets/snapshots/candidate-v29/package candidate-v29 all
ruby evaluation/engineer-spreadsheets/scripts/lab.rb run --without-skill no-skill development
ruby evaluation/engineer-spreadsheets/scripts/lab.rb grade evaluation/engineer-spreadsheets/runs/<run-id>
ruby evaluation/engineer-spreadsheets/scripts/lab.rb report evaluation/engineer-spreadsheets/runs/<run-id>
ruby evaluation/engineer-spreadsheets/scripts/lab.rb triggers engineer-spreadsheets 3
ruby evaluation/engineer-spreadsheets/scripts/lab.rb trigger-report evaluation/engineer-spreadsheets/runs/<trigger-run-id>
ruby evaluation/engineer-spreadsheets/scripts/lab.rb compare <baseline-run> <candidate-run>
ruby evaluation/engineer-spreadsheets/scripts/lab.rb review <sealed-skill> <review-id> <evidence>...
```

The runner uses the installed `codex` CLI in a read-only, ephemeral process with
a fresh temporary working directory. This stages the intended context without
providing OS-level filesystem isolation. Set `EVAL_MODEL` only when pinning a
model is intentional; set `EVAL_TIMEOUT_SECONDS` to change the default
300-second case timeout.

## Deterministic regression checks

```sh
ruby evaluation/engineer-spreadsheets/tests/lab_test.rb
python3 evaluation/engineer-spreadsheets/artifacts/test_artifacts.py -v
```

CI runs package, fixture, and harness/reader checks only. Authenticated model evaluations and the mandated spreadsheet runtime are separate lanes. Never turn an unavailable lane into a green CI assertion.

Use `CODEX_BIN` for an executable outside `PATH`. Use `SKILL_VALIDATOR_PYTHON` with an existing Python plus PyYAML to run the host official validator without fetching dependencies. Historical transcript records that lack the required prompt, response, staged-input, or execution-time source bindings cannot be relabeled as newly verified evidence. Identify any legacy comparison record and its missing provenance explicitly.

## Publication evidence

Publish a compact, hash-bound results summary with the exact skill tree, case definitions, and runner sources. Retain per-case outcomes and distinguish PASS, FAIL, BLOCKED, and not-run claims. Keep full model logs, generated workbooks, and snapshots outside the installable package. A detected runtime defect is a useful qualification result, but its affected feature cannot be described as verified. Native Excel behavior, rich opaque-feature preservation, and live collaborative mutation remain separate target-environment gates.
