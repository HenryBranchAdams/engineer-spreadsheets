# Real workbook qualification

This lane creates actual disposable XLSX files, perturbs a formula model, and
reads the saved OOXML independently. It qualifies a **bounded runtime path**.
It does not measure agent behavior, replace the behavior suite, or certify
Microsoft Excel compatibility.

## Requirements

- Python 3.10+ with the standard library. The independent reader and tests have
  no third-party Python dependencies and never author workbooks.
- The host-approved `@oai/artifact-tool` runtime, selected through
  `CODEX_PRIMARY_RUNTIME_NODE` and `CODEX_PRIMARY_RUNTIME_NODE_MODULES`.
- `soffice` for the separate LibreOffice destination read-back gate. When absent
  or explicitly skipped, this gate is **BLOCKED**.
- A reviewer able to inspect the generated PNGs. Rendering alone never passes
  the visual review gate.

Follow the host's required artifact initialization before the first authoring
run. The runner copies the single canonical `build.mjs` into a fresh temporary
directory and symlinks that directory's `node_modules` to the approved runtime.
It never installs or substitutes an authoring library. Each import/save step
runs in a fresh Node process.

## Run

From the repository root:

```sh
python evaluation/engineer-spreadsheets/artifacts/test_artifacts.py
python evaluation/engineer-spreadsheets/artifacts/run.py run \
  evaluation/engineer-spreadsheets/runs/artifact-candidate-1
```

Use a new output directory for every run. Existing directories are rejected so
stale workbooks cannot satisfy a later run. `--skip-libreoffice` leaves the
destination gate blocked; it is useful after a native-engine resource failure.

Inspect all seven PNGs, comparing typed record IDs against `inputs.json`, source
and edited records, and populated versus missing capacity inputs. Record what
you observed with the appropriate verdict:

```sh
python evaluation/engineer-spreadsheets/artifacts/run.py review \
  evaluation/engineer-spreadsheets/runs/artifact-candidate-1 \
  --reviewer 'Reviewer identity' --verdict FAIL \
  --observations 'Specific observations from all seven images; name defects and cells.'
python evaluation/engineer-spreadsheets/artifacts/run.py verify \
  evaluation/engineer-spreadsheets/runs/artifact-candidate-1
```

Exit codes are `0` for PASS, `1` for FAIL, and `2` for BLOCKED. `verify` checks
evidence integrity and re-runs successful semantic assertions, then returns the
run's status. Therefore verified evidence for a failing runtime correctly
returns `1`. Do not use `|| true` to turn a failing qualification into success.

## What is tested

| Gate | Evidence |
| --- | --- |
| Typed records | Exact leading-zero and 20-digit IDs, formula-like literal text, booleans, typed dates, decimal amounts, formulas and cached totals |
| Capacity model | The same formula build reacts to Base, Peak, zero volume, missing unselected volume and missing selected volume; verify literal driver cells, exact formulas, cached results, and unchanged fixed actuals |
| No-op qualification | A new process imports, saves and reopens the fixture before the narrow edit is attempted |
| Narrow edit | Only `Records!B6` and dependent cached total `B10` may change; formulas, unrelated cells and styles, sheet identity, table, validation, font-only conditional formatting, panes, row attributes, column dimensions, package members and relationships are compared |
| Qualification probes | The original solid-fill conditional-format round trip and direct empty-string comparison remain independently executable, even after supported alternatives are used |
| Rendering and visual review | Valid rendered PNGs plus a separate recorded reviewer verdict bound to every image hash |
| Destination read-back | LibreOffice opens and saves the Peak model, then the independent reader checks the result; this is not a documented `calculateAll` or native Excel test |

Relationship IDs can legitimately be regenerated. Preservation comparisons
resolve their targets and types instead of comparing arbitrary IDs. The reader
accepts both serial-date and ISO-date OOXML representations. It never treats a
missing formula cache as zero, a boolean as numeric evidence, or numeric ID
coercion as an acceptable precision tolerance.

The capacity checker verifies the fixture's specified formula text as well as
its inputs and cached outputs. This prevents a stale result from passing after
an input or formula changes. The empty-string probe has its own expected
formula, so it continues to test the original zero-versus-missing behavior.
Preservation checks include row heights, hidden flags, styles, and outline
attributes when present; unchanged cell contents alone are insufficient.

Every report binds the skill tree, builder, reader, inputs, and generated files
to SHA-256 hashes. The verifier rejects changed artifacts, omitted bindings,
changed skill versions, contradictory summary statuses, incomplete PASS gate
sets, and successful semantic labels that cannot be reproduced. These are
integrity checks, not digital signatures or proof of who ran the commands.

## Measured runtime boundaries

Artifact-tool 2.8.99 exposed these issues during development. Keep the probes
when upgrading the runtime and inspect whether they actually recover:

- Numeric-looking IDs are stored exactly as text in the XLSX, but its PNG
  renderer displays them as numeric values or scientific notation. Prefixing
  canonical IDs with an apostrophe changes their stored values and is not a
  valid repair. Preserve the originals and fail the affected visual gate.
- A no-op round trip removes `patternType="solid"` from the differential fill
  used by the solid-fill conditional-format probe. The font-only fixture is
  tested separately; its success does not waive the fill probe.
- A direct empty-string comparison in the original case-selection formula
  classified zero volume as missing. The supported model uses `ISBLANK` and
  separately tests real zero and missing inputs. The original formula remains
  a failing probe until the runtime behaves correctly.

The run must retain actual FAIL/BLOCKED statuses. Do not quote a single pass rate
that blends supported paths with failing probes. Macros, signatures, external
links, pivots, slicers, and arbitrary existing workbook round trips are outside
this fixture's preservation coverage.
