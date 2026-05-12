# Agent Rules

[![License: CC0-1.0](https://img.shields.io/badge/license-CC0%201.0-lightgrey.svg)](https://creativecommons.org/publicdomain/zero/1.0/)

## Overview

Agent Rules is a public-domain collection of reusable rules and workflows for AI coding agents.

The purpose of this repository is to document practical engineering standards that an AI assistant can follow when creating, reviewing, refactoring, or testing software.

The current focus is on Go projects that follow:

- Clean Architecture
- SOLID principles
- Test-Driven Development
- CQRS
- YAGNI
- Screaming Architecture
- Clean Code practices

These documents are intended to be copied or adapted into tools such as Windsurf, Cursor, Claude Code, GitHub Copilot instructions, OpenAI agents, or any custom agent workflow.

## Repository Report

This repository currently contains a Go-oriented rule set for disciplined software development with AI agents.

The main documents are located under:

```text
clean-architecture-rules/go-rules/
├── rules/
└── workflows/
```

### Rules

Rules define the non-negotiable standards the agent must respect while working on a codebase.

The current Go rules include clean code standards for writing idiomatic and maintainable Go code. They define principles such as expressive naming, small functions, one responsibility per method, encapsulation, consistency, YAGNI, and one type per file.

The rules also include concrete quality limits:

- Files should be no longer than 150 lines.
- Functions should be no longer than 20 lines.
- Each method should have exactly one responsibility.
- Tests should use `github.com/stretchr/testify/assert` for assertions.
- Unused code, imports, variables, and speculative functions should be removed.

The standards also cover naming conventions, function design, value objects, entities, collections, error handling, formatting, static analysis, CQRS interfaces, and testing expectations.

See:

- [`go-clean-code-standards.md`](./clean-architecture-rules/go-rules/rules/go-clean-code-standards.md)

### Workflows

Workflows define the step-by-step process the agent should follow when performing larger tasks.

The current workflow focuses on a disciplined TDD modification cycle. It requires the agent to analyze existing tests first, identify fragile test patterns, define missing edge cases, modify or add tests before production code, and run tests continuously after every refactor step.

The workflow is organized into phases:

1. Test analysis
2. Test implementation using Red -> Green
3. Test review
4. Minimal production implementation
5. Test code refactor
6. Production code refactor
7. Integration validation

The workflow reinforces Clean Architecture, CQRS, YAGNI, Screaming Architecture, small functions, manual mocks, ATDD-style test naming, and continuous testing.

See:

- [`modify-tdd-cycle.md`](./clean-architecture-rules/go-rules/workflows/modify-tdd-cycle.md)

## Rules vs Workflows

This repository separates rules from workflows.

Rules answer:

> What must always be true?

Examples:

- Domain logic must not depend on infrastructure.
- Each method must have exactly one responsibility.
- Do not add unused code.
- Use meaningful names.
- Keep functions small.

Workflows answer:

> What process should the agent follow to complete a task?

Examples:

- Analyze tests before changing production code.
- Write or modify tests first.
- Make tests pass with minimal implementation.
- Refactor only after tests pass.
- Run tests after every refactor step.

## How to Use

Copy the relevant Markdown files into your AI coding tool configuration.

For Windsurf, the documents can be adapted into:

```text
.windsurf/rules/
```

For other tools, they can be used as:

- repository instructions
- project rules
- agent prompts
- workflow playbooks
- pull request review guidelines
- coding standards

## Recommended Usage Pattern

Use the rules as always-on engineering standards.

Use the workflows when the agent is asked to perform a specific task, such as modifying existing code, adding tests, refactoring, or implementing behavior through TDD.

A practical agent setup could load:

```text
rules/go-clean-code-standards.md
workflows/modify-tdd-cycle.md
```

This gives the agent both the engineering constraints and the implementation process.

## Design Philosophy

The repository is based on the idea that AI-assisted development should be disciplined, explicit, and reviewable.

The goal is not to let the agent generate large amounts of code quickly. The goal is to help the agent work like a careful software engineer:

- understand the existing design
- protect architecture boundaries
- write tests before production code
- make small changes
- avoid speculative abstractions
- refactor safely
- keep behavior covered by tests
- explain decisions clearly

## License

This project is released into the public domain under the CC0 1.0 Universal license.

See the [LICENSE](./LICENSE.md) file for details.
