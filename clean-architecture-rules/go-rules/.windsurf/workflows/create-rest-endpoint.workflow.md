---
description: Design and implement a REST endpoint using consistent REST conventions and Clean Architecture
---

# Create REST Endpoint Workflow

Use this workflow whenever creating or changing an HTTP endpoint in a Go service.

## Phase 1: Model the Resource

**Goal**: Start from the domain resource.

**Checklist**:
- Identify the resource family, such as `orders`, `users`, or `locations`.
- Decide whether the use case is create, read, update, delete, list/filter, or projection.
- Choose the route under the service's established API prefix.
- Prefer identity in the path for single-resource operations.

## Phase 2: Define the HTTP Contract

**Goal**: Lock the API contract before implementation.

**Checklist**:
- Select method and final route.
- Define path params, query params, and body.
- Define success status and error statuses.
- Decide whether the response is a single DTO, collection DTO, or empty body.
- Decide which data comes from auth/session context instead of client input.

**Preferred patterns**:
- Create resource: `POST /api/orders`
- Read one resource: `GET /api/orders/{order_id}`
- Read user-scoped projection: `GET /api/orders?owner=me`
- Partially update resource: `PATCH /api/orders/{order_id}`
- Delete resource: `DELETE /api/orders/{order_id}`

## Phase 3: REST Quality Gate

**Goal**: Validate the design before coding.

**Rules**:
- Use nouns, not verbs.
- Use plural resource names.
- Use query params for filters only.
- Use path params for identity.
- Keep current API contracts stable unless a deliberate migration is in scope.

## Phase 4: Architecture Mapping

**Goal**: Implement through the existing architecture cleanly.

**Checklist**:
- Add or reuse boundary DTOs.
- Add or reuse application use cases.
- Add or reuse focused CQRS ports.
- Keep the transport handler thin.
- Keep ownership, authorization, and validation rules in application/domain.

## Phase 5: Router Integration

**Goal**: Register the route consistently.

**Checklist**:
- Register the route in the existing router.
- Apply auth and role middleware when required.
- Validate path/query/body input at the boundary.
- Return consistent status codes and JSON responses.
- Prefer:
  - `201` create
  - `200` read/update
  - `204` delete
  - `400`, `401`, `403`, `404`, `409`, `500` for failures

## Phase 6: Tests

**Goal**: Verify the public contract with realistic wiring.

**Minimum coverage**:
- Success path through handler, use case, and real adapter where practical.
- Empty result or not-found behavior.
- Pagination or filtering when applicable.
- Expected response shape and status code.
- Request parsing and validation.

**Test structure**:
- Handler + use case + real infrastructure adapter for E2E/integration tests.
- Setup with explicit test environment helpers.
- Seed test data in real infrastructure when the endpoint reads persisted state.
- Cleanup after each test.

## Phase 7: Consistency Review

**Goal**: Keep the service API coherent.

**Checklist**:
- Confirm the route follows existing API prefix and resource naming.
- Avoid adding custom verb routes when query/resource modeling already covers the need.
- If an existing non-REST route must remain, do not break it silently; document the preferred new route.
