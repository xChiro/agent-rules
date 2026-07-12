---
workflow_id: WORKFLOW-COMMON_SDD_COVERAGE_GATE_WORKFLOW
trigger: manual
description: Mandatory final project-wide test coverage gate for completed SDD features.
---

# Common SDD Coverage Gate Workflow

Run this workflow after Green, Refactor, and the relevant unit/HTTP/component tests pass, and before Gate 4 completion approval. Every completed SDD feature runs this workflow. A spec with no production code records an explicit `coverage_scope: none` and proves that no production files changed; it does not silently skip the gate.

Coverage evidence must use tests following `RULE-COMMON_TEST_ASSERTION_STRUCTURE`; do not add assertions to setup/helpers merely to increase coverage.

## Mandatory Threshold

- When production code is in scope, minimum required coverage is **90% or higher for the complete project production scope**.
- The project total is the aggregate statement/line coverage reported by the repository's native runner across all included production packages/modules, not 90% for every individual file.
- The affected production scope must also be measured and must not regress from the accepted baseline; critical L3 scope must be at least 90% independently.
- For backend changes, domain/application unit coverage remains required and HTTP integration coverage proves boundary wiring; neither suite may mask weak project-wide production coverage.
- For frontend changes, run the repository's supported statement/line coverage command across the complete application production scope, not only the changed feature.
- If the repository provides branch coverage, report it as additional evidence; the mandatory baseline remains 90% statement/line coverage unless the repository has a stricter threshold.

Do not lower the threshold for convenience. Generated code, third-party code, and framework glue may be excluded only when the repository already excludes them and the exclusion is documented in `verification.md` and `change-summary.md`.

## Phase 1: Discover The Real Command

Use the repository's existing test runner, scripts, build files, and CI commands. Do not invent a command or report an estimate.

Typical examples, only when they match the repository:

```text
Go:     go test -coverprofile=coverage.out ./... && go tool cover -func=coverage.out
.NET:   dotnet test --collect:"XPlat Code Coverage"
React:  npm run test -- --coverage
```

Record the exact command, tool version, coverage scope, exclusions, and output path.

## Phase 2: Run Coverage

1. Ensure the accepted production code and tests are clean and reproducible.
2. Run the complete relevant unit suite and the boundary/component suite required by the spec.
3. When production code is in scope, generate coverage for the complete project production scope and collect the affected-scope baseline/current result.
4. When production code is in scope, confirm project-wide coverage is `>= 90%` and the affected scope has not regressed.
5. Preserve the report only when the repository convention requires an artifact; do not commit noisy generated reports without approval.

## Phase 3: Remediation

If the required coverage result is below 90%:

1. Do not mark the spec complete.
2. Identify uncovered meaningful behavior and missing partitions in the project and affected scope.
3. Add focused ATDD-style/unit/component tests before changing production code.
4. If production code must change, return to the SDD RED and Gate 3 flow.
5. Re-run coverage until the threshold is met.

Never add shallow tests, constant assertions, getter-only tests, or exclusions solely to increase the percentage.

## Phase 4: Record Evidence

Update `verification.md` with:

- Coverage workflow ID.
- Exact command and tool/version.
- Project-wide measured percentage and threshold, or `coverage_scope: none` with the no-production-change evidence.
- Affected scope baseline/current percentage and exclusions when production code is in scope.
- Report path or CI artifact when applicable.
- Uncovered risk, if any.

Update `change-summary.md` with the coverage change/evidence row and final quality-gate result.

## Done

- Coverage was executed for every completed SDD feature.
- When production code is in scope, the complete project production scope reached at least 90% coverage.
- The affected scope did not regress.
- Meaningful tests, not test-only padding, produced the result.
- `verification.md` and `change-summary.md` contain reproducible evidence.
- Gate 4 and `common-sdd-complete-spec.workflow.md` may proceed only after this gate passes.
