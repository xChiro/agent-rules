---
trigger: always_on
description: REST API standards for endpoint design
globs: **/*.go,template.yaml
---

# REST API Standards

Standards for creating or modifying HTTP endpoints in a Go service.

## Scope

- Apply these rules to new or changed HTTP endpoints.
- Preserve existing public contracts unless a versioned change is intended.
- New endpoint design must align with REST resource modeling and the current router conventions.

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
