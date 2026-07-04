---
trigger: model_decision
description: C# EF Core and DataAccess adapter rules for Clean Architecture, mapping, migrations, queries, commands, and persistence DTOs.
globs: **/*DataAccess/**/*.cs,**/*DbContext.cs,**/*Configuration.cs,**/Migrations/**/*.cs
---

# C# EF Core And DataAccess

DataAccess is an adapter. It implements core ports and maps between domain/application models and persistence models.

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

Ports should expose domain objects or stable read models, not EF DTOs or `IQueryable`.

## Mapping

- Keep `From(domain)` or `ToDomain()` mapping near persistence DTOs or adapter code.
- Do not put EF attributes or provider concerns in domain objects for new code.
- Keep mapping explicit unless the project already uses a mapper and the mapping is simple.
- Do not introduce AutoMapper unless the project already uses it and the change needs it.

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
- Verify configuration and migrations with integration tests when risk is meaningful.

## Error Translation

Translate provider-specific exceptions only when the application needs a business classification.

Examples:

- unique constraint -> duplicate/conflict exception
- FK missing -> not found or invalid reference only if the use case expects it

Otherwise let technical exceptions bubble to boundary logging/mapping.

## Done Criteria

- Core does not reference EF Core.
- Adapter implements a focused port.
- Mapping is explicit and local to DataAccess.
- Query does not leak `IQueryable`.
- Integration tests cover risky mapping or schema behavior.
