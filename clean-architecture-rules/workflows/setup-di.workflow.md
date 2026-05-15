---
description: Setup dependency injection using Wire following Clean Architecture and CQRS
---

# Dependency Injection Setup Workflow (Wire)

Create Wire-based dependency injection following Clean Architecture, CQRS, and Wire patterns (see `go-dependency-injection.md`).

## Phase 1: Analysis

**Identify**:
- Target layer (Domain, Application, Infrastructure, Interface)
- Dependencies (CQRS interfaces and implementations)
- Configuration (env vars, connection strings)
- File size (≤150 lines)

## Phase 2: Wire Setup Pattern

```go
//go:build wireinject
// +build wireinject

package di

import (
    "github.com/google/wire"
    "yourproject/internal/config"
)

// Provider functions (in providers.go)
func ProvideDatabase(cfg config.Config) (*sql.DB, error) {
    db, err := sql.Open("postgres", cfg.DatabaseURL)
    if err != nil { return nil, fmt.Errorf("failed to open database: %w", err) }
    if err := db.Ping(); err != nil { return nil, fmt.Errorf("failed to ping: %w", err) }
    db.SetMaxOpenConns(25)
    db.SetMaxIdleConns(5)
    return db, nil
}

// Wire injector (in wire.go)
var InfrastructureProviderSet = wire.NewSet(
    ProvideDatabase,
    ProvideCache,
    wire.Struct(new(Infrastructure), "*"),
)

var ApplicationProviderSet = wire.NewSet(
    NewCreateUseCase,
    NewGetUseCase,
)

func InitializeApplication(cfg config.Config) (*Application, error) {
    wire.Build(
        wire.Value(cfg),
        InfrastructureProviderSet,
        ApplicationProviderSet,
    )
    return nil, nil
}
```

## Phase 3: Infrastructure Providers

```go
// providers.go
func ProvideDatabase(cfg config.Config) (*sql.DB, error) {
    db, err := sql.Open("postgres", cfg.DatabaseURL)
    if err != nil { return nil, fmt.Errorf("failed to open database: %w", err) }
    if err := db.Ping(); err != nil { return nil, fmt.Errorf("failed to ping: %w", err) }
    db.SetMaxOpenConns(25)
    db.SetMaxIdleConns(5)
    return db, nil
}

func ProvideCache(cfg config.Config) (*redis.Client, error) {
    client := redis.NewClient(&redis.Options{Addr: cfg.RedisURL})
    if err := client.Ping(context.Background()).Err(); err != nil {
        return nil, fmt.Errorf("failed to ping cache: %w", err)
    }
    return client, nil
}

func ProvideCreateCommand(db *sql.DB) CreateOrderCommand {
    return NewSQLCreateCommand(db)
}

func ProvideGetQuery(db *sql.DB) GetOrderByID {
    return NewSQLGetQuery(db)
}

// wire.go
var InfrastructureProviderSet = wire.NewSet(
    ProvideDatabase,
    ProvideCache,
    ProvideCreateCommand,
    ProvideGetQuery,
    wire.Struct(new(Infrastructure), "*"),
)
```

## Phase 4: Domain Providers

```go
// providers.go
func ProvidePricingService() *PricingService {
    return NewPricingService()
}

func ProvideValidationService() *ValidationService {
    return NewValidationService()
}

// wire.go
var DomainProviderSet = wire.NewSet(
    ProvidePricingService,
    ProvideValidationService,
    wire.Struct(new(Domain), "*"),
)
```

## Phase 5: Application Providers (CQRS)

```go
// providers.go
func NewCreateUseCase(
    createCmd CreateOrderCommand,
    validateCmd ValidateOrderUniqueness,
) *CreateUseCase {
    return &CreateUseCase{createCmd: createCmd, validateCmd: validateCmd}
}

func NewGetUseCase(getQuery GetOrderByID) *GetUseCase {
    return &GetUseCase{getQuery: getQuery}
}

// wire.go
var ApplicationProviderSet = wire.NewSet(
    NewCreateUseCase,
    NewGetUseCase,
    wire.Struct(new(Application), "*"),
)
```

## Phase 6: Interface Providers

```go
// providers.go
func NewHTTPHandler(createUC *CreateUseCase, getUC *GetUseCase) *Handler {
    return &Handler{createUC: createUC, getUC: getUC}
}

func SetupHTTPServer(handler *Handler, cfg config.Config) *HTTPServer {
    mux := http.NewServeMux()
    mux.HandleFunc("/resource", handler.Handle)
    
    return &HTTPServer{
        Server: &http.Server{Addr: fmt.Sprintf(":%d", cfg.APIPort), Handler: mux},
    }
}

// wire.go
var InterfaceProviderSet = wire.NewSet(
    NewHTTPHandler,
    SetupHTTPServer,
)
```

## Phase 7: Wire Injector

```go
// wire.go
func InitializeApplication(cfg config.Config) (*Application, error) {
    wire.Build(
        wire.Value(cfg),
        InfrastructureProviderSet,
        DomainProviderSet,
        ApplicationProviderSet,
    )
    return nil, nil
}

func InitializeServer(cfg config.Config) (*HTTPServer, error) {
    wire.Build(
        wire.Value(cfg),
        InfrastructureProviderSet,
        DomainProviderSet,
        ApplicationProviderSet,
        InterfaceProviderSet,
    )
    return nil, nil
}
```

## Phase 8: Main Function

```go
func main() {
    cfg, err := config.LoadConfig()
    if err != nil { log.Fatalf("config: %v", err) }
    
    // Wire-generated function
    server, err := di.InitializeServer(cfg)
    if err != nil { log.Fatalf("setup: %v", err) }
    
    log.Printf("Starting server on port %d", cfg.APIPort)
    if err := server.Server.ListenAndServe(); err != nil {
        log.Fatalf("server: %v", err)
    }
}
```

## File Organization

```
internal/
├── config/config.go
├── di/
│   ├── wire.go          // Wire injector (build tag: wireinject)
│   ├── wire_gen.go      // Generated by Wire (do not edit)
│   └── providers.go     // Provider functions
cmd/api/main.go
```

## Phase 9: Wire Generation

```bash
# Generate wire_gen.go
wire gen ./internal/di

# Or with specific output
wire gen ./internal/di/...
```

## Principles

**Wire DI**: Compile-time dependency injection via code generation, provider functions, no runtime reflection
**CQRS**: One interface per file, define in application, implement in infrastructure
**Configuration**: Env vars, validate at startup, centralized loading, type-safe structs
**Lifetime**: Singletons (DB pools, servers), request-scoped (transactions), explicit cleanup via providers

## Wire Best Practices

**Provider Functions**:
- Naming: `Provide{Type}` or `New{Type}` (for constructors)
- Return single value or (value, error)
- Keep simple, ≤20 lines
- One responsibility per provider

**Provider Sets**:
- Group related providers by layer (Infrastructure, Domain, Application, Interface)
- Use `wire.NewSet()` to create sets
- Nest sets for composition

**Wire Build**:
- Use `wire.Value()` for constant values (config, primitives)
- Use `wire.Struct()` for struct field binding
- Use `wire.Interface()` for interface binding
- Wire auto-detects dependencies from function signatures

## Testing with Wire

```go
// Test providers (in providers_test.go)
func TestProvideDatabase(t *testing.T) {
    cfg := config.Config{DatabaseURL: "test://db"}
    db, err := ProvideDatabase(cfg)
    assert.NoError(t, err)
    assert.NotNil(t, db)
    db.Close()
}

// Manual test setup (Wire not used for tests)
func SetupTestInfrastructure(t *testing.T) *Infrastructure {
    db := setupTestDB(t)
    return &Infrastructure{
        CreateCommand: NewMockCreateCommand(),
        GetQuery:      NewMockGetQuery(),
        Database:      db,
    }
}

func Test_wire_injects_dependencies(t *testing.T) {
    cfg := config.Config{DatabaseURL: ":memory:"}
    app, err := InitializeApplication(cfg)
    assert.NoError(t, err)
    assert.NotNil(t, app)
}
```

## Success Criteria

- ✅ All dependencies explicit (no hidden deps)
- ✅ Configuration validated (fail fast)
- ✅ No side effects in providers (pure construction)
- ✅ CQRS interfaces (small, focused, one per file)
- ✅ Files ≤150 lines
- ✅ Wire generation succeeds
- ✅ Easy to inject mocks (manual test setup)

**CQRS Pattern with Wire**:
```go
// Define in application (one per file)
type CreateCommand interface { Execute(ctx context.Context, data Data) error }
type GetQuery interface { Execute(ctx context.Context, id string) (*Data, error) }

// Implement in infrastructure
type SQLRepository struct { db *sql.DB }
func NewSQLCreateCommand(db *sql.DB) CreateCommand { return &SQLRepository{db: db} }

// Provider (in providers.go)
func ProvideCreateCommand(db *sql.DB) CreateCommand {
    return NewSQLCreateCommand(db)
}

// Wire set (in wire.go)
var InfrastructureProviderSet = wire.NewSet(
    ProvideDatabase,
    ProvideCreateCommand,
)
```
