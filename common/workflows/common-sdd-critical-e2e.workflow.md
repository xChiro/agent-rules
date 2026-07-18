---
workflow_id: WORKFLOW-COMMON_SDD_CRITICAL_E2E_WORKFLOW
trigger: manual
description: "Gherkin-backed end-to-end verification for critical user journeys and public trust boundaries."
---

# Common SDD Critical E2E Workflow

Use this workflow for every L3 change. Any spec that identifies a critical journey—login, authorization, tenant isolation, payments, destructive operations, migrations, data recovery, or a multi-step workflow whose failure materially harms users—must classify that scope as at least L3 before execution.

## Contract

- The User Story and `acceptance.feature` define the business-readable behavior.
- Each critical scenario maps to a stable `SCN-*` and one or more `TEST-*` executable tests.
- The test enters through the real actor-visible or public boundary selected by the repository. Execution technology belongs in the language/service adapter, not in the business scenario.
- Reuse the repository's established acceptance runner; do not introduce a second execution model for the same behavior.
- Gherkin is the acceptance contract; `spec.md` remains the source of approved intent and `verification.md` records evidence.

## Phase 1 — Plan

Record:

- actor, journey, risk level, and trust boundaries;
- Given/When/Then scenario IDs and non-regression scenarios;
- actor, locale, tenant, identity, and business-state fixtures;
- local or test environment dependencies and isolation;
- cleanup, evidence capture, sensitive-data redaction, timeout, and retry policy.

## Phase 2 — RED

- Apply `RULE-COMMON_TEST_ASSERTION_STRUCTURE`; keep all assertion APIs in the test's `// Assert` section.
- Apply `RULE-COMMON_TEST_LAYER_ISOLATION`; the critical boundary owns its environment and state and cannot require a unit or component test to prepare it.
- Add or update the critical Gherkin scenario after Gate 2.
- Implement the smallest executable E2E test for the scenario.
- Run it and capture a meaningful RED result before production behavior changes whenever the harness supports it.
- If the test cannot be RED first because the existing journey is already green, record a characterization baseline and explain the exception.

## Phase 3 — GREEN And Verification

- Run the real flow through the public boundary.
- Assert user-visible outcome, authorization/tenant behavior, persisted side effects, emitted events, and recovery behavior when relevant.
- Do not assert private structure or interaction mechanics; assert the actor-visible outcome and business invariants.
- Run the selected critical scenarios in the repository's established integration or browser acceptance runner after unit, boundary integration, security, and mutation evidence.
- Record results, artifacts, environment, repeat count, and residual risk in `verification.md`.

This gate does not create a third backend runtime suite or CI test job. Backend critical scenarios remain in the canonical `integration` suite; a browser acceptance runner remains a separate quality gate only when the repository already owns that execution model.

## Failure Policy

- A flaky E2E test is not silently retried into success; classify the cause and protect it with deterministic setup or a documented exception.
- Never weaken a scenario, remove an assertion, or broaden authorization to make the suite green.
- Critical E2E failures block final validation.
