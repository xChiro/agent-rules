---
description: Refactor C# production code safely without behavior changes, using tests, small steps, and Clean Architecture boundaries.
---

# C# Refactor Production Code Workflow

Use this workflow when improving structure without changing behavior.

## Phase 1: Safety Net

**Goal**: Protect current behavior.

Checklist:

- Find existing tests for the behavior.
- Run targeted tests if practical.
- Add characterization tests if behavior is uncovered and risky.
- Identify public contracts that must not change.

## Phase 2: Refactoring Target

**Goal**: Name the design problem.

Examples:

- mixed actor responsibilities
- domain rule in controller
- EF Core leak into application
- duplicated primitive validation
- broad repository interface
- duplicated exception mapping
- large unreadable method
- test setup duplication

## Phase 3: Small Step

**Goal**: Make one behavior-preserving change.

Options:

- rename
- extract method
- extract value object
- move mapping
- split port
- remove unused dependency
- move framework code outward
- replace duplication with a named concept

## Phase 4: Verify

**Goal**: Keep behavior stable.

Checklist:

- Run targeted tests after meaningful steps.
- Keep diffs reviewable.
- Do not combine refactor with feature work unless the refactor is necessary for the feature.

## Phase 5: Final Review

**Goal**: Confirm design improved.

Checklist:

- Boundaries are stricter.
- Names are clearer.
- No new unused code.
- Tests still describe behavior.
- Public contracts remain stable.
