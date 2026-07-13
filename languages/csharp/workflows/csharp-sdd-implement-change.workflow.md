---
workflow_id: WORKFLOW-CSHARP_SDD_IMPLEMENT_CHANGE_WORKFLOW
trigger: manual
description: Implement any small C# backend change through the common SDD/ATDD lifecycle.
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
| `http-integration-test` | `csharp-http-integration-tests.md`, `common-http-integration-harness.md` |
| `ci-pipeline` | `common-sdd-create-github-actions-pipeline.workflow.md` |
| `documentation` | owning spec and repository documentation |

Do not switch workflows when a vertical slice crosses work types. Split it into small ordered tasks under one spec.

## Required Test Order

1. Show the read-only SDD plan, including exact sequential/parallel tasks and agent slots, and obtain Gate 1 before spec writes.
2. Create/evolve User Stories, BDD scenarios, tasks, execution waves, tracks, and traceability.
3. Show the written artifacts and obtain Gate 2 before creating, modifying, or running tests.
4. Invoke the selected boundary workflow after BDD and before boundary-specific evidence: REST design, AWS Lambda REST, SNS publisher, or SQS consumer.
5. Write/confirm acceptance or HTTP integration RED.
6. Write focused domain/application `TEST-*` RED before production business logic.
7. Invoke `common-sdd-review-test-evidence.workflow.md` and obtain Gate 3 before production code.
8. Implement the smallest domain/application change.
9. Add EF Core, REST/Lambda, messaging, and DI changes only when required.
10. Make HTTP or message-boundary evidence green through real local resources.
11. Refactor with tests green and converge the spec.
12. Pass `RULE-COMMON_SDD_DOCUMENTATION_GATE` by invoking `WORKFLOW-COMMON_SDD_UPDATE_DOCUMENTATION_WORKFLOW` before completion; record affected surfaces or the workflow's explicit no-change result.

C# backends have only unit tests and HTTP integration tests. Do not add direct EF Core/repository/controller/adapter integration suites.

## REST And Lambda

- Invoke `WORKFLOW-CSHARP_REST_API_WORKFLOW` for the C# adapter and `WORKFLOW-COMMON_REST_API_DESIGN_WORKFLOW` for the provider-neutral contract before endpoint code.
- For Lambda, also invoke `WORKFLOW-COMMON_AWS_LAMBDA_REST_WORKFLOW`; record payload version, IaC, cost assumptions, and verification commands in `workflow-routing.md`.
- Model REST resources, DTOs, error contracts, and status codes before endpoint code.
- Keep controllers, Minimal APIs, and Lambda handlers thin.
- Keep ASP.NET, API Gateway, Lambda, EF Core, and AWS SDK types out of domain/application.
- For Lambda, update SAM/template route, method, authorizer, timeout, memory, environment, IAM, and local configuration only as required.
- Prove Lambda endpoints through local HTTP, preferably `sam local start-api`, using the real composition root and local resources.

## SNS And SQS

- `sns-publisher` invokes `WORKFLOW-COMMON_AWS_SNS_PUBLISH_WORKFLOW` and keeps the publisher port in application with the SNS adapter in infrastructure.
- `sqs-consumer` invokes `WORKFLOW-COMMON_AWS_SQS_CONSUMER_WORKFLOW` and keeps SQS/Lambda event, batch response, ACK/delete, retry, and logging decisions in the outer adapter.
- Apply `csharp-messaging-workers.md` for stable contracts, DTO-owned mapping, idempotency, retry, and poison-message behavior.
- Prove messaging through the repository's existing runtime/quality suites; do not add a third backend runtime suite.

## Verification

- Run focused unit test projects.
- Run the focused HTTP integration test project.
- Invoke `common-sdd-coverage-gate.workflow.md` and record `>= 90%` aggregate coverage for the complete project production scope with no affected-scope regression.
- Invoke `common-sdd-update-documentation.workflow.md` through the common documentation gate after verification and before completion approval.
- Run architecture, coverage, mutation, format, build, SAM/template, or security gates when touched or required by the spec.
- Record commands and evidence in `verification.md`.
