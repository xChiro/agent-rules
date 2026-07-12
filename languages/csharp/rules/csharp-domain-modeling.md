---
rule_id: RULE-CSHARP_DOMAIN_MODELING
trigger: always_on
description: C# DDD entity, value object, domain event, invariant, and domain service rules.
globs: **/*.cs
---

# C# Domain Modeling

## SDD Baseline

- Apply `common/rules/common-sdd-agentic-discipline.md` before this rule.
- Create or evolve the owning User Story based spec before production code when behavior, contracts, architecture, or risk changes.
- Apply mandatory Gate 1 before spec writes, Gate 2 before RED, and Gate 3 before Green, even for simple or low-risk changes.
- Keep artifact, task, track, and test IDs traceable through `traceability.yaml` and `parallel-tracks.md`.
- Write BDD Given/When/Then acceptance evidence first, then the unit-level ATDD-style focused failing test for the next rule or boundary before production code.
- Refactor only with tests green and converge spec history, tasks, parallel tracks, traceability, verification notes, and code.

Use DDD tactically where it protects business meaning. Do not add DDD vocabulary when a simple model is enough.

## Entities

Entities have identity and protect invariants.

- Keep identity explicit: `Id`, `BrandId`, `DeviceId`, `MessageId`.
- Expose behavior that changes state or evaluates rules.
- Keep setters private or absent unless the project convention requires otherwise.
- Do not let external layers mutate entity state freely.
- Do not put persistence attributes or EF Core concerns in domain entities for new code.
- Use constructors or factory methods to prevent invalid objects.

Good:

```csharp
public class Brand(BrandName name)
{
    public Id Id { get; } = Id.Create();
    public BrandName Name { get; } = name;
    public CreatedAt CreatedAt { get; } = CreatedAt.Now();
}
```

## Value Objects

Value objects are immutable, compare by value, and represent a domain concept.

Use a value object when:

- the primitive has business rules
- the value appears in multiple places with the same rules
- equality by value matters
- invalid values must not exist
- the name improves the ubiquitous language

Prefer records:

```csharp
public record BrandName
{
    private BrandName(string value) => Value = value;

    public string Value { get; }

    public static BrandName Create(string name)
    {
        if (string.IsNullOrWhiteSpace(name))
            throw new ArgumentException("Brand name cannot be empty.", nameof(name));

        return name.Length > 55
            ? throw new ArgumentOutOfRangeException(nameof(name), "Brand name is too long.")
            : new BrandName(name);
    }
}
```

Avoid repeated primitive validation:

```csharp
if (string.IsNullOrWhiteSpace(name)) ...
if (name.Length > 55) ...
```

when the rule belongs to a named domain concept.

## Invariants

An invariant is a rule that must always be true for the model.

- Enforce invariants in value object factories, entity constructors, entity methods, or domain services.
- Do not rely only on API validation, database constraints, or UI validation.
- Database constraints may duplicate invariants for safety, but they do not replace domain rules.
- Use tests to document every important invariant.

## Domain Services

Use a domain service only when a business rule:

- does not naturally belong to one entity or value object
- coordinates multiple aggregates
- is stateless
- speaks domain language

Do not use domain services as a dumping ground for application orchestration.

## Domain Events

Use domain events when a meaningful domain fact has occurred and another part of the system may react.

- Name events in past tense: `TelemetryRecorded`, `BrandCreated`, `OrderPaid`.
- Events should be immutable.
- Events should contain stable identifiers and data needed by consumers.
- Do not put broker metadata, delivery tags, queue names, or HTTP concepts in domain events.
- Publish through application/infrastructure after persistence when reliability matters.

## Exceptions

- Use `ArgumentException` or `ArgumentOutOfRangeException` for invalid value object input when that matches project style.
- Use typed domain/application exceptions for business outcomes that need mapping: not found, duplicate, invalid state, forbidden operation.
- Do not put HTTP status codes in domain exceptions.

## Anti-Patterns

- Anemic entities that only expose public setters while all rules live in use cases.
- Value objects that are only renamed primitives without behavior or meaning.
- EF Core attributes in domain models for new code.
- Domain code that logs, reads configuration, calls time directly, or talks to external systems.
- Catching domain exceptions inside domain code.
