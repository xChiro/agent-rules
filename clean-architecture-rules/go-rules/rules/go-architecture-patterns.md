---
trigger: always_on
description: Clean Architecture, DDD, CQRS, and Dependency Injection patterns
globs: ["**/*.go"]
---

# Go Architecture Patterns

Comprehensive guide for Clean Architecture, Domain-Driven Design, CQRS, and Dependency Injection in Go applications.

## Architecture Overview

### Layer Structure

**Dependency Rule**: Dependencies flow inward → Domain knows nothing about outer layers

#### Domain Layer (Core)
- **Purpose**: Pure business logic (entities, value objects)
- **Technology-agnostic**: No external dependencies, framework references, or infrastructure concerns
- **Independence**: Must remain completely independent of specific technologies
- **Contents**: Entities, value objects, domain services, events, repository interfaces

#### Application Layer
- **Purpose**: Use cases, ports/interfaces, orchestration
- **Responsibility**: Coordinates domain objects via interfaces
- **Contents**: Use cases, DTOs, application services, port definitions

#### Infrastructure Layer
- **Purpose**: Adapters implementing ports
- **Implementation**: Database, APIs, messaging, external services
- **Contents**: Repository implementations, external service clients

#### Interface Layer
- **Purpose**: HTTP/gRPC handlers, composition root
- **Responsibility**: Translate transport requests to application calls
- **Contents**: Handlers, middleware, server setup

## Domain-Driven Design (DDD)

### Core Concepts

#### Entities
- Objects with identity (ID)
- Enforce invariants through methods
- Mutable with lifecycle management
- Use pointers for identity-based objects

#### Value Objects
- Immutable, equality by value
- Validate inputs in constructors
- Use values (not pointers) for copy semantics
- No identity, only attributes

#### Repositories
- Domain interfaces for data access
- Defined in domain, implemented in infrastructure
- Return aggregates, not individual entities
- Handle persistence abstraction

#### Domain Services
- Stateless operations
- Business logic that doesn't fit in entities
- Coordinate between multiple aggregates
- Emit domain events

### DDD Implementation Example

```go
// Domain Entity
type Order struct {
    id     OrderID
    items  []OrderItem
    status OrderStatus
}

func NewOrder(id OrderID) *Order {
    return &Order{
        id:     id,
        status: StatusPending,
    }
}

func (o *Order) AddItem(product ProductID, quantity int) error {
    if quantity <= 0 {
        return errors.New("quantity must be positive")
    }
    o.items = append(o.items, OrderItem{
        ProductID: product,
        Quantity:  quantity,
    })
    return nil
}

// Domain Repository Interface
type OrderRepository interface {
    Save(ctx context.Context, order *Order) error
    FindByID(ctx context.Context, id OrderID) (*Order, error)
}

// Domain Service
type OrderPricingService struct {
    productRepo ProductRepository
}

func (s *OrderPricingService) CalculateTotal(order *Order) (Money, error) {
    var total Money
    for _, item := range order.items {
        product, err := s.productRepo.FindByID(item.ProductID)
        if err != nil {
            return Money{}, err
        }
        total = total.Add(product.Price.Multiply(item.Quantity))
    }
    return total, nil
}
```

## CQRS Pattern

### When to Use CQRS
- Different read/write performance requirements
- Independent scaling of reads and writes
- Event-driven workflows
- Complex query requirements

### Implementation Strategy

#### Command Side (Writes)
- Enforce business invariants
- Update aggregates
- Publish domain events
- Return simple results (ID, status)

#### Query Side (Reads)
- Denormalized data models
- Optimized for specific queries
- No business logic
- Return DTOs/projections

#### Port Separation
```go
// Command Port
type SaveOrder interface {
    Execute(ctx context.Context, cmd SaveOrderCommand) (OrderID, error)
}

// Query Port
type GetOrderQuery interface {
    FindByID(ctx context.Context, id OrderID) (*OrderDTO, error)
    ListByCustomer(ctx context.Context, customerID CustomerID) ([]OrderDTO, error)
}

// Command Model (Domain)
type SaveOrderCommand struct {
    CustomerID CustomerID
    Items      []OrderItemCommand
}

// Query Model (Read)
type OrderDTO struct {
    ID         string
    CustomerID string
    Status     string
    Total      float64
    Items      []OrderItemDTO
}
```

### CQRS Use Case Example

```go
// Command Use Case
type CreateOrderUseCase struct {
    orderRepo    OrderRepository
    eventBus     EventBus
    pricingSvc   OrderPricingService
}

func (uc *CreateOrderUseCase) Execute(ctx context.Context, cmd CreateOrderCommand) (OrderID, error) {
    // Create domain entity
    order := NewOrder(OrderID(uuid.New()))
    
    // Add items
    for _, item := range cmd.Items {
        if err := order.AddItem(item.ProductID, item.Quantity); err != nil {
            return "", err
        }
    }
    
    // Calculate total
    total, err := uc.pricingSvc.CalculateTotal(order)
    if err != nil {
        return "", err
    }
    
    // Persist
    if err := uc.orderRepo.Save(ctx, order); err != nil {
        return "", err
    }
    
    // Publish event
    uc.eventBus.Publish(OrderCreated{OrderID: order.ID()})
    
    return order.ID(), nil
}

// Query Use Case
type GetOrderUseCase struct {
    orderQuery GetOrderQuery
}

func (uc *GetOrderUseCase) Execute(ctx context.Context, id OrderID) (*OrderDTO, error) {
    return uc.orderQuery.FindByID(ctx, id)
}
```

## Dependency Injection (DI)

### Core Principles

#### Manual Wiring
- Prefer explicit construction over reflection
- Use constructor functions for clarity
- Keep dependency graph visible
- Avoid heavy DI frameworks

#### Dependency Inversion
- Depend on abstractions, not concrete types
- Define interfaces near consumers
- Implement interfaces in infrastructure
- Keep interfaces small and focused

#### Setup Functions
- Pure construction, no side effects
- Return errors, don't panic
- Keep under 150 lines per file
- Use clear naming conventions

### Layer Setup Pattern

```go
// Domain Setup
func SetupDomain(
    orderRepo OrderRepository,
    productRepo ProductRepository,
    eventBus EventBus,
) *Domain {
    pricingSvc := NewOrderPricingService(productRepo)
    return &Domain{
        OrderService:   NewOrderService(orderRepo, eventBus, pricingSvc),
        ProductService:  NewProductService(productRepo),
    }
}

// Infrastructure Setup
func SetupInfrastructure(cfg Config) (*Infrastructure, error) {
    db, err := sql.Open("postgres", cfg.DatabaseURL)
    if err != nil {
        return nil, fmt.Errorf("database connection: %w", err)
    }
    
    orderRepo := NewSQLOrderRepository(db)
    productRepo := NewSQLProductRepository(db)
    eventBus := NewRedisEventBus(cfg.RedisURL)
    
    return &Infrastructure{
        OrderRepository:   orderRepo,
        ProductRepository:  productRepo,
        EventBus:         eventBus,
    }, nil
}

// Application Setup
func SetupApplication(cfg Config) (*Application, error) {
    infra, err := SetupInfrastructure(cfg)
    if err != nil {
        return nil, err
    }
    
    domain := SetupDomain(
        infra.OrderRepository,
        infra.ProductRepository,
        infra.EventBus,
    )
    
    return &Application{
        CreateOrder: NewCreateOrderUseCase(domain.OrderService),
        GetOrder:    NewGetOrderUseCase(infra.OrderQuery),
    }, nil
}
```

### Interface Design Guidelines

#### Small Interfaces
- Focus on single responsibility
- Consumer should need only methods it uses
- Avoid "god interfaces"

#### Interface Location
- Define in domain or application layer
- Implement in infrastructure
- Keep close to consumer

#### Example Interfaces
```go
// Good: Small, focused interface
type OrderSaver interface {
    Save(ctx context.Context, order *Order) error
}

// Bad: Large, unfocused interface
type OrderRepository interface {
    Save(ctx context.Context, order *Order) error
    FindByID(ctx context.Context, id OrderID) (*Order, error)
    ListByCustomer(ctx context.Context, id CustomerID) ([]*Order, error)
    Delete(ctx context.Context, id OrderID) error
    UpdateStatus(ctx context.Context, id OrderID, status OrderStatus) error
}
```

## Configuration Management

### Configuration Structure
```go
type Config struct {
    Database DatabaseConfig
    Redis    RedisConfig
    HTTP     HTTPConfig
}

type DatabaseConfig struct {
    URL             string
    MaxConnections  int
    ConnectionTimeout time.Duration
}

func LoadConfig() (*Config, error) {
    cfg := &Config{
        Database: DatabaseConfig{
            URL:            os.Getenv("DATABASE_URL"),
            MaxConnections: 10,
            ConnectionTimeout: 5 * time.Second,
        },
        // ... other config
    }
    
    if err := cfg.Validate(); err != nil {
        return nil, err
    }
    
    return cfg, nil
}
```

### Configuration Rules
- Centralize loading in main package
- Use environment variables or config files
- Validate configuration at startup
- Pass configuration to setup functions
- Don't read environment variables deep in packages

## Error Flow in Architecture

### Error Mapping
```
Infrastructure Layer
    ↓ (map to domain errors)
Repository Layer
    ↓ (wrap with context)
Domain Layer
    ↓ (preserve domain errors)
Application Layer
    ↓ (map to HTTP status codes)
Interface Layer
```

### Error Translation
```go
// Infrastructure → Domain
func (r *sqlOrderRepo) Save(ctx context.Context, order *Order) error {
    if err := r.db.Save(order); err != nil {
        if errors.Is(err, sql.ErrNoRows) {
            return domain.ErrOrderNotFound
        }
        return fmt.Errorf("save order: %w", err)
    }
    return nil
}

// Application → Interface
func (h *OrderHandler) CreateOrder(w http.ResponseWriter, r *http.Request) {
    order, err := h.createOrderUC.Execute(ctx, cmd)
    if err != nil {
        switch {
        case errors.Is(err, domain.ErrInvalidOrder):
            http.Error(w, err.Error(), http.StatusBadRequest)
        case errors.Is(err, domain.ErrOrderNotFound):
            http.Error(w, err.Error(), http.StatusNotFound)
        default:
            http.Error(w, "internal error", http.StatusInternalServerError)
        }
        return
    }
    // ... success response
}
```

## Testing Architecture

### Unit Tests
- Test domain logic in isolation
- Mock external dependencies
- Focus on business rules
- Fast and deterministic

### Integration Tests
- Test real infrastructure
- Verify layer interactions
- Use test databases/queues
- Focus on happy path

### Test Organization
```
tests/
  units/
    domain/
      entity_test.go
    application/
      usecase_test.go
  integration/
    infrastructure/
      repository_test.go
  mocks/
    mock_repository.go
```

## Best Practices Summary

### Architecture Rules
- Dependencies flow inward only
- Domain stays pure and technology-agnostic
- Use ports and adapters pattern
- Separate command and query responsibilities

### DI Guidelines
- Manual wiring preferred
- Constructor injection pattern
- Small, focused interfaces
- Pure setup functions

### DDD Principles
- Ubiquitous language in code
- Rich domain models
- Aggregate consistency boundaries
- Domain events for integration

This architecture ensures maintainable, testable, and scalable Go applications that follow industry best practices.