---
workflow_id: WORKFLOW-COMMON_SDD_REVIEW_TEST_EVIDENCE_WORKFLOW
trigger: manual
description: "Reusable human review gate for actual RED evidence before each affected layer GREEN."
---

# Common SDD Review Test Evidence Workflow

Invoke this workflow after Gate 2 whenever an affected scope reaches RED and before production changes for that scope. Invoke it as Gate 3-DOMAIN, Gate 3-APPLICATION, or Gate 3-BOUNDARY. Approval for one scope does not authorize a later layer. Final security review is a separate mandatory validation gate handled by `common-sdd-security-gate.workflow.md`.

Load `RULE-COMMON_TEST_ASSERTION_STRUCTURE` and reject assertion APIs outside the test's `// Assert` section unless a documented repository/framework exception is approved.

## Preconditions

- Gate 1 approved the spec writes.
- Gate 2 approved starting RED.
- `gate_scope: domain | application | boundary` is recorded.
- The focused test for that scope exists and has a stable `TEST-*` ID.
- Prior required layer gates are `passed` or evidence-backed `not_affected`.
- `red-green-refactor.md` exists from `common/templates/red-green-refactor-report.md` and records the current behavior partition, risk level, and RED evidence fields.
- No production code was changed for the current scope.
- The test was run and the expected RED evidence was captured, or an explicit boundary exception is documented.

## Review Package

Show the user:

- Spec, User Story, requirement, scenario, task, track, and test IDs.
- Gate scope and the production layer this decision will authorize.
- Exact test files and changed lines.
- Given/When/Then explanation of each test.
- BDD `Given/When/Then` behavior naming and the executable `// Arrange`, `// Act`, and `// Assert` sections, with exactly one physical-line SUT/use-case/public-boundary call in `// Act` and every assertion in `// Assert`.
- Commands executed and concise failure output.
- Why each failure demonstrates the intended missing behavior.
- Assertions, edge cases, happy path, and state/resource side effects covered.
- Hand-written stubs, fakes, spies, mocks, fixtures, local resources, and isolation strategy.
- The layer's `standalone_test_command`, `depends_on_test_layer: none`, owned mutable state, setup/cleanup, and proof that no earlier test layer prepared its process or state.
- For application scope, confirmation that doubles replace only outgoing application ports and contain no assertions or business rules.
- For `integration_scope: infrastructure`, confirmation that the test invokes the Application use case, uses the real adapter and owned local resource, and simulates only third-party APIs with WireMock or a small hand-written HTTP stub.
- Confirmation that no production file was changed before RED.
- Parallel-track ownership and files that must remain untouched.
- The concise `red-green-refactor.md` entry for this cycle, including:
  - `RED`: test IDs, command, expected failure, and why the failure proves the missing behavior.
  - `GREEN`: the minimal production change and the passing command/result (complete after implementation).
  - `REFACTOR`: behavior-preserving cleanup, design/architecture checks, and the final green result before final validation.

## Gate 3-<SCOPE>: Approve Test Evidence Before That Scope GREEN

Ask explicitly:

```text
The <domain|application|boundary> test evidence is written and RED.
May I modify production code for this scope and continue to Green?
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

- Scoped Gate 3 name and request timestamp or history reference.
- User decision and any requested test changes.
- Test IDs, commands, expected failure reason, final RED result, and prior layer-gate status.
- Standalone clean-state result plus combined-suite result; record shuffle/repeat evidence when risk requires it.
- The report path and `RED` section from `red-green-refactor.md`.
- Boundary exceptions and residual risk.

## Exit

After explicit approval, return to the owning SDD workflow at Green. This workflow does not implement production code and does not redefine the User Story or acceptance criteria.
