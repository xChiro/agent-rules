---
rule_id: RULE-COMMON_SDD_SPEC_STRUCTURE
trigger: always_on
description: Folder structure, traceability, and history rules for SDD specs.
---

# Common SDD Spec Structure

Every project that uses SDD should keep specs as versioned engineering artifacts. The spec directory is not scratchpad context; it is the source of intent, behavior, constraints, and verification evidence. An active spec is mutable through the controlled `common-sdd-evolve-spec.workflow.md` protocol; its history remains append-only and plan drift requires approval.

Defect changes use the same folder shape as feature changes with `change_type: bug-fix`. They additionally include `bug-report.md` when the defect needs reproduction, classification, impact, or root-cause evidence. Use `BUG-*` for the defect, `REG-*` for regression evidence, and link the defect to its owning or source `FEAT-*`/`SPEC-*`. A completed source spec is never rewritten to erase a defect; create a new active defect spec when the source is completed.

## Recommended Structure

Use this structure unless the project already has a clear local equivalent:

```text
specs/
├── constitution.md
├── context/
│   ├── product.md
│   ├── domain-glossary.md
│   ├── architecture.md
│   ├── repository-map.md
│   ├── operations.md
│   └── ai-snapshots/
├── features/
│   ├── 0001-feature-slug/
│   │   ├── spec.md
│   │   ├── bug-report.md             # defect specs only
│   │   ├── change-summary.md
│   │   ├── acceptance.feature
│   │   ├── invariants.md
│   │   ├── plan.md
│   │   ├── spec-adjustment-request.md # only when discovery changes the plan
│   │   ├── security-review.md
│   │   ├── code-quality-review.md
│   │   ├── research.md
│   │   ├── data-model.md
│   │   ├── contracts/
│   │   ├── decisions/
│   │   ├── tasks.md
│   │   ├── workflow-routing.md
│   │   ├── parallel-tracks.md
│   │   ├── traceability.yaml
│   │   ├── verification.md
│   │   ├── red-green-refactor.md
│   │   ├── handoffs/
│   │   │   ├── latest-context-handoff.md
│   │   │   └── context-checkpoints/
│   │   └── history/
│   │       ├── 2026-07-10-created.md
│   │       └── 2026-07-12-command-broadcast-change.md
│   └── 0001-squad-radio-completed/
└── archive/
    └── 0000-retired-feature/
```

Use `specs/features/<number>-<slug>/` for active feature specs. After Gate 4 approval, rename verified features with Git to `specs/features/<number>-<slug>-completed/`. Use `archive/` only when a feature is retired, obsolete, or no longer drives implementation. Keep AI snapshots under `specs/context/ai-snapshots/`.

## Spec And Artifact IDs

Every spec folder and every spec artifact must be traceable by stable IDs.

Feature-level IDs:

- Feature ID: `FEAT-0001`.
- Spec ID: `SPEC-0001`.
- Change type: `feature`, `bug-fix`, `refactor`, `pipeline`, or `documentation`.
- Bug ID: `BUG-0001-001` for defect specs.
- Regression ID: `REG-0001-001` for defect behavior evidence.
- Security review ID: `SEC-0001-001`.
- Security check IDs: `SEC-CHECK-0001-001`.
- Security finding IDs: `FINDING-0001-001`.
- Code-quality review ID: `QUAL-0001-001`.
- Code-quality finding IDs: `QUALITY-FINDING-0001-001`.
- User Story IDs: `US-0001-001`.
- Requirement IDs: `REQ-0001-001`.
- Scenario IDs: `SCN-0001-001`.
- Task IDs: `T-0001-001`.
- Track IDs: `TRK-0001-001`.
- Test IDs: `TEST-0001-001`.
- Handoff IDs: `HANDOFF-0001-001`.
- Context checkpoint IDs: `CHECKPOINT-20260711-120000`.
- RED/Green/Refactor cycle IDs: `CYCLE-0001-001`.
- Change IDs: `CHG-0001-001`.
- Artifact IDs: `ART-0001-SPEC`, `ART-0001-CHANGE-SUMMARY`, `ART-0001-ACCEPTANCE`, `ART-0001-PLAN`, `ART-0001-SECURITY-REVIEW`, `ART-0001-TASKS`, `ART-0001-WORKFLOW-ROUTING`, `ART-0001-TRACKS`, `ART-0001-TRACEABILITY`, `ART-0001-VERIFICATION`, `ART-0001-RED-GREEN-REFACTOR`, `ART-0001-HANDOFF`, `ART-0001-CONTEXT-HANDOFF`, `ART-0001-HIST-YYYYMMDD`.
- Snapshot IDs: `SNAP-YYYYMMDD-001`.

Markdown artifacts should start with metadata:

```yaml
---
feature_id: FEAT-0001
spec_id: SPEC-0001
change_type: feature
artifact_id: ART-0001-PLAN
status: draft
created: 2026-07-10
updated: 2026-07-10
---
```

Gherkin artifacts should use comments when frontmatter is not supported:

```gherkin
# feature_id: FEAT-0001
# spec_id: SPEC-0001
# artifact_id: ART-0001-ACCEPTANCE
```

Contracts, schemas, diagrams, ADRs, generated files, and manual QA notes also need artifact IDs when they are part of the spec. A file without an ID is not a stable SDD artifact.

## Agent Rule Artifact IDs

Agent rule, workflow, and skill files are style artifacts. They must also be traceable.

Use frontmatter IDs:

```yaml
---
rule_id: RULE-<SCOPE>_<NAME>
---
```

```yaml
---
workflow_id: WORKFLOW-<SCOPE>_<NAME>_WORKFLOW
---
```

```yaml
---
skill_id: SKILL-<SCOPE>_<NAME>_SKILL
---
```

Reference these IDs when a spec, history entry, or repository decision depends on a specific rule, workflow, or skill. Do not rely only on filename prose for durable traceability.

## Documentation Gate

Every SDD spec includes a traceable documentation task governed by `RULE-COMMON_SDD_DOCUMENTATION_GATE` and `WORKFLOW-COMMON_SDD_UPDATE_DOCUMENTATION_WORKFLOW`. This applies to spec creation, evolution, bug fixes, refactors, implementation changes, pipeline changes, and completion. The task records the affected project/SDD documentation surfaces and verification evidence; when no project documentation surface is affected, it records `no_documentation_change_reason` in `spec.md`, `verification.md`, and `change-summary.md` after the workflow's surface analysis.

## Feature Spec Files

Minimum useful spec:

- `spec.md`: User Stories, actor, objective, requirements, out-of-scope, edge cases, non-functional constraints, and open questions.
- `change-summary.md`: human-readable summary of every planned and actual change, affected files, tests, workflows, documentation, risks, and rollback.
- `bug-report.md`: defect classification, reproduction evidence, actual/expected behavior, impact, root-cause analysis, and links to regression evidence. Required for defect specs when those details are not already captured in `change-summary.md`.
- `acceptance.feature`: BDD Given/When/Then scenarios or the local executable acceptance format.
- `plan.md`: architecture, contracts, data, risks, testing strategy, observability, and rollout/rollback when relevant.
- `security-review.md`: final security scope, identity role, trust boundaries, OAuth/OIDC and web-session evidence when applicable, scan commands, findings, exceptions, and security-gate decision. Every completed spec must contain it, including a `security_role: none` review when security impact is unchanged.
- `code-quality-review.md`: final review of every spec-created or spec-modified file, names, limits, ownership, Clean Code/SOLID/Clean Architecture/CQRS checks, findings, refactors, exceptions, and quality-gate decision. Every completed spec must contain it.
- `tasks.md`: ordered small tasks, each traceable to a requirement and verification method. Each task has one concrete outcome, `done_when`, `verification_command`, `next_step`, and explicit ownership/dependencies.
- `workflow-routing.md`: selected primary/supporting workflows for each SDD phase and task, with rationale.
- `parallel-tracks.md`: safe concurrent work plan, maximum agent count, track ownership, dependencies, write boundaries, and merge order.
- `traceability.yaml`: requirement -> scenario -> task -> test -> contract/metric links.
- `verification.md`: checks run, manual QA evidence, unverified scope, and residual risk.
- `red-green-refactor.md`: standardized RED, GREEN, and REFACTOR commands, failures, implementation evidence, and behavior-preservation evidence.
- `handoffs/`: append-only Architect, Tester, Coder, and Reviewer handoffs when multiple agents participate.
- `handoffs/context-checkpoints/`: append-only continuation handoffs created when AI context reaches the 60% pause threshold; use `common/templates/context-handoff.md`.
- `handoffs/latest-context-handoff.md`: pointer to the checkpoint the next AI must read first. It is operational state, not feature history.
- `history/`: immutable change notes for the feature spec.

Add optional files only when useful:

- `invariants.md` for domain rules that must always hold.
- `research.md` for tradeoffs, unknowns, spikes, and rejected options.
- `data-model.md` for entities, persistence shape, migrations, or state machines.
- `contracts/` for OpenAPI, AsyncAPI, JSON Schema, event schemas, or CLI contracts.
- `decisions/` for ADR-style records.
- `spec-adjustment-request.md` for an evidence-based plan/intent change; use `common/templates/spec-adjustment-request.md` and append the approved decision to `history/`.
- `ci-profile.md` when pipeline commands, local resources, artifacts, branch protection, environments, or deployment gates are part of the change.
- `mutation-report.md` when the mutation gate is required.
- `critical-e2e.md` when the critical E2E gate is required.

## Context Continuity

Context checkpoints are interim handoffs, not completed snapshots. At 60% consumed context, stop starting new tasks and update the active spec before requesting a context change. The checkpoint must leave `tasks.md`, `change-summary.md`, `verification.md`, `workflow-routing.md`, and `traceability.yaml` consistent enough for another AI to resume without reconstructing hidden context. Use `WORKFLOW-COMMON_SDD_CONTEXT_CHECKPOINT_WORKFLOW` and `tools/create-sdd-context-checkpoint.sh` when a context meter is available.

## Human Change Summary

`change-summary.md` is mandatory for every new SDD spec. It is written for human review, not as an implementation dump. It must describe all planned changes before Gate 1 and the actual changes after Converge.

Use this structure:

```markdown
---
feature_id: FEAT-0001
spec_id: SPEC-0001
artifact_id: ART-0001-CHANGE-SUMMARY
status: proposed
---

# Change Summary: <behavior>

## Decision Requested

What the user must approve before the spec is created.

## Why

Business problem, actor, and expected outcome.

## Planned Changes

| ID | Area | Change | Files/modules | Workflow | Track | Sequence |
|---|---|---|---|---|---|---|
| CHG-0001-001 | Domain | Add the business rule | src/... | WORKFLOW-... | TRK-... | wave 1 |

## Tests Before Production Code

- `SCN-*` acceptance or public-boundary test: path, workflow, expected RED.
- `TEST-*` unit/component test: path, workflow, expected RED.
- Gate 3 evidence required before Green.

## Documentation And Operations

- Documentation files to create/update.
- CI, local resources, contracts, migrations, metrics, and runbooks affected.

## Risks, Non-Goals, And Rollback

- Risks and mitigations.
- Explicit out-of-scope behavior.
- Rollback or recovery approach.

## Execution Order

1. Spec and acceptance artifacts.
2. Acceptance/public-boundary RED.
3. Unit-level ATDD RED.
4. Gate 3 review.
5. Production implementation.
6. Refactor, verification, documentation, and convergence.

## Actual Result

Updated during Converge with completed changes, deviations, tests, documentation, and residual risk.
```

Rules:

- Every planned production, test, infrastructure, CI, documentation, contract, migration, and operational change gets a `CHG-*` row.
- Every row names affected files/modules, primary workflow, track, sequence, and verification evidence.
- `status: proposed` is used before Gate 1; `approved` after Gate 1; `implemented` only after Green; `verified` after Converge.
- Do not hide deviations. Add them to `Actual Result` and history.

## Completion And AI Context Snapshots

Completion is separate from spec creation. A feature remains under `specs/features/<number>-<slug>/` while it is active. After implementation and Converge pass, invoke `WORKFLOW-COMMON_SDD_COMPLETE_SPEC_WORKFLOW`.

That workflow first runs `WORKFLOW-COMMON_SDD_CLEAN_UP_GATE_WORKFLOW` and requires a passed `code-quality-review.md` for every created or modified file, including confirmation that every in-scope code file is below 150 physical lines. It then runs `WORKFLOW-COMMON_SDD_SECURITY_GATE_WORKFLOW`, any required mutation/critical-E2E gate, and the mandatory `WORKFLOW-COMMON_SDD_COVERAGE_GATE_WORKFLOW` with `>= 90%` project coverage and no affected-scope regression when production code is in scope. After all required gates pass, it obtains final human completion approval, updates `change-summary.md` to `status: verified`, renames the folder to `specs/features/<number>-<slug>-completed/`, and creates an AI context snapshot at:

```text
specs/context/ai-snapshots/YYYY-MM-DD-<feature-slug>-snapshot.md
```

Every snapshot has a `SNAP-*` ID, source feature/spec IDs, source commit when available, final behavior and architecture summary, workflow/test evidence, documentation and operational constraints, known non-goals, residual risks, and links to the completed spec. Update `specs/context/ai-snapshots/index.md` whenever a snapshot is created.

Snapshots are derived context for agents and humans. They never replace `spec.md`, `change-summary.md`, contracts, decisions, verification, or append-only history. Never include secrets, credentials, private endpoints, or unbounded generated output.

## User Story Format

Every behavior requirement starts from a User Story:

```text
US-0001-001:
As a <actor>,
I want <capability>,
so that <business outcome>.
```

Each User Story must have at least one BDD scenario:

```gherkin
@US-0001-001 @REQ-0001-001 @SCN-0001-001
Scenario: Actor achieves the business outcome
  Given the required business context
  When the actor performs the behavior
  Then the system produces the observable outcome
```

Do not replace User Stories with technical tasks. Technical decisions belong in `plan.md`, not in the story.

## ATDD Test Code Style

Acceptance tests and the first implementation-driving tests should read like executable acceptance examples.

Prefer test names, fixtures, and assertion sections that make the behavior obvious:

```text
Given <business context>
When <actor action>
Then <observable outcome>
```

Use the local test framework idioms, but keep the test intent at the User Story level. Do not write tests that only mirror private methods, field names, or implementation structure.

## Mandatory Approval Gates

Before creating the spec folder or modifying any existing spec file, the agent must present the complete proposed SDD plan and ask for explicit approval. The presentation includes folder path, files, IDs, User Stories, Given/When/Then scenarios, plan scope, tasks, work types, parallel tracks, tests, and gates.

After the approved folders and artifacts are created or modified, the agent must present the resulting spec and ask for explicit approval to begin the RED phase. Until that second approval, the agent must not create, modify, or run acceptance, HTTP integration, component, or unit test code.

After the acceptance and focused unit-level tests are RED, the agent must present the actual test files, commands, failures, assertions, and confirmation that production files are unchanged. The agent must ask for explicit approval before Green. This is Gate 3 and applies to feature work and refactors that add or change test protection.

These gates apply even when the change is simple or unambiguous. Approval to discuss or plan is not approval to write spec files; approval to write spec files is not approval to start RED; approval to start RED is not approval to edit production code.

## Unit Tests Before Production Code

Production code must not be edited until the current behavior has a failing unit-level test.

Required order for each implementation slice:

1. BDD acceptance scenario or public-boundary acceptance evidence exists.
2. The acceptance evidence is confirmed RED when practical.
3. A unit/domain/application/component test is written with a stable `TEST-*` ID.
4. The unit-level test is confirmed RED for the intended rule.
5. Gate 3 approves the test evidence.
6. Only then may production code change.

Acceptance evidence alone is not enough for business logic implementation. If a true unit test is impossible because the behavior only exists at a UI, CLI, generated-code, or HTTP boundary, write the closest unit-level/component test and document the exception in `verification.md`.

## Architecture Principles

Each spec must state the architecture constraints that apply to the feature. Use `plan.md`, `invariants.md`, or `decisions/` for details.

Default principles:

- Follow the project's existing architecture before introducing new structure.
- Apply SOLID as design pressure: one reason to change, small interfaces owned by consumers, dependencies inverted at boundaries, and substitutable adapters.
- Follow Clean Architecture boundaries for backend/domain work: domain and application stay independent from transport, persistence, framework, cloud SDK, UI, and deployment concerns.
- Follow CQRS when the project architecture uses it: commands change state, queries read state, and command-side decisions do not leak into query projections without an explicit mapping.
- Keep business rules in the owning domain/application/use case or frontend behavior boundary, not in adapters, controllers, views, persistence models, or framework callbacks.
- Keep boundary mapping owned by the DTO that represents the external shape: persistence DTOs map domain values to database schemas and back, transport DTOs map requests/responses, and message DTOs map event payloads. Keep these functions colocated with the DTO and free of I/O, authorization, orchestration, and business policy.
- Do not add speculative layers, generic repositories, mediators, factories, or extension points unless the spec explains the current behavior or risk they protect.

If the local project has stricter architecture rules, the local project rules win. Do not weaken the architecture to make a spec easier to implement.

## Small Work Rules

Specs must be decomposed into small vertical slices.

Each task should represent one of:

- One acceptance scenario.
- One business rule or invariant.
- One public boundary change.
- One adapter or HTTP integration behavior.
- One behavior-preserving refactor protected by characterization tests.

Backend tasks also declare one canonical `work_type` from `common-workflow-taxonomy.md`. The work type selects focused language rules and the supporting boundary workflow when applicable; it does not replace the primary language SDD workflow.

Boundary routing examples:

- `rest-endpoint`: `WORKFLOW-COMMON_REST_API_DESIGN_WORKFLOW` + the language REST adapter.
- `lambda-rest-endpoint`: REST design + `WORKFLOW-COMMON_AWS_LAMBDA_REST_WORKFLOW` + the language REST adapter.
- `sns-publisher`: `WORKFLOW-COMMON_AWS_SNS_PUBLISH_WORKFLOW` + language messaging rules.
- `sqs-consumer`: `WORKFLOW-COMMON_AWS_SQS_CONSUMER_WORKFLOW` + language messaging rules.
- React REST client: REST design + `WORKFLOW-REACT_REST_API_CLIENT_WORKFLOW`.

Split a task when it touches unrelated actors, unrelated scenarios, multiple bounded contexts, unrelated filesystems/services, or more than one architectural boundary without a clear reason.

## Workflow Routing

Every spec must contain `workflow-routing.md`. It is the routing table for the agent and must be reviewed at Gate 1 before spec writes and again at Gate 2 before RED.

Each phase and task has one primary workflow. Supporting workflows may be listed when they add a focused procedure without changing ownership.

```yaml
feature_id: FEAT-0001
spec_id: SPEC-0001
artifact_id: ART-0001-WORKFLOW-ROUTING
phases:
  - phase: spec-create
    workflow_id: WORKFLOW-COMMON_SDD_CREATE_SPEC_WORKFLOW
    reason: Create the folder, artifacts, IDs, and approval record.
  - phase: implementation
    workflow_id: WORKFLOW-GO_SDD_IMPLEMENT_CHANGE_WORKFLOW
    reason: Execute the selected Go work types.
  - phase: bdd-specification
    workflow_id: WORKFLOW-COMMON_BDD_SPECIFICATION_WORKFLOW
    reason: Discover value, examples, abstract business scenarios, and executable acceptance intent.
  - phase: test-evidence-review
    workflow_id: WORKFLOW-COMMON_SDD_REVIEW_TEST_EVIDENCE_WORKFLOW
    reason: Review acceptance and unit RED before Green.
  - phase: clean-up-gate
    workflow_id: WORKFLOW-COMMON_SDD_CLEAN_UP_GATE_WORKFLOW
    reason: Review all changed files, complete required Fowler refactors, and confirm the strict <150-line source-file limit before final security and coverage gates.
  - phase: security-gate
    workflow_id: WORKFLOW-COMMON_SDD_SECURITY_GATE_WORKFLOW
    reason: Review changed trust boundaries, identity, secrets, web sessions, and security evidence before completion approval.
  - phase: coverage-gate
    workflow_id: WORKFLOW-COMMON_SDD_COVERAGE_GATE_WORKFLOW
    reason: Prove at least 90% project-wide coverage after the final quality and security review when production code is in scope.
  - phase: mutation-gate
    workflow_id: WORKFLOW-COMMON_SDD_MUTATION_GATE_WORKFLOW
    reason: Prove the tests detect meaningful changes for L2 non-trivial logic and all L3 changes.
  - phase: critical-e2e
    workflow_id: WORKFLOW-COMMON_SDD_CRITICAL_E2E_WORKFLOW
    reason: Prove L3 critical journeys through the real browser or public boundary.
  - phase: sdd-policy
    workflow_id: WORKFLOW-COMMON_SDD_VALIDATE_CHANGE_WORKFLOW
    reason: Validate risk-aligned artifacts and ownership in CI/PR before merge.
  - phase: context-checkpoint
    workflow_id: WORKFLOW-COMMON_SDD_CONTEXT_CHECKPOINT_WORKFLOW
    reason: Pause at 60% context usage and create a resumable handoff for the next AI.
  - phase: documentation
    workflow_id: WORKFLOW-COMMON_SDD_UPDATE_DOCUMENTATION_WORKFLOW
    reason: Reconcile project and SDD documentation.
  - phase: complete
    workflow_id: WORKFLOW-COMMON_SDD_COMPLETE_SPEC_WORKFLOW
    reason: Verify, snapshot, index, and add the `-completed` suffix to the feature folder.
tasks:
  - task_id: T-0001-001
    workflow_id: WORKFLOW-GO_SDD_IMPLEMENT_CHANGE_WORKFLOW
    workflow_phase: acceptance-red
    supporting_workflow_ids:
      - WORKFLOW-COMMON_SDD_REVIEW_TEST_EVIDENCE_WORKFLOW
```

Use these routing rules:

- New spec: `WORKFLOW-COMMON_SDD_CREATE_SPEC_WORKFLOW`.
- BDD specification: `WORKFLOW-COMMON_BDD_SPECIFICATION_WORKFLOW`; keep scenarios business-readable and implementation-independent.
- Existing spec: `WORKFLOW-COMMON_SDD_EVOLVE_SPEC_WORKFLOW`.
- Defect diagnosis and fix: `WORKFLOW-COMMON_SDD_FIX_BUG_WORKFLOW`; language implementation workflows are supporting adapters, not replacements for the common defect lifecycle.
- Feature, integration, or pipeline implementation: the language `*-sdd-implement-change` workflow.
- Behavior-preserving refactor: the language `*-sdd-refactor-code` workflow.
- Acceptance and unit RED review: `WORKFLOW-COMMON_SDD_REVIEW_TEST_EVIDENCE_WORKFLOW`.
- Final coverage: `WORKFLOW-COMMON_SDD_COVERAGE_GATE_WORKFLOW`, mandatory for every completed spec and at `>= 90%` when production code is in scope.
- Mutation evidence: `WORKFLOW-COMMON_SDD_MUTATION_GATE_WORKFLOW` for L2 non-trivial logic and all L3 changes.
- Critical user journeys: `WORKFLOW-COMMON_SDD_CRITICAL_E2E_WORKFLOW` for L3 and explicitly critical flows.
- CI/PR structural validation: `WORKFLOW-COMMON_SDD_VALIDATE_CHANGE_WORKFLOW` through the `sdd-policy` check.
- Context continuity: `WORKFLOW-COMMON_SDD_CONTEXT_CHECKPOINT_WORKFLOW` at 60% consumed context or a compaction warning.
- Final security review: `WORKFLOW-COMMON_SDD_SECURITY_GATE_WORKFLOW`, mandatory before Gate 4 even when the scope is recorded as `security_role: none`.
- Final clean up: `WORKFLOW-COMMON_SDD_CLEAN_UP_GATE_WORKFLOW`, mandatory for every completed spec and before security/coverage re-verification.
- HTTP infrastructure setup/evidence: the language implementation workflow with `common-http-integration-harness.md` as a supporting rule.
- GitHub Actions: `WORKFLOW-COMMON_SDD_CREATE_GITHUB_ACTIONS_PIPELINE_WORKFLOW` plus the applicable language/service profile.
- Documentation: `WORKFLOW-COMMON_SDD_UPDATE_DOCUMENTATION_WORKFLOW`.
- Documentation gate: `RULE-COMMON_SDD_DOCUMENTATION_GATE` requires the documentation workflow before final quality, security, coverage, or completion approval.
- Completion, snapshot, and rename with the `-completed` suffix: `WORKFLOW-COMMON_SDD_COMPLETE_SPEC_WORKFLOW`.

Do not infer a workflow from a file path. Use the stable `workflow_id` and record why it is the most specific applicable procedure.

## Parallel Tracks

Every feature spec must define how many agents may work at the same time.

Every entry in `tasks.md` must explicitly define its execution semantics:

```yaml
- id: T-0001-003
  story_id: US-0001-001
  requirement_id: REQ-0001-001
  scenario_id: SCN-0001-001
  test_id: TEST-0001-002
  change_id: CHG-0001-001
  work_type: application-command
  workflow_id: WORKFLOW-GO_SDD_IMPLEMENT_CHANGE_WORKFLOW
  workflow_phase: unit-red
  supporting_workflow_ids:
    - WORKFLOW-COMMON_SDD_REVIEW_TEST_EVIDENCE_WORKFLOW
  track_id: TRK-0001-002
  parallelizable: true
  depends_on:
    - T-0001-001
  blocked_by: []
  can_run_with:
    - T-0001-004
  owns:
    - internal/orders/application/create_order/
  done_when:
    - focused_unit_test_green
```

`parallelizable: true` is valid only when ownership does not overlap and all dependencies are already complete. A task without these fields is incomplete.

Use `parallel-tracks.md` even when the answer is one agent:

```markdown
# Parallel Tracks

max_parallel_agents: 1
merge_policy: sequential

## Execution Waves

- wave: 1
  agent_slots: 1
  tasks: [T-0001-001]
- wave: 2
  agent_slots: 2
  tasks: [T-0001-003, T-0001-004]
- wave: 3
  agent_slots: 1
  tasks: [T-0001-005]

## Tracks

### TRK-0001-001: Acceptance Harness

- Agent slot: agent-1
- Tasks: T-0001-001, T-0001-002
- Owns:
  - specs/features/0001-feature-slug/acceptance.feature
  - tests/acceptance/
- Must not touch:
  - src/infrastructure/
- Can start when:
  - User Stories are verified.
- Blocks:
  - TRK-0001-002
```

Concurrency rules:

- Default to `max_parallel_agents: 1` until independent tracks are explicit.
- Use more than one agent only when tracks own different files, modules, boundaries, or scenario groups.
- Do not let two agents edit the same file, spec section, migration, public contract, or generated artifact concurrently.
- Keep one track responsible for convergence: `tasks.md`, `traceability.yaml`, `verification.md`, and final history notes.
- Merge tracks sequentially and rerun the affected checks after each merge.
- If tracks conflict, stop parallel work and update `parallel-tracks.md` before continuing.
- Do not merely state that parallel work is possible. Generate concrete execution waves and exact task-to-agent assignments.

## Numbering And Naming

- Use stable numeric prefixes: `0001-user-registration`, `0002-squad-radio`.
- Do not reuse numbers after a feature is archived.
- Keep slugs behavior-oriented, not implementation-oriented.
- User Story IDs use the feature number: `US-0001-001`.
- Requirement IDs use the feature number: `REQ-0001-001`.
- Scenario IDs use the feature number: `SCN-0001-001`.
- Task IDs use the feature number: `T-0001-001`.
- Track IDs use the feature number: `TRK-0001-001`.
- Test IDs use the feature number: `TEST-0001-001`.
- Artifact IDs use the feature number and artifact role: `ART-0001-SPEC`, `ART-0001-PLAN`, `ART-0001-HIST-20260710`.

## History Rules

Every conceptual change to a spec gets a history entry before implementation.

History entry shape:

```markdown
# 2026-07-10: Short Change Title

## Reason

Why the spec changed.

## Changed

- REQ-0001-003 changed from ...
- SCN-0001-002 added ...

## Verification Requested

- Who must verify this change, or why verification was not needed.

## Implementation Impact

- Tests to add or update.
- Contracts or migrations affected.
- Risks and rollout notes.
```

History entries are append-only. Do not rewrite old history to hide changed intent.

## Traceability Rules

`traceability.yaml` should answer:

- Which User Stories justify a requirement?
- Which scenarios prove a requirement?
- Which tasks implement a requirement?
- Which track, execution wave, and agent slot own each task?
- Which primary and supporting workflows govern each phase and task?
- Which tests prove a scenario?
- Which `CHG-*` row describes the planned and actual change?
- Which artifact file contains each story, scenario, plan, task, track, decision, and verification note?
- Which contracts or metrics support the behavior?
- Which requirements changed in a history entry?

Minimal shape:

```yaml
feature:
  id: FEAT-0001
  spec_id: SPEC-0001
  folder: specs/features/0001-squad-radio
artifacts:
  ART-0001-SPEC:
    path: specs/features/0001-squad-radio/spec.md
    contains:
      - US-0001-001
      - REQ-0001-001
  ART-0001-CHANGE-SUMMARY:
    path: specs/features/0001-squad-radio/change-summary.md
    contains:
      - CHG-0001-001
  ART-0001-ACCEPTANCE:
    path: specs/features/0001-squad-radio/acceptance.feature
    contains:
      - SCN-0001-001
  ART-0001-TASKS:
    path: specs/features/0001-squad-radio/tasks.md
    contains:
      - T-0001-001
  ART-0001-TRACKS:
    path: specs/features/0001-squad-radio/parallel-tracks.md
    contains:
      - TRK-0001-001
  ART-0001-SECURITY-REVIEW:
    path: specs/features/0001-squad-radio/security-review.md
    contains:
      - SEC-0001-001
  ART-0001-CODE-QUALITY-REVIEW:
    path: specs/features/0001-squad-radio/code-quality-review.md
    contains:
      - QUAL-0001-001
  ART-0001-WORKFLOW-ROUTING:
    path: specs/features/0001-squad-radio/workflow-routing.md
    contains:
      - WORKFLOW-COMMON_SDD_CREATE_SPEC_WORKFLOW
      - WORKFLOW-GO_SDD_IMPLEMENT_CHANGE_WORKFLOW
requirements:
  REQ-0001-001:
    user_story: US-0001-001
    scenarios:
      - SCN-0001-001
    tasks:
      - T-0001-001
    changes:
      - CHG-0001-001
    tests:
      TEST-0001-001: tests/acceptance/squad_radio.feature
      TEST-0001-002: tests/unit/radio_access_policy_test.go
    contracts: []
    metrics: []
parallel_tracks:
  TRK-0001-001:
    max_agents: 1
    tasks:
      - T-0001-001
    owns:
      - tests/acceptance/squad_radio.feature
workflows:
  spec-create:
    workflow_id: WORKFLOW-COMMON_SDD_CREATE_SPEC_WORKFLOW
  implementation:
    workflow_id: WORKFLOW-GO_SDD_IMPLEMENT_CHANGE_WORKFLOW
  test-evidence-review:
    workflow_id: WORKFLOW-COMMON_SDD_REVIEW_TEST_EVIDENCE_WORKFLOW
  code-quality-gate:
    workflow_id: WORKFLOW-COMMON_SDD_CLEAN_UP_GATE_WORKFLOW
  security-gate:
    workflow_id: WORKFLOW-COMMON_SDD_SECURITY_GATE_WORKFLOW
  coverage-gate:
    workflow_id: WORKFLOW-COMMON_SDD_COVERAGE_GATE_WORKFLOW
  documentation:
    workflow_id: WORKFLOW-COMMON_SDD_UPDATE_DOCUMENTATION_WORKFLOW
  completion:
    workflow_id: WORKFLOW-COMMON_SDD_COMPLETE_SPEC_WORKFLOW
snapshots:
  SNAP-20260710-001:
    path: specs/context/ai-snapshots/2026-07-10-squad-radio-snapshot.md
    source_spec: SPEC-0001
```

## Verification And Convergence

Before reporting done:

- `spec.md`, `acceptance.feature`, `plan.md`, `tasks.md`, `workflow-routing.md`, `parallel-tracks.md`, `traceability.yaml`, and `verification.md` must agree.
- Every spec artifact has an `ART-*` ID and appears in `traceability.yaml`.
- Completed tasks must point to passing tests or documented manual verification.
- Every production behavior change points to a unit-level `TEST-*` created before production code.
- Every task points to a primary `workflow_id`; supporting workflows are explicit when needed.
- Every completed spec records `WORKFLOW-COMMON_SDD_COVERAGE_GATE_WORKFLOW`; specs with production code record `>= 90%` project-wide coverage and affected-scope non-regression in `verification.md` and `change-summary.md`, while docs-only specs record `coverage_scope: none` and proof that no production files changed.
- Every completed spec records `WORKFLOW-COMMON_SDD_SECURITY_GATE_WORKFLOW` and a `security-review.md` decision in `verification.md` and `change-summary.md`.
- Every completed spec records `WORKFLOW-COMMON_SDD_CLEAN_UP_GATE_WORKFLOW` and a `code-quality-review.md` decision in `verification.md` and `change-summary.md`.
- Documentation changes are complete, or the spec records `no_documentation_change_reason`.
- The documentation gate outcome is recorded in `change-summary.md`, including the inspected surfaces and evidence for any `no_documentation_change_reason`.
- A completed feature has a completion approval, a folder named `specs/features/<number>-<slug>-completed/`, an AI snapshot, and an index entry.
- Any implementation change that alters behavior must update the spec and history.
- Any refactor that changes structure or boundaries must update plan, architecture notes, repository map, or decisions as needed.
- Any discovery-driven adjustment has an approved adjustment record, append-only history entry, synchronized artifacts, and the required gate reset; no proposed adjustment remains unresolved at completion.
- If a spec is intentionally not updated, state why the change is purely mechanical and behavior-preserving.
