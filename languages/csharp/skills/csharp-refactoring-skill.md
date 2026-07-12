---
skill_id: SKILL-CSHARP_REFACTORING_SKILL
name: csharp-refactoring
trigger: model_decision
description: C# refactoring skill for safe behavior-preserving changes using tests, Clean Code, SOLID, and Clean Architecture boundaries.
globs: **/*.cs,**/*Test.cs,**/*Tests.cs
---

# C# Refactoring Skill

## SDD Baseline

- Follow `common-sdd-agentic-discipline.md` for every behavior-changing task.
- Keep specs versioned under `specs/features/<number>-<slug>/` when the project supports SDD artifacts.
- Apply mandatory Gate 1 before spec writes, Gate 2 before RED, and Gate 3 before Green, even for simple or low-risk changes.
- Start with BDD Given/When/Then acceptance evidence, then unit-level ATDD-style focused failing test code, then production code.
- Refactor only with tests green and converge specs, tasks, parallel tracks, traceability, verification notes, and code.

Refactor only with a safety net. If behavior is not covered, add a characterization or focused behavior test before restructuring.

## Refactoring Flow

1. Identify the behavior that must stay unchanged.
2. Run or add tests for that behavior.
3. Make one small structural change.
4. Run the relevant tests.
5. Repeat until the design issue is removed.

## Good Refactoring Targets

- Move business rule from controller/adapter into domain/application.
- Extract value object from repeated primitive validation.
- Split a fat port into focused commands/queries.
- Move mapping to WebApi/DataAccess/message adapter.
- Remove duplicate exception mapping.
- Replace vague helpers with named domain behavior.
- Delete unused abstractions.

## Guardrails

- Do not change behavior while wearing the refactoring hat.
- Do not introduce a design pattern without current pressure.
- Do not create base classes for test code unless shared behavior is stable and meaningful.
- Do not cross architecture boundaries for convenience.
- Keep public contracts stable unless the task includes a migration.

## Completion Check

- Tests pass.
- Diff is smaller or clearer than before.
- Names reveal responsibility.
- No new unused code.
- Boundaries are stricter than before.
