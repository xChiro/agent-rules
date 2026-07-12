---
workflow_id: WORKFLOW-GO_REST_API_WORKFLOW
trigger: model_decision
description: Implement or evolve a Go REST or API Gateway/Lambda boundary through the common REST and SDD test-first workflows.
---

# Go REST API Workflow

Use from `WORKFLOW-GO_SDD_IMPLEMENT_CHANGE_WORKFLOW` for `rest-endpoint` and `lambda-rest-endpoint` tasks. It is a language adapter, not a replacement for the common lifecycle.

## Route The Supporting Workflows

Always load:

- `WORKFLOW-COMMON_BDD_SPECIFICATION_WORKFLOW`
- `WORKFLOW-COMMON_REST_API_DESIGN_WORKFLOW`
- `RULE-GO_REST_API`
- `RULE-GO_HTTP_INTEGRATION_TESTS`
- `RULE-COMMON_HTTP_INTEGRATION_HARNESS`

For `lambda-rest-endpoint`, also load `WORKFLOW-COMMON_AWS_LAMBDA_REST_WORKFLOW`, `RULE-GO_SAM_GITHUB_ACTIONS`, and the repository's checked-in IaC rules.

## Execution Order

1. In `workflow-routing.md`, record this workflow as primary and the common REST/Lambda workflows as supporting for the exact task.
2. Write the abstract BDD scenario and obtain Gate 1 before spec writes; obtain Gate 2 before RED.
3. Model the resource, method, DTOs, errors, auth context, pagination/idempotency, compatibility, and OpenAPI/schema through the common REST workflow.
4. Create the smallest public HTTP RED, then the focused application/domain `TEST-*` RED. Invoke the test-evidence workflow and obtain Gate 3.
5. Implement the smallest Go change: transport DTO mapping, one application port/use case, and one outer adapter. Keep `net/http`, router, API Gateway, Lambda, AWS SDK, persistence, and framework types out of domain/application.
6. Keep `context.Context` and cancellation flowing into application ports and I/O. Put `ToApplication`/`FromApplication` on transport DTOs and `FromDomain`/`ToDomain` on persistence DTOs.
7. For Lambda, use the common Lambda workflow: thin event adapter, explicit payload version, reusable clients outside invocation, no request state in globals, bounded timeout/concurrency, least-privilege IAM, and cost evidence.
8. Make the HTTP integration evidence GREEN through the real local listener or Lambda HTTP emulator and local resources. Do not call handlers directly and do not create another backend runtime suite.
9. Refactor while green; update OpenAPI, IaC, `red-green-refactor.md`, `verification.md`, traceability, and residual-risk records.
10. Invoke the required quality, security, and coverage workflows; mutation, E2E, and policy workflows remain selected by risk.

## Done When

The Go boundary preserves REST semantics, dependency direction, DTO-owned mapping, CQRS separation where used, cancellation, compatibility, and observable HTTP evidence; Lambda-specific settings and cost choices are explicit when applicable.
