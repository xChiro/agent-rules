---
trigger: always_on
description: 
globs: 
---

---

# Go Clean Architecture, DDD & CQRS Guide 

This guide summarises how to structure a Go codebase using **Clean Architecture** and **Domain‑Driven Design (DDD)** while incorporating **Command‑Query Responsibility Segregation (CQRS)**.  It draws on internal best practices such as TDD‑first development, small files/functions, and clear separation between layers.

## Layered Design

* **Domain (Core)**: Entities and value objects that model the business. **Technology-agnostic**: Keep them pure; no imports from other layers, framework tags, or third-party framework references. Must remain completely independent of specific technologies like SignalR, Entity Framework, or external libraries.
* **Application**: Use cases that orchestrate domain objects via interfaces (ports).  Implements CQRS use cases by separating commands (writes) from queries (reads).
* **Infrastructure**: Adapters that implement ports using databases, message queues or external services.  Includes mappers/DTOs.  No business rules here.
* **Interface (Adapters)**: HTTP/gRPC/CLI handlers that translate transport requests into application calls and serialise responses back.  Hosts dependency wiring (composition root).

Dependencies must always flow inward (Interface → Infrastructure → Application → Domain).  The domain knows nothing about infrastructure details. **Domain must be technology-agnostic**: No references to specific frameworks, databases, or third-party libraries.

## Domain‑Driven Design Essentials

* **Entities**: Objects with identity and lifecycle (e.g., `Telemetry` with ID).  Enforce invariants in constructors or methods.
* **Value Objects**: Immutable types without identity (e.g., `Money`).  Validate inputs and provide domain‑specific behaviour.
* **Aggregates**: Clusters of entities and value objects modified only through the root.
* **Repositories**: Interfaces for accessing aggregates, defined in the domain and implemented in infrastructure.
* **Domain Services & Events**: Stateless operations and notifications that capture important domain occurrences.

## CQRS in Go

CQRS splits write operations (commands) from read operations (queries), allowing each to be optimised independently.

### When to Adopt CQRS

* Reads and writes have different performance requirements or data shapes.
* You need to scale reads independently of writes.
* Workflows are event‑driven and benefit from asynchronous processing.

### Implementing CQRS

1. **Define ports**: in the domain, create interfaces like `SaveTelemetry` (command) and `TelemetryQuery` (query).  Commands return an ID or result; queries return read models or DTOs.
2. **Separate models**: command models enforce invariants (entities/aggregates); query models are denormalised and contain only data.
3. **Use cases**: in the application layer, inject ports into use cases (`SaveTelemetryUseCase`, `GetTelemetryUseCase`).  Use dependency injection to decouple from implementations.
4. **Infrastructure adapters**: implement command and query ports using your database or messaging technology.  For commands, persist aggregates and publish domain events.  For queries, read from optimised views or projections.
5. **Consistency**: if reads are updated asynchronously, be aware of eventual consistency.  In simple systems, commands and queries can share the same DB but still use separate interfaces.
6. **Test‑driven**: start by writing failing tests for commands/queries using the `given_when_then` pattern and keep files/functions small.

### Minimal Example: Saving Telemetry

Below is a condensed example of saving a `Telemetry` aggregate and querying it:

```go
// Domain: entity and ports
package telemetry

type ID string

type Telemetry struct { id ID; lat, lon, speed float64 }
func NewTelemetry(id ID, lat, lon, speed float64) (*Telemetry, error) { /* validate inputs */ }

// Command port
type SaveTelemetry interface {
    Execute(ctx context.Context, t *Telemetry) (ID, error)
}

// Query port & DTO
type TelemetryDTO struct { ID ID; Lat, Lon, Speed float64 }
type TelemetryQuery interface {
    GetByID(ctx context.Context, id ID) (*TelemetryDTO, error)
}

// Application: use case
package app

type SaveTelemetryUseCase struct { saver telemetry.SaveTelemetry }
func (uc *SaveTelemetryUseCase) Execute(ctx context.Context, lat, lon, speed float64) (telemetry.ID, error) {
    id := telemetry.ID(uuid.NewString())
    tel, err := telemetry.NewTelemetry(id, lat, lon, speed)
    if err != nil { return "", err }
    return uc.saver.Execute(ctx, tel)
}

// Infrastructure: repository adapter (e.g., using GORM)
type TelemetryModel struct { ID string; Lat, Lon, Speed float64 }
type repo struct { db *gorm.DB }
func (r *repo) Execute(ctx context.Context, t *telemetry.Telemetry) (telemetry.ID, error) {
    m := TelemetryModel{ ID: string(t.ID()), Lat: t.Latitude(), Lon: t.Longitude(), Speed: t.Speed() }
    return t.ID(), r.db.WithContext(ctx).Create(&m).Error
}
func (r *repo) GetByID(ctx context.Context, id telemetry.ID) (*telemetry.TelemetryDTO, error) { /* query */ }
```

This example omits error handling details to keep it concise.  The key point is that commands (`Execute`) persist aggregates and return identifiers, while queries (`GetByID`) return read models.  Use dependency injection to supply the adapter to the use case.

## SOLID & Clean Code Highlights

* **Single Responsibility**: Each type has one reason to change; avoid mixing concerns.
* **Open/Closed & Liskov**: Code is extended via interfaces or small structs; implementations shouldn’t surprise clients.
* **Dependency Inversion**: Domain/application depends on abstractions, not concrete infrastructure.
* **TDD & small units**: Write tests before code; keep files under ~150 lines and functions under ~20 lines.
* **Edge‑case testing**: Cover invalid inputs and boundary cases first.
* **Pure domain**: No `json` or `sql` tags in domain structs; put mappers/DTOs in infrastructure.
* **Idempotent consumers**: When consuming events, ensure idempotency and consider an outbox pattern.

## Conclusion

A well‑structured Go service using Clean Architecture, DDD and CQRS separates concerns, promotes testability and scales gracefully.  Define your core business logic in the domain, orchestrate actions in the application layer, implement ports in infrastructure, and expose them through interfaces.  Use CQRS when your domain benefits from separate read/write models, and always start with tests to guide your design.

---
