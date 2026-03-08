---
trigger: always_on
description: Dependency Injection guidelines for Go applications
globs: ["**/*.go"]
---

# Dependency Injection (DI) Guidelines

Guidelines for structuring dependencies in Go projects using manual injection for modular, testable systems.

## Core Principles

- **Separation of concerns**: Each layer manages its own dependencies
- **Explicit dependencies**: Pass collaborators via constructors, not global lookups
- **Testability**: Use interfaces to enable test doubles
- **Minimal side-effects**: Setup functions should only construct objects

## Layer Structure

Each layer exposes a `Setup` function that takes dependencies and returns constructed objects.

### Domain Layer
```go
func SetupDomain(repo OrderRepository, bus EventBus) *Domain {
    return &Domain{
        OrderService: NewOrderService(repo, bus),
    }
}
```

### Infrastructure Layer
```go
func SetupDataAccess(cfg Config) (*DataAccess, error) {
    db, err := sql.Open("postgres", cfg.DatabaseURL)
    if err != nil {
        return nil, fmt.Errorf("database connection: %w", err)
    }
    
    return &DataAccess{
        OrderRepo: NewSQLOrderRepository(db),
    }, nil
}
```

### Application Layer
```go
func SetupApplication(cfg Config) (*Application, error) {
    dataAccess, err := SetupDataAccess(cfg)
    if err != nil {
        return nil, err
    }
    
    domain := SetupDomain(dataAccess.OrderRepo, dataAccess.EventBus)
    
    return &Application{Domain: domain}, nil
}
```

### Interface Layer
```go
func SetupServer(app *Application) *http.Server {
    mux := http.NewServeMux()
    handler := NewOrderHandler(app.Domain.OrderService)
    mux.HandleFunc("/orders", handler.Create)
    
    return &http.Server{
        Addr:    ":8080",
        Handler: mux,
    }
}
```

## Setup Function Guidelines

- **Pattern**: `func SetupX(args ...) (*X, error)`
- **Validation**: Check required config values, return descriptive errors
- **No side effects**: Don't start goroutines or block in setup
- **File size**: Keep under 150 lines
- **Naming**: Use `Setup<Layer>` pattern, camelCase variables

## Interface Design

- Keep interfaces small and focused
- Consumer should depend only on methods it needs
- Define interfaces in domain/application layer
- Implement in infrastructure layer

```go
// Interface in application
type OrderRepository interface {
    Save(ctx context.Context, order Order) error
    FindByID(ctx context.Context, id string) (*Order, error)
}

// Implementation in infrastructure
func NewSQLOrderRepository(db *sql.DB) OrderRepository {
    return &sqlOrderRepository{db: db}
}
```

## Configuration Management

```go
type Config struct {
    DatabaseURL string
    RedisURL    string
    HTTPPort    int
}

func LoadConfig() (*Config, error) {
    cfg := &Config{
        DatabaseURL: os.Getenv("DATABASE_URL"),
        RedisURL:    os.Getenv("REDIS_URL"),
        HTTPPort:    8080,
    }
    
    if err := cfg.Validate(); err != nil {
        return nil, err
    }
    
    return cfg, nil
}
```

## Testing with DI

### Mock Guidelines
1. Mock only outgoing ports (repositories, external APIs)
2. Don't mock domain logic
3. Implement manual mocks with exported fields
4. Place mocks in test packages
5. Inject via setup functions

### Mock Example
```go
type OrderRepositoryMock struct {
    SavedOrders []Order
    Error       error
}

func (m *OrderRepositoryMock) Save(ctx context.Context, order Order) error {
    m.SavedOrders = append(m.SavedOrders, order)
    return m.Error
}

func (m *OrderRepositoryMock) FindByID(ctx context.Context, id string) (*Order, error) {
    return &Order{}, nil
}
```

### Test Setup
```go
func TestOrderService(t *testing.T) {
    // Arrange
    mockRepo := &OrderRepositoryMock{}
    domain := SetupDomain(mockRepo, &EventBusMock{})
    
    // Act
    order := fixtures.NewTestOrder()
    err := domain.OrderService.CreateOrder(context.Background(), order)
    
    // Assert
    assertNoError(t, err)
    assertEqual(t, len(mockRepo.SavedOrders), 1)
}
```

## Lifetime Management

- **Singletons**: Create once at startup (connections, servers)
- **Request-scoped**: Pass context, create per request (transactions)
- **Avoid globals**: Keep dependencies explicit

## Composition Root

```go
func main() {
    cfg, err := LoadConfig()
    if err != nil {
        log.Fatalf("failed to load config: %v", err)
    }
    
    app, err := SetupApplication(cfg)
    if err != nil {
        log.Fatalf("failed to setup application: %v", err)
    }
    
    server := SetupServer(app)
    log.Printf("Starting server on port %d", cfg.HTTPPort)
    
    if err := server.ListenAndServe(); err != nil {
        log.Fatalf("server failed: %v", err)
    }
}
```

## Best Practices Summary

1. Define interfaces in domain/application layer
2. Implement in infrastructure packages
3. Provide Setup functions per layer
4. Wire explicitly in entrypoint
5. Avoid side effects in setup
6. Keep files under 150 lines
7. Use manual mocks for testing
