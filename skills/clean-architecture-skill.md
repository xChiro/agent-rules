# Clean Architecture Skill

## Purpose

Use this skill when creating, reviewing, or refactoring software that must follow Clean Architecture.

The agent must protect business rules from frameworks, databases, UI concerns, and external services.

## Core Rule

Dependencies must always point inward.

- Domain must not depend on any other layer.
- Application may depend on Domain.
- Infrastructure may depend on Application and Domain.
- UI/API may depend on Application.
- Outer layers must implement contracts defined by inner layers.

## Responsibilities

When using this skill, the agent must:

1. Identify the actors and reasons for change.
2. Keep business rules in the Domain or Application layer.
3. Avoid placing framework-specific code in Domain or Application.
4. Use interfaces/ports for external dependencies.
5. Keep persistence, messaging, HTTP clients, and framework code in Infrastructure.
6. Ensure use cases express application behavior clearly.
7. Reject shortcuts that couple business logic to UI, database, or external APIs.

## Review Checklist

- Are entities independent from frameworks?
- Are use cases independent from controllers, views, databases, and queues?
- Are dependencies inverted at architectural boundaries?
- Are interfaces owned by the layer that needs them?
- Is Infrastructure only an implementation detail?
- Can the business rules be tested without a database, web server, or cloud service?

## Output Expectations

When modifying code, explain:

- Which layer each change belongs to.
- Why dependencies are valid.
- Which architectural boundary is being protected.
- Any detected violation and how it was corrected.
