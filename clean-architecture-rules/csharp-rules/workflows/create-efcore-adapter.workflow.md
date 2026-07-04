---
description: Implement a C# EF Core DataAccess adapter for a command/query port with explicit mapping and integration coverage.
---

# C# Create EF Core Adapter Workflow

Use this workflow when implementing persistence for a focused port.

## Phase 1: Port Contract

**Goal**: Understand the adapter responsibility.

Checklist:

- Read the application/domain port.
- Identify whether it is command, query, checker, or projection.
- Confirm the port exposes domain types or stable read models.
- Confirm no `IQueryable` or EF DTO leaks through the port.

## Phase 2: Red Integration Test

**Goal**: Capture real persistence behavior.

Checklist:

- Use existing Testcontainers/fixture pattern.
- Apply real schema/migrations.
- Seed only required data.
- Execute the adapter through the port.
- Assert mapped result or database side effect.

## Phase 3: Persistence Model

**Goal**: Represent storage without polluting domain.

Checklist:

- Add or update persistence DTO.
- Add `IEntityTypeConfiguration<T>` for table, keys, indexes, required fields, lengths, and relationships.
- Add migration when schema changes.
- Keep provider-specific details in DataAccess.

## Phase 4: Mapping

**Goal**: Translate explicitly.

Checklist:

- Add `From(domain)` or `ToDomain()` near the DTO/adapter.
- Keep mapping small and deterministic.
- Do not introduce AutoMapper unless the project already relies on it.
- Test non-trivial conversions.

## Phase 5: Adapter Implementation

**Goal**: Implement the port.

Checklist:

- Use existing `DbContext` or `IDbContextFactory<TContext>` convention.
- Use `AsNoTracking()` for reads.
- Pass `CancellationToken` to async EF calls in new/touched code.
- Call `SaveChangesAsync` in command/unit-of-work adapters.
- Translate provider errors only when business classification requires it.

## Phase 6: Register And Verify

**Goal**: Connect and validate.

Checklist:

- Register adapter in DataAccess service extension.
- Run targeted integration tests.
- Confirm core projects do not reference EF Core.
- Confirm no persistence DTO leaks outward.
