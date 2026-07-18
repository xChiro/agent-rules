---
workflow_id: WORKFLOW-CSHARP_SDD_IMPLEMENT_CHANGE_WORKFLOW
trigger: manual
description: "Implement any small C# backend change through the common SDD/ATDD lifecycle."
---

# C# SDD Implement Change Workflow

This is the only C# backend implementation workflow. It is a global workflow. Do not search for it under the current project's `.windsurf/workflows/`; invoke it as `/csharp-sdd-implement-change`. Its common parent workflows are sibling global workflows: `common-sdd-create-spec.workflow.md`, `common-sdd-evolve-spec.workflow.md`, and `common-sdd-change-lifecycle.workflow.md`.

## Select The Work Type

Every task in `tasks.md` declares one `work_type` and the rules it loads:

| Work type | Primary rules |
| --- | --- |
| `domain-rule` | `csharp-business-logic-unit-tests.md`, `csharp-domain-modeling.md` |
| `application-command` | `csharp-use-cases.md`, `csharp-clean-architecture.md` |
| `application-query` | `csharp-use-cases.md`, `csharp-clean-architecture.md` |
| `rest-endpoint` | `csharp-rest-api.workflow.md`, `common-rest-api-design.workflow.md`, `csharp-rest-api.md`, `csharp-http-integration-tests.md`, `common-http-integration-harness.md` |
| `lambda-rest-endpoint` | `csharp-rest-api.workflow.md`, `common-rest-api-design.workflow.md`, `common-aws-lambda-rest.workflow.md`, `csharp-rest-api.md`, `csharp-http-integration-tests.md`, `common-http-integration-harness.md` |
| `persistence-adapter` | `csharp-efcore-data-access.md`, `csharp-http-integration-tests.md`, `common-http-integration-harness.md` |
| `message-consumer` | `csharp-messaging-workers.md` |
| `domain-event` | `csharp-messaging-workers.md` |
| `sns-publisher` | `common-aws-sns-publish.workflow.md`, `csharp-messaging-workers.md` |
| `sqs-consumer` | `common-aws-sqs-consumer.workflow.md`, `csharp-messaging-workers.md` |
| `composition-root` | `csharp-dependency-injection.md` |
| `boundary-integration-test` | `csharp-http-integration-tests.md` for HTTP boundaries plus the selected message workflow for broker boundaries |
| `ci-pipeline` | `common-sdd-create-github-actions-pipeline.workflow.md` |
| `documentation` | owning spec and repository documentation |

Do not switch workflows when a vertical slice crosses work types. Split it into small ordered tasks under one spec.

## Required Test Order

1. Show the read-only SDD plan, including exact sequential/parallel tasks and agent slots, and obtain Gate 1 before spec writes.
2. Create/evolve User Stories, abstract BDD scenarios, layer scope, inside-out tasks, execution waves, tracks, and traceability.
3. Show the written artifacts and obtain Gate 2 before creating, modifying, or running tests.
4. Write Domain RED, obtain Gate 3-DOMAIN, then complete Domain GREEN/refactor and pass `LAYER-GATE-DOMAIN` when affected.
5. Write Application RED, obtain Gate 3-APPLICATION, then complete Application GREEN/refactor and pass `LAYER-GATE-APPLICATION` when affected.
6. Invoke the selected boundary workflow after the core gate: REST design, AWS Lambda REST, SNS publisher, or SQS consumer.
7. When outer production is affected, write/confirm executable RED before production: use the real HTTP/message boundary for the HTTP scope, or invoke the Application use case with the real adapter path and local resource for the Infrastructure scope. Obtain Gate 3-BOUNDARY with the integration scope recorded; otherwise run existing boundary evidence GREEN and record `not_affected`.
8. Add EF Core/infrastructure adapters, delivery interfaces, and module-owned composition/DI/IaC in that order; make Infrastructure-scope RED GREEN against the real local resource.
9. Make HTTP or message-boundary evidence green through real local resources, and make Infrastructure-scope evidence green through the use case and real adapter implementation.
10. Refactor with tests green and converge the spec and layer gates.
11. Pass `RULE-COMMON_SDD_DOCUMENTATION_GATE` by invoking `WORKFLOW-COMMON_SDD_UPDATE_DOCUMENTATION_WORKFLOW` before final validation; record affected surfaces or the workflow's explicit no-change result.

Domain and Application code must use provider-neutral names for files, namespaces, ports, types, DTOs, events, and errors. Names such as `DynamoDB`, `Cosmos`, and `Kafka` belong only to Infrastructure adapters, mapping, and composition; name inner elements after the business capability they serve.

C# backends have only unit tests for Domain/Application and one integration test project for outer behavior. Keep HTTP/public-entry and use-case-driven Infrastructure adapter/resource tests as separate scopes within that project; do not create another integration project.

Apply `common-test-data-and-double-patterns.md`: use fresh Object Mothers/Test Data Builders, focused SUT factories, scoped fixtures, manual outgoing-port doubles, and no assertions or business policy inside Arrange helpers.

Each business module exposes `Add<Module>Domain`, `Add<Module>Application`, `Add<Module>Infrastructure`, `Add<Module>Interface`, and `Add<Module>Module`. Keep the Domain assembly framework-free by hosting its registration extension in the module's outer composition assembly. The executable host calls only `Add<Module>Module` for module-owned services.

## REST And Lambda

- Invoke `WORKFLOW-CSHARP_REST_API_WORKFLOW` for the C# adapter and `WORKFLOW-COMMON_REST_API_DESIGN_WORKFLOW` for the provider-neutral contract before endpoint code.
- For Lambda, also invoke `WORKFLOW-COMMON_AWS_LAMBDA_REST_WORKFLOW`; record payload version, IaC, cost assumptions, and verification commands in `workflow-routing.md`.
- Model REST resources, DTOs, error contracts, and status codes before endpoint code.
- Keep controllers, Minimal APIs, and Lambda handlers thin.
- Keep ASP.NET, API Gateway, Lambda, EF Core, and AWS SDK types out of domain/application.
- Keep provider names such as DynamoDB, Cosmos, Kafka, SNS, and SQS out of Domain/Application names even when the selected boundary uses those technologies.
- For Lambda, update SAM/template route, method, authorizer, timeout, memory, environment, IAM, and local configuration only as required.
- Prove Lambda endpoints through local HTTP, preferably `sam local start-api`, using the real composition root and local resources.

## SNS And SQS

- `sns-publisher` invokes `WORKFLOW-COMMON_AWS_SNS_PUBLISH_WORKFLOW` and keeps the publisher port in application with the SNS adapter in infrastructure.
- `sqs-consumer` invokes `WORKFLOW-COMMON_AWS_SQS_CONSUMER_WORKFLOW` and keeps SQS/Lambda event, batch response, ACK/delete, retry, and logging decisions in the outer adapter.
- Apply `csharp-messaging-workers.md` for stable contracts, DTO-owned mapping, idempotency, retry, and poison-message behavior.
- Prove messaging through the repository's existing runtime/quality suites; do not add a third backend runtime suite.

## Verification

- Run focused unit test projects.
- Run the focused boundary integration test project through HTTP or the real local message entry mechanism.
- Invoke `common-sdd-coverage-gate.workflow.md` and record `>= 90%` aggregate coverage for the complete project production scope with no affected-scope regression.
- Invoke `common-sdd-update-documentation.workflow.md` through the common documentation gate after implementation is complete and required test evidence is green, and before final validation.
- Run architecture, coverage, mutation, format, build, SAM/template, or security gates when touched or required by the spec.
- Record commands and evidence in `verification.md`.
