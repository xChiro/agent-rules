# CQRS Skill

## Purpose

Use this skill when designing systems that separate read and write responsibilities.

The goal is to improve scalability, maintainability, clarity, and separation of concerns.

## Core Rules

1. Commands change state.
2. Queries only return data.
3. Queries must not contain business mutations.
4. Commands should express business intent.
5. Read models may differ from write models.
6. Separate optimization strategies are allowed for reads and writes.

## Naming Conventions

### Commands

- CreateUserCommand
- UpdateOrderCommand
- DeleteCrewCommand

### Queries

- GetUserByIdQuery
- SearchOrdersQuery
- GetActiveCrewsQuery

### Handlers

- CreateUserHandler
- GetUserByIdHandler

## Review Checklist

- Are reads and writes separated?
- Are queries side-effect free?
- Do commands represent business intent?
- Are handlers focused on one operation?
- Are repositories aligned with CQRS responsibilities?
- Is business logic located in the correct layer?

## Anti-Patterns

The agent must reject:

- Generic repositories with unrelated operations.
- Query handlers that mutate state.
- Fat service classes mixing reads and writes.
- Controllers containing business logic.
