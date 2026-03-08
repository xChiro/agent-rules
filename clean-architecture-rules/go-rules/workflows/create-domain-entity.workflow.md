# Workflow: /create-domain-entity

Use this workflow to create a new domain entity or value object. When the user issues `/create-domain-entity <entity_name>`, perform the following steps:

## Description

Define a new **Entity** or **Value Object** in the domain layer with clear responsibilities and protected invariants. Ensure the design aligns with Clean Architecture and DDD principles, and write tests first following the TDD guidelines.

## Steps

1. **Clarify the domain concept** represented by `<entity_name>`: Is it an aggregate root, an entity with identity, or a value object without identity? Identify the invariants and constraints.
2. **Write tests first**: Use the `/create-tdd-add-test` workflow to generate failing tests that capture the entity’s expected behaviour and validation (e.g., invalid inputs, equality semantics).
3. **Create the type** in `internal/domain/<bounded_context>/<entity_name>.go`:
   - For value objects, define a struct with unexported fields and an exported constructor function (`New<entity_name>`) that validates inputs and returns `(entity, error)`.
   - For entities, define a struct with unexported fields and methods enforcing invariants. Provide an exported constructor or factory function.
4. **Do not add infrastructure concerns**: Avoid tags (`json`, `db`) or framework imports. Keep the type pure.
5. **Implement equality and behaviour**:
   - For value objects, implement methods such as `Equal(other <type>) bool` as needed.
   - For entities, expose domain actions (`Confirm()`, `Cancel()`) that modify state while maintaining invariants.
6. **Refactor**: After tests pass, ensure the file and functions respect the 150/20 line limits and follow the naming conventions in `go-clean-code.rules.md`.

## Guidelines

- Follow DDD patterns described in `go-clean-architecture-ddd.rules.md`.
- Enforce validations within constructors to maintain invariants.
- Write unit tests first and use manual mocks only for outgoing interfaces (not needed for pure value objects).