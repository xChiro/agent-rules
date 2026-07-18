---
skill_id: SKILL-CSHARP_DDD_CQRS_MODELING_SKILL
name: csharp-ddd-cqrs-modeling
trigger: model_decision
description: "C# DDD/CQRS/value object skill for modeling business concepts, invariants, focused ports, domain events, and application orchestration."
globs: "**/*.cs"
---

# C# DDD CQRS Modeling Skill

## SDD Integration

Load this skill only for C# Domain/Application modeling after `RULE-COMMON_SDD_AGENTIC_DISCIPLINE`. It adds DDD/CQRS technique and cannot redefine common gates, traceability, layer order, or convergence.

Use this skill when modeling or changing domain/application behavior.

## Modeling Flow

1. Name the business capability and actor.
2. Identify the aggregate/entity that owns identity.
3. Identify value objects for meaningful primitives.
4. Write tests for invariants and behavior.
5. Define focused CQRS ports in Application only for current external dependencies.
6. Keep use cases as orchestration.
7. Keep infrastructure mapping outside the core.

## Value Objects

Use a value object when a primitive has domain meaning or validation.

- Make it immutable.
- Validate in a factory or constructor.
- Prefer records where equality by value is useful.
- Expose the raw value through a clear property.
- Test invalid and valid values directly when the value object owns rules.

## Entities

- Protect invariants through constructors and methods.
- Expose behavior instead of public mutation.
- Keep EF Core and transport concerns out.
- Use domain events only for meaningful facts that occurred.

## CQRS Ports

- Commands change state: `ICreateBrandCommand`, `ISaveTelemetry`.
- Queries read state: `IGetBrandById`, `IGetDeviceSettingByDeviceId`.
- Checkers validate existence/uniqueness: `IBrandExistsChecker`.
- Keep ports small, behavior-named, and consumer-focused.
- Define port interfaces in Application, near the use case that consumes them.
- Infrastructure implements Application ports; Domain must not own infrastructure contracts.
- Wire use cases and ports through normal DI. Do not use MediatR, mediator handlers, or in-process buses for CQRS.

## Use Cases

Use cases may:

- create value objects
- load required state through ports
- invoke entity/domain behavior
- persist or publish through ports
- return an application response
- throw typed business exceptions

Use cases must not:

- query EF Core directly
- know HTTP status codes
- deserialize broker messages
- log ordinary business failures
- own domain invariants that naturally belong in entities/value objects
