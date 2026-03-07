---
trigger: model_decision
description: Use Google Wire for compile-time dependency injection in Go projects
globs: 
---

# Dependency Injection (DI) Guidelines for Go

These rules complement your clean‑code and architecture guidelines. They explain how to structure and wire dependencies in a Go project using **Google Wire** for compile-time dependency injection. The goal is to keep the system modular, testable and easy for AI coding agents to reason about.

## Goals
- **Separation of concerns:** Each layer (domain, application, infrastructure, interface) manages its own dependencies.
- **Explicit dependencies:** All collaborators are passed via constructors or setup functions rather than looked up globally.
- **Testability:** Interfaces decouple implementations, making it easy to substitute test doubles.
- **Minimal side‑effects:** Registration of dependencies should not perform work such as opening connections or starting goroutines.
- **Compile-time safety:** Wire generates dependency graph at compile time, catching errors early.

## General Principles
- **Dependency inversion:** Depend on small interfaces defined near their consumers, not on concrete types.
- **Wire-based injection:** Use Google Wire for compile-time dependency generation. Wire generates code that follows manual injection patterns.
- **Single responsibility:** Each component has one reason to change and exposes one constructor function.
- **Clear lifetimes:** Go does not have built‑in lifetimes (scoped, transient, singleton). Use the lifetime of the struct you construct: create per request or once at startup as appropriate.
- **Idempotent registration:** Wire providers should be repeatable without side effects.
- **Build tags:** Use `//go:build wireinject` for Wire files and regular Go files for implementations.

## Structure

For each layer, define constructor functions and Wire providers. These functions are pure in the sense that they only construct objects; they do not start background routines or mutate shared state.

### Domain layer
- Provides business logic (use cases) and value objects.
- Exposes constructors like `NewDomainService(repo TelemetryRepository, bus EventBus) *DomainService`.
- Wire provider: `func ProvideDomainService(repo TelemetryRepository, bus EventBus) *DomainService`.

### Infrastructure layer
- Provides concrete implementations of interfaces (database clients, message queues, external APIs).
- Exposes constructors like `func NewSQLRepository(db *sql.DB) TelemetryRepository`.
- Wire providers: `func ProvideSQLRepository(db *sql.DB) TelemetryRepository`, `func ProvideDatabase(cfg Config) (*sql.DB, error)`.
- These functions parse configuration, validate required values and instantiate objects, but do not start connections. For example, creating a database pool is acceptable; starting a consumer loop is deferred.

### Application layer
- Wires domain services to infrastructure. It composes the domain with concrete repositories and bus clients returned from infrastructure setup.
- Exposes constructors like `func NewApplication(domain *DomainService, config Config) *Application`.
- Wire provider: `func ProvideApplication(domain *DomainService, config Config) *Application`.

### Interface layer
- Wires transport protocols (HTTP, gRPC, CLI, consumers) to application use cases.
- Exposes constructors like `func NewServer(app *Application) *http.Server`.
- Wire provider: `func ProvideServer(app *Application) *http.Server`.
- Start listening and background routines outside of Wire-generated code.

## Constructor and Provider Guidelines
- **Signature:** `func NewX(args …) (*X, error)` or `func ProvideX(args …) (*X, error)`. Accept configuration and dependencies explicitly.
- **Validation:** Check for missing configuration keys and return descriptive errors.
- **No side effects:** Do not call `go` routines or block inside constructors. Provide a separate `Start()` method on the returned object to begin processing.
- **Error handling:** Return errors; do not panic inside constructors. This keeps startup predictable.
- **Length:** Keep each provider file under 150 lines. Extract helper functions if necessary.

## Naming Conventions
- Use clear, descriptive names for interfaces and structs (e.g., `TelemetryRepository`, `MessageBus`, `DataAccess`).
- Prefix constructors with `New` (e.g., `NewTelemetryProcessor`, `NewSQLTelemetryRepository`).
- Prefix Wire providers with `Provide` (e.g., `ProvideTelemetryProcessor`, `ProvideSQLTelemetryRepository`).
- Name Wire injector functions with the pattern `Initialize<Subsystem>` (e.g., `InitializeBot`, `InitializeAPI`).
- Use lower‑camel‑case for variables and function parameters (`dbPool`, `cfg`), as recommended by Go naming conventions.

## Wire Configuration
- **Wire files:** Create separate files with `//go:build wireinject` build tag for Wire configuration.
- **Provider sets:** Group related providers using `wire.NewSet` for better organization.
- **Injector functions:** Define injector functions that return the final object graph (e.g., `func InitializeBot(cfg Config) (*Bot, error)`).
- **Generated code:** Wire generates a `wire_gen.go` file with the actual dependency injection code.
- **Clean generation:** Run `wire` command to regenerate dependencies when providers change.

## Lifetime Management
- **Singletons:** Create long‑lived objects (e.g., connection pools) once in providers and reuse them.
- **Request‑scoped values:** Pass `context.Context` and create new resources per request if needed (e.g., transactions or correlation IDs).
- Avoid storing context or request data in global variables.
- Wire respects the lifetime of objects as defined in your constructors.

## Interfaces and Constructors
- Keep interfaces small and focused. A consumer should depend only on the methods it needs.
- Define interfaces in the domain or application layer. Implementations live in infrastructure.
- Provide constructors for concrete types. Example:

```go
// Interface in domain
type TelemetryRepository interface {
    Save(ctx context.Context, e TelemetryEvent) error
    FindByDeviceID(ctx context.Context, id string) (Device, error)
}

// Implementation in infrastructure
func NewSQLTelemetryRepository(db *sql.DB) TelemetryRepository {
    return &sqlTelemetryRepository{db: db}
}
```

## Example of Wire Dependency Injection

```go
// config.go
type Config struct {
    DBConnString string
    RabbitMQConn string
    TelemetryQueue string
}

// providers.go
//go:build wireinject
//+build wireinject

package wire

import (
    "database/sql"
    "github.com/google/wire"
)

// Infrastructure providers
func ProvideDatabase(cfg Config) (*sql.DB, error) {
    return sql.Open("postgres", cfg.DBConnString)
}

func ProvideSQLRepository(db *sql.DB) TelemetryRepository {
    return NewSQLTelemetryRepository(db)
}

// Domain providers
func ProvideTelemetryProcessor(repo TelemetryRepository) *TelemetryProcessor {
    return NewTelemetryProcessor(repo)
}

// Application providers
func ProvideApplication(processor *TelemetryProcessor) *Application {
    return NewApplication(processor)
}

// Server providers
func ProvideServer(app *Application) *http.Server {
    return NewServer(app)
}

// Provider sets
var DatabaseSet = wire.NewSet(ProvideDatabase, ProvideSQLRepository)
var DomainSet = wire.NewSet(ProvideTelemetryProcessor)
var ApplicationSet = wire.NewSet(ProvideApplication)
var ServerSet = wire.NewSet(ProvideServer)

// Injector function
func InitializeBot(cfg Config) (*Bot, error) {
    wire.Build(
        DatabaseSet,
        DomainSet, 
        ApplicationSet,
        ServerSet,
        NewBot, // Final constructor
    )
    return &Bot{}, nil // Wire will replace this line
}

// constructors.go (regular Go file)
package main

// Implementation constructors
func NewSQLTelemetryRepository(db *sql.DB) TelemetryRepository {
    return &sqlTelemetryRepository{db: db}
}

func NewTelemetryProcessor(repo TelemetryRepository) *TelemetryProcessor {
    return &telemetryProcessor{repo: repo}
}

func NewApplication(processor *TelemetryProcessor) *Application {
    return &Application{processor: processor}
}

func NewServer(app *Application) *http.Server {
    mux := http.NewServeMux()
    mux.HandleFunc("/telemetry", func(w http.ResponseWriter, r *http.Request) {
        // decode request and call app.processor.Process()...
    })
    return &http.Server{Addr: ":8080", Handler: mux}
}

func NewBot(server *http.Server) *Bot {
    return &Bot{server: server}
}
```

Testing
Create fake implementations of interfaces for unit tests. Inject them via Wire providers in test files.
Use table‑driven tests. Start with edge cases before happy paths.
Follow Arrange–Act–Assert: structure each test with // Arrange, // Act, // Assert comments. Only one call to the system under test in the Act section.
For tests, you can create separate Wire injector functions that use mock implementations.
Configuration Handling
Centralise configuration loading in the main package. Use environment variables or a config file to populate a Config struct.
Do not read environment variables deep inside packages. Pass configuration values into provider functions.
Summary
These rules outline a powerful pattern for dependency injection in Go using Google Wire:

Define interfaces in the domain/application layer.
Implement them in infrastructure packages with New constructors.
Create Wire providers with Provide prefix for each constructor.
Organize providers in logical sets using wire.NewSet.
Define injector functions that Wire will implement.
Run wire to generate the dependency injection code.
Avoid side effects in providers; keep files concise (<150 lines) and names meaningful.