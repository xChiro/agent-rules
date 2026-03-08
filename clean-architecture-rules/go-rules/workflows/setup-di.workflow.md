---
description: Setup dependency injection following Clean Architecture principles
---

# Dependency Injection Setup Workflow

Create dependency injection setup functions following Clean Architecture and manual DI principles.

## Phase 1: Layer Analysis
- Identify **Target Layer**: Domain, Application, Infrastructure, or Interface
- Determine **Dependencies**: Required interfaces and implementations
- Define **Configuration**: Connection strings, settings, environment variables
- Confirm **File Size**: ≤150 lines limit

## Phase 2: Setup Function Pattern

### Function Signature
```go
func Setup[Layer](config Config, dependencies ...) (*[Layer], error) {
    // Implementation
}
```

### Configuration Structure
```go
type Config struct {
    DatabaseURL string
    RedisURL    string
    APIPort     int
    LogLevel    string
}

func LoadConfig() (*Config, error) {
    cfg := &Config{
        DatabaseURL: os.Getenv("DATABASE_URL"),
        RedisURL:    os.Getenv("REDIS_URL"),
        APIPort:     8080,
        LogLevel:    "info",
    }
    
    if err := cfg.validate(); err != nil {
        return nil, err
    }
    
    return cfg, nil
}
```

## Phase 3: Infrastructure Setup

### Database Setup
```go
func SetupDatabase(cfg Config) (*sql.DB, error) {
    db, err := sql.Open("postgres", cfg.DatabaseURL)
    if err != nil {
        return nil, fmt.Errorf("failed to open database: %w", err)
    }
    
    // Test connection
    if err := db.Ping(); err != nil {
        return nil, fmt.Errorf("failed to ping database: %w", err)
    }
    
    // Configure connection pool
    db.SetMaxOpenConns(25)
    db.SetMaxIdleConns(5)
    
    return db, nil
}
```

### Message Queue Setup
```go
func SetupRedis(cfg Config) (*redis.Client, error) {
    client := redis.NewClient(&redis.Options{
        Addr:     cfg.RedisURL,
        Password: "", // no password set
        DB:       0,  // use default DB
    })
    
    // Test connection
    _, err := client.Ping(context.Background()).Result()
    if err != nil {
        return nil, fmt.Errorf("failed to connect to redis: %w", err)
    }
    
    return client, nil
}
```

### Complete Infrastructure Setup
```go
func SetupInfrastructure(cfg Config) (*Infrastructure, error) {
    db, err := SetupDatabase(cfg)
    if err != nil {
        return nil, fmt.Errorf("database setup failed: %w", err)
    }
    
    redis, err := SetupRedis(cfg)
    if err != nil {
        return nil, fmt.Errorf("redis setup failed: %w", err)
    }
    
    // Create concrete implementations
    userRepo := NewSQLUserRepository(db)
    messageRepo := NewSQLMessageRepository(db)
    messagePublisher := NewRedisMessagePublisher(redis)
    
    return &Infrastructure{
        UserRepository:   userRepo,
        MessageRepository: messageRepo,
        MessagePublisher: messagePublisher,
        Database:         db,
        Redis:            redis,
    }, nil
}
```

## Phase 4: Domain Setup

### Domain Services Setup
```go
func SetupDomain(infra *Infrastructure) (*Domain, error) {
    // Domain services typically don't need external dependencies
    // but may need repositories or event buses
    
    pricingSvc := NewOrderPricingService(infra.ProductRepository)
    validationSvc := NewOrderValidationService()
    
    return &Domain{
        OrderPricingService:    pricingSvc,
        OrderValidationService: validationSvc,
    }, nil
}
```

## Phase 5: Application Setup

### Use Cases Setup
```go
func SetupApplication(domain *Domain, infra *Infrastructure) (*Application, error) {
    // Create use cases with injected dependencies
    createUserUC := NewCreateUserUseCase(infra.UserRepository, infra.EventPublisher)
    processMessageUC := NewProcessMessageUseCase(
        infra.MessageRepository,
        infra.TranslationService,
        infra.MessagePublisher,
    )
    
    return &Application{
        CreateUserUC:      createUserUC,
        ProcessMessageUC:  processMessageUC,
    }, nil
}
```

## Phase 6: Interface Setup

### HTTP Handlers Setup
```go
func SetupHTTPHandlers(app *Application) *HTTPServer {
    // Create HTTP handlers
    userHandler := NewUserHandler(app.CreateUserUC)
    messageHandler := NewMessageHandler(app.ProcessMessageUC)
    
    // Setup router
    mux := http.NewServeMux()
    mux.HandleFunc("/users", userHandler.Create)
    mux.HandleFunc("/messages", messageHandler.Process)
    
    return &HTTPServer{
        Server: &http.Server{
            Addr:    fmt.Sprintf(":%d", 8080),
            Handler: mux,
        },
        Handlers: map[string]http.Handler{
            "user":    userHandler,
            "message": messageHandler,
        },
    }
}
```

## Phase 7: Complete Application Setup

### Composition Root
```go
func SetupApplication(cfg Config) (*Application, error) {
    // Setup infrastructure layer
    infra, err := SetupInfrastructure(cfg)
    if err != nil {
        return nil, fmt.Errorf("infrastructure setup failed: %w", err)
    }
    
    // Setup domain layer
    domain, err := SetupDomain(infra)
    if err != nil {
        return nil, fmt.Errorf("domain setup failed: %w", err)
    }
    
    // Setup application layer
    app, err := SetupApplication(domain, infra)
    if err != nil {
        return nil, fmt.Errorf("application setup failed: %w", err)
    }
    
    return app, nil
}

func SetupServer(cfg Config) (*HTTPServer, error) {
    app, err := SetupApplication(cfg)
    if err != nil {
        return nil, err
    }
    
    return SetupHTTPHandlers(app), nil
}
```

## Phase 8: Main Function Integration

### Application Entry Point
```go
// cmd/api/main.go
func main() {
    // Load configuration
    cfg, err := config.LoadConfig()
    if err != nil {
        log.Fatalf("failed to load config: %v", err)
    }
    
    // Setup application
    server, err := di.SetupServer(cfg)
    if err != nil {
        log.Fatalf("failed to setup server: %v", err)
    }
    
    // Start server (this is the side effect)
    log.Printf("Starting server on port %d", cfg.APIPort)
    if err := server.Server.ListenAndServe(); err != nil {
        log.Fatalf("server failed: %v", err)
    }
}
```

## File Organization
```
internal/
├── config/
│   └── config.go
├── infrastructure/
│   └── di/
│       ├── infrastructure.go
│       ├── database.go
│       └── redis.go
├── domain/
│   └── di/
│       └── domain.go
├── application/
│   └── di/
│       └── application.go
└── interfaces/
    └── di/
        └── http.go

cmd/
└── api/
    └── main.go
```

## Key Principles

### Manual Dependency Injection
- **Explicit dependencies**: All dependencies passed via constructors
- **No global state**: Avoid singletons or global variables
- **Pure setup functions**: Only construction, no side effects
- **Clear interfaces**: Define near consumers, implement in infrastructure

### Configuration Management
- **Environment-based**: Use environment variables for configuration
- **Validation**: Validate configuration at startup
- **Centralized loading**: Load config in main, pass to setup functions
- **Type safety**: Use structs for configuration, not maps

### Lifetime Management
- **Singletons**: Long-lived objects (database pools, HTTP servers)
- **Request-scoped**: Create per-request when needed
- **Transient**: Create new instances for each use
- **Cleanup**: Provide explicit cleanup methods

## Testing Integration

### Test Setup Functions
```go
func SetupTestInfrastructure(t *testing.T) *Infrastructure {
    db := setupTestDatabase(t)
    redis := setupTestRedis(t)
    
    return &Infrastructure{
        UserRepository:   NewMockUserRepository(),
        MessageRepository: NewMockMessageRepository(),
        Database:         db,
        Redis:            redis,
    }
}
```

### Mock Injection
```go
func Test_given_dependencies_when_setup_then_injected(t *testing.T) {
    // Arrange: Setup test infrastructure
    infra := di.SetupTestInfrastructure(t)
    
    // Act: Setup application with test dependencies
    app, err := di.SetupApplication(nil, infra)
    
    // Assert: Verify dependencies injected correctly
    assertNoError(t, err, "application setup should succeed")
    assertNotNil(t, app, "application should be created")
}
```

## Success Criteria
- **All dependencies explicit**: No hidden dependencies
- **Configuration validated**: Fail fast on invalid config
- **No side effects in setup**: Only construction
- **Clean interfaces**: Small, focused interfaces
- **File size compliance**: ≤150 lines per file
- **Testability**: Easy to inject mocks

## Common Patterns

### Repository Pattern
```go
type UserRepository interface {
    Save(ctx context.Context, user User) error
    FindByID(ctx context.Context, id string) (*User, error)
}

type SQLUserRepository struct {
    db *sql.DB
}

func NewSQLUserRepository(db *sql.DB) UserRepository {
    return &SQLUserRepository{db: db}
}
```

### Service Pattern
```go
type UserService struct {
    repo UserRepository
    bus EventBus
}

func NewUserService(repo UserRepository, bus EventBus) *UserService {
    return &UserService{repo: repo, bus: bus}
}
```

Manual dependency injection provides clear, testable, and maintainable code structure without complex frameworks.
