---
trigger: model_decision
description: C# ASP.NET Core REST API standards for thin controllers, DTOs, status codes, routes, and Clean Architecture boundaries.
globs: **/*Controller.cs,**/*Controllers/**/*.cs,**/*WebApi/**/*.cs,**/Program.cs
---

# C# REST API Standards

HTTP is a boundary. Keep controllers and endpoints thin.

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

## DTOs

- HTTP DTOs live in WebApi.
- Use request DTOs for body contracts.
- Use response DTOs for public output.
- Map to application requests or primitives before calling the use case.
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

## Documentation

- Keep XML comments useful when the project uses Swagger/OpenAPI.
- Document public response codes when the controller pattern already does it.
- Do not let comments drift from code.

## Tests

Add API/integration tests when changing:

- route
- status code
- request parsing
- response shape
- exception mapping
- auth/session behavior

Do not rely only on unit tests for public HTTP contract changes.
