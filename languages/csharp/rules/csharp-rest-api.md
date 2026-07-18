---
rule_id: RULE-CSHARP_REST_API
trigger: model_decision
description: "C# ASP.NET Core and API Gateway/Lambda REST rules for thin boundaries, contracts, and HTTP integration."
globs: "**/*Controller.cs,**/*Controllers/**/*.cs,**/*WebApi/**/*.cs,**/*Lambda*.cs,**/Program.cs,template.yaml"
---

# C# REST API

## SDD Integration

Apply the primary C# SDD workflow plus `WORKFLOW-COMMON_REST_API_DESIGN_WORKFLOW`. This rule adds ASP.NET/Lambda adapter details only; common core and Boundary gates remain authoritative.

HTTP is a boundary. Keep controllers and endpoints thin.

The same REST contract applies whether the adapter is an ASP.NET Core controller, Minimal API, container endpoint, or API Gateway/Lambda function.

## Route Design

- Use nouns, not verbs.
- Use plural resource names.
- Put identity in the path.
- Put filters, pagination, sorting, and search in query parameters.
- Preserve existing public routes unless a migration is explicitly in scope.

Preferred:

```text
POST /api/brands
GET /api/brands/{brandId}
GET /api/brands?name=ford
DELETE /api/brands/{brandId}
```

Avoid:

```text
POST /api/createBrand
GET /api/getBrandById
```

## Controllers

Controllers should:

- bind route/query/body values
- obtain auth/session context when needed
- call one use case/application service
- map application result to response DTO
- return the status code

Controllers should not:

- query EF Core
- open broker channels
- contain business rules
- duplicate exception mapping
- return persistence DTOs
- expose domain entities directly for new public contracts that need stability

Lambda handlers and Minimal API delegates follow the same restrictions. Map transport types immediately and call one application use case.

## DTOs

- HTTP DTOs live in WebApi.
- Use request DTOs for body contracts.
- Use response DTOs for public output.
- Request DTOs own `ToApplication` conversion and response DTOs own `FromApplication` conversion in the DTO type/module.
- Persistence DTOs own `FromDomain`/`ToDomain` conversion in DataAccess.
- Keep DTO mapping structural and free of I/O, authorization, logging, orchestration, and business policy.
- Do not leak WebApi DTOs into domain/application.

## Status Codes

- `201 Created` for resource creation.
- `200 OK` for successful read/update with body.
- `204 No Content` for successful delete or command with no body.
- `400 Bad Request` for invalid input.
- `401 Unauthorized` for unauthenticated.
- `403 Forbidden` for authenticated but not allowed.
- `404 Not Found` for missing resource.
- `409 Conflict` for duplicate business key or invalid state transition.
- `500` or `503` for unexpected/dependency failures.

## Error Handling

- Prefer central exception middleware/filter.
- Do not expose internal details.
- Preserve existing `ErrorResponse` or `ProblemDetails` convention.
- Log unexpected errors once at the boundary.

Prefer RFC 9457 `ProblemDetails` for new contracts unless the repository has an established error envelope. Never expose exceptions, SQL/provider errors, cloud SDK payloads, secrets, or stack traces.

## Lambda And API Gateway

- Keep API Gateway/Lambda event and response types in the outer adapter project.
- Define route, method, authorizer, payload version, timeout, memory, environment, and IAM in checked-in SAM/IaC.
- Prefer API Gateway HTTP API payload v2 unless compatibility requires REST API v1.
- Extract identity, tenant, and claims from trusted authorizer/request context.
- Handle base64 bodies, content type, query values, headers, and cancellation according to the configured payload version.
- Resolve the application use case through the explicit composition root; do not build a second domain/application path for Lambda.
- Reuse clients across invocations when safe, but never retain request-specific state in static/global objects.
- Use least-privilege IAM, environment-driven resource names, structured logs, and correlation IDs.
- Centralize CORS and error mapping.
- Make retryable commands idempotent when duplicate delivery is possible.

## Documentation

- Keep XML comments useful when the project uses Swagger/OpenAPI.
- Document public response codes when the controller pattern already does it.
- Do not let comments drift from code.

## Tests

Backends have only unit tests and one integration project. For REST services the HTTP scope enters through HTTP; add integration/http coverage when changing:

- route
- status code
- request parsing
- response shape
- exception mapping
- auth/session behavior

Run ASP.NET Core through `HttpClient`/`WebApplicationFactory` or a hosted local fixture. Run Lambda through `sam local start-api` or an equivalent HTTP emulator. Use the real composition root and local database/resources.

Direct controller, Minimal API delegate, Lambda handler, DbContext, repository, or adapter calls are not HTTP integration tests. Keep exhaustive business rules in unit tests.

## OpenAPI And Compatibility

- Update OpenAPI and public documentation with route, request, response, status, auth, and error changes.
- Treat removed fields, changed types, stricter validation, and status-code changes as compatibility changes requiring verification.
- Use bounded pagination and deterministic ordering for collection endpoints.
