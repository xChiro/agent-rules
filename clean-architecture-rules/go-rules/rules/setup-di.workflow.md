---
description: Setup dependency injection following Clean Architecture and CQRS
---

# Dependency Injection Setup Workflow

Create DI setup functions following Clean Architecture, CQRS, and manual DI (see `go-dependency-injection.md`).

## Phase 1: Analysis

**Identify**:
- Target layer (Domain, Application, Infrastructure, Interface)
- Dependencies (CQRS interfaces and implementations)
- Configuration (env vars, connection strings)
- File size (≤150 lines)

## Phase 2: Setup Pattern

```go
// Pattern: func Setup[Layer](config Config, deps ...) (*[Layer], error)

type Config struct {
    DatabaseURL string
    RedisURL    string
    APIPort     int
}

func LoadConfig() (*Config, error) {
    cfg := &Config{
        DatabaseURL: os.Getenv("DATABASE_URL"),
        RedisURL:    os.Getenv("REDIS_URL"),
        APIPort:     8080,
    }
    if err := cfg.validate(); err != nil { return nil, err }
    return cfg, nil
}
```

## Phase 3: Infrastructure Setup

```go
func SetupDatabase(cfg Config) (*sql.DB, error) {
    db, err := sql.Open("postgres", cfg.DatabaseURL)
    if err != nil { return nil, fmt.Errorf("failed to open database: %w", err) }
    if err := db.Ping(); err != nil { return nil, fmt.Errorf("failed to ping: %w", err) }
    db.SetMaxOpenConns(25)
    db.SetMaxIdleConns(5)
    return db, nil
}

func SetupInfrastructure(cfg Config) (*Infrastructure, error) {
    db, err := SetupDatabase(cfg)
    if err != nil { return nil, err }
    
    cache, err := SetupCache(cfg)
    if err != nil { return nil, err }
    
    // Create CQRS implementations
    createCmd := NewSQLCreateCommand(db)
    getQuery := NewSQLGetQuery(db)
    
    return &Infrastructure{
        CreateCommand: createCmd,
        GetQuery:      getQuery,
        Database:      db,
        Cache:         cache,
    }, nil
}
```

## Phase 4: Domain Setup

```go
func SetupDomain(infra *Infrastructure) (*Domain, error) {
    // Domain services (pure business logic)
    pricingSvc := NewPricingService()
    validationSvc := NewValidationService()
    
    return &Domain{
        PricingService:    pricingSvc,
        ValidationService: validationSvc,
    }, nil
}
```

## Phase 5: Application Setup (CQRS)

```go
func SetupApplication(domain *Domain, infra *Infrastructure) (*Application, error) {
    // Use cases with CQRS dependencies
    createUC := NewCreateUseCase(
        infra.CreateCommand,
        infra.ValidateUniqueness,
    )
    getUC := NewGetUseCase(infra.GetQuery)
    
    return &Application{
        CreateUC: createUC,
        GetUC:    getUC,
    }, nil
}
```

## Phase 6: Interface Setup

```go
func SetupHTTPHandlers(app *Application) *HTTPServer {
    handler := NewHandler(app.CreateUC, app.GetUC)
    
    mux := http.NewServeMux()
    mux.HandleFunc("/resource", handler.Handle)
    
    return &HTTPServer{
        Server: &http.Server{Addr: ":8080", Handler: mux},
    }
}
```

## Phase 7: Composition Root

```go
func SetupApplication(cfg Config) (*Application, error) {
    infra, err := SetupInfrastructure(cfg)
    if err != nil { return nil, fmt.Errorf("infrastructure: %w", err) }
    
    domain, err := SetupDomain(infra)
    if err != nil { return nil, fmt.Errorf("domain: %w", err) }
    
    app, err := SetupApplication(domain, infra)
    if err != nil { return nil, fmt.Errorf("application: %w", err) }
    
    return app, nil
}

func SetupServer(cfg Config) (*HTTPServer, error) {
    app, err := SetupApplication(cfg)
    if err != nil { return nil, err }
    return SetupHTTPHandlers(app), nil
}
```

## Phase 8: Main Function

```go
func main() {
    cfg, err := config.LoadConfig()
    if err != nil { log.Fatalf("config: %v", err) }
    
    server, err := di.SetupServer(cfg)
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
│   ├── infrastructure.go
│   ├── domain.go
│   ├── application.go
│   └── interfaces.go
cmd/api/main.go
```

## Principles

**Manual DI**: Explicit dependencies via constructors, no globals, pure setup (no side effects)
**CQRS**: One interface per file, define in application, implement in infrastructure
**Configuration**: Env vars, validate at startup, centralized loading, type-safe structs
**Lifetime**: Singletons (DB pools, servers), request-scoped (transactions), explicit cleanup

## Testing

```go
func SetupTestInfrastructure(t *testing.T) *Infrastructure {
    db := setupTestDB(t)
    return &Infrastructure{
        CreateCommand: NewMockCreateCommand(),
        GetQuery:      NewMockGetQuery(),
        Database:      db,
    }
}

func Test_setup_injects_dependencies(t *testing.T) {
    infra := di.SetupTestInfrastructure(t)
    app, err := di.SetupApplication(nil, infra)
    assert.NoError(t, err)
    assert.NotNil(t, app)
}
```

## Success Criteria

- ✅ All dependencies explicit (no hidden deps)
- ✅ Configuration validated (fail fast)
- ✅ No side effects in setup (pure construction)
- ✅ CQRS interfaces (small, focused, one per file)
- ✅ Files ≤150 lines
- ✅ Easy to inject mocks (testability)

**CQRS Pattern**:
```go
// Define in application (one per file)
type CreateCommand interface { Execute(ctx context.Context, data Data) error }
type GetQuery interface { Execute(ctx context.Context, id string) (*Data, error) }

// Implement in infrastructure
type SQLRepository struct { db *sql.DB }
func NewSQLCreateCommand(db *sql.DB) CreateCommand { return &SQLRepository{db: db} }
```
