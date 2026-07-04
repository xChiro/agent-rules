---
description: Create or change an ASP.NET Core REST endpoint using Clean Architecture, thin controllers, DTOs, and tested contracts.
---

# C# Create REST Endpoint Workflow

Use this workflow whenever adding or changing an HTTP endpoint.

## Phase 1: Resource Design

**Goal**: Model the endpoint as a resource operation.

Checklist:

- Identify the resource.
- Choose method and route.
- Use plural nouns.
- Put identity in the path.
- Put filters/paging/sorting in query params.
- Preserve existing public contracts unless migration is in scope.

## Phase 2: Contract

**Goal**: Define input, output, and errors before coding.

Checklist:

- Request body DTO.
- Path/query params.
- Success response DTO.
- Success status.
- Expected error statuses.
- Auth/session-derived fields.

## Phase 3: Red Test

**Goal**: Protect the public contract.

Checklist:

- Add API/integration test when route, status, response, parsing, auth, or exception mapping changes.
- Use unit tests for business behavior behind the endpoint.
- Seed real data only when needed.
- Assert stable response shape, not internal implementation.

## Phase 4: Application Mapping

**Goal**: Keep the controller thin.

Checklist:

- Map HTTP DTO to application request or primitive inputs.
- Call one use case.
- Map result to response DTO.
- Let central exception middleware map failures.
- Do not query EF Core in the controller.

## Phase 5: Register And Document

**Goal**: Integrate consistently.

Checklist:

- Register route/controller as the project requires.
- Add DI registration for new use case/adapters.
- Add XML docs/OpenAPI response metadata if the project uses it.
- Keep response contracts stable.

## Phase 6: Verify

**Goal**: Prove API and behavior.

Checklist:

- Run unit tests for the use case.
- Run API/integration tests for the endpoint.
- Confirm domain/application has no ASP.NET dependency.
- Confirm errors are mapped centrally.
