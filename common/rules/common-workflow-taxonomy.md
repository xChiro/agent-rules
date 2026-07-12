---
rule_id: RULE-COMMON_WORKFLOW_TAXONOMY
trigger: always_on
description: Canonical SDD workflow names, work types, IDs, test suites, and cross-language equivalence.
---

# Common Workflow Taxonomy

Names are part of the agent interface. Keep the SDD lifecycle in `common`; language workflows only adapt execution details.

## Scope Prefixes And IDs

- `common-*`, `go-*`, `csharp-*`, `react-*`, and `web-*` identify scope.
- Rules: `RULE-<SCOPE>_<NAME>`.
- Workflows: `WORKFLOW-<SCOPE>_<NAME>_WORKFLOW`.
- Skills: `SKILL-<SCOPE>_<NAME>_SKILL`.
- IDs remain stable unless artifact intent changes materially.

## Canonical SDD Workflows

Common lifecycle:

```text
common-sdd-create-spec.workflow.md
common-bdd-specification.workflow.md
common-sdd-evolve-spec.workflow.md
common-sdd-change-lifecycle.workflow.md
common-sdd-fix-bug.workflow.md
common-sdd-refactor-lifecycle.workflow.md
common-sdd-review-test-evidence.workflow.md
common-sdd-code-quality-gate.workflow.md
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
common-sdd-complete-spec.workflow.md
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

Do not add one workflow per endpoint, use case, adapter, event, consumer, DI registration, or test category. Those are small tasks and work types inside one SDD change. Documentation uses the common documentation workflow and is routed per task.

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
http-integration-test
ci-pipeline
documentation
```

Work types select focused rules; they do not change the SDD lifecycle. Split a vertical slice into small ordered tasks when it crosses boundaries.

Each task also declares `track_id`, `parallelizable`, `depends_on`, `blocked_by`, `can_run_with`, ownership, execution wave, and agent slot. Parallel tasks are concrete scheduled work, not a narrative suggestion.

Change types are separate from backend work types:

```text
change_type: feature | bug-fix | refactor | pipeline | documentation
```

For `change_type: bug-fix`, use `common-sdd-fix-bug.workflow.md` as the common parent. The task still selects one concrete `work_type` from the list above. Classify the defect with `bug_kind: production-behavior | spec-contract | test-or-harness | flaky-or-nondeterministic | http-or-local-resource | duplicate-or-not-reproducible`.

## Backend Test Taxonomy

Only two runtime suites are allowed:

- `unit`: domain/application behavior without external infrastructure.
- `http-integration`: real HTTP through server or API Gateway/Lambda into local databases/resources.

Canonical CI job names are `unit-tests` and `http-integration-tests`. Recommended policy/quality job names are `sdd-policy`, `sdd-mutation`, and `sdd-critical-e2e`. Build, lint, architecture, schema, security, package, deploy, E2E, mutation, and smoke checks may exist as quality gates, but they are not additional backend runtime suites. Every completed spec runs the common security and coverage gates; mutation, critical-E2E, and policy gates remain risk-selected. Security checks are deterministic/static or belong inside the existing unit and HTTP integration suites.

Every pull request runs `common-sdd-validate-change.workflow.md` through the `sdd-policy` check. It validates artifact presence and risk alignment; the test, coverage, mutation, E2E, security, and architecture workflows remain responsible for proving their respective behavior.

`common-sdd-context-checkpoint.workflow.md` is the canonical continuity workflow. It pauses new work at 60% context usage and creates a resumable handoff in the active spec folder; it does not mark a feature complete or replace Gate 4.

`common-bdd-specification.workflow.md` is the only common workflow for BDD meaning. Language and boundary workflows may define execution details, but must not change the business-language scenario contract.

`common-test-assertion-structure.md` is the common test layout: assertions are only in `Then/Assert`; setup and action code never asserts.

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

Map previous refactor workflows to `<language>-sdd-refactor-code.workflow.md`:

```text
refactor-production-code
refactor-test-code
refactor-infrastructure-integration-test
```

Map previous `update-documentation` workflows to `common-sdd-update-documentation.workflow.md`.

Route defect diagnosis and fixes through `common-sdd-fix-bug.workflow.md`; use the language SDD implementation workflow only as the execution adapter when production code is involved.

Do not keep alias/stub workflow files. Git history and this mapping preserve migration traceability without maintaining duplicate sources of truth. Infrastructure setup details belong to `common-http-integration-harness.md`; service-specific CI details belong to language/service profiles.

## Naming Rules

- Use `SDD`, `ATDD`, `BDD`, `spec`, `unit test`, `HTTP integration test`, and `production code` consistently.
- Use `spec`, never `spect` or `specification file` when the shorter term is clear.
- Use `HTTP integration`, not separate `API integration` and `infrastructure integration` labels.
- Use behavior-oriented slugs and stable IDs.
- Keep provider names out of general lifecycle filenames; dedicated provider-boundary workflows may name AWS when the resource/IaC/retry contract is provider-specific, as with Lambda, SNS, and SQS.
- Route every spec phase and task through `workflow-routing.md`; use the canonical frontmatter `workflow_id`, not a filename guess.
- Completion and snapshot routing use `WORKFLOW-COMMON_SDD_COMPLETE_SPEC_WORKFLOW`; move active specs only through that workflow after Gate 4 approval.
