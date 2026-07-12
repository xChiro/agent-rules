---
workflow_id: WORKFLOW-GO_SDD_IMPLEMENT_CHANGE_WORKFLOW
trigger: manual
description: Implement any small Go backend change through the common SDD/ATDD lifecycle.
---

# Go SDD Implement Change Workflow

This is the only Go backend implementation workflow. It is a global workflow. Do not search for it under the current project's `.windsurf/workflows/`; invoke it as `/go-sdd-implement-change`. Its common parent workflows are sibling global workflows: `common-sdd-create-spec.workflow.md`, `common-sdd-evolve-spec.workflow.md`, and `common-sdd-change-lifecycle.workflow.md`.

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
| `http-integration-test` | `go-http-integration-tests.md`, `common-http-integration-harness.md`, `go-test-suites.md` |
| `ci-pipeline` | `common-sdd-create-github-actions-pipeline.workflow.md`, `go-sam-github-actions.md` |
| `documentation` | owning spec and repository documentation |

Do not switch workflows when a vertical slice crosses work types. Split it into small ordered tasks and keep one owning spec.

## Required Test Order

For each behavior slice:

1. Show the read-only SDD plan, including exact sequential/parallel tasks and agent slots, and obtain Gate 1 before spec writes.
2. Create or evolve User Stories, BDD scenarios, tasks, execution waves, tracks, and traceability.
3. Show the written artifacts and obtain Gate 2 before creating, modifying, or running tests.
4. Invoke the selected boundary workflow after BDD and before boundary-specific evidence: REST design, AWS Lambda REST, SNS publisher, SQS consumer, or React client when the Go service is paired with that client.
5. Write/confirm acceptance or HTTP integration RED.
6. Write the focused unit-level `TEST-*` RED before production business logic.
7. Invoke `common-sdd-review-test-evidence.workflow.md` and obtain Gate 3 before production code.
8. Implement the smallest domain/application change.
9. Add or change adapters, REST/Lambda/messaging boundary, and DI only when required.
10. Make the HTTP or message-boundary evidence green through real local resources.
11. Refactor with tests green and converge all spec artifacts.

Go backends have only unit tests and HTTP integration tests. Do not add direct repository/adapter/handler integration suites.

## REST And Lambda

- Invoke `WORKFLOW-GO_REST_API_WORKFLOW` for the Go adapter and `WORKFLOW-COMMON_REST_API_DESIGN_WORKFLOW` for the provider-neutral contract before handler code.
- For Lambda, also invoke `WORKFLOW-COMMON_AWS_LAMBDA_REST_WORKFLOW`; record payload version, IaC, cost assumptions, and verification commands in `workflow-routing.md`.
- Model REST resources and contracts before handler code.
- Keep routers and Lambda handlers thin: parse, authenticate, validate, call one use case, map response.
- Keep API Gateway/Lambda event types out of domain/application.
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
- Run focused HTTP integration tests with `-tags=integration`.
- Invoke `common-sdd-coverage-gate.workflow.md` and record `>= 90%` aggregate coverage for the complete project production scope with no affected-scope regression.
- Run race, architecture, coverage, mutation, lint, format, build, or SAM validation gates when touched or required by the spec.
- Record commands and evidence in `verification.md`.
