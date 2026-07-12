---
rule_id: RULE-COMMON_SDD_AGENTIC_DISCIPLINE
trigger: always_on
description: Spec-Driven Development constitution for agentic work: spec-first, ATDD first, TDD, deterministic checks, and convergence.
---

# Common SDD Agentic Discipline

Use this rule as the constitution for all feature work, bug fixes, refactors, and reviews. The code serves the specification. The agent does not redefine success after implementation begins. Classify the change with `common-change-risk-classification.md` first so evidence scales without weakening the rules.

Before implementation, split the work into small `T-*` microtasks. Each microtask has one behavior partition or one boundary, one owner, one done condition, and one narrow verification command. Execute one step at a time and update `tasks.md`, `verification.md`, and `change-summary.md` before starting the next task. The active spec is mutable, but discovery that changes the approved plan or intent pauses work and requires impact analysis plus approval through `common-sdd-evolve-spec.workflow.md`. If context usage reaches 60%, invoke `common-sdd-context-checkpoint.workflow.md`, stop starting new tasks, update the active spec folder, and ask the user to move to a new context for the next AI.

## Non-Negotiable Loop

Every behavior-changing task follows this order. Risk classification selects additional evidence and scope-specific checks; it never authorizes skipping the approval-gated RED, unit-test-first, or Gate 3 sequence for executable behavior:

1. **Draft the SDD plan read-only**: inspect the repository, classify risk, and prepare the proposed spec folder, files, IDs, User Stories, BDD scenarios, architecture plan, tasks, parallel tracks, role assignments, workflow routing, and verification strategy without writing files.
2. **Human Gate 1 - Approve spec writes**: show that SDD plan and ask explicitly for permission to create or modify the proposed Markdown/spec artifacts. Do not write under `specs/` before approval.
3. **Create or evolve the spec**: after approval, create/update the folder, artifacts, User Stories, acceptance scenarios, plan, tasks, workflow routing, tracks, traceability, verification, and history.
4. **Human Gate 2 - Approve RED**: show exactly what was created or modified and ask explicitly for permission to continue to the RED phase. Do not create, modify, or run test code before approval.
5. **Acceptance RED**: create or update the executable acceptance/HTTP/component test first and confirm it fails for the intended reason when the harness supports RED evidence.
6. **Unit RED**: create the smallest focused unit-level test for one behavior partition and confirm it fails before production code changes.
7. **Human Gate 3 - Review test evidence**: show the actual RED tests, commands, failures, assertions, and unchanged production files. Ask explicitly for permission to write production code.
8. **Green**: implement only enough production code to pass the current failing test and record the result in `red-green-refactor.md`.
9. **Refactor**: improve structure only with tests green and without changing behavior; record the refactor evidence.
10. **Verify**: run targeted unit tests, backend HTTP integration or frontend interaction tests, required critical E2E/mutation checks, architecture checks, and quality gates.
11. **Code Quality Gate**: invoke `common-sdd-code-quality-gate.workflow.md`, review every created/modified file, and perform required behavior-preserving refactors through the refactor lifecycle.
12. **Security Gate**: invoke `common-sdd-security-gate.workflow.md`, review the changed trust boundaries and identity role, and prove no unresolved security findings remain.
13. **Coverage Gate**: invoke `common-sdd-coverage-gate.workflow.md` for every completed spec and prove at least 90% aggregate coverage across the complete project production scope when production code is in scope, with no affected-scope regression.
14. **Converge**: invoke the documentation workflow when documentation surfaces are affected, then update spec, plan, tasks, contracts, docs, code-quality review, security review, and verification notes so they match the final code and tests.
15. **Complete**: after final verification and human approval, invoke `common-sdd-complete-spec.workflow.md` to mark the spec completed, create the AI snapshot, update the index, and move the feature folder to `specs/features/completed/<number>-<slug>/`.
For a reported defect, invoke `common-sdd-fix-bug.workflow.md` before this lifecycle. Reproduce and classify it as a production, spec-contract, test/harness, flaky, HTTP/local-resource, or duplicate/non-reproducible defect. Never weaken the acceptance contract or rewrite a completed spec's history to make the defect disappear.

If a repository has no acceptance harness yet, use the closest executable boundary: backend HTTP integration test, frontend component/page interaction test, CLI smoke test, or documented manual QA checklist with clear pass/fail evidence.

When a project has `specs/context/ai-snapshots/index.md`, use the latest relevant snapshot as bounded AI context, then confirm current active specs and repository state before making decisions.

## Dynamic Spec Contract

The spec is a living baseline, not a frozen prediction. At every microtask boundary, compare new evidence with the approved intent and plan. If a discovery changes behavior, contracts, architecture, risk, test strategy, scope, ordering, ownership, or gates, pause and use `common/templates/spec-adjustment-request.md`. Show evidence, impact, proposed delta, alternatives, affected IDs/files, gate reset, and exact resume action; ask for approval before changing artifacts or continuing. After approval, invoke `common-sdd-evolve-spec.workflow.md`, append history, update traceability, and rebaseline tasks. Never hide a deviation or rewrite history to make it appear pre-approved.

## SDD Artifacts

Prefer small, reviewable artifacts over large ceremonial documents. Create only the artifacts needed for the risk and scope.

For product behavior, maintain or create:

- A feature spec built around User Stories: "As a <actor>, I want <capability>, so that <outcome>".
- Stable IDs for the feature, spec, artifacts, User Stories, requirements, scenarios, tasks, tracks, and tests.
- Acceptance scenarios in BDD Given/When/Then form for every meaningful User Story.
- Functional requirements, out-of-scope, edge cases, and success criteria derived from the stories.
- A technical plan that maps behavior to boundaries, contracts, data, observability, and risks.
- A final `security-review.md` artifact and `WORKFLOW-COMMON_SDD_SECURITY_GATE_WORKFLOW` evidence, including `security_role: none` when security impact is unchanged.
- A final `code-quality-review.md` artifact and `WORKFLOW-COMMON_SDD_CODE_QUALITY_GATE_WORKFLOW` evidence for every created or modified file.
- A `red-green-refactor.md` artifact using `common/templates/red-green-refactor-report.md` for every production behavior change, with one append-only cycle per behavior partition.
- Role handoffs under `handoffs/` for multi-agent work, using `common-agent-roles-and-handoffs.md`.
- A context checkpoint under `handoffs/context-checkpoints/` whenever the AI context reaches the 60% pause threshold, using `common/templates/context-handoff.md`.
- A `workflow-routing.md` artifact that selects the primary and supporting workflow for every SDD phase and task.
- A documentation task using `WORKFLOW-COMMON_SDD_UPDATE_DOCUMENTATION_WORKFLOW`, or an explicit `no_documentation_change_reason` in the spec when no documentation surface is affected.
- A completion route using `WORKFLOW-COMMON_SDD_COMPLETE_SPEC_WORKFLOW` for verified features, including the completed catalog move and AI snapshot.
- A `spec-adjustment-request` using `common/templates/spec-adjustment-request.md` whenever new evidence changes the approved plan or intent.
- Tasks that reference User Stories, requirements, scenarios, tracks, test IDs, artifact IDs, execution waves, and agent slots.
- Every task explicitly declares a primary `workflow_id` and `workflow_phase`; supporting workflow IDs are explicit when needed.
- Every task explicitly declares `track_id`, `parallelizable`, `depends_on`, `blocked_by`, `can_run_with`, and owned files/modules/contracts.
- Every task explicitly declares one concrete outcome, `done_when`, `verification_command`, and `next_step`; split any task that crosses unrelated behavior partitions or boundaries.
- A parallel track plan that states `max_parallel_agents`, concrete task-to-agent assignments, file/module ownership, dependencies, execution waves, and merge order.
- Verification notes that record which checks were run and what remains unverified.

For refactors, maintain or create:

- A refactor intent: what structure changes and what behavior must remain unchanged.
- Characterization or approval tests before restructuring when behavior is not already protected.
- A convergence note explaining why the external behavior is unchanged.

## Acceptance Test Discipline

- Use `common-bdd-specification.workflow.md` as the single source for BDD value, examples, language, and scenario quality.
- Acceptance scenarios describe observable behavior from User Stories, not private classes, methods, tables, or implementation details.
- Specs use BDD Given/When/Then language. Avoid implementation prose in the acceptance section.
- Acceptance tests must use a stable public boundary or acceptance harness when one exists.
- Do not loosen, delete, or rewrite acceptance scenarios to make implementation pass unless the user/product owner explicitly verifies the changed intent.
- For protected specs or locked scenarios, request verification before changing them.
- Keep traceability from requirement to scenario to task to test.

## TDD Discipline

- Tests come before production code for every behavior change.
- A unit-level test for the current rule is mandatory before editing production code. Acceptance evidence alone does not authorize production changes.
- Each unit/component/domain/application test that proves behavior should have or map to a stable `TEST-*` ID in `traceability.yaml`.
- Test code should use ATDD style: names, fixtures, and assertions should read as Given/When/Then behavior whenever practical.
- Each RED → GREEN → REFACTOR cycle covers one behavior partition; do not combine unrelated rules into one failing test or implementation step.
- Record concise Red, Green, and Refactor evidence in `red-green-refactor.md`; do not substitute private chain-of-thought for reproducible commands and results.
- Unit tests drive domain/application design after the acceptance scenario exists, but they still describe acceptance behavior and business examples rather than private implementation.
- All assertion APIs (`assert`, `require`, `expect`, `Should`, or equivalents) stay in the test's `Then/Assert` section; Given/Arrange, When/Act, fixtures, and helpers do not assert.
- Backend HTTP integration tests or frontend component/page tests cover real boundaries when the task touches those boundaries.
- If a true unit test cannot exist for the slice, create the closest unit-level/component test and document the exception in `verification.md` before production code.
- Avoid coverage theater: no tests that only instantiate DTOs, call getters, assert constants, or mirror implementation details.
- Prefer equivalence partitions, edge cases, property-style tests, and mutation-resistant assertions for important rules.

## Architecture Discipline

- Respect the local architecture as the primary constraint.
- Apply SOLID to keep responsibilities narrow, interfaces consumer-owned, and dependencies pointed toward stable policy.
- Use Clean Architecture boundaries for backend/domain work: domain and application must not depend on transport, persistence, framework, cloud SDK, UI, or deployment details.
- Use CQRS where the project architecture expects it: commands change state, queries read state, and projections/mappings are explicit.
- Keep business decisions in domain/application/use case or the owning frontend behavior boundary. Adapters translate; they do not own policy.
- Do not add speculative layers, ports, repositories, mediators, or factories unless they protect a current requirement, risk, or boundary in the spec.

## Parallel Agent Discipline

Parallel work is allowed only when the spec defines it.

- Default to one agent per spec.
- Increase `max_parallel_agents` only in `parallel-tracks.md`.
- Each track must own explicit tasks and files/modules/contracts/spec sections.
- Each parallel wave must list exact task IDs and agent slots; implicit parallelism is not valid.
- No two agents may edit the same file, public contract, migration, generated artifact, or spec section at the same time.
- Merge tracks sequentially and rerun affected tests after each merge.
- One track must own final convergence of `tasks.md`, `traceability.yaml`, `verification.md`, and history.
- The convergence track must also own `workflow-routing.md` and documentation tasks.
- If a conflict appears, stop parallel work, reduce concurrency, and update the track plan before continuing.

## Refactoring Under SDD

Refactoring is behavior-preserving convergence, not a license to change scope.

- Refactor only after the relevant tests are green.
- For pure refactor tasks, add or identify characterization tests first.
- Make one structural change at a time and rerun the smallest relevant test set.
- Update specs, plans, tasks, architecture docs, or repository maps when the refactor changes structure or boundaries.
- Do not mix broad cleanup with behavior change unless the cleanup directly reduces risk for the current spec.

## Deterministic Feedback Controls

Instructions are not enough. Critical policies should have executable checks when practical:

- Acceptance tests for user-visible behavior.
- Unit tests for domain/application rules.
- Architecture/dependency tests for boundaries and cycles.
- Static OpenAPI/schema compatibility checks for public APIs/events when contracts exist.
- Lint/type/build checks for static correctness.
- Coverage thresholds for touched critical code.
- Mandatory final coverage gate at or above 90% for the complete project production scope when production code is in scope, with no affected-scope regression.
- Mandatory final security gate with no unresolved Critical/High findings and explicit handling of lower-severity exceptions.
- Mandatory final code-quality gate for names, file/function limits, ownership, Clean Code, SOLID, Clean Architecture, CQRS, duplication, complexity, and refactoring evidence.
- CRAP/complexity checks when the ecosystem supports them.
- Risk-based mutation and critical-E2E gates are routed through the common mutation and critical-E2E workflows.
- Automated SDD/PR structural validation runs through `tools/validate-sdd-change.sh` when the repository uses this catalog.
- Context continuity is routed through `common-sdd-context-checkpoint.workflow.md`; `tools/create-sdd-context-checkpoint.sh` creates the append-only handoff when a context meter is available.
- Performance, security, and observability checks when those criteria are part of the spec.

When a deterministic check does not exist, record the manual verification performed and the risk that remains.

## Mandatory Human Gates

Every task that creates or evolves SDD artifacts has three non-optional implementation approval points, followed by a mandatory Gate 4 completion approval before the spec is finalized:

### Gate 1: Approve Spec Writes

Before creating directories or changing any spec artifact, show:

- Proposed spec folder and every file to create or modify.
- Proposed feature, spec, artifact, User Story, requirement, scenario, task, track, and test IDs.
- Any approved-spec delta discovered since the last baseline, with its adjustment analysis and affected gates.
- User Stories and summarized Given/When/Then scenarios.
- Out-of-scope, open questions, architecture constraints, work types, test strategy, and quality gates.
- `max_parallel_agents`, track ownership, dependencies, and merge order.

Ask a direct question requesting approval to create or modify those artifacts. Reading and analysis may continue; filesystem writes to spec artifacts may not.

### Gate 2: Approve RED

After spec artifacts are written, show:

- Files created or modified.
- Final User Stories, scenarios, tasks, parallel tracks, and traceability summary.
- Planned acceptance/HTTP/component RED test and first focused unit RED test.
- Remaining clarifications, assumptions, risks, and manual verification.

Ask a direct question requesting approval to begin the RED phase. Before approval, do not create, modify, or execute test code and do not edit production code.

### Gate 3: Approve Test Evidence Before Green

After the acceptance/public-boundary test and focused unit-level test have been created and run, invoke `common-sdd-review-test-evidence.workflow.md`.

Show:

- Test IDs, files, Given/When/Then intent, commands, and concise RED output.
- Why each failure proves the intended missing behavior.
- Assertions, edge cases, fixtures, resource isolation, and parallel-track ownership.
- Confirmation that production files remain unchanged.

Ask a direct question requesting approval to edit production code and continue to Green. If the tests are rejected, modify only the authorized spec/test artifacts, rerun RED, and ask again. Record the decision and evidence in `verification.md`.

No production code may be created, modified, or refactored before Gate 3. The first three gates may not be skipped because a change appears simple, low risk, mechanical, or unambiguous. After implementation, quality, security, coverage, documentation, and convergence, Gate 4 must approve completion, snapshot creation, and the move to `specs/features/completed/<number>-<slug>/`. If implementation or discovery later changes intent, pause, analyze the adjustment, obtain approval through `common-sdd-evolve-spec.workflow.md`, then return to Gate 1 and repeat Gate 2 and Gate 3 before resuming.
