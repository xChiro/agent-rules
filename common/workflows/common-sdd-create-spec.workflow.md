---
workflow_id: WORKFLOW-COMMON_SDD_CREATE_SPEC_WORKFLOW
trigger: manual
description: Create a new SDD feature spec with requirements, acceptance scenarios, plan, tasks, traceability, verification, and history.
---

# Common SDD Create Spec Workflow

Use this workflow before implementing a new feature, significant behavior change, public contract, or risky refactor. For a reported defect, use `common-sdd-fix-bug.workflow.md` first so the defect is reproduced and classified before selecting a new or existing spec.

## Phase 0: Show The Proposed SDD Plan And Ask To Write

Inspect the repository without creating or modifying spec files. Present:

- Proposed `specs/features/<number>-<behavior-slug>/` path.
- Every required and optional file to create.
- `code-quality-review.md` and `security-review.md` are created with proposed status and their final-gate routing.
- Proposed IDs, User Stories, requirements, and summarized Given/When/Then scenarios.
- Proposed human-readable `change-summary.md` with every planned code, test, infrastructure, CI, documentation, contract, migration, and operational change.
- Architecture scope, work types, test strategy, and quality gates.
- Proposed tasks, including which are sequential and which are parallel.
- Proposed tracks, task ownership, dependencies, `can_run_with`, merge order, and `max_parallel_agents`.
- Proposed workflow routing: primary workflow for each SDD phase and task, supporting workflow IDs, and the reason each workflow is the most specific applicable procedure.
- Proposed BDD route: `WORKFLOW-COMMON_BDD_SPECIFICATION_WORKFLOW` for value, conversation, examples, business-language scenarios, executable acceptance evidence, and living documentation.
- Proposed boundary routes when applicable: `WORKFLOW-COMMON_REST_API_DESIGN_WORKFLOW`, `WORKFLOW-COMMON_AWS_LAMBDA_REST_WORKFLOW`, `WORKFLOW-COMMON_AWS_SNS_PUBLISH_WORKFLOW`, `WORKFLOW-COMMON_AWS_SQS_CONSUMER_WORKFLOW`, and the selected Go/C#/React adapter workflow. Attach each route to the task phase that owns it.
- Proposed completion route: `WORKFLOW-COMMON_SDD_COMPLETE_SPEC_WORKFLOW`, snapshot path under `specs/context/ai-snapshots/`, and destination `specs/features/completed/<number>-<slug>/`.
- Proposed mandatory code-quality route: `WORKFLOW-COMMON_SDD_CODE_QUALITY_GATE_WORKFLOW`, with `code-quality-review.md` covering every created or modified file and controlled refactoring when needed.
- Proposed mandatory security route: `WORKFLOW-COMMON_SDD_SECURITY_GATE_WORKFLOW`, with `security_role: oauth-client | resource-server | identity-server | none` and a `security-review.md` artifact.
- Proposed mandatory coverage route: `WORKFLOW-COMMON_SDD_COVERAGE_GATE_WORKFLOW`; production scopes require a minimum project-wide result of `>= 90%` and no affected-scope regression.
- Proposed continuity route: `WORKFLOW-COMMON_SDD_CONTEXT_CHECKPOINT_WORKFLOW`, with `handoffs/context-checkpoints/` created automatically if context reaches 60%.

Ask explicitly: may these folders and artifacts be created? Do not continue to Phase 1 without approval.

## Phase 1: Locate Or Create The Spec Folder

After Gate 1 approval:

1. Inspect `specs/` and confirm the next stable feature number.
2. Create `specs/features/<number>-<behavior-slug>/`.
3. If the project has no `specs/`, create the minimum structure from `common-sdd-spec-structure.md`.
4. Assign `FEAT-*`, `SPEC-*`, and `ART-*` IDs for the spec folder and each artifact file.
5. Assign `ART-<feature>-CHANGE-SUMMARY` to `change-summary.md` and `CHG-<feature>-*` IDs to every planned change row.
6. Do not put specs in `.windsurf`, `.codex`, issue comments, chat history, or temporary notes.

Minimum files:

```text
spec.md
change-summary.md
acceptance.feature
plan.md
security-review.md
tasks.md
workflow-routing.md
parallel-tracks.md
traceability.yaml
verification.md
history/YYYY-MM-DD-created.md
```

Add `invariants.md`, `research.md`, `data-model.md`, `contracts/`, or `decisions/` only when they reduce ambiguity or drive verification.

## Phase 2: Capture User Stories

In `spec.md`, define:

- `feature_id`, `spec_id`, and `artifact_id` metadata.
- `status: active` and `change_summary_artifact_id: ART-<feature>-CHANGE-SUMMARY`.
- `workflow_routing_artifact_id: ART-<feature>-WORKFLOW-ROUTING`.
- Objective.
- Actors.
- User Stories with stable IDs:
  - `As a <actor>,`
  - `I want <capability>,`
  - `so that <business outcome>.`
- Functional requirements derived from the User Stories, with stable IDs.
- Out-of-scope.
- Edge cases.
- Failure behavior.
- Non-functional requirements when relevant.
- `[NEEDS CLARIFICATION]` markers for unresolved decisions.

Keep the spec behavior-oriented. Do not replace User Stories with technical tasks. Do not choose frameworks, tables, or class names unless they are already hard constraints.

## Phase 3: Write BDD Acceptance Scenarios

Invoke `WORKFLOW-COMMON_BDD_SPECIFICATION_WORKFLOW`. Write `acceptance.feature` from business value and concrete examples before planning implementation. Keep scenarios concise, actor/business-readable, stable-ID linked, and free of delivery mechanics or implementation structure. If executable acceptance evidence is unavailable, record the automation gap and closest verification path in `verification.md`.

## Phase 4: Resolve Spec Content

Ensure the written draft clearly contains:

- Requirements.
- Acceptance scenarios.
- Out-of-scope.
- Open questions.
- Risky tradeoffs.

Keep unresolved decisions marked `[NEEDS CLARIFICATION]`. They must be shown at Gate 2 and resolved before RED when they affect implementation.

## Phase 5: Technical Plan

In `plan.md`, map behavior to implementation strategy:

- Architecture boundaries.
- SOLID, Clean Architecture, CQRS, and project-specific architecture constraints that apply.
- Domain/application ownership.
- Public contracts and compatibility.
- Data model or migrations.
- Acceptance harness or public boundary.
- Unit and HTTP integration checks for backends; component/page checks for frontends; architecture, performance, and security gates when relevant.
- Observability and operational validation.
- Rollback approach when relevant.
- Workflow routing: which workflow governs spec creation, implementation, RED review, verification, documentation, and convergence.
- Completion routing: final approval, move to `specs/features/completed/`, snapshot, and snapshot index update.
- Coverage routing: command, complete project scope, affected baseline/current scope, expected `>= 90%` threshold, exclusions, and report location.
- Security routing: declared role, changed trust boundaries, OAuth/OIDC or web-session evidence when applicable, security commands, findings, and exception owner.
- Code-quality routing: reviewed file manifest, naming/size/ownership checks, Clean Code/SOLID/Clean Architecture/CQRS checks, refactor workflow, and quality evidence.
- Boundary workflow routing: for REST, Lambda, SNS, SQS, and React REST-client work, name the common boundary workflow, language adapter, invocation phase, expected RED/GREEN evidence, and the IaC/contract verification command.

Keep the plan as a strategy, not a code dump.

In `change-summary.md`, create the human-readable execution list. Every planned code, test, infrastructure, CI, documentation, contract, migration, and operational change must have a `CHG-*` row with affected files/modules, workflow, track, sequence, and verification evidence.

## Phase 6: Small Tasks

In `tasks.md`, create small ordered tasks.

Each task should include:

- Task ID.
- Artifact ID for the file or section that owns the task definition.
- User Story ID.
- Requirement ID.
- Scenario ID.
- Test ID for the acceptance or unit-level test it creates or updates.
- `CHG-*` ID for the human-readable change row in `change-summary.md`.
- Expected test or verification.
- Primary `workflow_id` and `workflow_phase`.
- Supporting `workflow_id` values when the task needs a focused common, language, infrastructure, CI, documentation, or review procedure.
- Dependency on earlier tasks.
- Done condition.
- Canonical `work_type` for backend tasks.
- `track_id`.
- `parallelizable: true|false`.
- `depends_on` and `blocked_by` task IDs.
- `can_run_with` task IDs when parallel execution is safe.
- Explicit file/module/contract ownership.
- One concrete outcome, `done_when`, `verification_command`, and `next_step`; split tasks that cross unrelated behavior partitions or boundaries.

First tasks must be BDD acceptance and unit-level ATDD-style test-code tasks. Production implementation tasks come after test tasks.

No production task is valid unless an earlier task creates or updates a failing unit/domain/application/component test with a `TEST-*` ID.

Split tasks until each task changes one scenario, rule, boundary, adapter, or behavior-preserving refactor.

Do not schedule a task that requires multiple independent implementation steps. Finish and verify the current microtask before starting the next one. If context reaches 60%, invoke `common-sdd-context-checkpoint.workflow.md` and leave the spec ready for another AI.

Update the corresponding `CHG-*` rows when tasks are split, reordered, assigned to tracks, or given a different workflow.

## Phase 7: Parallel Tracks

In `parallel-tracks.md`, define:

- Feature/spec/artifact metadata.
- `max_parallel_agents`.
- Track IDs.
- Agent slot per track.
- Tasks owned by each track.
- Files, modules, contracts, or spec sections owned by each track.
- Dependencies between tracks.
- Must-not-touch boundaries.
- Merge order and verification after each merge.
- A parallel execution wave for tasks that may start together.
- Sequential tasks that gate or converge those waves.

Default to `max_parallel_agents: 1`. Increase it only when tracks are independent and can merge sequentially without conflicting file ownership.

Do not leave parallelism implicit. When no tasks are safely parallel, record `parallelizable: false`, explain the dependency, and keep `max_parallel_agents: 1`. When tasks are parallel, list the exact simultaneous task IDs and agent slots.

## Phase 8: Traceability

In `traceability.yaml`, connect:

- Artifact IDs to file paths and contained IDs.
- User Stories to requirements.
- Requirements to scenarios.
- Scenarios to tasks.
- Tasks to parallel tracks.
- Tasks to execution waves and agent slots.
- Tasks to tests.
- Phases and tasks to primary and supporting workflow IDs.
- Test IDs to concrete test files.
- Requirements to contracts, metrics, and history entries when relevant.

Any requirement without a scenario or verification method is incomplete.

## Phase 9: Initial Verification Notes

In `verification.md`, record:

- Feature/spec/artifact metadata.
- Workflow routing artifact and selected workflow IDs.
- Spec review status.
- Acceptance tests to create.
- Unit-level ATDD-style test code to create before production code.
- Gates expected.
- Manual QA needed.
- Current unverified scope.
- Current microtask, exact next task, and context checkpoint status.

## Phase 10: History Entry

Create `history/YYYY-MM-DD-created.md` with:

- Feature/spec/artifact metadata.
- Reason for the spec.
- User Stories added.
- Requirements added.
- Scenarios added.
- Parallel track decision and maximum agent count.
- Workflow routing decision: primary and supporting workflow IDs by phase/task.
- Verification requested.
- Known assumptions.
- Expected implementation impact.

The history entry is append-only and should not be rewritten after implementation starts except for typo fixes.

## Phase 11: Show The Created Spec And Ask To Start RED

After all approved folders and files exist, show:

- Files created.
- Human-readable `change-summary.md` with all planned changes and affected files.
- Completion workflow, snapshot path, and `specs/features/completed/` destination.
- Coverage workflow, command, scope, measured result, threshold, and exclusions.
- Final User Stories and Given/When/Then scenarios.
- Sequential and parallel task table with task IDs, track IDs, dependencies, ownership, execution waves, and `max_parallel_agents`.
- Workflow routing table with the primary and supporting workflow for every phase and task.
- Traceability summary.
- First acceptance/HTTP/component RED test and first focused unit RED test to be written.
- Clarifications, assumptions, risks, and unverified scope.

Ask explicitly: may implementation continue to the RED phase? Do not write or run test code until the user approves.

## Phase 12: Gate 3 Before Green

After the acceptance/HTTP/component test and focused unit-level test are written and confirmed RED, invoke `common-sdd-review-test-evidence.workflow.md`.

Show the actual test files, IDs, commands, failures, assertions, fixtures, isolation, and confirmation that production files are unchanged. Ask explicitly for approval to continue to Green. Record the decision in `verification.md`.

## Done

The spec is ready for implementation only when:

- No unresolved `[NEEDS CLARIFICATION]` blocks remain for implementation-critical behavior.
- User Stories exist and each has at least one BDD Given/When/Then scenario.
- Every spec artifact has an `ART-*` ID and is listed in `traceability.yaml`.
- Tasks start with acceptance and unit-level ATDD-style tests.
- Every production implementation task depends on a prior failing unit-level `TEST-*`.
- Include a final `documentation` task using `WORKFLOW-COMMON_SDD_UPDATE_DOCUMENTATION_WORKFLOW`, or record `no_documentation_change_reason` in `spec.md` and `verification.md`.
- `parallel-tracks.md` defines maximum concurrent agents and ownership boundaries.
- Traceability links artifacts, User Stories, requirements, scenarios, tasks, tracks, and tests.
- Gate 1, Gate 2, and Gate 3 approvals are recorded in `verification.md`.
- Gate 1 approval was received before creating folders or artifacts.
- Every task explicitly states whether it is parallelizable and which track owns it.
- Gate 2 approval was received before creating or running RED tests.
- Gate 3 approval was received after RED evidence and before editing production code.
- Documentation was updated through the routed documentation workflow, or `no_documentation_change_reason` is recorded.
- Every phase and task has a primary `workflow_id`; supporting workflows are explicit when needed.
- Completion uses `WORKFLOW-COMMON_SDD_COMPLETE_SPEC_WORKFLOW`; spec creation alone does not move the feature to `specs/features/completed/`.
- Completion is blocked until `WORKFLOW-COMMON_SDD_COVERAGE_GATE_WORKFLOW` records its final result; production scopes must record `>= 90%` coverage and docs-only specs must record `coverage_scope: none`.
- If context reaches 60%, completion of the current AI turn is blocked until `WORKFLOW-COMMON_SDD_CONTEXT_CHECKPOINT_WORKFLOW` leaves an append-only handoff and an explicit resume action in the active spec.
- Completion is blocked until `WORKFLOW-COMMON_SDD_SECURITY_GATE_WORKFLOW` records a passed review with no unresolved findings.
- Completion is blocked until `WORKFLOW-COMMON_SDD_CODE_QUALITY_GATE_WORKFLOW` records a passed review for every created/modified file.
