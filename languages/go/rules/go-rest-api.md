---
rule_id: RULE-GO_REST_API
trigger: always_on
description: Go REST API and API Gateway/Lambda rules for resource design, thin boundaries, contracts, and HTTP integration.
globs: **/*.go,template.yaml
---

# Go REST API

## SDD Baseline

- Apply `common/rules/common-sdd-agentic-discipline.md` before this rule.
- Create or evolve the owning User Story based spec before production code when behavior, contracts, architecture, or risk changes.
- Apply mandatory Gate 1 before spec writes, Gate 2 before RED, and Gate 3 before Green, even for simple or low-risk changes.
- Keep artifact, task, track, and test IDs traceable through `traceability.yaml` and `parallel-tracks.md`.
- Write BDD Given/When/Then acceptance evidence first, then the unit-level ATDD-style focused failing test for the next rule or boundary before production code.
- Refactor only with tests green and converge spec history, tasks, parallel tracks, traceability, verification notes, and code.


Rules for creating or modifying HTTP endpoints in a Go service.

## Scope

- Apply these rules to new or changed HTTP endpoints.
- Apply the same resource and contract rules to server, container, and API Gateway/Lambda deployments.
- Preserve existing public contracts unless a versioned change is intended.
- New endpoint design must align with REST resource modeling and the current router conventions.

## Architecture Boundary

- The HTTP adapter parses transport input, extracts auth/session context, validates transport shape, calls one use case, and maps the result.
- Keep business decisions in domain/application code.
- Keep router, API Gateway, Lambda event, AWS SDK, persistence, and framework types outside domain/application.
- Reuse one application use case from server and Lambda adapters; deployment style must not duplicate behavior.
- Register dependencies in one explicit composition root.

## Resource Modeling

- Use nouns, not verbs.
- Use plural resource names: `orders`, `users`, `locations`.
- Put identity in the path: `/api/orders/{order_id}`.
- Use sub-resources when a child concept is bounded by a parent resource.
- Keep nesting shallow unless the relationship is intrinsic.

## URL Conventions

- Keep the service base prefix consistent.
- Use lowercase path segments.
- Use query params for filters, search, sorting, and pagination.
- Avoid route names such as `/create-order`, `/get-users`, or `/delete-location`.

## HTTP Method Rules

- `POST /resources`: create.
- `GET /resources`: list.
- `GET /resources/{id}`: get one.
- `PUT /resources/{id}`: full replacement only.
- `PATCH /resources/{id}`: partial update.
- `DELETE /resources/{id}`: delete.

## Request Design

- Use JSON bodies for `POST`, `PUT`, and `PATCH`.
- Use the project's established JSON naming convention consistently.
- Validate path params at the boundary.
- Use query params for optional filters such as `status`, `owner`, `prefix`, `limit`, and `offset`.
- Do not accept actor, owner, tenant, or permission-sensitive fields from the client when they should come from auth/session context.

## Response Design

- `201 Created` for create operations.
- `200 OK` for reads and updates with a body.
- `204 No Content` for successful deletes.
- Return DTOs, not internal persistence shapes.
- For list endpoints, use a stable collection envelope when pagination or filtering exists.

## DTO Mapping Ownership

- HTTP request and response DTOs own their `ToApplication`/`FromApplication` functions in the DTO file/package.
- Persistence DTOs own their `FromDomain`/`ToDomain` functions in the infrastructure DTO file/package.
- Keep these functions explicit, structural, and free of I/O, authorization, logging, orchestration, and business policy.
- Handlers call DTO mapping functions and then one use case; they do not duplicate field-by-field translation.

## Collection Responses

- Prefer a consistent envelope for pageable collections:

```json
{
  "items": [],
  "limit": 20,
  "offset": 0,
  "total": 100
}
```

- If the endpoint is not paginated, still keep the response shape predictable and documented.

## Error Contract

- Prefer a consistent machine-readable shape for new endpoints:

```json
{
  "error": "Bad Request",
  "message": "invalid resource id",
  "code": "VALIDATION_ERROR",
  "request_id": "..."
}
```

- `400` for invalid body, query, or path params.
- `401` for authentication failures.
- `403` for role or ownership authorization failures.
- `404` for missing resources.
- `409` for ownership, uniqueness, or state conflicts.
- `500` for unexpected failures.

Prefer RFC 9457 Problem Details when the repository already uses it; otherwise preserve one documented machine-readable error contract. Never expose stack traces, SQL errors, cloud SDK payloads, secrets, or internal identifiers.

## Lambda And API Gateway

- Define route, method, authorizer, request/response format, timeout, memory, environment variables, and IAM in the checked-in SAM/IaC template.
- Prefer API Gateway HTTP API payload v2 unless the existing service requires REST API v1.
- Treat API Gateway events as transport DTOs and map them immediately.
- Extract identity, tenant, and claims from the trusted authorizer/request context, not client-provided body fields.
- Handle base64 bodies, content type, query values, and headers according to the configured payload version.
- Initialize reusable SDK/database clients outside the invocation path when safe, but do not store request state globally.
- Use least-privilege IAM and environment-driven resource names/endpoints.
- Keep CORS centralized in API Gateway or shared middleware; do not create conflicting per-handler policies.
- Make retryable commands idempotent when API Gateway/client retries can duplicate requests.
- Return before the Lambda timeout and propagate request cancellation/deadlines to I/O.
- Use structured logs with request/correlation IDs and no sensitive payloads.

## HTTP Integration

- Backend tests are either unit tests or HTTP integration tests.
- Test REST servers through a real local listener/router.
- Test Lambda endpoints through `sam local start-api` or the repository's equivalent HTTP emulator.
- Exercise the real composition root and local databases/resources.
- Do not count direct handler, Lambda function, repository, or adapter invocation as HTTP integration.
- Keep exhaustive business rules in unit tests; use HTTP integration for contract, wiring, persistence, and local-resource evidence.

## OpenAPI And Compatibility

- Update OpenAPI or checked-in API documentation when route, request, response, status, auth, or error contracts change.
- Treat public field removal, type changes, stricter validation, and changed status codes as compatibility changes requiring spec verification.
- Add pagination bounds and deterministic ordering to collection endpoints.

## Good Examples

- `POST /api/orders`
- `GET /api/orders/{order_id}`
- `GET /api/orders?owner=me`
- `PATCH /api/orders/{order_id}`
- `DELETE /api/orders/{order_id}`
- `POST /api/categories`
- `GET /api/categories?prefix=primary`
- `POST /api/locations`
- `GET /api/locations?status=active`

## Avoid

- `PUT /api/orders` for partial updates without resource identity in the path.
- `GET /api/user/orders` when query/resource modeling can express the same projection.
- `POST /api/delete-order`
- `GET /api/get-categories`
