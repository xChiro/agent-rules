# Agent Rules

[![License: CC0-1.0](https://img.shields.io/badge/license-CC0%201.0-lightgrey.svg)](https://creativecommons.org/publicdomain/zero/1.0/)

Reusable rules, workflows, and skills for AI coding agents. The repository follows Spec-Driven Development with ATDD first: User Stories and BDD scenarios define behavior, acceptance evidence frames the change, focused unit tests fail before production code, and deterministic gates prove convergence.

## Repository Map

```text
common/
  rules/       # SDD constitution, risk, roles, spec structure, taxonomy, guardrails
  workflows/   # Shared SDD lifecycle, mutation, E2E, and operational workflows
  skills/      # Cross-language engineering behavior
  templates/   # Standard evidence and handoff templates

languages/
  go/          # Go rules, REST/messaging adapters, SDD workflows, skills
  csharp/      # C# rules, REST/messaging adapters, SDD workflows, skills
  react/       # React + TypeScript + Vite feature/API-client workflows
  web/         # Lightweight web rules and workflow

tools/
  validate-sdd-change.sh       # CI/PR SDD policy validator
  validate-bdd-spec.sh         # abstract BDD language/structure lint
  create-sdd-context-checkpoint.sh # 60% context handoff automation
  tests/                       # validator contract tests
  windsurf/    # Cleanup of deprecated project-local Windsurf copies
```

Project-local copies are not sources of truth. Refactored reusable assets live here under `common/` and `languages/`.

## Global Windsurf Installation

Install the repository into the machine-wide Windsurf store:

```bash
bash tools/windsurf/install-global.sh
bash tools/windsurf/verify-global.sh
```

The installer publishes:

```text
~/.codeium/windsurf/common/                 # canonical full catalog
~/.codeium/windsurf/common/templates/       # handoff/checkpoint templates
~/.codeium/windsurf/memories/global_rules.md
~/.codeium/windsurf/global_workflows/
~/.codeium/windsurf/skills/<name>/SKILL.md
```

Compatibility symlinks under `~/.codeium/` expose the same catalog to the Windsurf/Codeium plugins used by GoLand, WebStorm, and Rider. Previous global customizations are archived under `~/.codeium/windsurf/agent-rules-backups/`, outside discovered rule/workflow/skill paths.

On macOS the installer also publishes system-level assets under `/Library/Application Support/Windsurf/{rules,workflows,skills}`. This is required by Cascade in JetBrains when it does not resolve the user-level workflow directory; it keeps workflows available without adding `.windsurf/workflows/` to each project.

If the macOS account cannot write `/Library/Application Support/Windsurf`, the installer leaves the user-level Windsurf catalog intact and reports the limitation. In that case use Windsurf/Devin Desktop, or have an administrator run the installer; do not copy the workflows into projects.

The administrator-only step can be run separately with `sudo bash tools/windsurf/install-system.sh`.

Do not copy these assets into project `.windsurf/`, `.agents/`, `.devin/`, `AGENTS.md`, or `.windsurfrules` locations. Feature specs remain project-owned under `specs/`; only reusable agent behavior is global.

Devin cloud currently manages Skills & Rules at organization/repository scope and cannot read this machine-local catalog. Devin Desktop uses the Windsurf store as the local fallback; use Windsurf rather than adding repository-local copies when cloud-level configuration is unavailable.

## SDD Lifecycle

Every behavior change follows:

```text
read-only SDD plan
  -> Human Gate 1: approve creation/modification of spec folders and files
  -> discover value, examples, and abstract BDD scenarios
  -> create User Stories, acceptance evidence, change-summary, plan, tasks, routing and traceability
  -> Human Gate 2: approve starting RED
  -> acceptance or HTTP integration RED
  -> focused unit-level TEST-* RED
  -> Human Gate 3: approve actual RED test evidence
  -> smallest production change
  -> GREEN
  -> refactor with tests green
  -> code quality review and required refactor
  -> security review gate
  -> mutation/E2E gates when risk requires them
  -> mandatory project-wide coverage gate >= 90% when production code is in scope
  -> at 60% context: checkpoint the spec and request a new context
  -> deterministic gates
  -> documentation and spec/code/test convergence
  -> Human Gate 4: approve completion
  -> AI snapshot and move the spec folder to specs/features/completed/<number>-<slug>/
```

Reported defects enter through `common-sdd-fix-bug.workflow.md`: reproduce, classify, preserve or explicitly evolve the behavior contract, write regression evidence, then continue through the same approval-gated SDD/TDD cycle.

All four human gates are mandatory. Approval to discuss the plan does not authorize spec writes; approval to create spec files does not authorize test changes or execution; approval to start RED does not authorize production code.

BDD owns shared business meaning and executable examples. SDD owns intent and traceability. ATDD proves the actor-visible outcome. TDD drives domain/application design. Production code must not be edited until the current focused unit-level test exists and fails for the intended reason.

Shared lifecycle files:

- [common-sdd-agentic-discipline.md](./common/rules/common-sdd-agentic-discipline.md)
- [common-sdd-spec-structure.md](./common/rules/common-sdd-spec-structure.md)
- [common-sdd-spec-evolution.md](./common/rules/common-sdd-spec-evolution.md)
- [common-workflow-taxonomy.md](./common/rules/common-workflow-taxonomy.md)
- [common-architecture-guardrails.md](./common/rules/common-architecture-guardrails.md)
- [common-change-risk-classification.md](./common/rules/common-change-risk-classification.md)
- [common-context-continuity.md](./common/rules/common-context-continuity.md)
- [common-agent-roles-and-handoffs.md](./common/rules/common-agent-roles-and-handoffs.md)
- [common-security-and-identity.md](./common/rules/common-security-and-identity.md)
- [common-code-quality-guardrails.md](./common/rules/common-code-quality-guardrails.md)
- [common-test-assertion-structure.md](./common/rules/common-test-assertion-structure.md)
- [common-sdd-create-spec.workflow.md](./common/workflows/common-sdd-create-spec.workflow.md)
- [common-bdd-specification.workflow.md](./common/workflows/common-bdd-specification.workflow.md)
- [common-rest-api-design.workflow.md](./common/workflows/common-rest-api-design.workflow.md)
- [common-aws-lambda-rest.workflow.md](./common/workflows/common-aws-lambda-rest.workflow.md)
- [common-aws-sns-publish.workflow.md](./common/workflows/common-aws-sns-publish.workflow.md)
- [common-aws-sqs-consumer.workflow.md](./common/workflows/common-aws-sqs-consumer.workflow.md)
- [common-sdd-evolve-spec.workflow.md](./common/workflows/common-sdd-evolve-spec.workflow.md)
- [common-sdd-change-lifecycle.workflow.md](./common/workflows/common-sdd-change-lifecycle.workflow.md)
- [common-sdd-fix-bug.workflow.md](./common/workflows/common-sdd-fix-bug.workflow.md)
- [common-sdd-refactor-lifecycle.workflow.md](./common/workflows/common-sdd-refactor-lifecycle.workflow.md)
- [common-sdd-review-test-evidence.workflow.md](./common/workflows/common-sdd-review-test-evidence.workflow.md)
- [common-sdd-code-quality-gate.workflow.md](./common/workflows/common-sdd-code-quality-gate.workflow.md)
- [common-sdd-coverage-gate.workflow.md](./common/workflows/common-sdd-coverage-gate.workflow.md)
- [common-sdd-mutation-gate.workflow.md](./common/workflows/common-sdd-mutation-gate.workflow.md)
- [common-sdd-critical-e2e.workflow.md](./common/workflows/common-sdd-critical-e2e.workflow.md)
- [common-sdd-validate-change.workflow.md](./common/workflows/common-sdd-validate-change.workflow.md)
- [common-sdd-context-checkpoint.workflow.md](./common/workflows/common-sdd-context-checkpoint.workflow.md)
- [common-sdd-security-gate.workflow.md](./common/workflows/common-sdd-security-gate.workflow.md)
- [common-sdd-update-documentation.workflow.md](./common/workflows/common-sdd-update-documentation.workflow.md)
- [common-sdd-complete-spec.workflow.md](./common/workflows/common-sdd-complete-spec.workflow.md)

## Spec Structure

Each feature owns a folder with multiple versioned artifacts:

```text
specs/
├── constitution.md
├── context/
│   └── ai-snapshots/
├── features/
│   ├── 0001-feature-slug/
│   │   ├── spec.md
│   │   ├── change-summary.md
│   │   ├── acceptance.feature
│   │   ├── plan.md
│   │   ├── spec-adjustment-request.md   # only when discovery changes the plan
│   │   ├── security-review.md
│   │   ├── code-quality-review.md
│   │   ├── tasks.md
│   │   ├── workflow-routing.md
│   │   ├── parallel-tracks.md
│   │   ├── red-green-refactor.md
│   │   ├── handoffs/
│   │   │   ├── HANDOFF-0001-001.md
│   │   │   ├── latest-context-handoff.md
│   │   │   └── context-checkpoints/
│   │   ├── traceability.yaml
│   │   ├── verification.md
│   │   └── history/
│   └── completed/
│       └── 0001-feature-slug/
└── archive/
```

Stable IDs connect intent to evidence:

```text
FEAT-0001       SPEC-0001       ART-0001-SPEC
BUG-0001-001    REG-0001-001
QUAL-0001-001   QUALITY-FINDING-0001-001
US-0001-001     REQ-0001-001    SCN-0001-001
T-0001-001      TRK-0001-001    TEST-0001-001
CHG-0001-001    SNAP-20260710-001
HANDOFF-0001-001
CYCLE-0001-001
CHECKPOINT-20260711-120000
```

`parallel-tracks.md` always defines `max_parallel_agents`, ownership, dependencies, must-not-touch boundaries, and merge order. Default to one agent. Every task is small, step-by-step, and has one outcome, done condition, verification command, and next step. History entries are append-only. Pipeline changes may add `ci-profile.md` for concrete commands and deployment evidence.

Every task in `tasks.md` declares `track_id`, `parallelizable`, `depends_on`, `blocked_by`, `can_run_with`, ownership, and execution wave. When parallel execution is safe, the spec must generate concrete waves with exact task IDs and agent slots; saying only “these tasks can run in parallel” is insufficient.

Every task also declares its primary `workflow_id`, `workflow_phase`, and any supporting workflow IDs in `workflow-routing.md` and `traceability.yaml`.

`change-summary.md` is the human-readable record of every planned and actual change. At 60% consumed context, the active spec is checkpointed under `handoffs/context-checkpoints/` and the user is asked to change context; the next AI reads that handoff first. After final verification and approval, `common-sdd-complete-spec.workflow.md` moves the feature folder to `specs/features/completed/<number>-<slug>/` and creates an AI context snapshot under `specs/context/ai-snapshots/`.

Every pull request runs `tools/validate-sdd-change.sh` through the `sdd-policy` check. Every spec completion runs `common-sdd-code-quality-gate.workflow.md`, `common-sdd-security-gate.workflow.md`, and `common-sdd-coverage-gate.workflow.md`; when production code is in scope, the complete project production scope must reach at least 90% before Gate 4. Mutation and critical E2E gates are selected by risk level.

## Backend Workflow Model

The SDD lifecycle lives in `common`. Go and C# only adapt language-specific execution:

```text
languages/go/workflows/
├── go-sdd-implement-change.workflow.md
├── go-rest-api.workflow.md
└── go-sdd-refactor-code.workflow.md

languages/csharp/workflows/
├── csharp-sdd-implement-change.workflow.md
├── csharp-rest-api.workflow.md
└── csharp-sdd-refactor-code.workflow.md
```

Each spec task selects a `work_type` rather than another workflow:

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

A vertical slice may use several work types, but it remains under one spec and one SDD implementation workflow.

## Backend Test Model

Backend repositories have exactly two runtime test suites:

- `unit`: fast domain/application behavior without external infrastructure.
- `http-integration`: real HTTP through a server or API Gateway/Lambda boundary into local databases and resources.

All test suites use `common-test-assertion-structure.md`: Arrange/Given and Act/When do not assert; every assertion is in the final Then/Assert section.

HTTP integration tests exercise routing, serialization, auth/session context, validation, use cases, DI, persistence mappings/schema, local services, errors, and response contracts. Direct handler, controller, Lambda function, repository, DbContext, or adapter invocation is not an HTTP integration test.

Do not create separate infrastructure, API, repository, adapter, handler, end-to-end, Lambda, or contract runtime test suites. Checked-in OpenAPI/schema validation may remain a static gate.

Canonical CI job names:

```text
unit-tests
http-integration-tests
sdd-policy
sdd-mutation          # L2 non-trivial and L3
sdd-critical-e2e      # L3 critical journeys
```

Build, lint, format, architecture, security, package, deploy, mutation, E2E, and smoke checks are allowed as quality gates, but are not additional backend runtime test suites.

## Go

Core rules:

- [go-clean-architecture.md](./languages/go/rules/go-clean-architecture.md)
- [go-clean-code.md](./languages/go/rules/go-clean-code.md)
- [go-project-structure.md](./languages/go/rules/go-project-structure.md)
- [go-solid-design.md](./languages/go/rules/go-solid-design.md)
- [go-use-cases.md](./languages/go/rules/go-use-cases.md)
- [go-business-logic-unit-tests.md](./languages/go/rules/go-business-logic-unit-tests.md)
- [go-http-integration-tests.md](./languages/go/rules/go-http-integration-tests.md)
- [go-sam-github-actions.md](./languages/go/rules/go-sam-github-actions.md)
- [go-rest-api.md](./languages/go/rules/go-rest-api.md)
- [go-test-suites.md](./languages/go/rules/go-test-suites.md)

Focused rules:

- [go-advanced-practices.md](./languages/go/rules/go-advanced-practices.md)
- [go-dependency-injection.md](./languages/go/rules/go-dependency-injection.md)
- [go-domain-events.md](./languages/go/rules/go-domain-events.md)
- [go-error-boundaries.md](./languages/go/rules/go-error-boundaries.md)

Workflows and skills:

- [go-sdd-implement-change.workflow.md](./languages/go/workflows/go-sdd-implement-change.workflow.md)
- [go-rest-api.workflow.md](./languages/go/workflows/go-rest-api.workflow.md)
- [go-sdd-refactor-code.workflow.md](./languages/go/workflows/go-sdd-refactor-code.workflow.md)
- [go-backend-senior-skill.md](./languages/go/skills/go-backend-senior-skill.md)
- [go-business-logic-testing-skill.md](./languages/go/skills/go-business-logic-testing-skill.md)
- [go-ddd-cqrs-modeling-skill.md](./languages/go/skills/go-ddd-cqrs-modeling-skill.md)

## C# / .NET

Core rules:

- [csharp-clean-architecture.md](./languages/csharp/rules/csharp-clean-architecture.md)
- [csharp-clean-code.md](./languages/csharp/rules/csharp-clean-code.md)
- [csharp-solid-design.md](./languages/csharp/rules/csharp-solid-design.md)
- [csharp-domain-modeling.md](./languages/csharp/rules/csharp-domain-modeling.md)
- [csharp-use-cases.md](./languages/csharp/rules/csharp-use-cases.md)
- [csharp-business-logic-unit-tests.md](./languages/csharp/rules/csharp-business-logic-unit-tests.md)
- [csharp-http-integration-tests.md](./languages/csharp/rules/csharp-http-integration-tests.md)
- [csharp-rest-api.md](./languages/csharp/rules/csharp-rest-api.md)

Focused rules:

- [csharp-dependency-injection.md](./languages/csharp/rules/csharp-dependency-injection.md)
- [csharp-efcore-data-access.md](./languages/csharp/rules/csharp-efcore-data-access.md)
- [csharp-error-boundaries.md](./languages/csharp/rules/csharp-error-boundaries.md)
- [csharp-messaging-workers.md](./languages/csharp/rules/csharp-messaging-workers.md)

Workflows and skills:

- [csharp-sdd-implement-change.workflow.md](./languages/csharp/workflows/csharp-sdd-implement-change.workflow.md)
- [csharp-rest-api.workflow.md](./languages/csharp/workflows/csharp-rest-api.workflow.md)
- [csharp-sdd-refactor-code.workflow.md](./languages/csharp/workflows/csharp-sdd-refactor-code.workflow.md)
- [csharp-backend-senior-skill.md](./languages/csharp/skills/csharp-backend-senior-skill.md)
- [csharp-business-logic-testing-skill.md](./languages/csharp/skills/csharp-business-logic-testing-skill.md)
- [csharp-ddd-cqrs-modeling-skill.md](./languages/csharp/skills/csharp-ddd-cqrs-modeling-skill.md)
- [csharp-refactoring-skill.md](./languages/csharp/skills/csharp-refactoring-skill.md)

## REST And Lambda

REST resource, status, DTO, error, compatibility, observability, and security rules apply equally to long-running servers and API Gateway/Lambda.

The common REST workflow defines the contract. Go and C# adapter workflows define language execution; the Lambda workflow adds explicit API Gateway payload/IaC, thin handlers, reusable clients, idempotency, bounded concurrency, and measured memory/duration choices. Lambda endpoints keep API Gateway/AWS types in the outer adapter, use least-privilege IAM, and call the same application use cases as other adapters. They are proven through local HTTP, preferably `sam local start-api`, with production-equivalent local database/resources.

SNS publication and SQS consumption use dedicated supporting workflows. SNS is selected for fan-out facts; SQS is selected for durable buffering/consumer isolation. Both require stable DTO-owned mappings, idempotency, explicit retry/DLQ behavior, and ATDD/TDD evidence without adding a third backend runtime suite.

The backend boundary decision is recorded in [ADR-0001-backend-http-integration-boundary.md](./common/decisions/ADR-0001-backend-http-integration-boundary.md). The shared setup, isolation, cleanup, and evidence contract is [common-http-integration-harness.md](./common/rules/common-http-integration-harness.md).

## GitHub Actions

[common-sdd-create-github-actions-pipeline.workflow.md](./common/workflows/common-sdd-create-github-actions-pipeline.workflow.md) creates SDD-aligned pipelines. Backend validation runs `unit-tests` and `http-integration-tests`; old infrastructure/API integration jobs are merged into the HTTP suite while concrete service commands and artifacts remain in the generated workflow/profile. Deploys require both jobs and keep credentials away from pull requests.

## React

React uses feature-oriented frontend architecture without forcing backend Clean Architecture:

- [react-feature-architecture.md](./languages/react/rules/react-feature-architecture.md)
- [react-vite-api-client.md](./languages/react/rules/react-vite-api-client.md)
- [react-advanced-patterns-skill.md](./languages/react/skills/react-advanced-patterns-skill.md)
- [react-implement-feature.workflow.md](./languages/react/workflows/react-implement-feature.workflow.md)
- [react-rest-api-client.workflow.md](./languages/react/workflows/react-rest-api-client.workflow.md)
- [react-create-hbk-webapp-template.workflow.md](./languages/react/workflows/react-create-hbk-webapp-template.workflow.md)

The HBK template workflow remains specialized. `hbk-identity-webapp` is its canonical reference for stack, providers, theme, i18n, shared primitives, tests, scripts, and project shape. Template components begin with failing component tests.

## Web

- [web-frontend-architecture.md](./languages/web/rules/web-frontend-architecture.md)
- [web-implement-frontend-change.workflow.md](./languages/web/workflows/web-implement-frontend-change.workflow.md)

## Legacy Workflow Migration

Old feature, use-case, REST, persistence, messaging, event, DI, test-cycle, and documentation workflows map to `<language>-sdd-implement-change.workflow.md`. Old production/test/infrastructure refactor workflows map to `<language>-sdd-refactor-code.workflow.md`. Their concrete HTTP harness steps live in `common-http-integration-harness.md`, and their service-specific CI steps live in language/service profiles.

No alias workflow files are retained. The detailed map is in [common-workflow-taxonomy.md](./common/rules/common-workflow-taxonomy.md), and Git preserves file history.

## License

This project is released into the public domain under the CC0 1.0 Universal license. See [LICENSE.md](./LICENSE.md).
