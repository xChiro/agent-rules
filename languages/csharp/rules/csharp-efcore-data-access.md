---
rule_id: RULE-CSHARP_EFCORE_DATA_ACCESS
trigger: model_decision
description: C# EF Core and DataAccess adapter rules for Clean Architecture, mapping, migrations, queries, commands, and persistence DTOs.
globs: **/*DataAccess/**/*.cs,**/*DbContext.cs,**/*Configuration.cs,**/Migrations/**/*.cs
---

# C# EF Core Data Access

## SDD Baseline

- Apply `common/rules/common-sdd-agentic-discipline.md` before this rule.
- Create or evolve the owning User Story based spec before production code when behavior, contracts, architecture, or risk changes.
- Apply mandatory Gate 1 before spec writes, Gate 2 before RED, and Gate 3 before Green, even for simple or low-risk changes.
- Keep artifact, task, track, and test IDs traceable through `traceability.yaml` and `parallel-tracks.md`.
- Write BDD Given/When/Then acceptance evidence first, then the unit-level ATDD-style focused failing test for the next rule or boundary before production code.
- Refactor only with tests green and converge spec history, tasks, parallel tracks, traceability, verification notes, and code.

DataAccess is an adapter. It implements Application ports and maps between domain/application models and persistence models.

## Ownership

DataAccess owns:

- `DbContext`
- EF configurations
- migrations
- persistence DTOs/entities
- database-specific query expressions
- adapter mapping
- provider-specific configuration

Core code must not depend on EF Core.

## Ports

Implement focused ports:

```csharp
public class CreateBrandCommand(IDbContextFactory<OnnodoDbContext> dbContextFactory)
    : DataBaseBase(dbContextFactory), ICreateBrandCommand
{
    public async Task Execute(Brand brand, CancellationToken cancellationToken = default)
    {
        DbContext.Brands.Add(BrandDto.From(brand));
        await DbContext.SaveChangesAsync(cancellationToken);
    }
}
```

Port interfaces must live in Application. DataAccess implements them and must not define the contract unless it is moving an existing misplaced port into Application as part of the change.

Ports should expose domain objects or stable read models, not EF DTOs or `IQueryable`.

## Mapping

- Put `FromDomain` and `ToDomain` mapping functions inside the persistence DTO that owns the database schema. The DTO may call domain constructors/value objects so invalid records return an explicit mapping/domain error.
- Do not put EF attributes or provider concerns in domain objects for new code.
- Keep mapping explicit unless the project already uses a mapper and the mapping is simple.
- Do not introduce AutoMapper unless the project already uses it and the change needs it.
- Use a boundary-local companion only when the DTO is generated or immutable; do not create a global mapper package.

## Queries

- Use `AsNoTracking()` for read-only queries.
- Project only fields needed by the port result.
- Include related data only when needed.
- Keep provider-specific logic inside DataAccess.
- Return nullable only when absence is a normal query result.
- Let the use case convert required absence to a business exception.

## Commands

- Save changes in command/unit-of-work adapters.
- Keep domain objects free from persistence side effects.
- Respect `CancellationToken` in new or touched EF async calls.
- Avoid multiple `SaveChangesAsync` calls in one adapter unless the transaction boundary requires it.
- Use database constraints to enforce uniqueness and integrity in addition to domain rules.

## Migrations

- Migrations should reflect deliberate schema changes.
- Do not edit old migrations unless the project has not shared/applied them and the team convention allows it.
- Keep migrations out of domain/application.
- Verify configuration and migrations through HTTP integration tests when risk is meaningful; do not add a separate EF Core integration suite.

## Error Translation

Translate provider-specific exceptions only when the application needs a business classification.

Examples:

- unique constraint -> duplicate/conflict exception
- FK missing -> not found or invalid reference only if the use case expects it

Otherwise let technical exceptions bubble to boundary logging/mapping.

## Done Criteria

- Core does not reference EF Core.
- Adapter implements a focused Application port.
- Mapping is explicit and local to DataAccess.
- Query does not leak `IQueryable`.
- Integration tests cover risky mapping or schema behavior.
