---
trigger: model_decision
description: Apply Go clean code principles with focus on readability, clarity, and maintainability
globs: 
---

# Clean Architecture + DDD Rules (Go)

Architecture Layers:

domain/
application/
infrastructure/
interfaces/

Dependency Direction:
interfaces -> application -> domain
infrastructure -> domain/application

Domain Rules:
- No framework dependencies.
- No database logic.
- No HTTP or transport concerns.

Domain Elements:

Value Objects
- Immutable
- Validated at creation
- Compared by value

Entities
- Have identity
- Contain behavior
- Protect invariants

Aggregates
- Root controls modifications
- External access only through root

Repositories
- Defined in domain
- Implemented in infrastructure

Application Layer:
- Orchestrates use cases
- Loads aggregates
- Persists changes
- Publishes events

SOLID:

SRP (Clean Architecture definition):
A module should be responsible to one, and only one, actor.

OCP:
Extend behavior without modifying stable code.

DIP:
Depend on abstractions.

Encapsulation:
Fields private unless necessary.

Domain Events:
Used for cross‑aggregate communication.