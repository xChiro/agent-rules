---
rule_id: RULE-COMMON_WORKFLOW_TAXONOMY
trigger: model_decision
description: "Canonical SDD workflow names, work types, IDs, test suites, and cross-language equivalence."
---

# Common Workflow Taxonomy

Names are part of the agent interface. Keep the SDD lifecycle in `common`; language workflows only adapt execution details.

## Scope Prefixes And IDs

- `common-*`, `go-*`, `csharp-*`, `react-*`, and `web-*` identify scope.
- Rules: `RULE-<SCOPE>_<NAME>`.
- Workflows: `WORKFLOW-<SCOPE>_<NAME>_WORKFLOW`.
- Skills: `SKILL-<SCOPE>_<NAME>_SKILL`.
- IDs remain stable unless artifact intent changes materially.
- The stable filename stem mirrors the scope/name tokens in the canonical ID; the catalog validator derives one from the other. Renaming either side is an interface change, not a storage-only move.
- Every rule, workflow, skill, and SDD entity definition pairs its ID with a human-readable title. Display `<ID> — <title>` to humans; use separate ID/title fields in structured data.
- Frontmatter is valid YAML. Quote `description` and comma-separated `globs` values; a glob beginning with `*` must never be left as an unquoted YAML alias.

## Trigger Contract

- Rules and skills use only `always_on` or `model_decision`.
- Workflows use only `manual`, `model_decision`, or `automatic`.
- Reserve `always_on` for a compact baseline whose scope or `globs` matches the active project. Detailed architecture, testing, provider, and boundary guidance uses `model_decision`.
- Keep the complete catalog's `always_on` footprint at or below 2,500 physical lines; move specialized detail to `model_decision` instead of increasing the baseline.
- `manual` means the user or agent explicitly selects the workflow; `automatic` requires an objective condition defined by that workflow.
- Metadata selects candidates but never replaces routing: every task still records one primary workflow and any supporting workflow IDs in `workflow-routing.md`.

## Canonical SDD Workflows

Common lifecycle:

```text
common-sdd-create-spec.workflow.md
common-bdd-specification.workflow.md
common-sdd-evolve-spec.workflow.md
common-sdd-change-lifecycle.workflow.md
common-sdd-fix-bug.workflow.md
common-sdd-refactor-lifecycle.workflow.md
common-sdd-refactor-production-code.workflow.md
common-sdd-refactor-unit-tests.workflow.md
common-sdd-refactor-integration-tests.workflow.md
common-sdd-refactor-http-tests.workflow.md
common-sdd-migrate-legacy-tests.workflow.md
common-sdd-review-test-evidence.workflow.md
common-sdd-clean-up-gate.workflow.md
common-sdd-coverage-gate.workflow.md
common-sdd-mutation-gate.workflow.md
common-sdd-critical-e2e.workflow.md
common-sdd-validate-change.workflow.md
common-sdd-context-checkpoint.workflow.md
common-sdd-security-gate.workflow.md
common-sdd-create-github-actions-pipeline.workflow.md
common-rest-api-design.workflow.md
common-aws-lambda-rest.workflow.md
common-aws-sns-publish.workflow.md
common-aws-sqs-consumer.workflow.md
common-sdd-update-documentation.workflow.md
common-sdd-verify-spec.workflow.md
```

Backend language adapters:

```text
go-sdd-implement-change.workflow.md
go-rest-api.workflow.md
go-sdd-refactor-code.workflow.md
csharp-sdd-implement-change.workflow.md
csharp-rest-api.workflow.md
csharp-sdd-refactor-code.workflow.md
```

Do not add one workflow per endpoint, use case, adapter, event, consumer, or DI registration. The four common refactor tools are intentional category-level tools: production code, Domain/Application unit tests, infrastructure integration tests, and HTTP integration tests. They specialize the common refactor lifecycle; they do not create additional runtime suites. Documentation uses the common documentation workflow and is routed per task.

Every SDD lifecycle also loads `RULE-COMMON_SDD_DOCUMENTATION_GATE`. The gate is mandatory for create, evolve, fix, refactor, implementation, pipeline, and validation workflows; it always invokes `WORKFLOW-COMMON_SDD_UPDATE_DOCUMENTATION_WORKFLOW` and records either updated surfaces or an explicit `no_documentation_change_reason`.

React keeps `react-implement-feature.workflow.md`, `react-rest-api-client.workflow.md`, and the specialized `react-create-hbk-webapp-template.workflow.md`. Web keeps `web-implement-frontend-change.workflow.md`.

## Backend Work Types

Every backend task declares one canonical `work_type`:

```text
domain-rule
application-command
application-query
rest-endpoint
lambda-rest-endpoint
persistence-adapter
message-consumer
domain-event
sns-publisher
sqs-consumer
composition-root
boundary-integration-test
ci-pipeline
documentation
```

Work types select focused rules; they do not change the SDD lifecycle or the inside-out layer order. Split a vertical slice into small ordered tasks when it crosses boundaries.

Each task also declares `task_title`, `development_layer`, `layer_gate`, `track_id`, `track_title`, `parallelizable`, `depends_on`, `blocked_by`, `can_run_with`, ownership, execution wave, and agent slot. Parallel tasks are concrete scheduled work, not a narrative suggestion.

Canonical backend development layers are:

```text
domain
application
boundary
infrastructure
interface
composition
verification
documentation
```

`boundary` owns executable public acceptance evidence, while `interface` owns production delivery adapters such as REST/Lambda handlers and message consumers. Application-owned ports remain in `application`. Apply `RULE-COMMON_INSIDE_OUT_DEVELOPMENT`; new outer production tasks depend on `LAYER-GATE-APPLICATION`.

Change types are separate from backend work types:

```text
change_type: feature | bug-fix | refactor | pipeline | documentation
```

For `change_type: bug-fix`, use `common-sdd-fix-bug.workflow.md` as the common parent. The task still selects one concrete `work_type` from the list above. Classify the defect with `bug_kind: production-behavior | spec-contract | test-or-harness | flaky-or-nondeterministic | http-or-local-resource | duplicate-or-not-reproducible`.

## Backend Test Taxonomy

Only two runtime suites/folders are allowed:

- `unit`: domain/application behavior without external infrastructure.
- `integration`: executable integration evidence with exactly two focused scopes: `integration/http` and `integration/infrastructure`.

For compatibility, `integration/http` is the canonical public-entry scope path. HTTP systems send a real request; message, CLI, and worker systems use their equivalent real entry but describe the test as a boundary integration test, not an HTTP test, and do not apply the HTTP-specific harness. `integration/infrastructure` enters through the Application use case and verifies the real application port, persistence/messaging/storage adapter, and local resource. Both scopes may start Docker/Testcontainers or faithful emulators such as LocalStack and DynamoDB Local. Third-party APIs are isolated with WireMock or small hand-written HTTP stubs; external API behavior is simulated, while the application's integration wiring remains real. These are two scopes of one integration suite/job, not additional runtime suites.

Unit suites run first and open the core gate. Integration RED is created after the affected core is green and before affected outer production implementation; when outer production is unchanged, existing integration evidence runs GREEN. Go uses `testing` with approved `testify/assert` or `testify/require` assertions and hand-written outgoing-port doubles; tests may still import production APIs under test.

Canonical CI job names are `unit-tests` and `integration-tests`. Recommended policy/quality job names are `sdd-policy`, `sdd-mutation`, and `sdd-critical-e2e`. Build, lint, architecture, schema, security, package, deploy, E2E, mutation, and smoke checks may exist as quality gates, but they are not additional backend runtime suites. Every spec entering `verified` status runs the common security and coverage gates; mutation, critical-E2E, and policy gates remain risk-selected. Security checks are deterministic/static or belong inside the existing unit and integration suites.

Every pull request runs `common-sdd-validate-change.workflow.md` through the `sdd-policy` check. It validates artifact presence and risk alignment; the test, coverage, mutation, E2E, security, and architecture workflows remain responsible for proving their respective behavior.

`common-sdd-context-checkpoint.workflow.md` is the canonical continuity workflow. It pauses new work at 60% context usage and creates a resumable handoff in the active spec folder; it does not change the spec lifecycle status.

`common-bdd-specification.workflow.md` is the only common workflow for BDD meaning. Language and boundary workflows may define execution details, but must not change the business-language scenario contract.

`common-test-assertion-structure.md` is the common test layout: BDD uses Given/When/Then, code uses `// Arrange`, `// Act`, and `// Assert`, `// Act` has exactly one executable statement on one physical line that executes the layer-appropriate SUT/use case/public boundary, and assertions are only in `// Assert`.

`common-test-data-and-double-patterns.md` is the common test-data architecture: Object Mothers and Test Data Builders create fresh deterministic values, SUT factories expose dependencies, fixtures own lifecycle, and doubles replace only the ports or external simulators allowed by the test layer.

`common-test-layer-isolation.md` is the common execution contract: Domain, Application, and Boundary each have a standalone clean-state command and `depends_on_test_layer: none`; development order never authorizes shared test state.

Boundary workflows are supporting procedures, not alternatives to the SDD lifecycle. A language implementation workflow remains primary and must call the REST/Lambda/SNS/SQS workflow selected by `work_type` and record the invocation in the active spec.

## Legacy Workflow Migration

Map previous implementation workflows to `<language>-sdd-implement-change.workflow.md`:

```text
implement-business-feature
create-use-case
change-existing-business-logic
business-logic-test-cycle
create-rest-endpoint
create-api-integration-test
create-infrastructure-integration-test
create-persistence-adapter
implement-message-consumer
publish-domain-event
setup-dependency-injection
update-documentation
```

Map previous broad refactor workflows to the common category tool or the language adapter:

```text
refactor-production-code -> common-sdd-refactor-production-code.workflow.md
refactor-unit-tests -> common-sdd-refactor-unit-tests.workflow.md
refactor-integration-tests -> common-sdd-refactor-integration-tests.workflow.md
refactor-http-tests -> common-sdd-refactor-http-tests.workflow.md
refactor-test-code -> common-sdd-refactor-unit-tests.workflow.md
```

Use `common-sdd-migrate-legacy-tests.workflow.md` when the work changes the test suite structure or consolidates legacy test projects/folders. It is a supporting migration workflow, not a third runtime suite and not a replacement for the language refactor adapter when production code changes.

Map previous `update-documentation` workflows to `common-sdd-update-documentation.workflow.md`.

Route defect diagnosis and fixes through `common-sdd-fix-bug.workflow.md`; use the language SDD implementation workflow only as the execution adapter when production code is involved.

Do not keep alias/stub workflow files. Git history and this mapping preserve migration traceability without maintaining duplicate sources of truth. Infrastructure setup details belong to `common-http-integration-harness.md`; service-specific CI details belong to language/service profiles.

## Naming Rules

- Use `SDD`, `ATDD`, `BDD`, `spec`, `unit test`, `boundary integration test`, and `production code` consistently. Use `HTTP integration test` only for the HTTP specialization.
- Use `spec`, never `spect` or `specification file` when the shorter term is clear.
- Use `integration` for the canonical suite, with `HTTP integration` and `Infrastructure integration` as its two scopes; do not create separate API, repository, adapter, or message suites.
- Use behavior-oriented slugs and stable IDs.
- Give every stable ID an intent-revealing human title; task/change titles start with an action verb, and behavior/test titles state observable intent.
- Keep provider names out of general lifecycle filenames; dedicated provider-boundary workflows may name AWS when the resource/IaC/retry contract is provider-specific, as with Lambda, SNS, and SQS.
- Route every spec phase and task through `workflow-routing.md`; use the canonical frontmatter `workflow_id`, not a filename guess.
- Final evidence routing uses `WORKFLOW-COMMON_SDD_VERIFY_SPEC_WORKFLOW`; the feature folder remains at its stable path.
