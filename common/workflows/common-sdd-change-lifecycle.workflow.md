---
workflow_id: WORKFLOW-COMMON_SDD_CHANGE_LIFECYCLE_WORKFLOW
trigger: manual
description: "End-to-end SDD lifecycle for any code change: spec, inside-out TDD, boundary verification, refactor, gates, and convergence."
---

# Common SDD Change Lifecycle Workflow

Use this workflow as the parent lifecycle for feature work, integration work, UI behavior, infrastructure changes, and refactors. Apply `RULE-COMMON_INSIDE_OUT_DEVELOPMENT` to every backend behavior slice. For a defect, invoke `common-sdd-fix-bug.workflow.md` first; it owns diagnosis, classification, regression evidence, and the decision to evolve or preserve the existing contract. Language-specific workflows may add details, but they must not skip test-first evidence or reorder outer production ahead of the core.

## Phase 1: Prepare And Show The SDD Plan Read-Only

Inspect the repository and prepare the smallest useful specification plan without creating or modifying files.

Include:

- Feature/spec/artifact IDs.
- User Stories: actor, capability, and business reason.
- Actor or system boundary.
- Observable behavior.
- BDD Given/When/Then acceptance scenarios.
- `WORKFLOW-COMMON_BDD_SPECIFICATION_WORKFLOW` for business value, shared examples, abstract scenarios, and living documentation.
- Out-of-scope.
- Edge cases and failure behavior.
- Non-functional constraints when relevant: performance, security, compatibility, observability, rollback.
- SOLID, Clean Architecture, CQRS, and project-specific architecture constraints that apply.
- Technology-neutral inner-layer naming: Domain/Application files, packages, ports, types, DTOs, events, and errors must use business capabilities rather than provider names such as DynamoDB, Cosmos, or Kafka; provider names stay in outer adapters and composition.
- Existing behavior that must remain unchanged.
- Parallel track constraints: maximum agents, ownership boundaries, dependencies, and merge order.
- Test ID strategy for acceptance and unit-level tests.
- Proposed spec folder and exact artifact files.
- Proposed `workflow-routing.md` with the primary and supporting workflow for every SDD phase and task.
- Proposed documentation gate: `RULE-COMMON_SDD_DOCUMENTATION_GATE` with a final `documentation` task routed to `WORKFLOW-COMMON_SDD_UPDATE_DOCUMENTATION_WORKFLOW`; identify affected project/SDD documentation surfaces or the evidence required for a no-change outcome.
- Sequential and parallel tasks, track IDs, dependencies, ownership, execution waves, merge order, and `max_parallel_agents`.
- Primary `workflow_id`, `workflow_phase`, supporting workflow IDs, and rationale for each task.
- Context budget plan: small task boundaries, current/next task state, and the checkpoint route if context reaches 60%.

Use `[NEEDS CLARIFICATION]` for unresolved product decisions. Do not silently turn ambiguity into implementation.

Show the complete proposed SDD plan to the user before any spec write.

## Phase 2: Human Gate 1 - Approve Spec Writes

Ask the user/product owner explicitly for permission to create or modify the proposed spec folders and artifacts.

When verification is requested, include:

- The behavior to approve.
- Open questions.
- User Stories and BDD acceptance scenarios.
- Out-of-scope.
- Risks and tradeoffs.
- The exact sequential/parallel task proposal, track ownership, execution waves, and maximum concurrent agents.

Do not create or modify `specs/**`, history, contracts, decisions, or related spec documentation before approval. This gate cannot be skipped for low-risk, mechanical, or unambiguous work.

## Phase 3: Create Or Update The Approved Spec

After approval, create or update the approved folder and artifacts, then translate the behavior into the technical plan.

Cover:

- Architecture boundaries and ownership.
- SOLID, Clean Architecture, CQRS, and local architecture rules that constrain the design.
- Provider-neutral Domain/Application naming, with concrete technology names confined to Infrastructure, Interface, or Composition adapters and mapping/configuration.
- Contracts, DTOs, events, schemas, or UI states touched.
- Data model and migration impact.
- Acceptance harness or public boundary to test through.
- Unit test targets.
- A layer scope map and **Development Sequence And Layer Gates** section covering domain, application, boundary, infrastructure, interface, and composition.
- A **Domain Model And Business Policy** section that precedes the layer map and identifies capability/context, ubiquitous terms, policy owner, invariants/transitions, domain events, and counterexamples, or justifies `domain: not_affected`.
- Boundary integration tests needed for backend public wiring and local resources; HTTP is one entry specialization, with component/page tests for frontend behavior.
- Architecture, security, performance, coverage, CRAP, or mutation gates that apply.
- Rollback or operational verification when relevant.
- Parallel tracks: maximum concurrent agents, file/module ownership, dependencies, and sequential merge policy.

Select supporting boundary workflows from the task routing matrix before writing `workflow-routing.md`:

| Task surface | Supporting workflows |
| --- | --- |
| REST endpoint | `WORKFLOW-COMMON_REST_API_DESIGN_WORKFLOW` + language REST workflow |
| API Gateway/Lambda REST | REST workflow + `WORKFLOW-COMMON_AWS_LAMBDA_REST_WORKFLOW` + language REST workflow |
| SNS publisher/domain event | `WORKFLOW-COMMON_AWS_SNS_PUBLISH_WORKFLOW` + language messaging rules |
| SQS Lambda consumer | `WORKFLOW-COMMON_AWS_SQS_CONSUMER_WORKFLOW` + language messaging rules |
| React + TypeScript + Vite REST client | `WORKFLOW-COMMON_REST_API_DESIGN_WORKFLOW` + `WORKFLOW-REACT_REST_API_CLIENT_WORKFLOW` |

The language implementation workflow remains primary. Supporting workflows are invoked at the phase that owns the boundary decision; record every invocation and result in `workflow-routing.md`, `tasks.md`, and `verification.md`.

The active spec is a mutable baseline. If repository evidence changes the approved behavior, plan, architecture, contract, risk, test strategy, scope, ordering, ownership, or gates, pause the current task. Invoke `common-sdd-evolve-spec.workflow.md`, use `common/templates/spec-adjustment-request.md`, obtain approval, update affected artifacts and append-only history, and reset impacted gates before continuing. Never absorb discovery as an unrecorded deviation.

## Phase 4: Create Sequential And Parallel Tasks

Break the plan into small tasks. Each task should reference at least one User Story, requirement or acceptance scenario, parallel track, artifact ID, test ID, verification method, and canonical backend `work_type` when applicable.

Every task must declare:

- `track_id`.
- `workflow_id` and `workflow_phase`.
- `supporting_workflow_ids` when a focused procedure is required.
- `parallelizable: true|false`.
- `depends_on` and `blocked_by`.
- `can_run_with` when safe.
- File/module/contract ownership.
- Execution wave and merge position.
- One concrete outcome, `done_when`, `verification_command`, and `next_step`.

Good task shape:

```text
T001: Add the abstract BDD scenario for REQ-003.
T002: Add the Domain RED for the invariant behind SCN-003.
T003: Implement Domain GREEN and pass LAYER-GATE-DOMAIN.
T004: Add the Application RED with hand-written outgoing-port doubles.
T005: Implement Application GREEN and pass LAYER-GATE-APPLICATION.
T006: Add the executable public-boundary RED when outer production is affected.
T007: Implement the infrastructure adapter and pass its layer gate.
T008: Implement the delivery interface and pass its layer gate.
T009: Add composition/IaC last and pass its layer gate.
T010: Make boundary evidence green, refactor, and run final gates.
```

Each test task also records its independent clean-state command, `depends_on_test_layer: none`, isolation scope, and cleanup. Task ordering opens production layers; it does not make test execution depend on earlier test tasks.

Do not create large mixed tasks. Split work by one scenario, one business rule, one boundary, one adapter, or one protected refactor.

When no tasks can run concurrently, state why and keep `max_parallel_agents: 1`. When tasks can run concurrently, show the exact task IDs assigned to each agent slot.

## Phase 5: Human Gate 2 - Approve RED

Show the written spec artifacts, final User Stories and abstract scenarios, task/track table, parallel execution waves, traceability, risks, layer scope, the first domain/application RED, and either the later executable boundary RED or GREEN `not_affected` verification planned.

Ask explicitly for permission to begin RED. Do not create, modify, or run test code before approval.

## Phase 6: Domain RED, GREEN, Refactor, And Gate

When domain behavior is affected, write the smallest focused test for one invariant, value object, entity transition, or domain service. Apply `RULE-COMMON_TEST_ASSERTION_STRUCTURE`, run the test, and confirm RED for the intended missing rule.

Run the Domain standalone command from a clean process. Domain evidence must not load Application or outer-layer test helpers/state.

Invoke `common-sdd-review-test-evidence.workflow.md` with `gate_scope: domain`. After explicit Gate 3-DOMAIN approval, implement only enough pure domain code to pass. Refactor while green and record `LAYER-GATE-DOMAIN: passed` with its command and dependency evidence.

When domain is not affected, record `LAYER-GATE-DOMAIN: not_affected`, its reason, and the existing domain-suite result. Do not invent domain code or a meaningless test.

## Phase 7: Application RED, GREEN, Refactor, And Core Gate

When application behavior is affected, write the smallest focused use-case test. Use real domain values and hand-written stubs, fakes, spies, or mocks only for outgoing application-owned ports. Test doubles return configured data and capture meaningful calls; they contain no assertions or business policy.

Run the test, confirm RED, and invoke the evidence workflow with `gate_scope: application`. After explicit Gate 3-APPLICATION approval, implement the use case and required application-owned ports. Refactor while green, rerun domain/application tests, and record `LAYER-GATE-APPLICATION: passed`.

Application's focused command must also pass alone; rerunning Domain is combined regression evidence, never a setup step for Application.

No new adapter, handler, controller, router, cloud client, DI registration, or IaC production task may start until the application/core gate is `passed` or evidence-backed `not_affected`.

## Phase 8: Conditional Executable Boundary RED And Gate

After the core gate, create the smallest executable ATDD evidence at the closest stable boundary when boundary, infrastructure, interface, or composition production is affected. For `integration/http`, enter through the real public boundary. For `integration/infrastructure`, invoke the Application use case with the real adapter path and a real local resource. The BDD scenario is specified first in business language; executable RED must exist before implementing the affected outer production code, and boundary-specific setup belongs in test code and `verification.md`.

For REST, Lambda, SNS, SQS, or a React REST client, invoke the selected supporting workflow before writing boundary-specific RED evidence. Run the test and confirm it fails because outer behavior or wiring is missing, not because core policy is absent. If it passes, investigate whether the behavior already exists, the assertion is weak, or the wrong boundary is under test.

Invoke the evidence workflow with `gate_scope: boundary`. After Gate 3-BOUNDARY approval, record `LAYER-GATE-BOUNDARY-RED: passed`.

When all outer production layers are `not_affected`, run existing public-boundary evidence as GREEN acceptance verification when available. Record Gate 3-BOUNDARY and `LAYER-GATE-BOUNDARY-RED` as `not_affected`; do not invent a failing test or outer implementation.

The Boundary command owns its complete local-resource lifecycle and must produce the same result when no Domain/Application test command has run.

## Phase 9: Infrastructure, Interface, And Composition GREEN

Implement the smallest outer changes in strict dependency order:

1. Infrastructure adapters implement application-owned ports and own only translation/I/O. Make the use-case-driven `integration/infrastructure` RED GREEN against the real local resource before declaring the infrastructure layer complete.
2. Delivery interfaces parse/authenticate/validate/map, call one use case, and map the result.
3. Each business module owns its DI and delivery registrations; the executable composition root aggregates module entry points, configuration, IAM/IaC, and deployment wiring last.

Pass `LAYER-GATE-INFRASTRUCTURE`, `LAYER-GATE-INTERFACE`, and `LAYER-GATE-COMPOSITION` as their scopes complete. Make boundary evidence green through the real composition root and required local resources. Do not move business decisions outward to make the boundary test pass.

## Phase 10: Refactor

Refactor each opened layer only while its relevant tests are green.

Focus on:

- Names that reveal behavior.
- Duplicate rules, mappings, permissions, and error decisions.
- Boundary leaks.
- Excessive branching or file size.
- Unused helpers, fields, ports, and extension points.
- Test clarity and acceptance harness stability.

After each small refactor, rerun the smallest relevant tests. For broad refactors, run the full affected suite before continuing.
Record the behavior-preserving changes and final green evidence in `red-green-refactor.md` before entering the gates.

## Phase 11: Verify Gates

Run the checks that match the touched surface.

Baseline:

- Targeted unit tests.
- Acceptance test or public-boundary test.
- Build/typecheck/lint/format when available.
- Mandatory `common-sdd-clean-up-gate.workflow.md` for every created/modified file, including names, the strict <150-line limit for in-scope maintained source, test, configuration, CI, and script files, ownership, Clean Code, SOLID, Clean Architecture, CQRS, complexity, duplication, and required behavior-preserving refactors.
- Mandatory `RULE-COMMON_SDD_DOCUMENTATION_GATE`: after behavior and tests are green, invoke `common-sdd-update-documentation.workflow.md` before final clean-up, security, coverage, or validation review.

When relevant:

- Backend integration tests or frontend component/page tests.
- Architecture/dependency checks.
- Mandatory `common-sdd-security-gate.workflow.md` with a recorded `security_role`, changed trust boundaries, security evidence, and no unresolved Critical/High findings before validation.
- Mandatory `common-sdd-coverage-gate.workflow.md` before a spec enters `verified`; with production code in scope it requires `>= 90%` aggregate coverage for the project production scope and no affected-scope regression.
- CRAP/complexity checks.
- `common-sdd-mutation-gate.workflow.md` for L2 non-trivial business logic and every L3 change.
- `common-sdd-critical-e2e.workflow.md` for every L3 change; a journey explicitly marked critical is classified as L3.
- `common-sdd-validate-change.workflow.md` through the `sdd-policy` CI/PR check.
- `common-sdd-context-checkpoint.workflow.md` when consumed context reaches 60% or the host warns about compaction.
- Security, performance, observability, smoke, or rollback checks.

Do not report a spec as `verified` with a failing gate. If a gate cannot run, state why and what risk remains.

## Phase 12: Converge

Before finishing, reconcile:

- Spec.
- Human change summary.
- Workflow routing.
- Artifact IDs and traceability records.
- User Stories.
- Acceptance scenarios.
- Plan.
- Tasks.
- Parallel tracks.
- Contracts/schemas/events.
- Code.
- Tests.
- Documentation.
- Operational notes.

If context reaches 60% before convergence, stop starting new tasks and invoke `common-sdd-context-checkpoint.workflow.md`. Update the active spec folder and request a new context; do not change the lifecycle status merely because the current context is ending.

Invoke `common-sdd-update-documentation.workflow.md` through the traceable `documentation` task for every change. If its surface analysis finds no affected project documentation, record `no_documentation_change_reason` in `spec.md`, `verification.md`, and `change-summary.md`; this explicit workflow result is the only allowed no-change exception.

When all implementation and documentation tasks are done, invoke `common-sdd-verify-spec.workflow.md` to review final evidence and record `status: verified` in the stable feature folder.

Validation is blocked until the clean-up workflow passes for every created/modified file, every in-scope maintained source, test, configuration, CI, and script file is below 150 physical lines, the security workflow records no unresolved findings, and the coverage workflow records its command, scope, result, threshold, and exclusions in `verification.md` and `change-summary.md`; production scopes must reach `>= 90%`.

Final report should include:

- Spec or behavior implemented.
- User Stories and BDD scenarios covered.
- Abstract BDD acceptance plus executable boundary evidence.
- Domain/application RED/GREEN evidence, manual test-double evidence, and every layer-gate result.
- The standardized `red-green-refactor.md` report with one entry per behavior partition.
- Context checkpoint path and resume instruction when a context handoff occurred.
- Gate 1, Gate 2, each scoped Gate 3 decision, and the final validation decision.
- Coverage command, affected scope, measured percentage, `>= 90%` threshold, and exclusions.
- Parallel track outcome and agent count if multiple tracks were used.
- Clean-up gate result, reviewed file scope, metrics, findings, refactors, exceptions, and human decision.
- Security gate result, `security_role`, trust-boundary review, commands, findings, exceptions, and residual risk.
- Refactors performed.
- Files changed.
- Residual risk or manual verification still needed.
- Any spec-adjustment request, approved delta, repeated gates, and exact resume action.
- Documentation gate outcome: changed surfaces and verification evidence, or the workflow's inspected-surface `no_documentation_change_reason`.
- Final validation decision, stable spec path, and any optional context-summary evidence.
