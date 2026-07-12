---
rule_id: RULE-GO_CLEAN_ARCHITECTURE
trigger: always_on
description: Go Clean Architecture rules for DDD, CQRS, and YAGNI
globs: **/*.go
---

# Go Clean Architecture

## SDD Baseline

- Apply `common/rules/common-sdd-agentic-discipline.md` before this rule.
- Create or evolve the owning User Story based spec before production code when behavior, contracts, architecture, or risk changes.
- Apply mandatory Gate 1 before spec writes, Gate 2 before RED, and Gate 3 before Green, even for simple or low-risk changes.
- Keep artifact, task, track, and test IDs traceable through `traceability.yaml` and `parallel-tracks.md`.
- Write BDD Given/When/Then acceptance evidence first, then the unit-level ATDD-style focused failing test for the next rule or boundary before production code.
- Refactor only with tests green and converge spec history, tasks, parallel tracks, traceability, verification notes, and code.


Clean Architecture, DDD, CQRS, YAGNI, and Screaming Architecture for Go.

See `go-advanced-practices.md` for advanced Go techniques and the evidence required before introducing them.

## Layer Structure

**Dependency Rule**: Infrastructure → Application → Domain

**Domain**: Pure business logic, entities, value objects, and errors
**Application**: Use cases, DTOs, consumer-owned command/query/validation ports, and orchestration
**Infrastructure**: Adapters implementing ports (DB, APIs, messaging)
**Interface**: HTTP/gRPC handlers, composition root

## YAGNI Principle

**Core**: Create only what's needed now, delete unused code, focus on current use cases
**CQRS**: One port per use case, delete unused ports, minimal interfaces
**Apply**: When refactoring/adding features, prefer simplicity, no "just in case" code
**Advanced Patterns**: Strategy, decorators, worker pools, event outbox, streaming, functional options, and generics require current evidence, not speculation

## CQRS Pattern

**Use when**: Different read/write performance, independent scaling, event-driven, complex queries

**Structure**: `application/{use_case}/ports/{commands|queries|validation}/{action}_{entity}_{type}.go`

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

**Structure**: `internal/{domain}/domain/{entity}/{entity.go, value_objects/, errors.go}` and `internal/{domain}/application/{use_case}/ports/{commands|queries|validation}/`

**Rules**: One type per file (snake_case), folder structure communicates purpose

**Good**: `internal/membership/domain/member/` with separate files
**Bad**: `internal/domain/entities.go` mixing multiple entities

## Domain-Driven Design

**Entities**: Identity (ID), enforce invariants, mutable, one per file
**Value Objects**: Immutable, equality by value, validate in constructors, one per file
**Domain Errors**: Separate `errors.go`, sentinel errors, grouped by concept
**Domain Services**: Stateless, business logic, coordinate aggregates, emit events

**Structure**: `{entity}/{entity.go, value_objects/, errors.go}`; application ports live under `{use_case}/ports/{commands|queries|validation}/`

## DTO-Owned Boundary Mapping

DTOs own the functions that translate their external representation. Keep the functions in the DTO's file/package, not in a global mapper package.

```go
type ItemDBDTO struct {
    ID       string `dynamodbav:"id"`
    Quantity int    `dynamodbav:"quantity"`
}

func NewItemDBDTOFromDomain(item domain.Item) ItemDBDTO {
    return ItemDBDTO{ID: item.ID().String(), Quantity: item.Quantity().Value()}
}

func (dto ItemDBDTO) ToDomain() (domain.Item, error) {
    return domain.NewItem(dto.ID, dto.Quantity)
}
```

- Persistence DTOs own `FromDomain`/`ToDomain` schema translation.
- HTTP request/response DTOs own transport/application translation.
- Message DTOs own event/message translation.
- Mapping performs structural conversion and domain construction only; it does not perform I/O, authorization, logging, orchestration, or policy decisions.
- If a generated DTO cannot be edited, keep a companion mapping file beside it in the same infrastructure/interface package and document the generation constraint.

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
**YAGNI**: Do not create interfaces for private helpers or concrete code that does not cross a boundary

```go
// ✅ Small focused interfaces
type CreateOrderCommand interface { Execute(ctx context.Context, cmd CreateOrderRequest) (OrderID, error) }
type GetOrderByID interface { Execute(ctx context.Context, id OrderID) (*OrderDTO, error) }

// ❌ Large unfocused interface
type OrderRepository interface { Save(); FindByID(); ListByCustomer(); Delete(); UpdateStatus() }
```

## Decorator Pattern With Guardrails

Use a decorator when a current cross-cutting concern must wrap an existing use case or port without changing its business contract.

**Good triggers**:
- Metrics, tracing, auditing, idempotency, cache for reads, transaction boundaries, retries around external dependencies
- The concern applies to one or more current use cases or ports
- The inner contract stays unchanged

**Rules**:
- Keep business rules in the inner use case/domain, not in the decorator
- Keep infrastructure dependencies in the decorator or composition root, not in domain
- Return errors; do not log and return the same error from a decorator unless the decorator is the final boundary
- Wire decorators explicitly in DI/composition; do not create a generic pipeline framework
- Do not add decorators for future use

```go
type CreateOrderUseCase interface {
	Execute(ctx context.Context, request CreateOrderRequest) (*OrderDTO, error)
}

type CreateOrderMetricsDecorator struct {
	inner   CreateOrderUseCase
	metrics Metrics
}

func (d *CreateOrderMetricsDecorator) Execute(ctx context.Context, request CreateOrderRequest) (*OrderDTO, error) {
	done := d.metrics.Measure("create_order")
	defer done()

	return d.inner.Execute(ctx, request)
}
```

## DTO Pattern (DIP Compliance)

**Principle**: Interface layer DTOs with translation methods to convert between domain and interface representations

**Structure**:
- **Application Layer**: Pure domain DTOs (no infrastructure tags like `json`, `dynamodbav`)
- **Interface Layer**: Transport-specific DTOs with translation methods

```go
// ✅ Application layer - pure domain DTO
// internal/catalog/application/category_catalog_retriever/requests/get_categories_catalog_response.go
package requests

type CategoryDTO struct {
	CategoryID string
	Path       string
}

type GetCategoriesCatalogResponse struct {
	Categories []CategoryDTO
}

// ✅ Interface layer - transport DTO with translation methods
// internal/catalog/interfaces/http/handlers/category_dto.go
package handlers

type CategoryDTO struct {
	CategoryID string `json:"categoryID"`
	Path       string `json:"path"`
}

func (dto CategoryDTO) ToApplication() map[string]interface{} {
	return map[string]interface{}{
		"categoryID": dto.CategoryID,
		"path":       dto.Path,
	}
}

func CategoryDTOFromApplication(categoryID string, path string) CategoryDTO {
	return CategoryDTO{
		CategoryID: categoryID,
		Path:       path,
	}
}

// ✅ Handler uses translation method
appResponse, err := h.catalogRetriever.Execute(ctx, request)
categories := make([]CategoryDTO, len(appResponse.Categories))
for i, cat := range appResponse.Categories {
    categories[i] = CategoryDTOFromApplication(cat.CategoryID, cat.Path)
}
```

**Rules**:
- Application DTOs: No infrastructure tags, pure domain data
- Interface DTOs: Transport tags (`json`, `dynamodbav`), translation methods
- Translation: `FromApplication` and `ToApplication` methods in HTTP DTOs; `FromDomain` and `ToDomain` methods in persistence DTOs
- Separation: Interface layer depends on application, not vice versa

## File Organization

**Rules**: One type per file, single responsibility, snake_case.go, ≤150 lines
**Structure**: `{entity}/{entity.go, value_objects/, errors.go}` and `{use_case}/{usecase.go, requests.go, ports/}`

## Advanced Patterns with Guardrails

Use advanced patterns only when the project has a real need:

- **Strategy**: Use when there are multiple current algorithms or providers selected by policy.
- **Decorator**: Use when current cross-cutting behavior must wrap a use case or port while preserving its contract.
- **Worker pool**: Use when concurrency must be bounded and work volume justifies queueing.
- **`errgroup`**: Use for parallel I/O where failure should cancel sibling work.
- **Domain events/outbox**: Use when side effects must be reliable across transaction boundaries.
- **Streaming**: Use for large files, responses, messages, or imports where memory use matters.
- **Functional options**: Use for optional settings with stable defaults, not required dependencies.
- **Generics**: Use for type-safe reusable algorithms across current call sites, not repositories/use cases.

Before adding one of these patterns, document or encode the trigger in the code shape: current implementations, operational requirement, performance evidence, or a failing test that the simpler design cannot satisfy cleanly.

## Summary

**Principles**: YAGNI, single responsibility, dependency inversion, Clean Architecture, Screaming Architecture
**CQRS**: One interface per file, small interfaces, delete unused ports, consumer-focused
**Organization**: One type per file, clear naming, logical grouping, no unused code
**Apply**: always_on (new code/refactors), context (features/bugs), manual (small adjustments)

Ensures maintainable, testable, scalable Go applications following Clean Architecture, DDD, CQRS, YAGNI, and Screaming Architecture.
