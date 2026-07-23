---
workflow_id: WORKFLOW-GO_SDD_IMPLEMENT_CHANGE_WORKFLOW
trigger: manual
description: "Implement any small Go backend change through the common SDD/ATDD lifecycle."
---

# Go SDD Implement Change Workflow

This is the only Go backend implementation workflow. It is a global workflow. Do not search for it under the current project's `.windsurf/workflows/`; invoke it as `/go-sdd-implement-change`. Its common parent workflows are sibling global workflows: `common-sdd-spec.workflow.md` and `common-sdd-change-lifecycle.workflow.md`.

## Select The Work Type

Every task in `tasks.md` declares one `work_type` and the rules it loads:

| Work type | Primary rules |
| --- | --- |
| `domain-rule` | `go-business-logic-unit-tests.md`, `go-solid-design.md` |
| `application-command` | `go-use-cases.md`, `go-clean-architecture.md` |
| `application-query` | `go-use-cases.md`, `go-clean-architecture.md` |
| `rest-endpoint` | `go-rest-api.workflow.md`, `common-rest-api-design.workflow.md`, `go-rest-api.md`, `go-http-integration-tests.md`, `common-http-integration-harness.md` |
| `lambda-rest-endpoint` | `go-rest-api.workflow.md`, `common-rest-api-design.workflow.md`, `common-aws-lambda-rest.workflow.md`, `go-rest-api.md`, `go-http-integration-tests.md`, `common-http-integration-harness.md` |
| `persistence-adapter` | `go-clean-architecture.md`, `go-dependency-injection.md`, `go-http-integration-tests.md`, `common-http-integration-harness.md` |
| `message-consumer` | `go-domain-events.md` |
| `domain-event` | `go-domain-events.md` |
| `sns-publisher` | `common-aws-sns-publish.workflow.md`, `go-domain-events.md` |
| `sqs-consumer` | `common-aws-sqs-consumer.workflow.md`, `go-domain-events.md` |
| `composition-root` | `go-dependency-injection.md` |
| `boundary-integration-test` | `go-http-integration-tests.md` for HTTP boundaries plus the selected message workflow and `go-test-suites.md` |
| `ci-pipeline` | `common-sdd-create-github-actions-pipeline.workflow.md`, `go-sam-github-actions.md` |
| `documentation` | owning spec and repository documentation |

Do not switch workflows when a vertical slice crosses work types. Split it into small ordered tasks and keep one owning spec.

## Required Test Order

For each behavior slice:

1. Show the read-only SDD plan, including exact sequential/parallel tasks and agent slots, and obtain Gate 1 before spec writes.
2. Create or evolve User Stories, abstract BDD scenarios, layer scope, inside-out tasks, execution waves, tracks, and traceability.
3. Show the written artifacts and obtain Gate 2 before creating, modifying, or running tests.
4. When domain is affected, write Domain RED using real domain values; obtain Gate 3-DOMAIN, implement/refactor Domain GREEN, and pass `LAYER-GATE-DOMAIN`.
5. When application is affected, write Application RED using only hand-written doubles for outgoing ports; obtain Gate 3-APPLICATION, implement/refactor Application GREEN, and pass `LAYER-GATE-APPLICATION`.
6. Invoke the selected boundary workflow after the core gate: REST design, AWS Lambda REST, SNS publisher, SQS consumer, or React client when the Go service is paired with that client.
7. When outer production is affected, write/confirm executable RED before production: use the real HTTP/message boundary for `integration/http`, or invoke the Application use case with the real adapter path and local resource for `integration/infrastructure`. Obtain Gate 3-BOUNDARY with the integration scope recorded; otherwise run existing boundary evidence GREEN and record `not_affected`.
8. Implement infrastructure adapters, then delivery interfaces, then module-owned composition/DI/IaC. Do not move business logic outward; the use-case-driven infrastructure RED must turn GREEN against the real local resource.
9. Make HTTP or message-boundary evidence green through the real composition root and local resources, and make infrastructure-scope evidence green through the use case and real adapter implementation.
10. Refactor each layer with tests green and converge all spec artifacts and layer-gate evidence.
11. Pass `RULE-COMMON_SDD_DOCUMENTATION_GATE` by invoking `WORKFLOW-COMMON_SDD_UPDATE_DOCUMENTATION_WORKFLOW` before final validation; record affected surfaces or the workflow's explicit no-change result.

Domain and Application code must use provider-neutral names for files, packages, ports, types, DTOs, events, and errors. Names such as `DynamoDB`, `Cosmos`, and `Kafka` belong only to Infrastructure adapters, mapping, and composition; name inner elements after the business capability they serve.

Go backends have only `tests/unit/` and `tests/integration/`. Do not add a third integration folder; repository/adapter/handler evidence belongs under the HTTP or Infrastructure scope.

Each business module owns `internal/<module>/di` and exposes one initializer/module output. The executable root aggregates module outputs only; it does not enumerate the module's providers, adapters, use cases, handlers, or consumers.

Go uses `testing` for the runner and `testify/assert` or `testify/require` for assertions. Do not use `require.NoError(t, err)`; use an explicit context-rich `if err != nil` check with `t.Fatalf` when continuation is unsafe, or `assert.NoError` when continuation is safe. Tests may import production APIs under test, but do not add generated mocks or mocking frameworks. Domain tests use real domain objects; application tests use small hand-written stubs, fakes, spies, or mocks for outgoing ports.
Use fresh Object Mothers/Test Data Builders for scenario data, focused SUT factories for explicit wiring, and scoped fixtures for lifecycle; no helper may assert or hide business policy.

## REST And Lambda

- Invoke `WORKFLOW-GO_REST_API_WORKFLOW` for the Go adapter and `WORKFLOW-COMMON_REST_API_DESIGN_WORKFLOW` for the provider-neutral contract before handler code.
- For Lambda, also invoke `WORKFLOW-COMMON_AWS_LAMBDA_REST_WORKFLOW`; record payload version, IaC, cost assumptions, and verification commands in `workflow-routing.md`.
- Model REST resources and contracts before handler code.
- Keep routers and Lambda handlers thin: parse, authenticate, validate, call one use case, map response.
- Keep API Gateway/Lambda event types out of domain/application.
- Keep provider names such as DynamoDB, Cosmos, Kafka, SNS, and SQS out of Domain/Application names even when the selected boundary uses those technologies.
- For Lambda, update SAM/template routing, method, authorizer, timeout, memory, environment, IAM, and local configuration only as required by the spec.
- Prove Lambda endpoints through local HTTP, preferably `sam local start-api`, with the real composition root and local resources.
- Keep production infrastructure and application behavior in separate tasks/tracks when ownership is independent.

## SNS And SQS

- `sns-publisher` invokes `WORKFLOW-COMMON_AWS_SNS_PUBLISH_WORKFLOW` and keeps the publisher port in `application` with the SNS adapter in `infrastructure`.
- `sqs-consumer` invokes `WORKFLOW-COMMON_AWS_SQS_CONSUMER_WORKFLOW` and keeps SQS/Lambda event, batch response, ACK/delete, retry, and logging decisions in the outer adapter.
- Apply `go-domain-events.md` for the stable envelope, DTO-owned mapping, idempotency, outbox decision, and poison-message behavior.
- Prove messaging through the repository's existing runtime/quality suites; do not add a third backend runtime suite.

## Verification

- Run focused unit tests without build tags.
- Run focused integration tests with `-tags=integration` under `tests/integration/http/...` and/or `tests/integration/infrastructure/...` as applicable.
- Invoke `common-sdd-coverage-gate.workflow.md` and record `>= 90%` aggregate coverage for the complete project production scope with no affected-scope regression.
- Invoke `common-sdd-update-documentation.workflow.md` through the common documentation gate after implementation is complete and required test evidence is green, and before final validation.
- Run race, architecture, coverage, mutation, lint, format, build, or SAM validation gates when touched or required by the spec.
- Record commands and evidence in `verification.md`.
