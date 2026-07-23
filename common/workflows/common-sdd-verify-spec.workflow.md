---
workflow_id: WORKFLOW-COMMON_SDD_VERIFY_SPEC_WORKFLOW
trigger: manual
description: "Final evidence review for a living SDD specification."
---

# Common SDD Verify Spec Workflow

Use this workflow after implementation, refactoring, testing, documentation, and risk-selected quality checks have converged. It verifies that the specification, implementation, tests, and evidence describe the same behavior. The specification remains in its stable project path; verification never depends on renaming or moving directories.

## SDD Model

Spec-Driven Development is a living contract:

```text
Constitution -> Specify -> Clarify -> Plan -> Tasks -> Implement -> Validate -> Evolve
```

The spec is the durable source of intent. Code, tests, architecture decisions, and documentation provide executable or reviewable evidence for that intent. A folder name is not evidence and does not represent lifecycle state.

## Preconditions

Read the active feature folder and confirm:

- `spec.md`, `acceptance.feature`, `plan.md`, `tasks.md`, `workflow-routing.md`, `traceability.yaml`, `verification.md`, `change-summary.md`, and append-only history agree.
- User Stories, requirements, invariants, scenarios, contracts, and out-of-scope decisions are covered or explicitly marked `not_affected`.
- RED/GREEN/REFACTOR evidence exists for every production behavior partition, with characterization evidence recorded for approved exceptions.
- Affected Domain, Application, Boundary, Infrastructure, Interface, and Composition evidence has a standalone command and deterministic setup/cleanup where applicable.
- Documentation, clean-up, security, coverage, mutation, and critical journey checks have the status required by the risk classification.
- No unresolved spec adjustment, blocker, security finding, or unowned exception remains.
- Every in-scope task is done. Remaining out-of-scope work is moved to a separately identified follow-up spec; an open or blocked in-scope task prevents `verified`.

## Phase 1: Validate The Evidence

1. Run `WORKFLOW-COMMON_SDD_VALIDATE_CHANGE_WORKFLOW` and record the exact command, risk, scope, and result.
2. Run the unit suite, the applicable `integration/http` and `integration/infrastructure` scopes of the integration suite, and the E2E, mutation, architecture, security, and documentation checks selected by the spec. Do not invent a third backend runtime suite.
3. Compare the final diff with the approved intent. If behavior, architecture, contract, risk, or scope changed, stop and route the change through `WORKFLOW-COMMON_SDD_SPEC_WORKFLOW`.
4. Confirm that every in-scope task is `done`. Move deferred scope to a named follow-up spec with explicit ownership; do not silently delete unfinished work or mark a blocked task as verified.

## Phase 2: Human Verification Review

Show the user:

- Feature/spec IDs and the stable active path.
- User Stories, acceptance scenarios, actual implementation, tests, and verification commands.
- Architecture and dependency-direction evidence, including Clean Architecture/CQRS boundaries when applicable.
- Clean-up, security, coverage, mutation, critical-journey, documentation, and residual-risk results.
- Confirmation that no in-scope task or blocker remains, plus approved exceptions, residual risk, and linked follow-up specs.

Ask explicitly:

```text
The SDD evidence is aligned with the implementation. May I set the specification status to verified and record the validation result?
```

Do not change the specification status to `verified` before this review and explicit approval. Non-SDD L0 catalog work does not create or verify a feature spec.

## Phase 3: Record The Result

After approval:

- Set `spec.md` and `change-summary.md` to `status: verified`.
- Set `verification.md` to `validation_status: passed` and record the exact evidence, date, reviewer, and residual risk.
- Mark every in-scope task as `[x]` or `status: done`; link separately owned follow-up work explicitly.
- Append a history entry for the validation decision. Never rewrite earlier history.
- Keep the spec at `specs/features/<number>-<slug>-verified/`; the folder suffix must match the final `status: verified`.
- Rename the feature folder to its final `-verified` suffix as part of the approved status transition; do not create a lifecycle artifact outside the spec.

An AI context checkpoint remains an operational handoff. A project may keep an optional context summary for onboarding, but it is never a lifecycle marker or a substitute for the active spec and verification evidence.

## Alternative Outcomes

- `implemented`: code and focused tests exist, but one or more validation gates remain open.
- `verified`: the evidence was reviewed and matches the approved intent.
- `superseded`: a newer approved spec replaces this intent; link both specs and preserve history.
- `retired`: the behavior is intentionally removed or no longer maintained; record the decision and impact.

## Done

- The `-verified` spec path remains discoverable and all references resolve to it.
- The implementation, tests, architecture, documentation, and verification evidence agree.
- The lifecycle status is explicit and supported by recorded evidence.
- No unresolved in-scope work remains; residual risk and follow-up ownership are visible.
