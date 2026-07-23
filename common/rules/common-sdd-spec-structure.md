---
rule_id: RULE-COMMON_SDD_SPEC_STRUCTURE
trigger: model_decision
description: "Folder structure, traceability, and history rules for SDD specs."
---

# Common SDD Spec Structure

Every project that uses SDD should keep specs as versioned engineering artifacts. The spec directory is not scratchpad context; it is the source of intent, behavior, constraints, and verification evidence. An active spec is mutable through the controlled `common-sdd-spec.workflow.md` protocol; its history remains append-only and plan drift requires approval.

Defect changes use the same folder shape as feature changes with `change_type: bug-fix`. They additionally include `bug-report.md` when the defect needs reproduction, classification, impact, or root-cause evidence. Use `BUG-*` for the defect, `REG-*` for regression evidence, and link the defect to its owning or source `FEAT-*`/`SPEC-*`. A verified, superseded, or retired source spec is never rewritten to erase a defect; create a new active defect spec when the source no longer owns the change.

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
│   └── operations.md
├── features/
│   ├── 0001-feature-slug/
│   │   ├── spec.md
│   │   ├── bug-report.md             # defect specs only
│   │   ├── change-summary.md
│   │   ├── acceptance.feature
│   │   ├── invariants.md              # required when domain is affected
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
│   └── 0001-squad-radio/
└── archive/
    └── 0000-retired-feature/
```

Use `specs/features/<number>-<slug>-<CURRENT_SPEC-STATUS>/` for every feature spec. The final suffix must equal the canonical lifecycle `status` in `spec.md`; for example, `0017-contracts-dashboard-icons-filter-spacing-verified/`. Keep the path stable while the status is unchanged. When the status changes, rename the folder and update every path reference in the same change. Use `archive/` only when a feature is retired, obsolete, or no longer drives implementation.

## Current Spec Status Suffix

The top-level status in `spec.md` is the single source of truth for the global lifecycle state. It must be one of:

```text
draft | proposed | approved | active | implemented | verified | superseded | retired
```

The feature folder must end in `-<status>` using lowercase ASCII text. The literal notation `-[CURRENT_SPEC-STATUS]` describes the required slot; it is not copied verbatim. Examples are `0001-radio-client-proposed`, `0005-authentication-active`, and `0013-blueprint-details-verified`.

Status changes are lifecycle changes, not cosmetic edits: update `spec.md`, append the relevant history/evidence, rename the feature folder, and update links, traceability paths, snapshots, and handoffs atomically. Never infer a global status from a filename that disagrees with `spec.md`.

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
- Artifact IDs: `ART-0001-SPEC`, `ART-0001-CHANGE-SUMMARY`, `ART-0001-ACCEPTANCE`, `ART-0001-INVARIANTS`, `ART-0001-PLAN`, `ART-0001-SECURITY-REVIEW`, `ART-0001-TASKS`, `ART-0001-WORKFLOW-ROUTING`, `ART-0001-TRACKS`, `ART-0001-TRACEABILITY`, `ART-0001-VERIFICATION`, `ART-0001-RED-GREEN-REFACTOR`, `ART-0001-HANDOFF`, `ART-0001-CONTEXT-HANDOFF`, `ART-0001-HIST-YYYYMMDD`.

## Human-Readable Titles For Every Stable ID

Every defined SDD element must pair its stable machine ID with a concise human-readable title. This applies to features, specs, artifacts, bugs, regressions, security and quality reviews/checks/findings, User Stories, requirements, scenarios, tasks, tracks, tests, changes, cycles, handoffs, checkpoints, adjustments, invariants, ADRs, and any future stable-ID element type. Agent rules, workflows, and skills follow the same contract through their frontmatter ID plus their human-readable Markdown heading or `name`.

Use this canonical display form in Markdown headings, lists, plans, status reports, approval gates, and handoffs:

```text
<STABLE-ID> — <human-readable title>
T-0001-001 — Add the focused retry-policy RED test
REQ-0001-002 — Reject retries after the configured limit
TEST-0001-003 — Retry exhaustion returns the domain error
```

The title is part of the element definition, not part of the ID. In structured metadata keep them as separate fields so tools can resolve the ID without parsing prose:

```yaml
task_id: T-0001-001
task_title: Add the focused retry-policy RED test
```

Apply these rules:

- A definition always includes both ID and title. A reference may use only the stable ID when its definition is linked or in the same artifact.
- Human-facing tables include separate `ID` and `Title` columns; prose may use the canonical `<ID> — <title>` display form.
- Titles are specific and intent-revealing. Do not use `Task 1`, `Requirement`, `Test`, filenames, workflow names, or an ID repeated as the title.
- Feature, spec, story, requirement, scenario, regression, invariant, and test titles describe observable behavior or business intent.
- Task and change titles start with an action verb and state one concrete outcome.
- Track titles describe owned responsibility or boundary. Review, finding, handoff, checkpoint, cycle, artifact, adjustment, and ADR titles state their purpose or decision.
- IDs remain stable when wording improves. Change an ID only when the element's intent changes materially; record that evolution in append-only history.
- Keep the same title for the same ID across `spec.md`, `change-summary.md`, `acceptance.feature`, `plan.md`, `tasks.md`, `workflow-routing.md`, `parallel-tracks.md`, `traceability.yaml`, `verification.md`, reports, handoffs, and history.

Gherkin keeps the scenario ID in a tag or comment and the human title in the `Scenario`/`Scenario Outline` line:

```gherkin
@SCN_0001_001
Scenario: Reject a retry after the configured limit
```

Markdown artifacts should start with metadata:

```yaml
---
feature_id: FEAT-0001
feature_title: Enforce notification retry limits
spec_id: SPEC-0001
spec_title: Notification retry-limit behavior
change_type: feature
artifact_id: ART-0001-PLAN
artifact_title: Notification retry-limit implementation plan
status: draft
created: 2026-07-10
updated: 2026-07-10
---
```

Gherkin artifacts should use comments when frontmatter is not supported:

```gherkin
# feature_id: FEAT-0001
# feature_title: Enforce notification retry limits
# spec_id: SPEC-0001
# spec_title: Notification retry-limit behavior
# artifact_id: ART-0001-ACCEPTANCE
# artifact_title: Notification retry-limit acceptance scenarios
```

Contracts, schemas, diagrams, ADRs, generated files, and manual QA notes also need artifact IDs when they are part of the spec. A file without an ID is not a stable SDD artifact.

## Agent Rule Artifact IDs

Agent rule, workflow, and skill files are style artifacts. They must also be traceable.

Use frontmatter IDs:

```yaml
---
rule_id: RULE-<SCOPE>_<NAME>
---
# Human-Readable Rule Title
```

```yaml
---
workflow_id: WORKFLOW-<SCOPE>_<NAME>_WORKFLOW
---
# Human-Readable Workflow Title
```

```yaml
---
skill_id: SKILL-<SCOPE>_<NAME>_SKILL
name: human-readable-skill-name
---
# Human-Readable Skill Title
```

Reference these IDs when a spec, history entry, or repository decision depends on a specific rule, workflow, or skill. Do not rely only on filename prose for durable traceability.

## Documentation Gate

Every SDD spec includes a traceable documentation task governed by `RULE-COMMON_SDD_DOCUMENTATION_GATE` and `WORKFLOW-COMMON_SDD_UPDATE_DOCUMENTATION_WORKFLOW`. This applies to spec creation, evolution, bug fixes, refactors, implementation changes, pipeline changes, and final validation. The task records the affected project/SDD documentation surfaces and verification evidence; when no project documentation surface is affected, it records `no_documentation_change_reason` in `spec.md`, `verification.md`, and `change-summary.md` after the workflow's surface analysis.

## Feature Spec Files

Minimum useful spec:

- `spec.md`: User Stories, actor, objective, requirements, out-of-scope, edge cases, non-functional constraints, and open questions.
- `change-summary.md`: human-readable summary of every planned and actual change, affected files, tests, workflows, documentation, risks, and rollback.
- `bug-report.md`: defect classification, reproduction evidence, actual/expected behavior, impact, root-cause analysis, and links to regression evidence. Required for defect specs when those details are not already captured in `change-summary.md`.
- `acceptance.feature`: BDD Given/When/Then scenarios for every meaningful User Story; executable acceptance mappings may be added later without replacing the business-language scenario.
- `plan.md`: a mandatory **Domain Model And Business Policy** section before architecture, followed by contracts, data, risks, testing strategy, observability, rollout/rollback, and **Development Sequence And Layer Gates** with canonical `layer_scope` YAML when backend code is in scope; `domain: not_affected` also requires `domain_not_affected_reason`.
- `security-review.md`: final security scope, identity role, trust boundaries, OAuth/OIDC and web-session evidence when applicable, scan commands, findings, exceptions, and security-gate decision. Every spec entering `verified` must contain it, including a `security_role: none` review when security impact is unchanged.
- `code-quality-review.md`: final review of every spec-created or spec-modified file, names, limits, ownership, Clean Code/SOLID/Clean Architecture/CQRS checks, findings, refactors, exceptions, and quality-gate decision. Every spec entering `verified` must contain it.
- `tasks.md`: inside-out ordered small tasks, each traceable to a requirement and verification method. Each backend task declares `development_layer`, `layer_gate`, one concrete outcome, `done_when`, `verification_command`, `next_step`, and explicit ownership/dependencies.
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

- `invariants.md` for domain rules that must always hold; required when the domain layer is `affected`, omitted when `domain: not_affected` is justified in `spec.md` and `plan.md`.
- `research.md` for tradeoffs, unknowns, spikes, and rejected options.
- `data-model.md` for entities, persistence shape, migrations, or state machines.
- `contracts/` for OpenAPI, AsyncAPI, JSON Schema, event schemas, or CLI contracts.
- `decisions/` for ADR-style records.
- `spec-adjustment-request.md` for an evidence-based plan/intent change; use `common/templates/spec-adjustment-request.md` and append the approved decision to `history/`.
- `ci-profile.md` when pipeline commands, local resources, artifacts, branch protection, environments, or deployment gates are part of the change.
- `mutation-report.md` when the mutation gate is required.
- `critical-e2e.md` when the critical E2E gate is required.

## Context Continuity

Context checkpoints are interim handoffs, not lifecycle evidence. At 60% consumed context, stop starting new tasks and update the active spec before requesting a context change. The checkpoint must leave `tasks.md`, `change-summary.md`, `verification.md`, `workflow-routing.md`, and `traceability.yaml` consistent enough for another AI to resume without reconstructing hidden context. Use `WORKFLOW-COMMON_SDD_CONTEXT_CHECKPOINT_WORKFLOW` and `tools/create-sdd-context-checkpoint.sh` when a context meter is available.

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

- `SCN-*` abstract acceptance scenario and its later executable public-boundary mapping.
- Domain/Application `TEST-*`: path, workflow, expected RED, hand-written doubles, and resulting layer gate.
- Boundary `TEST-*`: path, workflow, expected RED after the core gate when outer behavior changes.
- Per-layer isolation: `standalone_test_command`, `depends_on_test_layer: none`, owned state, setup/cleanup, and clean-process evidence.
- Scoped Gate 3 evidence required before each affected Green.

## Documentation And Operations

- Documentation files to create/update.
- CI, local resources, contracts, migrations, metrics, and runbooks affected.

## Risks, Non-Goals, And Rollback

- Risks and mitigations.
- Explicit out-of-scope behavior.
- Rollback or recovery approach.

## Execution Order

1. Spec and acceptance artifacts.
2. Domain RED, Gate 3-DOMAIN, GREEN/refactor, and `LAYER-GATE-DOMAIN`.
3. Application RED with hand-written outgoing-port doubles, Gate 3-APPLICATION, GREEN/refactor, and `LAYER-GATE-APPLICATION`.
4. Executable public-boundary RED and Gate 3-BOUNDARY only when outer production is affected; otherwise existing boundary evidence runs GREEN and the scope is `not_affected`.
5. Infrastructure, delivery interface, and composition/IaC GREEN, in that order.
6. Boundary GREEN, refactor, verification, documentation, and convergence.

## Actual Result

Updated during Converge with completed changes, deviations, tests, documentation, and residual risk.
```

Rules:

- Every planned production, test, infrastructure, CI, documentation, contract, migration, and operational change gets a `CHG-*` row.
- Every row names affected files/modules, primary workflow, track, sequence, and verification evidence.
- `status: proposed` describes the read-only Gate 1 proposal or a pre-existing draft; `approved` is written after Gate 1; `implemented` only after Green; `verified` only after Converge and the final evidence review approves it.
- Do not hide deviations. Add them to `Actual Result` and history.

## Spec Status And Context

The spec is a living source of truth. Use these lifecycle states in `spec.md` and `change-summary.md`:

- `draft`: the intent is being shaped and has not been proposed for implementation.
- `proposed`: the requirements, scenarios, constraints, and open questions are ready for review.
- `approved`: the intent and plan are approved for implementation.
- `active`: implementation or validation work is currently in progress.
- `implemented`: the approved behavior is implemented, but validation evidence is still open.
- `verified`: the implementation, tests, architecture, documentation, and risk-selected gates agree with the spec, and the final evidence review explicitly approved recording that state.
- `superseded`: another spec replaces this intent; link both specs and preserve history.
- `retired`: the behavior is intentionally removed or no longer maintained; record the decision and impact.

Use `WORKFLOW-COMMON_SDD_VERIFY_SPEC_WORKFLOW` for the final evidence review. It records `verified` in `spec.md` and synchronizes the feature folder to its `-verified` suffix after approval. Context checkpoints under `handoffs/context-checkpoints/` remain operational handoffs and never replace the active spec, traceability, verification, or append-only history. A repository may maintain an optional context summary for onboarding, but it is not lifecycle evidence.

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

After each affected scope reaches RED, the agent must present the actual test files, commands, failures, assertions, prior layer gates, and confirmation that production files for that scope are unchanged. The agent must ask for explicit approval before that scope's Green. This reusable Gate 3 is recorded as Gate 3-DOMAIN, Gate 3-APPLICATION, or Gate 3-BOUNDARY.

These gates apply even when the change is simple or unambiguous. Approval to discuss or plan is not approval to write spec files; approval to write spec files is not approval to start RED; approval to start RED is not approval to edit production code.

## Inside-Out Tests Before Production Code

Production code for a layer must not be edited until the current behavior has failing evidence at that layer and the prior inner gate has passed.

Required order for each implementation slice:

1. An abstract BDD acceptance scenario exists.
2. A domain unit test is RED and Gate 3-DOMAIN approves it when domain changes.
3. Domain GREEN/refactor passes `LAYER-GATE-DOMAIN`.
4. An application unit test is RED and Gate 3-APPLICATION approves it when application changes.
5. Application GREEN/refactor passes `LAYER-GATE-APPLICATION`.
6. When outer production is affected, the executable public-boundary test is RED and Gate 3-BOUNDARY approves it; otherwise existing boundary evidence is GREEN verification and Boundary is `not_affected`.
7. Affected infrastructure, delivery interfaces, and module-owned composition/IaC may then change in that order until the boundary is GREEN.

Boundary evidence alone is not enough for business-logic implementation. If a layer is genuinely unaffected, record `status: not_affected`, the reason, and existing evidence instead of inventing code or tests. If a true unit test is impossible because behavior only exists at a UI, CLI, generated-code, or HTTP boundary, start at the closest affected boundary and document the exception in `verification.md`.

The order above is an implementation sequence, not a test-runtime dependency. Domain, Application, and Boundary must each expose a focused command that passes from a clean process without another layer running first. Apply `RULE-COMMON_TEST_LAYER_ISOLATION` and record standalone plus combined results.

## Architecture Principles

Each spec must state the architecture constraints that apply to the feature. Use `plan.md`, `invariants.md`, or `decisions/` for details.

Default principles:

- Follow the project's existing architecture before introducing new structure.
- Apply SOLID as design pressure: one reason to change, small interfaces owned by consumers, dependencies inverted at boundaries, and substitutable adapters.
- Follow Clean Architecture boundaries for backend/domain work: domain and application stay independent from transport, persistence, framework, cloud SDK, UI, and deployment concerns.
- Follow CQRS when the project architecture uses it: commands change state, queries read state, and command-side decisions do not leak into query projections without an explicit mapping.
- Keep business rules in the owning domain/application/use case or frontend behavior boundary, not in adapters, controllers, views, persistence models, or framework callbacks.
- Name Application use cases with agent nouns that reveal the capability and actor-facing responsibility, for example `PartyCreator`, `MemberEnroller`, or `OrderCanceller`; use `party-creator` in human-facing slugs. Do not use generic `*UseCase`, `*Service`, or `*Handler` names for the use case itself.
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

Backend tasks additionally declare `development_layer` and `layer_gate`. Outer production tasks must depend on `LAYER-GATE-APPLICATION`; composition/IaC tasks also depend on the infrastructure and interface gates when those layers are affected. Composition is owned per business module; the executable root only invokes module composition entry points.

Every test task additionally declares `test_layer`, `standalone_test_command`, `depends_on_test_layer: none`, `isolation_scope`, owned mutable state, setup/cleanup, and the clean-state done condition.

Boundary routing examples:

- `rest-endpoint`: `WORKFLOW-COMMON_REST_API_DESIGN_WORKFLOW` + the language REST adapter.
- `lambda-rest-endpoint`: REST design + `WORKFLOW-COMMON_AWS_LAMBDA_REST_WORKFLOW` + the language REST adapter.
- `sns-publisher`: `WORKFLOW-COMMON_AWS_SNS_PUBLISH_WORKFLOW` + language messaging rules.
- `sqs-consumer`: `WORKFLOW-COMMON_AWS_SQS_CONSUMER_WORKFLOW` + language messaging rules.
- React REST client: REST design + `WORKFLOW-REACT_REST_API_CLIENT_WORKFLOW`.

Split a task when it touches unrelated actors, unrelated scenarios, multiple bounded contexts, unrelated filesystems/services, or more than one architectural boundary without a clear reason.

## Workflow Routing

Every spec must contain `workflow-routing.md`. Review its proposed contents at Gate 1 before spec writes; after writing the file, review the recorded routing again at Gate 2 before RED.

Each phase and task has one primary workflow. Supporting workflows may be listed when they add a focused procedure without changing ownership.

```yaml
feature_id: FEAT-0001
spec_id: SPEC-0001
artifact_id: ART-0001-WORKFLOW-ROUTING
phases:
  - phase: spec-create
    workflow_id: WORKFLOW-COMMON_SDD_SPEC_WORKFLOW
    reason: Create the folder, artifacts, IDs, and approval record.
  - phase: implementation
    workflow_id: WORKFLOW-GO_SDD_IMPLEMENT_CHANGE_WORKFLOW
    reason: Execute the selected Go work types.
  - phase: bdd-specification
    workflow_id: WORKFLOW-COMMON_BDD_SPECIFICATION_WORKFLOW
    reason: Discover value, examples, abstract business scenarios, and executable acceptance intent.
  - phase: test-evidence-review
    workflow_id: WORKFLOW-COMMON_SDD_REVIEW_TEST_EVIDENCE_WORKFLOW
    reason: Review scoped Domain, Application, or Boundary RED before that scope's Green.
  - phase: clean-up-gate
    workflow_id: WORKFLOW-COMMON_SDD_CLEAN_UP_GATE_WORKFLOW
    reason: Review all changed files, complete required Fowler refactors, and confirm the strict <150-line limit for maintained source, test, configuration, CI, and script files before final security and coverage gates.
  - phase: security-gate
    workflow_id: WORKFLOW-COMMON_SDD_SECURITY_GATE_WORKFLOW
    reason: Review changed trust boundaries, identity, secrets, web sessions, and security evidence before final validation.
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
  - phase: final-validation
    workflow_id: WORKFLOW-COMMON_SDD_VERIFY_SPEC_WORKFLOW
    reason: Validate convergence and record the spec status, renaming the feature folder when the global status changes.
tasks:
  - task_id: T-0001-001
    workflow_id: WORKFLOW-GO_SDD_IMPLEMENT_CHANGE_WORKFLOW
    workflow_phase: domain-red
    development_layer: domain
    layer_gate: LAYER-GATE-DOMAIN
    supporting_workflow_ids:
      - WORKFLOW-COMMON_SDD_REVIEW_TEST_EVIDENCE_WORKFLOW
```

Use these routing rules:

- New or modified spec: `WORKFLOW-COMMON_SDD_SPEC_WORKFLOW`.
- BDD specification: `WORKFLOW-COMMON_BDD_SPECIFICATION_WORKFLOW`; keep scenarios business-readable and implementation-independent.
- Existing spec: `WORKFLOW-COMMON_SDD_SPEC_WORKFLOW`.
- Defect diagnosis and fix: `WORKFLOW-COMMON_SDD_FIX_BUG_WORKFLOW`; language implementation workflows are supporting adapters, not replacements for the common defect lifecycle.
- Feature, integration, or pipeline implementation: the language `*-sdd-implement-change` workflow.
- Behavior-preserving refactor: the language `*-sdd-refactor-code` workflow.
- Scoped Domain, Application, or Boundary RED review: `WORKFLOW-COMMON_SDD_REVIEW_TEST_EVIDENCE_WORKFLOW`.
- Final coverage: `WORKFLOW-COMMON_SDD_COVERAGE_GATE_WORKFLOW`, mandatory for every spec entering `verified` status and at `>= 90%` when production code is in scope.
- Mutation evidence: `WORKFLOW-COMMON_SDD_MUTATION_GATE_WORKFLOW` for L2 non-trivial logic and all L3 changes.
- Critical user journeys: `WORKFLOW-COMMON_SDD_CRITICAL_E2E_WORKFLOW` for every L3 change; marking a flow critical escalates it to L3.
- CI/PR structural validation: `WORKFLOW-COMMON_SDD_VALIDATE_CHANGE_WORKFLOW` through the `sdd-policy` check.
- Context continuity: `WORKFLOW-COMMON_SDD_CONTEXT_CHECKPOINT_WORKFLOW` at 60% consumed context or a compaction warning.
- Final security review: `WORKFLOW-COMMON_SDD_SECURITY_GATE_WORKFLOW`, mandatory before final validation even when the scope is recorded as `security_role: none`.
- Final clean up: `WORKFLOW-COMMON_SDD_CLEAN_UP_GATE_WORKFLOW`, mandatory for every spec entering `verified` status and before security/coverage re-verification.
- HTTP infrastructure setup/evidence: the language implementation workflow with `common-http-integration-harness.md` as a supporting rule.
- GitHub Actions: `WORKFLOW-COMMON_SDD_CREATE_GITHUB_ACTIONS_PIPELINE_WORKFLOW` plus the applicable language/service profile.
- Documentation: `WORKFLOW-COMMON_SDD_UPDATE_DOCUMENTATION_WORKFLOW`.
- Documentation gate: `RULE-COMMON_SDD_DOCUMENTATION_GATE` requires the documentation workflow before final quality, security, coverage, or validation review.
- Final evidence review: `WORKFLOW-COMMON_SDD_VERIFY_SPEC_WORKFLOW` records `verified` and synchronizes the feature folder to its `-verified` suffix.

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

### TRK-0001-001: Public-Boundary Evidence

- Agent slot: agent-1
- Tasks: T-0001-001, T-0001-002
- Owns:
  - specs/features/0001-feature-slug-active/acceptance.feature
  - tests/integration/http/squad_radio/
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
  folder: specs/features/0001-squad-radio-active
artifacts:
  ART-0001-SPEC:
    path: specs/features/0001-squad-radio-active/spec.md
    contains:
      - US-0001-001
      - REQ-0001-001
  ART-0001-CHANGE-SUMMARY:
    path: specs/features/0001-squad-radio-active/change-summary.md
    contains:
      - CHG-0001-001
  ART-0001-ACCEPTANCE:
    path: specs/features/0001-squad-radio-active/acceptance.feature
    contains:
      - SCN-0001-001
  ART-0001-TASKS:
    path: specs/features/0001-squad-radio-active/tasks.md
    contains:
      - T-0001-001
  ART-0001-TRACKS:
    path: specs/features/0001-squad-radio-active/parallel-tracks.md
    contains:
      - TRK-0001-001
  ART-0001-SECURITY-REVIEW:
    path: specs/features/0001-squad-radio-active/security-review.md
    contains:
      - SEC-0001-001
  ART-0001-CODE-QUALITY-REVIEW:
    path: specs/features/0001-squad-radio-active/code-quality-review.md
    contains:
      - QUAL-0001-001
  ART-0001-WORKFLOW-ROUTING:
    path: specs/features/0001-squad-radio-active/workflow-routing.md
    contains:
      - WORKFLOW-COMMON_SDD_SPEC_WORKFLOW
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
      TEST-0001-001: tests/integration/http/squad_radio/access_test.go
      TEST-0001-002: tests/unit/radio/domain/radio_access_policy_test.go
    contracts: []
    metrics: []
parallel_tracks:
  TRK-0001-001:
    max_agents: 1
    tasks:
      - T-0001-001
    owns:
      - tests/integration/http/squad_radio/access_test.go
workflows:
  spec-create:
    workflow_id: WORKFLOW-COMMON_SDD_SPEC_WORKFLOW
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
  final-validation:
    workflow_id: WORKFLOW-COMMON_SDD_VERIFY_SPEC_WORKFLOW
```

## Verification And Convergence

Before reporting the spec as verified:

- `spec.md`, `acceptance.feature`, `plan.md`, `tasks.md`, `workflow-routing.md`, `parallel-tracks.md`, `traceability.yaml`, and `verification.md` must agree.
- Every spec artifact has an `ART-*` ID and appears in `traceability.yaml`.
- Completed tasks must point to passing tests or documented manual verification.
- Every core production behavior change points to a Domain/Application unit-level `TEST-*` created before production code. Pure infrastructure, delivery-interface, or composition changes point to the closest executable boundary `TEST-*` created before that outer production code.
- Every task points to a primary `workflow_id`; supporting workflows are explicit when needed.
- Every spec entering `verified` records `WORKFLOW-COMMON_SDD_COVERAGE_GATE_WORKFLOW`; specs with production code record `>= 90%` project-wide coverage and affected-scope non-regression in `verification.md` and `change-summary.md`, while documentation-only specs record `coverage_scope: none` and proof that no production files changed.
- Every spec entering `verified` records `WORKFLOW-COMMON_SDD_SECURITY_GATE_WORKFLOW` and a `security-review.md` decision in `verification.md` and `change-summary.md`.
- Every spec entering `verified` records `WORKFLOW-COMMON_SDD_CLEAN_UP_GATE_WORKFLOW` and a `code-quality-review.md` decision in `verification.md` and `change-summary.md`.
- Documentation changes are complete, or the spec records `no_documentation_change_reason`.
- The documentation gate outcome is recorded in `change-summary.md`, including the inspected surfaces and evidence for any `no_documentation_change_reason`.
- A verified feature has a validation decision and remains discoverable at its `specs/features/<number>-<slug>-verified/` path.
- Any implementation change that alters behavior must update the spec and history.
- Any refactor that changes structure or boundaries must update plan, architecture notes, repository map, or decisions as needed.
- Any discovery-driven adjustment has an approved adjustment record, append-only history entry, synchronized artifacts, and the required gate reset; no proposed adjustment remains unresolved at final validation.
- If a spec is intentionally not updated, state why the change is purely mechanical and behavior-preserving.
