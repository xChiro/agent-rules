---
description: Full TDD cycle - Red → Green → Refactor
---

# Full TDD Cycle Workflow

**Strict TDD**: Red (failing test) → Green (minimal code) → Refactor (improve)

## Global Rules

**Process**:
- Analyze code before changes
- Frame acceptance behavior with A-TDD before implementation
- Write tests before implementation
- Start with edge cases, then happy paths
- Never implement without failing tests
- Never add speculative features
- Never break Clean Architecture boundaries

**Quality** (see `go-clean-code-standards.md`):
- Files target ≤150 lines unless a cohesive exception is clearer
- Functions target ≤20 lines unless a cohesive exception is clearer
- Each method must have one cohesive reason to change
- Use `testify/assert`
- Manual mocks only
- Maintain 90%+ unit coverage for domain/application layers
- Follow CQRS, YAGNI, Screaming Architecture
- Follow `go-idiomatic-advanced-practices.md` for context, errors, interfaces, concurrency, generics, and performance

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
- Use no build tag for default unit tests
- Use `//go:build integration` for integration tests
- Use `//go:build e2e` for end-to-end tests
- **MANDATORY**: Use comment separators `// Arrange`, `// Act`, `// Assert` to divide test sections
- Use Builder pattern for test data in `fixtures/builders.go`
- Use setup helpers in `{use_case}_test_setup.go`
- Use value object helpers in `{use_case}_value_object_helpers.go`

**Test Order**: Invalid input → dependency failures → business rule violations → happy path

**Verify**: Tests fail for correct reason

**Rule**: No production code yet

## Phase 2.5: Test Review

**Goal**: User review and approval before implementation

**Action**: Present created tests to user for review

**Review Checklist**:
- Test names clearly describe scenarios
- Edge cases are comprehensive
- Happy paths are covered
- Test assertions are correct
- Mock dependencies are appropriate
- Tests follow A-TDD naming convention
- No fragile test patterns

**User Approval Required**: Wait for user confirmation before proceeding to Green phase

**Rule**: No production code until user approves tests

## Phase 3: Green (Minimal Code)

**Goal**: Minimum code to pass tests

**Rules**:
- Re-analyze before implementing
- Respect architecture layers (see `go-architecture-patterns.md`)
- Implement only what test requires
- No unnecessary abstractions
- No interfaces, generics, worker pools, caching, or functional options without a current trigger
- No refactoring yet

**Allowed**: Domain logic, use cases, DTOs, validation, dependency wiring

**Stop**: When tests pass

## Phase 4: Refactor

**Goal**: Improve without changing behavior

**Order**: Test code → Production code → Run tests

**Look for**: Semantic duplication, long/cohesion-poor methods, SRP violations (multiple responsibilities), poor naming, architecture violations, large files, decorative abstractions, incorrect context/error/logging boundaries

**Verify**: All tests still pass

## Final Validation

**Verify**:
- ✅ All tests pass
- ✅ Edge cases + happy paths covered
- ✅ Domain/application unit coverage remains 90%+ or improves toward it in touched packages
- ✅ Architecture boundaries respected
- ✅ Test build tags match suite type (`integration`, `e2e`, or no tag for unit)
- ✅ No unused code (YAGNI)
- ✅ File/function size targets respected or exceptions are cohesive
- ✅ Each method has one cohesive reason to change
- ✅ CQRS compliance (one interface per file)
- ✅ Advanced patterns have current evidence and tests
- ✅ Race detector run when concurrency changed

**Summary**: Tests added, production changes, refactors, risks, next TDD step
