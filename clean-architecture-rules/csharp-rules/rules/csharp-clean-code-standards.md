---
trigger: always_on
description: C# Clean Code, refactoring, naming, file size, and readability standards for backend projects.
globs: **/*.cs
---

# C# Clean Code Standards

Write code that a senior maintainer can scan, test, and change safely.

## Core Style

- Prefer simple, explicit C# over clever abstractions.
- Use nullable reference types consistently when enabled.
- Use records for immutable data and value objects when they fit.
- Use primary constructors when they improve readability.
- Use `async`/`await` for asynchronous boundaries.
- Preserve existing project conventions unless the task explicitly changes them.

## Size Limits

- Target files at 150 lines or less.
- Target methods at 20 lines or less.
- Split by responsibility, actor, or business concept.
- Do not split code only to satisfy a line count if the extracted names are vague.

## Names

- Use intent-revealing names from the domain.
- Classes, records, structs, interfaces, properties, and methods use `PascalCase`.
- Locals and parameters use `camelCase`.
- Async methods returning `Task` should end with `Async` for new APIs, unless implementing an established project convention.
- File name must match the main public type.
- Avoid `Helper`, `Utility`, `Common`, `Base`, `Manager`, `Processor`, and `Handler` unless the role is already meaningful in the project.

Prefer:

```csharp
BrandName.Create(name)
ICreateBrandCommand
IGetDeviceSettingByDeviceId
TelemetryProcessor
```

Avoid:

```csharp
DataHelper
BrandServiceManager
ProcessAndSaveData
ValidateAndPersist
```

## Functions

Each function should do one cohesive thing.

Good reasons to extract:

- a named business decision
- a mapping boundary
- a validation rule
- a persistence query
- a retry or error handling policy
- a repeated test setup concept

Bad reasons to extract:

- making code look abstract
- hiding a difficult branch behind a vague name
- reducing line count without improving meaning

## Control Flow

- Use guard clauses for invalid input and early exits.
- Keep nested conditionals shallow.
- Prefer clear `switch` expressions for small classification rules.
- Avoid boolean parameters that change method behavior; prefer named methods or options records when variation is real.
- Avoid returning `null` from core behavior unless absence is the explicit query contract.

## Comments

- Prefer names and types over comments.
- Use comments only for non-obvious business constraints, provider limitations, or operational decisions.
- Delete stale comments when behavior changes.
- Do not narrate obvious code.

## Exceptions

- Use exceptions for invalid domain/application operations and technical failures.
- Throw typed exceptions when callers need to classify the failure.
- Preserve the original exception as `InnerException` when wrapping.
- Do not catch `Exception` just to return `false`, `null`, or an empty collection.
- Map exceptions at the boundary, not inside domain/application.

## Refactoring Discipline

Use the two-hat rule:

- When changing behavior, add/adjust tests and implement the smallest change.
- When refactoring, keep behavior unchanged and tests green.

Refactor in small steps:

- rename for clarity
- extract value object
- extract method for a real concept
- move mapping to boundary
- split ports by consumer need
- remove duplication after tests show stable behavior

## Duplication

Remove semantic duplication, not coincidental similarity.

Extract when duplicated code represents the same:

- business rule
- mapping decision
- exception mapping
- test fixture
- query shape
- adapter policy

Do not create generic base classes or helper libraries for two pieces of code that only look similar.

## Review Gate

- Names reveal intent.
- Files and methods remain readable.
- No dead code, unused using, unused package, or unused interface.
- Error handling is not duplicated across layers.
- Domain/application code remains framework-free.
- Refactors were protected by tests.
