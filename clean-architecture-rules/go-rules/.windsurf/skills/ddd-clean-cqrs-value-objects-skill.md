---
trigger: always_on
description: DDD, Clean Architecture, CQRS, and value-object modeling skill.
globs:
---

# DDD Clean CQRS Value Objects Skill

Model the business explicitly. Invalid states should be difficult or impossible to create.

## Layer Rules

- Domain is pure: no framework, persistence, transport, env, logger, or queue dependencies.
- Application owns use cases and consumer-side ports.
- Infrastructure implements ports and maps between storage/message DTOs and domain/application types.
- Interfaces/handlers/controllers map transport DTOs and errors.
- Dependencies point inward only.

## Value Objects

- Create a value object when a primitive has validation, behavior, formatting, identity semantics, or domain language.
- Validate in constructors/factories and return explicit errors/exceptions.
- Keep value objects immutable and comparable by value.
- Expose a clear primitive conversion (`String`, `Value`, or record property) only when needed by outer layers.
- Do not allow raw strings/ints to pass deep into use cases when the domain has a named concept.

## Entities and Aggregates

- Entities protect invariants through constructors and methods.
- Business state transitions happen through named methods, not public field mutation.
- Keep timestamps, IDs, user/session context, and external data explicit.
- Emit domain events from business decisions, not from persistence adapters.

## CQRS Ports

- Commands mutate one business concept and return only what the use case needs.
- Queries return DTOs for read models or domain objects only when behavior needs them.
- Validation ports answer one business question.
- One port per behavior; no god repository with unused CRUD methods.

## Error Strategy

- Domain errors describe violated rules.
- Application wraps technical failures with context and preserves cause.
- Interface layer maps known domain/application errors to transport status/messages.
- Infrastructure failures do not become business rules.

