---
workflow_id: WORKFLOW-COMMON_SDD_COMPLETE_SPEC_WORKFLOW
trigger: manual
description: Verify, snapshot, and move a completed SDD feature into the completed spec catalog.
---

# Common SDD Complete Spec Workflow

Use this workflow only after implementation, refactoring, verification, documentation, and convergence are complete. Creating a spec does not complete the feature; completion is a separate, traceable action.

## Phase 1: Prepare Completion Review

Read the active feature folder and verify:

- `spec.md`, `change-summary.md`, `acceptance.feature`, `plan.md`, `code-quality-review.md`, `security-review.md`, `tasks.md`, `workflow-routing.md`, `parallel-tracks.md`, `traceability.yaml`, `verification.md`, and history agree.
- User Stories and BDD scenarios are covered.
- Acceptance/public-boundary tests and unit-level ATDD tests were RED before production code and GREEN after.
- Gate 1, Gate 2, and Gate 3 evidence is recorded.
- `common-sdd-code-quality-gate.workflow.md` was executed after Green, every created/modified file was reviewed, and required refactors were completed through the refactor lifecycle.
- `common-sdd-security-gate.workflow.md` was executed after Green and Refactor, `security-review.md` exists, and no unresolved Critical/High security findings remain.
- `common-sdd-coverage-gate.workflow.md` was executed after Green and the complete project production scope reached at least 90% coverage with no affected-scope regression when production code is in scope.
- Required `common-sdd-mutation-gate.workflow.md` and `common-sdd-critical-e2e.workflow.md` evidence is present for the classified risk level.
- If context checkpoints exist, `handoffs/latest-context-handoff.md` points to the latest append-only handoff and its resume work is either complete or explicitly represented in the final tasks/verification.
- Architecture, CI, security, performance, documentation, and operational gates are passed or explicitly justified.
- All tasks are complete or have an approved follow-up spec.
- No `spec-adjustment-request` remains proposed, unresolved, or hidden in chat/context.
- The final `change-summary.md` lists actual changes, deviations, tests, documentation, residual risks, and rollback notes.

## Phase 2: Mandatory Code Quality Gate

Invoke `common-sdd-code-quality-gate.workflow.md` after implementation, relevant tests, and the initial refactor pass, and before the final security and coverage gates.

The gate must review every file created or modified by the spec, including production code, tests, contracts, configuration, CI/IaC, documentation, generated files, and scripts. It must record `code-quality-review.md`, file scope, names, limits, ownership, Clean Code/SOLID/Clean Architecture/CQRS checks, findings, refactors, exceptions, and the human quality decision.

If a behavior-preserving refactor is needed, invoke `common-sdd-refactor-lifecycle.workflow.md` and the language refactor adapter. Do not edit production code directly from the quality gate. Do not request Gate 4 until the quality review passes.

## Phase 3: Mandatory Security Gate

Invoke `common-sdd-security-gate.workflow.md` after implementation, refactoring, relevant tests, and documentation convergence, and before Gate 4.

The gate must review the final diff, changed trust boundaries, secrets, dependencies, authorization, identity role, OAuth/OIDC behavior, web session cookies, CSRF/CORS, and security evidence. It must record `security_role: oauth-client | resource-server | identity-server | none` in `security-review.md`.

If the scope is `none`, the workflow still records why security impact is unchanged. Do not request Gate 4 with unavailable security evidence, unresolved Critical/High findings, or unowned exceptions.

## Phase 4: Mandatory Coverage Gate

Invoke `common-sdd-coverage-gate.workflow.md` for every completed spec after all implementation, refactoring, and relevant tests are green. If the spec has no production code scope, record `coverage_scope: none`, prove that no production files changed, and document why a percentage is not applicable; do not silently skip the gate.

When production code is in scope, the gate must measure the complete project production scope at `>= 90%` and confirm the affected scope did not regress. Record the exact command, tool/version, project percentage, affected baseline/current percentage, exclusions, and report path in `verification.md` and `change-summary.md`.

If coverage is below 90%, do not request Gate 4. Return to the RED/test-review flow for meaningful tests and repeat the coverage gate.

## Phase 5: Human Gate 4 - Approve Completion

Show the user:

- Feature/spec IDs and current active path.
- Final human change summary.
- Completed tasks, tests, workflows, documentation, and verification evidence.
- Code-quality review status, complete file scope, limits, names, findings, refactors, exceptions, and residual risk.
- Security review status, declared role, trust boundaries, findings, remediations, exceptions, and residual risk.
- Coverage command, measured percentage, affected scope, threshold, and exclusions.
- Remaining risk and any follow-up work that will stay outside this spec.
- Any context checkpoint path and confirmation that no unfinished task is hidden in the prior AI context.
- Proposed snapshot path and destination under `specs/features/completed/<number>-<slug>/`.

Ask explicitly:

```text
The SDD is verified. May I mark it completed, create the AI context snapshot, update the snapshot index, and move the feature folder to specs/features/completed/<number>-<slug>/?
```

Do not move or mark the spec completed before approval.

## Phase 6: Finalize The Human Summary

Update `change-summary.md`:

- `status: verified`.
- Actual files created, modified, deleted, or moved.
- Actual workflow IDs used.
- Test commands and results.
- Documentation and operational updates.
- Deviations from the approved plan.
- Residual risk and rollback/follow-up notes.

Update `spec.md` status to `completed` and add the completion artifact metadata.

## Phase 7: Create The AI Context Snapshot

Create:

```text
specs/context/ai-snapshots/YYYY-MM-DD-<feature-slug>-snapshot.md
```

The snapshot must include:

- `snapshot_id: SNAP-YYYYMMDD-<sequence>`.
- Source feature/spec IDs and source commit when available.
- Completed User Stories, requirements, invariants, public contracts, and architecture boundaries.
- Final file/module map and workflow IDs used.
- Test suites, commands, verification status, and operational constraints.
- Known non-goals, residual risks, and follow-up specs.
- Links to the moved completed spec and relevant decisions.

Snapshots are concise, human-readable, safe for agent context, and free of secrets, credentials, private endpoints, and generated noise. They are derived context, not a replacement for the completed spec or append-only history.

## Phase 8: Move And Index

1. Confirm the active folder exists under `specs/features/<number>-<slug>/`.
2. Create `specs/features/completed/` when missing and confirm `specs/features/completed/<number>-<slug>/` does not already exist. If it does, stop and reconcile the collision; do not overwrite either spec.
3. Move the active folder with Git so history remains visible:
   `git mv specs/features/<number>-<slug> specs/features/completed/<number>-<slug>`.
4. Update `specs/context/ai-snapshots/index.md` with the snapshot ID, feature ID, completed spec path, date, and short context summary.
5. Update repository maps or documentation links that point to the active path.
6. Keep all completed specs under the shared `specs/features/completed/` catalog.
7. Do not rewrite old history entries. If a repository has a legacy completed layout, migrate each child once with Git and preserve the history before removing obsolete paths.

Use this index shape:

```markdown
# AI Context Snapshots

## Latest

- Snapshot: `SNAP-20260710-001`
- Feature: `FEAT-0001`
- Spec: `SPEC-0001`
- Path: `specs/context/ai-snapshots/2026-07-10-squad-radio-snapshot.md`
- Completed spec: `specs/features/completed/0001-squad-radio/`
- Generated: `2026-07-10`
```

## Phase 9: Verify Completion

- The active path no longer exists.
- The completed path exists under `specs/features/completed/` and contains all spec artifacts.
- The snapshot and snapshot index exist and contain no secrets.
- `code-quality-review.md` has a passed decision and its evidence is present in `verification.md` and `change-summary.md`.
- `security-review.md` has a passed decision and its evidence is present in `verification.md` and `change-summary.md`.
- Links, artifact IDs, workflow IDs, and traceability resolve.
- The completed feature is discoverable from the snapshot index and repository documentation.
- `git diff --check` and the repository's documentation checks pass.

## Done

- Gate 4 approval is recorded in the final history or `verification.md`.
- The feature is under `specs/features/completed/<number>-<slug>/` with `status: completed`.
- `change-summary.md` contains the actual result.
- An AI context snapshot and index entry exist.
- No production code or specification intent was changed during the move.
