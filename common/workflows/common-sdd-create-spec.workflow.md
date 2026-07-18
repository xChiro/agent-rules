---
workflow_id: WORKFLOW-COMMON_SDD_CREATE_SPEC_WORKFLOW
trigger: manual
description: "Create a new SDD feature spec with requirements, acceptance scenarios, plan, tasks, traceability, verification, and history."
---

# Common SDD Create Spec Workflow

Use this workflow before implementing a new feature, significant behavior change, public contract, or risky refactor. For a reported defect, use `common-sdd-fix-bug.workflow.md` first so the defect is reproduced and classified before selecting a new or existing spec.

## Phase 0: Show The Proposed SDD Plan And Ask To Write

Inspect the repository without creating or modifying spec files. Present:

- Proposed `specs/features/<number>-<behavior-slug>/` path.
- Every required and optional file to create.
- `code-quality-review.md` and `security-review.md` are created with proposed status and their final-gate routing.
- Proposed IDs and human-readable titles for every SDD element, plus User Stories, requirements, and summarized Given/When/Then scenarios.
- Proposed human-readable `change-summary.md` with every planned code, test, infrastructure, CI, documentation, contract, migration, and operational change.
- Architecture scope, work types, test strategy, and quality gates.
- Proposed tasks, including which are sequential and which are parallel.
- Proposed tracks, task ownership, dependencies, `can_run_with`, merge order, and `max_parallel_agents`.
- Proposed workflow routing: primary workflow for each SDD phase and task, supporting workflow IDs, and the reason each workflow is the most specific applicable procedure.
- Proposed BDD route: `WORKFLOW-COMMON_BDD_SPECIFICATION_WORKFLOW` for value, conversation, examples, business-language scenarios, the later executable acceptance mapping, and living documentation.
- Proposed domain model/business-policy map: capability or bounded context, ubiquitous language, policy owner, invariants, state transitions, domain events, and counterexamples; derive technical layers from this map.
- Proposed inside-out layer scope and gates from `RULE-COMMON_INSIDE_OUT_DEVELOPMENT`; domain/application test and production tasks precede boundary, infrastructure, interface, and composition production tasks.
- Proposed boundary routes when applicable: `WORKFLOW-COMMON_REST_API_DESIGN_WORKFLOW`, `WORKFLOW-COMMON_AWS_LAMBDA_REST_WORKFLOW`, `WORKFLOW-COMMON_AWS_SNS_PUBLISH_WORKFLOW`, `WORKFLOW-COMMON_AWS_SQS_CONSUMER_WORKFLOW`, and the selected Go/C#/React adapter workflow. Attach each route to the task phase that owns it.
- Proposed validation route: `WORKFLOW-COMMON_SDD_VERIFY_SPEC_WORKFLOW`, recording `status: verified` in the stable feature path.
- Proposed mandatory clean-up route: `WORKFLOW-COMMON_SDD_CLEAN_UP_GATE_WORKFLOW`, with `code-quality-review.md` covering every created or modified file, the strict <150-line maintained-file check for source, tests, configuration, CI, and scripts, and controlled Fowler refactoring.
- Proposed mandatory security route: `WORKFLOW-COMMON_SDD_SECURITY_GATE_WORKFLOW`, with `security_role: oauth-client | resource-server | identity-server | none` and a `security-review.md` artifact.
- Proposed mandatory coverage route: `WORKFLOW-COMMON_SDD_COVERAGE_GATE_WORKFLOW`; production scopes require a minimum project-wide result of `>= 90%` and no affected-scope regression.
- Proposed continuity route: `WORKFLOW-COMMON_SDD_CONTEXT_CHECKPOINT_WORKFLOW`, with `handoffs/context-checkpoints/` created automatically if context reaches 60%.
- Proposed documentation gate: `RULE-COMMON_SDD_DOCUMENTATION_GATE` with a final `documentation` task routed to `WORKFLOW-COMMON_SDD_UPDATE_DOCUMENTATION_WORKFLOW`; list the expected project/SDD documentation surfaces or the evidence-based no-change outcome.

Ask explicitly: may these folders and artifacts be created? Do not continue to Phase 1 without approval.

## Phase 1: Locate Or Create The Spec Folder

After Gate 1 approval:

1. Inspect `specs/` and confirm the next stable feature number.
2. Create `specs/features/<number>-<behavior-slug>/`.
3. If the project has no `specs/`, create the minimum structure from `common-sdd-spec-structure.md`.
4. Assign `FEAT-*`, `SPEC-*`, and `ART-*` IDs plus separate human-readable titles for the spec folder and each artifact file.
5. Assign `ART-<feature>-CHANGE-SUMMARY` and an artifact title to `change-summary.md`; assign `CHG-<feature>-*` IDs and action-oriented titles to every planned change row.
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

Add `invariants.md` whenever domain behavior is affected. Add `research.md`, `data-model.md`, `contracts/`, or `decisions/` when they reduce ambiguity or drive verification. If `domain: not_affected`, keep the evidence-based reason in `spec.md` and `plan.md` instead of creating an empty invariant artifact.

## Phase 2: Capture User Stories

In `spec.md`, define:

- `feature_id`, `spec_id`, and `artifact_id` metadata.
- `feature_title`, `spec_title`, and `artifact_title` metadata using the canonical title contract in `common-sdd-spec-structure.md`.
- `status: active` and `change_summary_artifact_id: ART-<feature>-CHANGE-SUMMARY`.
- `workflow_routing_artifact_id: ART-<feature>-WORKFLOW-ROUTING`.
- Objective.
- Actors.
- User Stories with stable IDs:
  - a concise behavior-oriented title paired with each ID;
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

Invoke `WORKFLOW-COMMON_BDD_SPECIFICATION_WORKFLOW`. Write `acceptance.feature` from business value and concrete examples before planning implementation. Keep scenarios concise, actor/business-readable, stable-ID linked, human-titled in the `Scenario`/`Scenario Outline` line, and free of delivery mechanics or implementation structure. This phase specifies acceptance; it does not create executable HTTP/message/UI test code before the core. If executable acceptance evidence will be unavailable at the boundary phase, record the automation gap and closest verification path in `verification.md`.

## Phase 4: Resolve Spec Content

Ensure the written draft clearly contains:

- Requirements.
- Acceptance scenarios.
- Out-of-scope.
- Open questions.
- Risky tradeoffs.

Keep unresolved decisions marked `[NEEDS CLARIFICATION]`. They must be shown at Gate 2 and resolved before RED when they affect implementation.

## Phase 5: Domain Model And Business Policy

Before choosing technical layers, record in `plan.md` and, when domain is affected, `invariants.md`:

- business capability and bounded context;
- ubiquitous terms and their precise meanings;
- the policy owner: aggregate, entity, value object, or domain service;
- invariants and valid/invalid state transitions;
- domain events and when they become true;
- successful examples, counterexamples, and boundary cases;
- an evidence-backed `domain: not_affected` reason when the behavior is only application orchestration or an outer concern.

Do not derive the domain model from controllers, tables, SDKs, queues, or framework types. Technical boundaries implement the business model, not the reverse.

## Phase 6: Technical Plan

In `plan.md`, map behavior to implementation strategy:

- Architecture boundaries derived from the Domain Model And Business Policy section.
- SOLID, Clean Architecture, CQRS, and project-specific architecture constraints that apply.
- Domain/application ownership.
- Business-module DI ownership and the single module entry point consumed by the executable root; for C#, list all four required layer extension methods.
- A **Development Sequence And Layer Gates** section with `affected | not_affected` status and rationale for domain, application, boundary, infrastructure, interface, and composition.
- Public contracts and compatibility.
- Data model or migrations.
- Acceptance harness or public boundary.
- Unit and integration checks for backends, naming the `http` and/or `infrastructure` scope as applicable; component/page checks for frontends; architecture, performance, and security gates when relevant.
- Observability and operational validation.
- Rollback approach when relevant.
- Workflow routing: which workflow governs spec creation, implementation, RED review, verification, documentation, convergence, and final validation.
- Validation routing: the evidence review that records `status: verified` without moving the feature folder.
- Coverage routing: command, complete project scope, affected baseline/current scope, expected `>= 90%` threshold, exclusions, and report location.
- Security routing: declared role, changed trust boundaries, OAuth/OIDC or web-session evidence when applicable, security commands, findings, and exception owner.
- Clean-up routing: reviewed file manifest, naming/size/ownership checks, Clean Code/SOLID/Clean Architecture/CQRS checks, Fowler refactor workflow, and clean-up evidence.
- Boundary workflow routing: for REST, Lambda, SNS, SQS, and React REST-client work, name the common boundary workflow, language adapter, invocation phase, expected RED/GREEN evidence, and the IaC/contract verification command.

Keep the plan as a strategy, not a code dump.

Use this machine-checkable scope block in that section, followed by the human rationale for every status:

```yaml
layer_scope:
  domain: affected | not_affected
  application: affected | not_affected
  boundary: affected | not_affected
  infrastructure: affected | not_affected
  interface: affected | not_affected
  composition: affected | not_affected
```

When Domain is not affected, add `domain_not_affected_reason: <evidence-based reason>` immediately after the block; the status alone is not a reason. If any of `infrastructure`, `interface`, or `composition` is `affected`, `boundary` is also `affected` because executable boundary evidence must drive the outer change. If all outer layers are `not_affected`, do not add a Boundary implementation task.

In `change-summary.md`, create the human-readable execution list. Every planned code, test, infrastructure, CI, documentation, contract, migration, and operational change must have a `CHG-*` row with a separate action-oriented title, affected files/modules, workflow, track, sequence, and verification evidence.

## Phase 7: Small Tasks

In `tasks.md`, create small ordered tasks.

Each task should include:

- Task ID.
- Human-readable task title in the form `T-* — <action and concrete outcome>`, also stored separately as `task_title` in structured records.
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
- `development_layer: domain | application | boundary | infrastructure | interface | composition | verification | documentation`.
- `layer_gate` opened or required.
- For test work: `test_layer`, `standalone_test_command`, `depends_on_test_layer: none`, `isolation_scope`, owned mutable state, setup, and cleanup.
- `parallelizable: true|false`.
- `depends_on` and `blocked_by` task IDs.
- `can_run_with` task IDs when parallel execution is safe.
- Explicit file/module/contract ownership.
- One concrete outcome, `done_when`, `verification_command`, and `next_step`; split tasks that cross unrelated behavior partitions or boundaries.

First tasks create abstract BDD and domain-model artifacts, then follow the affected inside-out cycles: Domain RED/GREEN/gate, Application RED/GREEN/core gate, conditional executable Boundary RED, infrastructure, interface, and module-owned composition/IaC. Application unit tests use hand-written doubles only for outgoing ports. Boundary RED/Gate 3-BOUNDARY exists only when outer production is affected; otherwise record GREEN acceptance verification and `not_affected`.

Apply `RULE-COMMON_TEST_LAYER_ISOLATION`: each Domain, Application, and Boundary test task must run alone from clean state. The development dependency between tasks must never become `depends_on_test_layer`; combined-suite commands are additional evidence only.

No production task is valid unless the same layer has prior failing evidence and the preceding inner `layer_gate` is passed or evidence-backed `not_affected`. Every outer production task depends on `LAYER-GATE-APPLICATION`.

Split tasks until each task changes one scenario, rule, boundary, adapter, or behavior-preserving refactor.

Do not schedule a task that requires multiple independent implementation steps. Finish and verify the current microtask before starting the next one. If context reaches 60%, invoke `common-sdd-context-checkpoint.workflow.md` and leave the spec ready for another AI.

Update the corresponding `CHG-*` rows when tasks are split, reordered, assigned to tracks, or given a different workflow.

## Phase 8: Parallel Tracks

In `parallel-tracks.md`, define:

- Feature/spec/artifact metadata.
- `max_parallel_agents`.
- Track IDs and responsibility-oriented track titles.
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

## Phase 9: Traceability

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
- Every defined entity ID to its canonical title; repeated references must not introduce a conflicting title.

Any requirement without a scenario or verification method is incomplete.

## Phase 10: Initial Verification Notes

In `verification.md`, record:

- Feature/spec/artifact metadata.
- Workflow routing artifact and selected workflow IDs.
- Spec review status.
- Acceptance tests to create.
- Unit-level ATDD-style test code to create before production code.
- Scoped Gate 3 decisions and every layer gate expected.
- Manual QA needed.
- Current unverified scope.
- Current microtask, exact next task, and context checkpoint status.
- The documentation gate task, workflow ID, expected surfaces, and the condition that blocks final validation until the documentation workflow runs or records `no_documentation_change_reason`.

## Phase 11: History Entry

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

## Phase 12: Show The Created Spec And Ask To Start RED

After all approved folders and files exist, show:

- Files created.
- Human-readable `change-summary.md` with all planned changes and affected files.
- Final validation workflow and the stable `specs/features/<number>-<slug>/` path.
- Coverage workflow, command, scope, measured result, threshold, and exclusions.
- Final User Stories and Given/When/Then scenarios.
- Sequential and parallel task table with task IDs, track IDs, dependencies, ownership, execution waves, and `max_parallel_agents`.
- Human-readable titles beside every feature, spec, story, requirement, scenario, task, track, test, change, gate/review, artifact, and handoff ID shown for approval.
- Workflow routing table with the primary and supporting workflow for every phase and task.
- Traceability summary.
- First domain/application unit RED, hand-written test-double plan, and later acceptance/HTTP/message/component Boundary RED when outer production is affected or GREEN `not_affected` evidence otherwise.
- Standalone command, owned state, setup/cleanup, and `depends_on_test_layer: none` for every affected test layer.
- Clarifications, assumptions, risks, and unverified scope.

Ask explicitly: may implementation continue to the RED phase? Do not write or run test code until the user approves.

## Phase 13: Scoped Gate 3 Before Each GREEN

Invoke `common-sdd-review-test-evidence.workflow.md` after each affected RED and before that layer's production code: Gate 3-DOMAIN, Gate 3-APPLICATION, then Gate 3-BOUNDARY after the core gate only when outer production is affected.

Show the actual test files, IDs, commands, failures, assertions, fixtures/doubles, prior layer gates, isolation, and confirmation that production files for the scope are unchanged. Ask explicitly for approval to continue to that scope's Green. Record each decision in `verification.md`.

Run the focused layer command in a clean process. Gate 3 does not accept evidence produced only by a combined command or after another layer prepared mutable state.

## Done

The spec is ready for implementation only when:

- No unresolved `[NEEDS CLARIFICATION]` blocks remain for implementation-critical behavior.
- User Stories exist and each has at least one BDD Given/When/Then scenario.
- `plan.md` contains **Domain Model And Business Policy** with capability/context, ubiquitous terms, policy owner, invariants/transitions, events, and examples, or an evidence-backed `domain: not_affected` reason.
- Every spec artifact has an `ART-*` ID and is listed in `traceability.yaml`.
- Every defined stable ID has a non-placeholder human-readable title, and the same ID uses the same title across all artifacts.
- Tasks follow domain → application → conditional boundary → infrastructure → interface → module-owned composition order; Boundary is omitted only when all outer production is `not_affected`.
- Every production implementation task depends on same-layer failing evidence and the prior layer gate; outer production depends on `LAYER-GATE-APPLICATION`.
- Every affected test layer records a standalone command and passes independently with `depends_on_test_layer: none`.
- Include a final `documentation` task using `WORKFLOW-COMMON_SDD_UPDATE_DOCUMENTATION_WORKFLOW`, or record `no_documentation_change_reason` in `spec.md` and `verification.md`.
- Load `RULE-COMMON_SDD_DOCUMENTATION_GATE`; the documentation workflow must run during final convergence before the spec can be reported `verified`, even when the change appears documentation-free.
- `parallel-tracks.md` defines maximum concurrent agents and ownership boundaries.
- Traceability links artifacts, User Stories, requirements, scenarios, tasks, tracks, and tests.
- Gate 1, Gate 2, and every applicable scoped Gate 3 approval are recorded in `verification.md`.
- Gate 1 approval was received before creating folders or artifacts.
- Every task explicitly states whether it is parallelizable and which track owns it.
- Gate 2 approval was received before creating or running RED tests.
- Each scoped Gate 3 approval was received after that layer's RED evidence and before editing production code for that scope.
- `RULE-COMMON_SDD_DOCUMENTATION_GATE` passed: `WORKFLOW-COMMON_SDD_UPDATE_DOCUMENTATION_WORKFLOW` was invoked and evidence was recorded, or its surface analysis produced an explicit `no_documentation_change_reason` in `spec.md`, `verification.md`, and `change-summary.md`.
- Every phase and task has a primary `workflow_id`; supporting workflows are explicit when needed.
- Final validation uses `WORKFLOW-COMMON_SDD_VERIFY_SPEC_WORKFLOW`; the feature folder remains at its stable path.
- Final validation is blocked until `WORKFLOW-COMMON_SDD_COVERAGE_GATE_WORKFLOW` records its final result; production scopes must record `>= 90%` coverage and docs-only specs must record `coverage_scope: none`.
- If context reaches 60%, new work is paused until `WORKFLOW-COMMON_SDD_CONTEXT_CHECKPOINT_WORKFLOW` leaves an append-only handoff and an explicit resume action in the active spec.
- Final validation is blocked until `WORKFLOW-COMMON_SDD_SECURITY_GATE_WORKFLOW` records a passed review with no unresolved findings.
- Final validation is blocked until `WORKFLOW-COMMON_SDD_CLEAN_UP_GATE_WORKFLOW` records a passed review for every created/modified file and confirms every in-scope maintained source, test, configuration, CI, and script file is below 150 physical lines.
