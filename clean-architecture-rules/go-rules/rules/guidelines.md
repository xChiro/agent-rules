---
trigger: always_on
description: 
globs: 
---

# Go Clean Architecture, DDD & CQRS Guide

This guide summarizes Go codebase structure using **Clean Architecture**, **Domain‑Driven Design (DDD)**, and **CQRS** with TDD‑first development.

## Architecture Overview

### Layer Structure
- **Domain**: Pure business logic (entities, value objects). **Technology-agnostic**: No external dependencies, third-party framework references, or infrastructure concerns. Must remain completely independent of specific technologies like SignalR, Entity Framework, or external libraries.
- **Application**: Use cases, ports/interfaces. Orchestrates domain objects.
- **Infrastructure**: Adapters implementing ports (DB, APIs, messaging).
- **Interface**: HTTP/gRPC handlers, composition root.

**Dependency Rule**: Dependencies flow inward → Domain knows nothing about outer layers. **Domain must be technology-agnostic**: No references to specific frameworks, databases, or third-party libraries.

### DDD Essentials
- **Entities**: Objects with identity (ID). Enforce invariants.
- **Value Objects**: Immutable, equality by value. Validate inputs.
- **Aggregates**: Entity clusters modified through root only.
- **Repositories**: Domain interfaces, infrastructure implementations.
- **Domain Services/Events**: Stateless operations, notifications.

### CQRS Pattern
Separate read (queries) from write (commands) operations.

**When to use**: Different read/write performance, independent scaling, event-driven workflows.

**Implementation**:
1. Domain: Define command/query ports
2. Separate models: Commands enforce invariants, queries are denormalized
3. Application: Use cases with injected ports
4. Infrastructure: Implement ports with DB/messaging tech
5. Test-driven: Use `given_when_then` pattern

## Development Standards

### SOLID Principles
- **SRP**: One reason to change per type
- **OCP**: Extend via interfaces, not modification
- **DIP**: Depend on abstractions, not implementations

### Testing Strategy
**TDD-First**: Always write failing test first → Red → Green → Refactor

**Test Naming**: `given_when_then` pattern in snake_case
- Example: `given_empty_input_when_validating_then_return_error`

**Test Structure**:
```go
func Test_given_scenario_when_action_then_expected(t *testing.T) {
    // Given: setup
    // When: single action line
    // Then: assertions only
}
```

**SUT Naming**: System Under Test variable must be `sut`

**Test Types**:
- **Unit**: Domain/Application logic, no external dependencies
- **Integration**: Real infrastructure behind ports

**Avoiding Fragile Tests**:
- **No repeated assertions across tests**: Don't assert the same condition in multiple test methods. Each assertion should verify a unique aspect of behavior in a single test.
- **Test behavior, not implementation**: Focus on observable outcomes
- **Use stable test data**: Avoid hardcoded timestamps, IDs, or changing values
- **Test isolation**: Each test independent, no shared state
- **Clear failure messages**: Descriptive assertions that explain failures
- **File size limit (MANDATORY)**: Test files MUST NOT exceed 150 lines. Split into multiple files when limit is reached. This is non-negotiable.

### Code Quality
- **File limit**: ≤150 lines
- **Function limit**: ≤20 lines
- **Edge cases first**: Validate before happy path
- **No nil pointers**: Use Special Case pattern
- **Error handling**: Explicit `error` as last return, wrap with context

## Go Conventions

### Naming
- **Packages**: lowercase, single word
- **Files**: snake_case.go, snake_case_test.go
- **Functions**: CamelCase (exported), camelCase (private)
- **Structs**: PascalCase
- **Interfaces**: PascalCase describing behavior

### Error Handling
```go
// Always return error last
func DoSomething() (Result, error) {
    if err != nil {
        return Result{}, fmt.Errorf("operation failed: %w", err)
    }
    return result, nil
}
```

### Dependency Injection
```go
// Constructor pattern
func NewUseCase(dep1 Port1, dep2 Port2) *UseCase {
    return &UseCase{
        port1: dep1,
        port2: dep2,
    }
}
```

### File Organization
```
internal/
  domain/[module]/
    entity.go
    value_object.go
    repository.go
  application/[module]/
    usecases/use_case.go
    ports/port.go
    requests.go
  infrastructure/[module]/
    repository_impl.go
  interfaces/http/
    handler.go

tests/[module]/
  usecase_test.go
mocks/
  mock_repository.go
```

## Pointer Semantics

### Rules
- **Entities**: Use pointers (`*Entity`) - identity-based, mutable
- **Value Objects**: Use values (`ValueObject`) - immutable, copy semantics
- **Pointer receivers**: Only for methods that modify state
- **Value receivers**: Default for immutable types

### Examples
```go
// Value Object (immutable)
type Money struct {
    amount   int64
    currency string
}

func (m Money) Add(other Money) Money {
    return Money{amount: m.amount + other.amount, currency: m.currency}
}

// Entity (identity-based)
type Account struct {
    id      string
    balance Money
}

func NewAccount(id string) *Account {
    return &Account{id: id, balance: Money{amount: 0, currency: "USD"}}
}

func (a *Account) Deposit(amount Money) {
    a.balance = a.balance.Add(amount)
}
```

## CQRS Example

```go
// Domain ports
type SaveTelemetry interface {
    Execute(ctx context.Context, t *Telemetry) (ID, error)
}

type TelemetryQuery interface {
    GetByID(ctx context.Context, id ID) (*TelemetryDTO, error)
}

// Application use case
type SaveTelemetryUseCase struct {
    saver telemetry.SaveTelemetry
}

func (uc *SaveTelemetryUseCase) Execute(ctx context.Context, lat, lon, speed float64) (telemetry.ID, error) {
    id := telemetry.ID(uuid.NewString())
    tel, err := telemetry.NewTelemetry(id, lat, lon, speed)
    if err != nil {
        return "", err
    }
    return uc.saver.Execute(ctx, tel)
}
```

## Summary

Clean Architecture + DDD + CQRS provides:
- **Separation of concerns** across layers
- **Testability** through dependency inversion
- **Scalability** with read/write optimization
- **Maintainability** with clear boundaries

Key principles: TDD-first, small units, pure domain, explicit dependencies.
