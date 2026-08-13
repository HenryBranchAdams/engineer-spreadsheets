# Engineer Spreadsheets Acceptance

## Objective

Keep the always-loaded skill concise through progressive disclosure while preserving spreadsheet correctness, preservation, security, routing, and verification behavior. Incorporate the strongest professional-formatting, input-control, print, accessibility, and release-governance guidance from the user-supplied `professional-excel-formatting-gold-standard (1).md` without imposing a universal house style or inventing organizational policy.

## Authority and boundaries

- Mutation owner: primary Codex agent.
- Independent verification: separate read-only agents after the candidate is sealed.
- Local files may be created or changed only inside this workspace.
- The supplied formatting document is design input, not independent authority for a user's template, policy, accessibility obligation, or approval state.
- One disposable native Google Sheet is authorized only through the required local-XLSX import path; no existing Google file may be touched.
- Live Microsoft Excel may be exercised only when the request explicitly targets an open or connected workbook and all setup gates pass. This optimization request does not authorize live workbook mutation.
- Do not install dependencies, execute workbook code, refresh external data, overwrite user files, publish, or delete external data.

## Context measurements

| Artifact | Lines | Words | Bytes |
|---|---:|---:|---:|
| Original core | 192 | 2,991 | 20,863 |
| Prior optimized core | 171 | 2,272 | 16,351 |
| Current core | 180 | 2,428 | 17,556 |
| Conditional professional-formatting reference | 51 | 941 | 6,598 |

The current core remains 18.8% smaller by words and 15.9% smaller by bytes than the original. The detailed professional guidance loads only for its stated conditions.

## Acceptance manifest

| Gate | Required evidence | Status |
|---|---|---|
| Core context | Core remains materially smaller than the original; detailed guidance is conditionally loaded | PASS — 180 lines, 2,428 words, 17,556 bytes; professional detail is in one directly linked reference |
| Package shape | Frontmatter, name, description, folder, and UI metadata satisfy the official validator contract | PASS — exact rules reproduced with Ruby YAML: 21-character name, 947-character description, permitted keys only, folder/name match, 46-character UI description, and default prompt invokes `$engineer-spreadsheets` |
| Reference architecture | Every reference is directly and conditionally linked from core, exists, and does not link to another reference | PASS — exactly three one-level references: data integrity, format/security, and professional formatting/print |
| Professional judgment | Skill covers proportional risk, working-versus-presentation architecture, recognizable inputs, explicit checks, scenarios, structures, annotations, accessibility, print/PDF QA, and evidence-bound release status | PASS — rules preserve template precedence, avoid fixed house-style mandates, and distinguish workbook labels from approval evidence |
| Formatting decisions | Realistic prompts exercise the new judgment without leaking expected answers to responding agents | PASS — all 10 cases passed across blind agent batches; the revised one-off input case and three narrow structure/name/annotation trigger probes also passed after repair; raw responses are task-history evidence rather than packaged transcripts |
| Trigger precision | Positive, negative, and routing prompts match expected activation and execution surfaces | PASS — all 24 outcomes in `TRIGGER_CASES.md` were independently reviewed against metadata and active-runtime routing |
| Safety retention | Authorization, privacy, active-content, formula-injection, protection, preservation, and honest-block rules remain mandatory | PASS — core retains these rules and references add format-specific detail only under sufficient triggers |
| Local workbook | Mandated runtime builds and validates a typed workbook with formulas, chart, controls, renders, export, reopen, and reconciliation | BLOCKED — `load_workspace_dependencies` is absent from the callable tool surface; runtime rules forbid dependency guessing, installation, or alternate writers |
| Adversarial data | Messy identifiers, timezones, null states, duplicate headers, long digits, and formula-like text avoid silent coercion or injection | PARTIAL — deterministic fixture assertions pass for all 12 risk signals; end-to-end workbook proof shares the runtime blocker |
| Google Sheets | Verified local workbook imports through native conversion, then metadata, formulas, and rendering are checked without touching existing files | BLOCKED — native import requires the verified local `.xlsx` prerequisite; no Google file was created or changed |
| Live Excel routing | Generic file work stays local; only explicit open/connected Excel work activates live control | PASS — regression cases preserve this routing; this request did not authorize a live workbook mutation |
| Independent verification | Two fresh read-only reviewers accept the sealed candidate and evidence | PASS — both fresh full-package reviews accepted core SHA-256 `da11216538c7833173a0d104819e5486708b917fe932f4368ab38f7d8180faa6` with no material findings |

## Known environment observations

- The official `quick_validate.py` cannot start because its Python environment lacks `PyYAML`. Its exact contract was reproduced without installing packages; this remains a validator-environment limitation.
- The required `load_workspace_dependencies` capability must be present before any `@oai/artifact-tool` workbook build. Its absence blocks workbook and downstream Google-import execution and does not authorize another writer or dependency-path guessing.

## Executed checks

- `quick_validate.py engineer-spreadsheets`: blocked before validation with `ModuleNotFoundError: No module named 'yaml'`.
- Exact official validator constraints reproduced with the system Ruby YAML parser: PASS.
- Direct-reference existence and one-level/no-nested-reference assertion: PASS.
- `FORMATTING_CASES.md`: 10/10 decision cases passed in blind batches; the revised one-off input case and three narrow reference-trigger probes passed after repair.
- `TRIGGER_CASES.md`: all 24 expected outcomes independently reviewed as consistent with metadata and runtime routing.
- `ruby evaluation/engineer-spreadsheets/verify_fixtures.rb`: PASS — six rows, one duplicate header, five long and five leading-zero identifiers, one duplicate-key group, one invalid timestamp, distinct blank/zero/not-applicable amounts, one locale-sensitive amount, four formula-sensitive strings, and preserved canonical originals.
- Unfinished-content marker scan across the package and evaluation files: PASS — no matches.
- A first fresh review found that general editable inputs and narrow Table/name/annotation requests were not guaranteed to load the right guidance. Both defects were repaired before resealing; prior acceptances do not count for this candidate.
- Two fresh, independent, read-only full-package reviews of the repaired seal: ACCEPT with no material findings.
- Current core SHA-256: `da11216538c7833173a0d104819e5486708b917fe932f4368ab38f7d8180faa6`.

The original and prior-core counts came from earlier `wc -l -w -c` observations in this task. No redundant baseline copy was retained, so the current counts and arithmetic reproduce locally while older counts remain task-history evidence.

## Terminal rule

Terminal outcome: **ACCEPTED WITH EXPLICIT EXECUTION BLOCKERS.** All locally executable gates pass, and two fresh independent reviewers accepted the sealed skill. Real-workbook and downstream Google-Sheet execution remain blocked by the absent mandatory dependency loader and are not reported as passed.
