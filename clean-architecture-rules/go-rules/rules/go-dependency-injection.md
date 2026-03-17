---
trigger: always_on
description: 
globs: 
---

# Go Dependency Injection Guidelines

**Principles**: Separation of concerns, explicit dependencies via constructors, testability with interfaces, minimal side-effects, YAGNI

## Layer Structure

Each layer exposes `Setup` function taking dependencies and returning constructed objects.

```go
// Domain
func SetupDomain(orderRepo OrderRepository, bus EventBus) *Domain {
    return &Domain{OrderService: NewOrderService(orderRepo, bus)}
}

// Infrastructure
func SetupInfrastructure(cfg Config) (*Infrastructure, error) {
    db, err := sql.Open("postgres", cfg.DatabaseURL)
    if err != nil { return nil, fmt.Errorf("database connection: %w", err) }
    return &Infrastructure{OrderRepository: NewSQLOrderRepository(db), EventBus: NewRedisEventBus(cfg.RedisURL)}, nil
}

// Application
func SetupApplication(cfg Config) (*Application, error) {
    infra, err := SetupInfrastructure(cfg)
    if err != nil { return nil, err }
    domain := SetupDomain(infra.OrderRepository, infra.EventBus)
    return &Application{CreateOrder: NewCreateOrderUseCase(domain.OrderService)}, nil
}
```

## Setup Guidelines

**Pattern**: `func SetupX(args ...) (*X, error)`
**Rules**: Validate config, return descriptive errors, no side effects, ≤150 lines, `Setup<Layer>` naming

## Interface Design (CQRS)

**Guidelines**: Single responsibility, one per file, consumer-focused, no god interfaces
**Location**: Define in domain/application (near consumer), implement in infrastructure
**Naming**: Commands (`CreateOrderCommand`), Queries (`GetOrderByID`), Validation (`ValidateOrderUniqueness`)
**Files**: `snake_case.go`

```go
// ✅ Small focused interfaces
type CreateOrderCommand interface { Execute(ctx context.Context, cmd CreateOrderRequest) (OrderID, error) }
type GetOrderByID interface { Execute(ctx context.Context, id OrderID) (*OrderDTO, error) }

// ❌ Large unfocused interface
type OrderRepository interface { Save(); FindByID(); ListByCustomer(); Delete(); UpdateStatus() }
```

## Constructor Pattern

```go
func NewCreateOrderUseCase(createCmd CreateOrderCommand, validateCmd ValidateOrderUniqueness, eventBus EventBus) *CreateOrderUseCase {
    return &CreateOrderUseCase{createCmd: createCmd, validateCmd: validateCmd, eventBus: eventBus}
}

func NewGetOrderUseCase(getQuery GetOrderByID) *GetOrderUseCase {
    return &GetOrderUseCase{getQuery: getQuery}
}
```

## YAGNI in DI

**Philosophy**: Only inject what's used, delete unused dependencies, simple constructors, avoid over-engineering

```go
// ❌ Unused dependencies
func NewOrderService(repo OrderRepository, eventBus EventBus, notificationService NotificationService, auditLogger AuditLogger) *OrderService {
    return &OrderService{repo: repo, eventBus: eventBus} // Others unused
}

// ✅ Only what's used
func NewOrderService(repo OrderRepository, eventBus EventBus) *OrderService {
    return &OrderService{repo: repo, eventBus: eventBus}
}
```

## Configuration

```go
type Config struct { Database DatabaseConfig; Redis RedisConfig; HTTP HTTPConfig }
type DatabaseConfig struct { URL string; MaxConnections int; ConnectionTimeout time.Duration }

func LoadConfig() (*Config, error) {
    cfg := &Config{Database: DatabaseConfig{URL: os.Getenv("DATABASE_URL"), MaxConnections: 10, ConnectionTimeout: 5 * time.Second}}
    if err := cfg.Validate(); err != nil { return nil, err }
    return cfg, nil
}
```

**Rules**: Centralize in main, use env vars/files, validate at startup, pass to setup functions

## Lifetime Management

**Types**: Singletons (connections, servers), Request-scoped (transactions), avoid globals
**YAGNI**: Simple lifetimes, explicit creation, avoid containers, manual DI

## Composition Root

```go
func main() {
    cfg, err := LoadConfig()
    if err != nil { log.Fatalf("failed to load config: %v", err) }
    
    app, err := SetupApplication(cfg)
    if err != nil { log.Fatalf("failed to setup application: %v", err) }
    
    server := SetupServer(app)
    log.Printf("Starting server on port %d", cfg.HTTPPort)
    if err := server.ListenAndServe(); err != nil { log.Fatalf("server failed: %v", err) }
}
```

## Testing with DI

**Mock Guidelines**: One per interface, mock only outgoing ports, manual mocks with exported fields, verification capabilities
**Structure**: `tests/{use_case}/mocks/mock_{interface}.go`

```go
type MockCreateOrderCommand struct {
    Error error
    Calls []CreateOrderCall
}

func (m *MockCreateOrderCommand) Execute(ctx context.Context, order Order) error {
    m.Calls = append(m.Calls, CreateOrderCall{Order: order})
    return m.Error
}

// Test
func TestCreateOrderUseCase(t *testing.T) {
    createCmd := &MockCreateOrderCommand{}
    validateCmd := &MockValidateOrderUniqueness{}
    useCase := NewCreateOrderUseCase(createCmd, validateCmd)
    result, err := useCase.Execute(ctx, request)
    assert.NoError(t, err)
    assert.Len(t, createCmd.Calls, 1)
}
```

## YAGNI Testing

**Philosophy**: Test current functionality, simple mocks, delete unused tests, focus on behavior

```go
// ❌ Over-engineered
type MockOrderService struct { mu sync.RWMutex; calls map[string][]interface{}; config MockConfig; hooks []MockHook }

// ✅ Simple
type MockOrderService struct { Error error; Calls []CreateOrderCall }
func (m *MockOrderService) CreateOrder(ctx context.Context, order Order) error {
    m.Calls = append(m.Calls, CreateOrderCall{Order: order})
    return m.Error
}
```

## Summary

**Test Design**: TDD (failing test first), test behavior not implementation, descriptive names (ATDD), simple tests
**CQRS DI**: One interface per file, implement in infrastructure, setup functions (pure construction), explicit wiring, manual mocks
**YAGNI DI**: Simple constructors, delete unused dependencies, avoid frameworks, focus on current needs
**Lifetime**: Singletons (shared resources), request-scoped (per-request), avoid globals, simple lifetimes
**Principles**: CQRS interfaces, infrastructure implements, setup functions (no side effects), explicit wiring, YAGNI compliance

Ensures maintainable, testable, scalable Go applications following Clean Architecture, CQRS, and YAGNI.
