# Working on Engineer Spreadsheets

The installable skill is the inner `engineer-spreadsheets/` directory. Keep development tooling, benchmark prompts, generated artifacts, and acceptance records outside it.

## Change discipline

- Improve observed task behavior, not wording chosen to satisfy one grader.
- Keep the core concise; put detailed procedures in directly routed references.
- Preserve active-host runtime, authorization, privacy, and feature-preservation requirements.
- Prefer useful, proportional spreadsheet workflows over additional ceremonial controls.
- Do not copy historical evaluation scores onto a changed skill hash.

## Evaluation discipline

- Freeze a candidate before running held-out cases. Do not tune against their individual answers.
- Version changed case definitions. Keep historical acceptance records distinguishable from current results.
- Separate a prior-skill baseline from a true no-skill control.
- Give behavior agents only the task and allowed package; give graders the rubric and untrusted response separately.
- Bind evidence to exact prompts, package files, inputs, outputs, and runner sources.
- Preserve known failing runtime probes. A supported workaround does not prove the unsupported feature passed.
- Treat missing tools as BLOCKED. A planned action, successful save, or green CI check is not workbook execution evidence.

## Before delivery

Run the applicable checks:

```sh
ruby evaluation/engineer-spreadsheets/scripts/lab.rb verify
ruby evaluation/engineer-spreadsheets/tests/lab_test.rb
python3 evaluation/engineer-spreadsheets/artifacts/test_artifacts.py -v
git diff --check
```

For skill changes, run relevant behavior cases and independent review against a sealed package. For artifact-lane changes, run the actual authoring/inspection path when the required runtime is available. Use the host's official skill validator when available. Update the acceptance record with actual outcomes, unresolved limitations, and the tested hash.

Do not commit full model logs, generated workbooks, temporary runtime directories, or credentials. Publish concise evidence sufficient to understand and reproduce the findings.
