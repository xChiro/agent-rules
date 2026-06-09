---
trigger: always_on
description: HBK Inventory REST API standards for endpoint design
globs: **/*.go,template.yaml
---

# HBK Inventory REST API Standards

Standards for creating or modifying HTTP endpoints in `hbk-inventory-service`. Use these rules as a service-specific profile, not as generic REST guidance for every project.

## Scope

- Apply these rules to new endpoints under `/api/inventory`
- Preserve existing public contracts unless a versioned change is intended
- New endpoint design must align with REST resource modeling and the current Lambda router conventions

## Resource Modeling

- Use nouns, not verbs
- Use plural resource names: `items`, `categories`, `locations`
- Put identity in the path: `/api/inventory/items/{item_id}`
- Use sub-resources when a child concept is bounded by a parent resource
- Keep nesting shallow unless the relationship is intrinsic

## URL Conventions

- Keep the base prefix consistent: `/api/inventory`
- Use lowercase path segments
- Use query params for filters and pagination
- Avoid route names such as `/create-item`, `/get-locations`, `/delete-category`

## HTTP Method Rules

- `POST /resources`: create
- `GET /resources`: list
- `GET /resources/{id}`: get one
- `PUT /resources/{id}`: full replacement only
- `PATCH /resources/{id}`: partial update
- `DELETE /resources/{id}`: delete

## Inventory-Specific Rules

- Inventory items are a resource collection: prefer `/api/inventory/items/{item_id}` for update/delete/get-one
- User-scoped inventory should still be modeled as a resource projection, not a verb route
- Prefer `/api/inventory/items?owner=me` over adding more endpoints like `/api/inventory/user/inventory` for new designs
- Catalogs such as categories and locations are first-class resources, not commands
- Batch creation is allowed with `POST /api/inventory/categories` when the request explicitly represents a collection payload

## Request Design

- Use JSON bodies for `POST`, `PUT`, and `PATCH`
- Use `snake_case` JSON tags
- Validate UUID path params at the boundary
- Use query params for optional filters like `path`, `parent`, `prefix`, `depth`
- Do not accept `owner_id` or `performed_by` from the client when it should come from auth/session context

## Response Design

- `201 Created` for create operations
- `200 OK` for reads and updates with body
- `204 No Content` for successful deletes
- Return DTOs, not internal persistence shapes
- For list endpoints, use a stable collection envelope when pagination or filtering exists

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

- If the endpoint is not paginated, still keep the response shape predictable and documented

## Error Contract

- Prefer a consistent machine-readable shape for new endpoints:

```json
{
  "error": "Bad Request",
  "message": "invalid location id",
  "code": "VALIDATION_ERROR",
  "request_id": "..."
}
```

- `400` for invalid body, query, or path params
- `401` for authentication failures
- `403` for role or ownership authorization failures
- `404` for missing resources
- `409` for ownership or state conflicts
- `500` for unexpected failures

## Inventory Service Notes

- Core resource families:
  - `/api/inventory/items`
  - `/api/inventory/categories`
  - `/api/inventory/locations`
- Prefer `PATCH /api/inventory/items/{item_id}` over `PUT /api/inventory/items` for future partial updates
- Prefer `GET /api/inventory/items/{item_id}` and `GET /api/inventory/items?owner=me` for new reads instead of creating more custom route families

## Good Examples

- `POST /api/inventory/items`
- `GET /api/inventory/items/{item_id}`
- `GET /api/inventory/items?owner=me`
- `PATCH /api/inventory/items/{item_id}`
- `DELETE /api/inventory/items/{item_id}`
- `POST /api/inventory/categories`
- `GET /api/inventory/categories?prefix=armor/`
- `POST /api/inventory/locations`
- `GET /api/inventory/locations?path=stanton`

## Avoid

- `PUT /api/inventory/items` for new partial updates without item identity in path
- `GET /api/inventory/user/inventory` for new user inventory routes when query/resource modeling can express it
- `POST /api/inventory/delete-item`
- `GET /api/inventory/get-categories`
