---
description: Design and implement a REST endpoint in the inventory service using consistent REST conventions and Clean Architecture
---

# Create REST Endpoint Workflow

Use this workflow whenever creating or changing an endpoint in `hbk-inventory-service`.

## Phase 1: Model the Resource

**Goal**: Start from the domain resource.

**Checklist**:
- Identify the resource family: `items`, `categories`, `locations`
- Decide whether the use case is CRUD, list/filter, or projection
- Choose the route under `/api/inventory`
- Prefer identity in the path for single-resource operations

## Phase 2: Define the HTTP Contract

**Goal**: Lock the API contract before implementation.

**Checklist**:
- Select method and final route
- Define path params, query params, and body
- Define success status and error statuses
- Decide whether the response is a single DTO, collection DTO, or empty body
- Decide which data comes from auth context instead of client input

**Preferred patterns**:
- Create item: `POST /api/inventory/items`
- Read one item: `GET /api/inventory/items/{item_id}`
- Read user items: `GET /api/inventory/items?owner=me`
- Update item: `PATCH /api/inventory/items/{item_id}`
- Delete item: `DELETE /api/inventory/items/{item_id}`

## Phase 3: REST Quality Gate

**Goal**: Validate the design before coding.

**Rules**:
- Use nouns, not verbs
- Use plural resource names
- Use query params for filters only
- Use path params for identity
- Keep current API contracts stable unless a deliberate migration is in scope

## Phase 4: Architecture Mapping

**Goal**: Implement through the existing architecture cleanly.

**Checklist**:
- Add or reuse DTOs
- Add or reuse application use cases
- Add or reuse focused CQRS ports
- Keep the Lambda handler thin
- Keep ownership and validation rules in application/domain

## Phase 5: Lambda Router Integration

**Goal**: Register the route consistently.

**Checklist**:
- Add the `RouteKey` in the router
- Apply auth and role middleware
- Validate path/query/body input
- Return consistent status codes and JSON responses
- Prefer:
  - `201` create
  - `200` read/update
  - `204` delete
  - `400`, `401`, `403`, `404`, `409`, `500` for failures

## Phase 6: Tests

**Goal**: Verify the public contract.

**Minimum coverage**:
- Success path
- Invalid request
- Authentication failure
- Authorization or ownership failure when applicable
- Not found or conflict
- Expected response shape and status code

## Phase 7: Consistency Review

**Goal**: Keep the service API coherent.

**Checklist**:
- Confirm the route matches `/api/inventory/items`, `/categories`, or `/locations`
- Avoid adding new custom route families when query/resource modeling already covers the need
- If an existing non-REST route must remain, do not break it silently; document the preferred new route
