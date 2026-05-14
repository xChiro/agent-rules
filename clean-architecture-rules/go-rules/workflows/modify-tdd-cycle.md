---
description: Test-Driven TDD - Analyze Tests → Make Pass → Refactor with Continuous Testing
---

# Test-Driven TDD Workflow

**Focus**: Test analysis first, avoid fragile tests, continuous testing after each refactor

## Global Rules

**Process**:
- Analyze existing tests before any changes
- Identify what tests to add or modify
- Avoid fragile test patterns
- Make tests pass before refactoring
- Run tests after EVERY refactor step
- Follow Clean Architecture, CQRS, YAGNI, Screaming Architecture

**Quality** (see `go-clean-code-standards.md`):
- Files ≤150 lines
- Functions ≤20 lines
- Each method must have exactly ONE responsibility (SRP strict)
- Use `testify/assert`
- Manual mocks only
- Follow ATDD naming conventions

## Phase 1: Test Analysis

**Goal**: Understand test landscape before changes

**Analyze Existing Tests**:
- Current test coverage gaps
- Fragile test patterns (implementation details, tight coupling)
- Missing edge cases and happy paths
- Test duplication and redundancy
- Mock dependency issues
- Integration vs unit test separation

**Identify Test Actions**:
- **Add**: Missing critical test cases
- **Modify**: Fragile or incorrect tests
- **Delete**: Redundant or obsolete tests
- **Refactor**: Poorly structured tests

**Output**: Test plan with specific actions, prioritized by impact

**Rule**: No production code changes yet

## Phase 2: Test Implementation (Red → Green)

**Goal**: Create/modify tests to define behavior correctly

**Add New Tests**:
- Start with edge cases → happy paths
- Use `Test_given_[scenario]_when_[action]_then_[expected]` naming
- Focus on behavior, not implementation
- Use `testify/assert` (MANDATORY)
- Create manual mocks only when needed

**Modify Existing Tests**:
- Fix fragile test patterns
- Remove implementation dependencies
- Improve test clarity and maintainability
- Ensure single responsibility per test

**Avoid Fragile Tests**:
- ❌ Testing private implementation details
- ❌ Tight coupling to production code structure
- ❌ Over-specific assertions
- ❌ Testing framework internals
- ❌ Brittle mock setups

**Good Test Patterns**:
- ✅ Test public behavior and contracts
- ✅ Use descriptive scenario-based names
- ✅ Focus on business outcomes
- ✅ Simple, focused assertions
- ✅ Stable mock interfaces

**Verify**: Tests fail for correct reasons (new tests) or pass (modified tests)

## Phase 2.5: Test Review

**Goal**: User review and approval before implementation

**Action**: Present created tests to user for review

**Review Checklist**:
- Test names clearly describe scenarios
- Edge cases are comprehensive
- Happy paths are covered
- Test assertions are correct
- Mock dependencies are appropriate
- Tests follow ATDD naming convention
- No fragile test patterns

**User Approval Required**: Wait for user confirmation before proceeding to Phase 3

**Rule**: No production code until user approves tests

## Phase 3: Make Tests Pass

**Goal**: Minimal production code to satisfy all tests

**Rules**:
- Implement ONLY what failing tests require
- Respect architecture layers
- No premature refactoring
- No speculative features
- Follow YAGNI principles

**Implementation Order**:
1. Fix any breaking changes from test modifications
2. Implement new behavior for new tests
3. Ensure all existing tests still pass

**Stop**: When ALL tests pass

## Phase 4: Test Code Refactor

**Goal**: Improve test code quality without changing behavior

**Refactor Test Code**:
- Remove test duplication
- Improve test naming and clarity
- Extract test helpers and utilities
- Simplify mock setups
- Consolidate similar test patterns

**Run Tests After Each Change**:
- Make one small refactor change
- Run relevant tests immediately
- Verify all tests still pass
- Fix any failures before proceeding

**Quality Checks**:
- Test files ≤150 lines
- Test functions ≤20 lines
- Each test has single responsibility
- Clear, descriptive test names

## Phase 5: Production Code Refactor

**Goal**: Improve production code without changing behavior

**Refactor Production Code**:
- Remove duplication
- Extract methods/functions
- Improve naming and structure
- Ensure SRP compliance (one responsibility per method)
- Follow CQRS patterns
- Maintain Clean Architecture boundaries

**Run Tests After Each Change**:
- Make one small refactor change
- Run ALL tests immediately
- Verify all tests still pass
- Fix any failures before proceeding

**Quality Checks**:
- Files ≤150 lines
- Functions ≤20 lines
- Each method has exactly ONE responsibility
- No unused code (YAGNI)
- Proper interface segregation

## Phase 6: Integration Validation

**Goal**: Ensure system integrity after all changes

**Final Test Run**:
- Run complete test suite
- Verify all unit tests pass
- Run integration tests if available
- Check test coverage improvements

**Architecture Validation**:
- Clean Architecture boundaries maintained
- CQRS compliance verified
- YAGNI principles followed
- Screaming Structure preserved

## Continuous Testing Rules

**MANDATORY**: Run tests after EVERY refactor step

**When to Run Tests**:
- After each test code change
- After each production code change
- After each interface modification
- After each mock update
- Before moving to next phase

**Test Commands**:
```bash
# Unit tests only
go test ./tests/unit_tests/...

# Specific package tests
go test ./tests/unit_tests/memberships/application/enroll_member_requests/...

# With coverage
go test -cover ./tests/unit_tests/...

# Integration tests (if applicable)
go test -tags=integration ./tests/integration/...
```

## Final Validation

**Verify All Criteria**:
- ✅ All tests pass
- ✅ No fragile test patterns
- ✅ Test coverage improved
- ✅ Architecture boundaries respected
- ✅ Files ≤150 lines, functions ≤20 lines
- ✅ Each method has exactly ONE responsibility (SRP strict)
- ✅ CQRS compliance (one interface per file)
- ✅ YAGNI compliance (no unused code)
- ✅ Tests run after each refactor step

**Summary**: Test analysis performed, fragile tests avoided, tests added/modified, production code implemented, continuous testing completed, refactors validated

## Anti-Patterns to Avoid

**Fragile Test Patterns**:
- Testing implementation details
- Tight coupling to production code
- Over-specific mock expectations
- Testing framework internals
- Brittle test data setups

**Refactor Anti-Patterns**:
- Big bang refactors (many changes at once)
- Skipping test runs between changes
- Refactoring without test coverage
- Breaking architecture boundaries
- Adding unnecessary abstractions
