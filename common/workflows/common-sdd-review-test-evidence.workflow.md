---
workflow_id: WORKFLOW-COMMON_SDD_REVIEW_TEST_EVIDENCE_WORKFLOW
trigger: manual
description: Human review gate for acceptance and ATDD-style RED evidence before production code is written.
---

# Common SDD Review Test Evidence Workflow

Invoke this workflow after Gate 2, once the acceptance/public-boundary test and the focused unit-level test have been created and executed. It is the final human check before Green. Final security review is a separate mandatory completion gate handled by `common-sdd-security-gate.workflow.md`.

Load `RULE-COMMON_TEST_ASSERTION_STRUCTURE` and reject assertion APIs outside the test's `Then/Assert` section unless a documented repository/framework exception is approved.

## Preconditions

- Gate 1 approved the spec writes.
- Gate 2 approved starting RED.
- The acceptance, HTTP integration, component, or closest boundary test exists and has a stable `TEST-*` ID.
- The focused unit/domain/application/component test exists and has a stable `TEST-*` ID.
- `red-green-refactor.md` exists from `common/templates/red-green-refactor-report.md` and records the current behavior partition, risk level, and RED evidence fields.
- No production code was changed for the current slice.
- The tests were run and the expected RED evidence was captured, or an explicit boundary exception is documented.

## Review Package

Show the user:

- Spec, User Story, requirement, scenario, task, track, and test IDs.
- Exact test files and changed lines.
- Given/When/Then explanation of each test.
- The `Given/Arrange`, `When/Act`, and `Then/Assert` sections, with every assertion located in the final section.
- Commands executed and concise failure output.
- Why each failure demonstrates the intended missing behavior.
- Assertions, edge cases, happy path, and state/resource side effects covered.
- Fakes, spies, fixtures, local resources, and isolation strategy.
- Confirmation that no production file was changed before RED.
- Parallel-track ownership and files that must remain untouched.
- The concise `red-green-refactor.md` entry for this cycle, including:
  - `RED`: test IDs, command, expected failure, and why the failure proves the missing behavior.
  - `GREEN`: the minimal production change and the passing command/result (complete after implementation).
  - `REFACTOR`: behavior-preserving cleanup, design/architecture checks, and the final green result (complete before Gate 4).

## Gate 3: Approve Test Evidence Before Green

Ask explicitly:

```text
The acceptance and focused ATDD-style tests are written and RED.
May I modify production code and continue to Green?
```

Do not edit, generate, or refactor production code until the user approves.

If the user rejects the tests:

1. Record the feedback in `verification.md`.
2. Modify only the spec/test artifacts authorized by the feedback.
3. Rerun the relevant RED tests.
4. Show the updated evidence and ask again.

If the test passes before production code changes, investigate whether the behavior already exists, the assertion is weak, or the test is exercising the wrong boundary. Do not silently continue to Green.

## Verification Record

Record in `verification.md`:

- Gate 3 request timestamp or history reference.
- User decision and any requested test changes.
- Test IDs, commands, expected failure reason, and final RED result.
- The report path and `RED` section from `red-green-refactor.md`.
- Boundary exceptions and residual risk.

## Exit

After explicit approval, return to the owning SDD workflow at Green. This workflow does not implement production code and does not redefine the User Story or acceptance criteria.
