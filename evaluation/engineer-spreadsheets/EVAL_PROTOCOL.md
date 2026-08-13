# Engineer Spreadsheets Evaluation Protocol

## Purpose

Measure whether the skill improves real spreadsheet-agent decisions without weakening authority, preservation, correctness, or runtime routing. Keep evaluation artifacts outside the skill package so installation does not load benchmark machinery.

## Evidence layers

1. **Package checks:** metadata, reference routing, context size, forbidden nesting, and deterministic fixtures.
2. **Trigger checks:** realistic positive prompts and difficult adjacent-domain negatives, with a development/held-out split.
3. **Behavior checks:** isolated Codex runs receive either a sealed skill snapshot or no skill, never the expected answers. A separate grader receives the output and preregistered expectations.
4. **Artifact checks:** when the mandatory spreadsheet runtime is available, create or edit disposable workbooks and grade formulas, types, objects, recalculation, preservation, and rendered surfaces. A missing mandatory runtime is BLOCKED, never PASS.
5. **Blind comparison:** compare old and candidate outputs without revealing their identities when a change affects subjective judgment.
6. **Human review:** inspect representative outputs and adjudicate rubric quality before publication.

## Splits and leakage control

- Development cases may guide repairs.
- Held-out cases are run only after a candidate is sealed. Do not tune wording to individual held-out answers.
- Evaluation prompts are never placed in the skill package or given to behavior-run agents.
- A changed case receives a new ID or version; historical results remain bound to their original case bytes and skill hash.
- Synthetic cases may expand coverage but cannot replace realistic user tasks or human adjudication.

## Grading

- Prefer deterministic assertions for file structure, hashes, formulas, values, types, relationships, and required status fields.
- Use rubric graders only for context-dependent decisions. Rubric results must include evidence and are calibrated against human review.
- Critical expectations are hard gates. Weighted averages cannot compensate for a failed authority, privacy, preservation, formula-integrity, or honest-block expectation.
- Record the Codex CLI version, model setting, duration, exit status, prompt hash, skill tree hash, output, and grader result for every run.
- Repeat stochastic cases three times when variance matters. Do not spend repeated trials on deterministic static checks.

## Promotion gates

A candidate may replace the baseline only when all apply:

- package and fixture checks pass;
- every critical development and held-out expectation passes;
- trigger specificity and recall are each at least 0.90, with zero false positives on explicit exclusion-precedence cases;
- noncritical behavioral pass rate is at least 0.90 and no lower than the baseline;
- no material regression appears in blind comparison, context size, runtime routing, or preservation behavior;
- artifact lanes pass in their required target engines, or publication explicitly states that those lanes are blocked and does not claim them;
- two fresh read-only reviews accept one unchanged skill hash;
- the publication target, visibility, license, and included evaluation evidence are explicit.

Stop iterating when the sealed candidate clears every applicable gate and another full run produces no material repair, or when the same external blocker prevents meaningful progress and is reported honestly.

## Commands

```sh
ruby evaluation/engineer-spreadsheets/scripts/lab.rb verify
ruby evaluation/engineer-spreadsheets/scripts/lab.rb snapshot baseline-v1 engineer-spreadsheets
ruby evaluation/engineer-spreadsheets/scripts/lab.rb run snapshots/baseline-v1/package baseline development
ruby evaluation/engineer-spreadsheets/scripts/lab.rb grade evaluation/engineer-spreadsheets/runs/<run-id>
ruby evaluation/engineer-spreadsheets/scripts/lab.rb report evaluation/engineer-spreadsheets/runs/<run-id>
ruby evaluation/engineer-spreadsheets/scripts/lab.rb triggers engineer-spreadsheets 3
ruby evaluation/engineer-spreadsheets/scripts/lab.rb compare <baseline-run> <candidate-run>
ruby evaluation/engineer-spreadsheets/scripts/lab.rb review <sealed-skill> <review-id> <evidence>...
```

The runner uses the installed `codex` CLI in an isolated, read-only, ephemeral process. Set `EVAL_MODEL` only when pinning a model is intentional; set `EVAL_TIMEOUT_SECONDS` to change the default 300-second case timeout.
