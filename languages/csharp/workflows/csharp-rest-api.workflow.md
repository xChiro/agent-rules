---
workflow_id: WORKFLOW-CSHARP_REST_API_WORKFLOW
trigger: model_decision
description: "Implement or evolve a C# REST or API Gateway/Lambda boundary through the common REST and SDD test-first workflows."
---

# C# REST API Workflow

Use from `WORKFLOW-CSHARP_SDD_IMPLEMENT_CHANGE_WORKFLOW` for `rest-endpoint` and `lambda-rest-endpoint` tasks. It adapts execution without changing the common SDD/ATDD/TDD lifecycle.

## Route The Supporting Workflows

Always load:

- `WORKFLOW-COMMON_BDD_SPECIFICATION_WORKFLOW`
- `WORKFLOW-COMMON_REST_API_DESIGN_WORKFLOW`
- `RULE-CSHARP_REST_API`
- `RULE-CSHARP_HTTP_INTEGRATION_TESTS`
- `RULE-COMMON_HTTP_INTEGRATION_HARNESS`

For `lambda-rest-endpoint`, also load `WORKFLOW-COMMON_AWS_LAMBDA_REST_WORKFLOW` and the repository's checked-in SAM/IaC rules.

## Execution Order

1. Record this workflow as primary and the common REST/Lambda workflows as supporting in `workflow-routing.md`.
2. Write the abstract BDD scenario and obtain Gate 1 before spec writes; obtain Gate 2 before RED.
3. Model resources, methods, DTOs, errors/Problem Details, auth context, pagination/idempotency, compatibility, and OpenAPI through the common REST workflow.
4. Complete affected Domain and Application RED/GREEN/refactor cycles and pass `LAYER-GATE-APPLICATION`.
5. Create the smallest public HTTP RED, or the use-case-driven Infrastructure RED when an adapter/resource is the affected boundary, and obtain Gate 3-BOUNDARY with the integration scope recorded.
6. Implement the smallest outer change in order: EF/infrastructure adapter, request/response DTO and delivery adapter, then composition/DI/IaC. Make Infrastructure RED GREEN against the real local resource. Keep ASP.NET, API Gateway, Lambda, EF Core, AWS SDK, and transport types out of domain/application.
7. Keep `CancellationToken` flowing through application ports and I/O. Put `ToApplication`/`FromApplication` on HTTP DTOs and `FromDomain`/`ToDomain` on persistence DTOs.
8. For Lambda, use the common Lambda workflow: explicit payload version, trusted authorizer context, reusable clients outside invocation, no request state in static/global objects, bounded timeout/concurrency, least-privilege IAM, and cost evidence.
9. Make HTTP integration evidence GREEN through `HttpClient`/hosted local resources or the Lambda HTTP emulator. Do not call controllers/handlers directly and do not create another backend runtime suite.
10. Refactor while green; update OpenAPI, IaC, `red-green-refactor.md`, `verification.md`, traceability, layer gates, and residual-risk records.
11. Invoke the required quality, security, and coverage workflows; mutation, E2E, and policy workflows remain selected by risk.

## Done When

The C# boundary preserves REST semantics, dependency direction, DTO-owned mapping, CQRS separation where used, cancellation, compatibility, and observable HTTP evidence; Lambda-specific settings and cost choices are explicit when applicable.
