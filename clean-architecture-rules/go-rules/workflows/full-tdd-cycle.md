---
description: Full TDD cycle - Red → Green → Refactor
---

# Full TDD Cycle Workflow

**Strict TDD**: Red (failing test) → Green (minimal code) → Refactor (improve)

## Global Rules

**Process**:
- Analyze code before changes
- Write tests before implementation
- Start with edge cases, then happy paths
- Never implement without failing tests
- Never add speculative features
- Never break Clean Architecture boundaries

**Quality** (see `go-clean-code-standards.md`):
- Files ≤150 lines
- Functions ≤20 lines
- Each method must have exactly ONE responsibility (SRP strict)
- Use `testify/assert`
- Manual mocks only
- Follow CQRS, YAGNI, Screaming Architecture

## Phase 1: Code Analysis

**Goal**: Understand before testing

**Analyze**: Structure, existing/missing behavior, layer, dependencies, tests, edge cases, happy path

**Output**: Edge cases list, happy paths list, mock dependencies, files to modify

**Rule**: No production code yet

## Phase 2: Red (Failing Tests)

**Goal**: Define behavior with failing tests

**Rules**:
- Start with edge cases → happy paths
- Use `Test_given_[scenario]_when_[action]_then_[expected]` naming
- Use `testify/assert` (MANDATORY)
- One behavior per test
- Manual mocks only

**Test Order**: Invalid input → dependency failures → business rule violations → happy path

**Verify**: Tests fail for correct reason

**Rule**: No production code yet

## Phase 3: Green (Minimal Code)

**Goal**: Minimum code to pass tests

**Rules**:
- Re-analyze before implementing
- Respect architecture layers (see `go-architecture-patterns.md`)
- Implement only what test requires
- No unnecessary abstractions
- No refactoring yet

**Allowed**: Domain logic, use cases, DTOs, validation, dependency wiring

**Stop**: When tests pass

## Phase 4: Refactor

**Goal**: Improve without changing behavior

**Order**: Test code → Production code → Run tests

**Look for**: Duplication, long methods (>20 lines), SRP violations (multiple responsibilities), poor naming, architecture violations, large files (>150 lines)

**Verify**: All tests still pass

## Final Validation

**Verify**:
- ✅ All tests pass
- ✅ Edge cases + happy paths covered
- ✅ Architecture boundaries respected
- ✅ No unused code (YAGNI)
- ✅ Files ≤150 lines, functions ≤20 lines
- ✅ Each method has exactly ONE responsibility (SRP strict)
- ✅ CQRS compliance (one interface per file)

**Summary**: Tests added, production changes, refactors, risks, next TDD step