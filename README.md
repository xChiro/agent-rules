# Agent Rules

[![License: CC0-1.0](https://img.shields.io/badge/license-CC0%201.0-lightgrey.svg)](https://creativecommons.org/publicdomain/zero/1.0/)

## Overview

Agent Rules is a public-domain collection of reusable rules, workflows, and skills for AI coding agents.

The goal is to give coding agents explicit engineering standards they can follow when creating, reviewing, refactoring, or testing software. The repository favors disciplined, reviewable work over fast generation of large amounts of code.

## Repository Map

```text
clean-architecture-rules/go-rules/
├── rules/       # Go backend standards and selected service-specific profiles
├── workflows/   # Step-by-step task workflows
└── skills/      # Go-oriented skill copies for tools that consume skills locally

react-rules/
├── rules/       # React feature architecture standards
└── workflows/   # React feature implementation workflow

windsurf-skills/
├── skills/      # Canonical Windsurf skill definitions
└── workflows/   # Canonical Windsurf workflows
```

## Rule Families

### Go Clean Architecture

Use these rules for Go backend projects that follow Clean Architecture, DDD, CQRS, TDD, YAGNI, SOLID, and Screaming Architecture.

Core reusable rules:

- [`go-clean-code-standards.md`](./clean-architecture-rules/go-rules/rules/go-clean-code-standards.md)
- [`go-architecture-patterns.md`](./clean-architecture-rules/go-rules/rules/go-architecture-patterns.md)
- [`go-project-structure.md`](./clean-architecture-rules/go-rules/rules/go-project-structure.md)
- [`go-solid-principles.md`](./clean-architecture-rules/go-rules/rules/go-solid-principles.md)
- [`go-use-case-protocol.md`](./clean-architecture-rules/go-rules/rules/go-use-case-protocol.md)
- [`go-unit-testing-standards.md`](./clean-architecture-rules/go-rules/rules/go-unit-testing-standards.md)
- [`go-integration-testing-standards.md`](./clean-architecture-rules/go-rules/rules/go-integration-testing-standards.md)
- [`go-dependency-injection.md`](./clean-architecture-rules/go-rules/rules/go-dependency-injection.md)

Service-specific HBK Inventory rules:

- [`rest-api-standards.md`](./clean-architecture-rules/go-rules/rules/rest-api-standards.md)
- [`domain-event-publishing.md`](./clean-architecture-rules/go-rules/rules/domain-event-publishing.md)
- [`create-rest-endpoint.workflow.md`](./clean-architecture-rules/go-rules/workflows/create-rest-endpoint.workflow.md)
- [`create-e2e-test.workflow.md`](./clean-architecture-rules/go-rules/workflows/create-e2e-test.workflow.md)
- [`publish-domain-event.workflow.md`](./clean-architecture-rules/go-rules/workflows/publish-domain-event.workflow.md)

Load service-specific files only when working on that service or an equivalent project that uses the same API, AWS, DynamoDB, SNS, Lambda, and route conventions.

### React

Use the React rules for frontend applications. They intentionally do not force backend-style Clean Architecture, ports, use cases, or TDD by default.

- [`react-feature-architecture-standards.md`](./react-rules/rules/react-feature-architecture-standards.md)
- [`react-feature-implementation.workflow.md`](./react-rules/workflows/react-feature-implementation.workflow.md)

### Windsurf Skills

`windsurf-skills/` is the canonical source for reusable Windsurf skills and workflows. The copies under `clean-architecture-rules/go-rules/skills/` exist only for Go-oriented package layouts.

## Rules vs Workflows vs Skills

Rules answer: what must always be true?

Examples:

- Domain logic must not depend on infrastructure.
- Each use case should have one actor and one business outcome.
- Do not add unused code.
- Use meaningful names.
- Keep functions small.

Workflows answer: what process should the agent follow for a task?

Examples:

- Analyze existing tests before changing production code.
- Write or modify tests first.
- Make tests pass with minimal implementation.
- Refactor only after tests pass.
- Run tests after each meaningful refactor step.

Skills answer: what behavior and judgment should the agent apply in a tool-specific runtime?

Examples:

- Use senior engineering judgment.
- Prefer small vertical slices.
- Keep ports consumer-owned and behavior-named.
- Use manual mocks for outgoing dependencies.

## Recommended Usage

For a reusable Go backend setup, start with:

```text
clean-architecture-rules/go-rules/rules/go-clean-code-standards.md
clean-architecture-rules/go-rules/rules/go-architecture-patterns.md
clean-architecture-rules/go-rules/rules/go-project-structure.md
clean-architecture-rules/go-rules/rules/go-unit-testing-standards.md
clean-architecture-rules/go-rules/workflows/senior-tdd-feature.workflow.md
```

Add more focused files only when the task needs them:

```text
go-dependency-injection.md        # DI or Wire work
go-integration-testing-standards.md # real adapter or external-system tests
rest-api-standards.md             # HBK Inventory REST endpoints only
domain-event-publishing.md        # HBK Inventory domain events only
```

For React:

```text
react-rules/rules/react-feature-architecture-standards.md
react-rules/workflows/react-feature-implementation.workflow.md
```

For Windsurf:

```text
windsurf-skills/skills/
windsurf-skills/workflows/
```

## Design Philosophy

AI-assisted development should be disciplined, explicit, and reviewable.

The agent should:

- read the existing design before changing it
- protect architecture boundaries
- write tests before production behavior when TDD is in scope
- make small changes
- avoid speculative abstractions
- refactor safely after tests pass
- keep behavior covered by tests
- explain decisions clearly

## License

This project is released into the public domain under the CC0 1.0 Universal license.

See the [LICENSE](./LICENSE.md) file for details.
