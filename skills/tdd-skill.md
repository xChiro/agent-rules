# TDD Skill

## Purpose

Use this skill when implementing features using disciplined Test-Driven Development.

The goal is to create maintainable software through small iterations, fast feedback, and high confidence refactoring.

## Mandatory Rules

1. Follow Red -> Green -> Refactor.
2. Start with the simplest failing test.
3. Only write enough production code to pass the current test.
4. Refactor only after tests pass.
5. Never implement multiple behaviors at once.
6. Tests must document behavior.
7. Edge cases should be considered early.

## Test Style

- Use AAA (Arrange, Act, Assert).
- The Act section should contain only one action.
- Use meaningful test names.
- Tests should describe business behavior.
- Avoid unnecessary mocking.
- Prefer behavior verification over implementation details.

## Anti-Patterns

The agent must reject:

- Massive tests.
- Testing private methods.
- Framework-heavy tests.
- Hidden assertions.
- Multiple Acts.
- Excessive setup.
- Fragile mocks.
- Tests tightly coupled to implementation.

## Review Checklist

- Does the test fail before implementation?
- Is the test focused on one behavior?
- Is the implementation minimal?
- Is refactoring safe and covered?
- Is the code easier to maintain after the cycle?
