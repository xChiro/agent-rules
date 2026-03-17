---
trigger: always_on
description: 
globs: 
---

# Go Architecture Patterns

Clean Architecture, DDD, CQRS, YAGNI, and Screaming Architecture for Go.

## Layer Structure

**Dependency Rule**: Infrastructure → Application → Domain

**Domain**: Pure business logic, entities, value objects, errors, port interfaces
**Application**: Use cases, DTOs, orchestration via interfaces
**Infrastructure**: Adapters implementing ports (DB, APIs, messaging)
**Interface**: HTTP/gRPC handlers, composition root

## YAGNI Principle

**Core**: Create only what's needed now, delete unused code, focus on current use cases
**CQRS**: One port per use case, delete unused ports, minimal interfaces
**Apply**: When refactoring/adding features, prefer simplicity, no "just in case" code

## CQRS Pattern

**Use when**: Different read/write performance, independent scaling, event-driven, complex queries

**Structure**: `ports/{commands|queries|validation}/{action}_{entity}_{type}.go`

**Naming**:
- Commands: `{Action}{Entity}Command` → `CreateMemberCommand`
- Queries: `{Get/List/Search}{Entity}By{Criteria}` → `GetMemberByID`
- Validation: `Validate{Entity}{Property}Uniqueness`
- Files: `snake_case.go`

**YAGNI Ports**:
```go
// ❌ Generic repository with unused methods
type MemberRepository interface { Save(); FindByID(); FindByHandlerName(); ListByStatus(); Delete(); UpdateStatus() }

// ✅ Specific ports for actual use
type CreateMemberCommand interface { Execute(ctx context.Context, member Member) error }
type GetMemberByHandlerName interface { Execute(ctx context.Context, name HandlerName) (*Member, error) }
type ValidateHandlerNameUniqueness interface { Execute(ctx context.Context, name HandlerName) (bool, error) }
```

## Screaming Architecture

**Principle**: Directory structure communicates business purpose

**Structure**: `internal/{domain}/domain/{entity}/{entity.go, value_objects/, errors.go, ports/}`

**Rules**: One type per file (snake_case), folder structure communicates purpose

**Good**: `internal/membership/domain/member/` with separate files
**Bad**: `internal/domain/entities.go` mixing multiple entities

## Domain-Driven Design

**Entities**: Identity (ID), enforce invariants, mutable, one per file
**Value Objects**: Immutable, equality by value, validate in constructors, one per file
**Domain Errors**: Separate `errors.go`, sentinel errors, grouped by concept
**Domain Services**: Stateless, business logic, coordinate aggregates, emit events

**Structure**: `{entity}/{entity.go, value_objects/, errors.go, ports/{commands|queries|validation}/}`

## Dependency Injection

**Principles**: Manual wiring, depend on abstractions, define interfaces near consumers, small focused interfaces
**Setup**: Pure construction, return errors, ≤150 lines, clear naming

```go
func NewEnrollMemberUseCase(
    createCmd commands.CreateMemberCommand,
    validateName validation.ValidateHandlerNameUniqueness,
) *EnrollMemberUseCase {
    return &EnrollMemberUseCase{createCmd: createCmd, validateName: validateName}
}
```

## Configuration

```go
type Config struct { Database DatabaseConfig; Redis RedisConfig; HTTP HTTPConfig }
func LoadConfig() (*Config, error) { /* load from env, validate, return */ }
```

**Rules**: Centralize in main, use env vars/files, validate at startup, pass to setup functions

## Error Flow

**Mapping**: Domain → Application → Interface
**Types**: Domain (business rules), Application (use case failures), Infrastructure (technical), Interface (transport)

```go
// Domain: var ErrInvalidQuantity = errors.New("quantity must be positive")
// Application: return "", fmt.Errorf("failed to create: %w", err)
// Interface: http.Error(w, "invalid request", http.StatusBadRequest)
```

## Interface Design

**Guidelines**: One per file, single method, consumer-focused, no god interfaces
**Location**: Define in application (near consumer), implement in infrastructure
**Group**: commands/queries/validation

```go
// ✅ Small focused interfaces
type CreateOrderCommand interface { Execute(ctx context.Context, cmd CreateOrderRequest) (OrderID, error) }
type GetOrderByID interface { Execute(ctx context.Context, id OrderID) (*OrderDTO, error) }

// ❌ Large unfocused interface
type OrderRepository interface { Save(); FindByID(); ListByCustomer(); Delete(); UpdateStatus() }
```

## File Organization

**Rules**: One type per file, single responsibility, snake_case.go, ≤150 lines
**Structure**: `{entity}/{entity.go, value_objects/, errors.go, ports/}` and `{use_case}/{usecase.go, requests.go, ports/}`

## Summary

**Principles**: YAGNI, single responsibility, dependency inversion, Clean Architecture, Screaming Architecture
**CQRS**: One interface per file, small interfaces, delete unused ports, consumer-focused
**Organization**: One type per file, clear naming, logical grouping, no unused code
**Apply**: always_on (new code/refactors), context (features/bugs), manual (small adjustments)

Ensures maintainable, testable, scalable Go applications following Clean Architecture, DDD, CQRS, YAGNI, and Screaming Architecture.