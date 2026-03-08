---
trigger: always_on
description: 
globs: 
---

# Dependency Injection (DI) Guidelines for Go

These rules complement your clean‑code and architecture guidelines. They explain how to structure and wire dependencies in a Go project using manual injection. The goal is to keep the system modular, testable and easy for AI coding agents to reason about.

## Goals
- **Separation of concerns:** Each layer (domain, application, infrastructure, interface) manages its own dependencies.
- **Explicit dependencies:** All collaborators are passed via constructors or setup functions rather than looked up globally.
- **Testability:** Interfaces decouple implementations, making it easy to substitute test doubles.
- **Minimal side‑effects:** Registration of dependencies should not perform work such as opening connections or starting goroutines.

## General Principles
- **Dependency inversion:** Depend on small interfaces defined near their consumers, not on concrete types.
- **Manual wiring:** Prefer explicit construction of objects over using runtime reflection or heavy DI frameworks. Go's simplicity makes manual wiring straightforward.
- **Single responsibility:** Each component has one reason to change and exposes one *Setup* function for its dependencies.
- **Clear lifetimes:** Go does not have built‑in lifetimes (scoped, transient, singleton). Use the lifetime of the struct you construct: create per request or once at startup as appropriate.
- **Idempotent registration:** Registering services should be repeatable without side effects.

## Structure

For each layer, define a `Setup` function that takes the dependencies it needs and returns the objects it provides. These functions are pure in the sense that they only construct objects; they do not start background routines or mutate shared state.

### Domain layer
- Provides business logic (use cases) and value objects.
- Exposes `SetupDomain` which accepts abstractions (repositories, event buses) and returns a struct containing the domain services.
- Example: `func SetupDomain(repo TelemetryRepository, bus EventBus) *Domain`.

### Infrastructure layer
- Provides concrete implementations of interfaces (database clients, message queues, external APIs).
- Exposes functions such as `SetupDataAccess(cfg Config) (*DataAccess, error)` or `SetupMessageBus(cfg Config) (*MessageBus, error)`.
- These functions parse configuration, validate required values and instantiate objects, but do not start connections. For example, creating a database pool is acceptable; starting a consumer loop is deferred.

### Application layer
- Wires domain services to infrastructure. It composes the domain with concrete repositories and bus clients returned from infrastructure setup.
- Exposes a `SetupApplication` that accepts `Config` and returns a fully wired application service.
- Example:

```go
func SetupApplication(cfg Config) (*Application, error) {
    dataAccess, err := SetupDataAccess(cfg)
    if err != nil {
        return nil, err
    }
    bus, err := SetupMessageBus(cfg)
    if err != nil {
        return nil, err
    }
    domain := SetupDomain(dataAccess.TelemetryRepository, bus.EventBus)
    return &Application{Domain: domain, Bus: bus}, nil
}
```

### Interface layer
- Wires transport protocols (HTTP, gRPC, CLI, consumers) to application use cases.
- Exposes `SetupServer` or `SetupHandlers` that accept the application service and return the server/handler ready to start.
- Start listening and background routines outside of registration.

## Setup Function Guidelines
- **Signature:** `func SetupX(args …) (*X, error)` or `func RegisterX(container *Container, cfg Config) error`. Accept configuration and dependencies explicitly.
- **Validation:** Check for missing configuration keys and return descriptive errors.
- **No side effects:** Do not call `go` routines or block inside setup functions. Provide a separate `Start()` method on the returned object to begin processing.
- **Error handling:** Return errors; do not panic inside setup functions. This keeps startup predictable.
- **Length:** Keep each setup file under 150 lines. Extract helper functions if necessary.

## Naming Conventions
- Use clear, descriptive names for interfaces and structs (e.g., `TelemetryRepository`, `MessageBus`, `DataAccess`).
- Prefix constructors with `New` (e.g., `NewTelemetryProcessor`, `NewSQLTelemetryRepository`).
- Name setup functions with the pattern `Setup<Layer>` or `Setup<Subsystem>` (e.g., `SetupDomain`, `SetupDataAccess`, `SetupAPI`).
- Use lower‑camel‑case for variables and function parameters (`dbPool`, `cfg`), as recommended by Go naming conventions.

## Lifetime Management
- **Singletons:** Create long‑lived objects (e.g., connection pools) once in setup and reuse them.
- **Request‑scoped values:** Pass `context.Context` and create new resources per request if needed (e.g., transactions or correlation IDs).
- Avoid storing context or request data in global variables.

## Interfaces and Constructors
- Keep interfaces small and focused. A consumer should depend only on the methods it needs.
- Define interfaces in the domain or application layer. Implementations live in infrastructure.
- Provide constructors for concrete types. Example:

```go
// Interface in application
type TelemetryRepository interface {
    Save(ctx context.Context, e TelemetryEvent) error
    FindByDeviceID(ctx context.Context, id string) (Device, error)
}

// Implementation in infrastructure
func NewSQLTelemetryRepository(db *sql.DB) TelemetryRepository {
    return &sqlTelemetryRepository{db: db}
}
```

## Example of Manual Dependency Injection

```go
// config.go
type Config struct {
    DBConnString string
    RabbitMQConn string
    TelemetryQueue string
}

// dataaccess.go
type DataAccess struct {
    TelemetryRepo TelemetryRepository
}

func SetupDataAccess(cfg Config) (*DataAccess, error) {
    db, err := sql.Open("postgres", cfg.DBConnString)
    if err != nil {
        return nil, err
    }
    repo := NewSQLTelemetryRepository(db)
    return &DataAccess{TelemetryRepo: repo}, nil
}

// application.go
type Domain struct {
    TelemetryProcessor TelemetryProcessor
}

func SetupDomain(repo TelemetryRepository) *Domain {
    processor := NewTelemetryProcessor(repo)
    return &Domain{TelemetryProcessor: processor}
}

// application.go
type Application struct {
    Domain *Domain
}

func SetupApplication(cfg Config) (*Application, error) {
    dataAccess, err := SetupDataAccess(cfg)
    if err != nil {
        return nil, err
    }
    domain := SetupDomain(dataAccess.TelemetryRepo)
    return &Application{Domain: domain}, nil
}

// server.go
func SetupServer(app *Application) *http.Server {
    mux := http.NewServeMux()
    mux.HandleFunc("/telemetry", func(w http.ResponseWriter, r *http.Request) {
        // decode request and call app.Domain.TelemetryProcessor.Process()...
    })
    return &http.Server{Addr: ":8080", Handler: mux}
}
```

## Testing

### Mocks and Test Doubles

To test services in isolation, provide **manual mocks** for your dependencies. Follow these rules:

1. **Mock only outgoing ports**: Create mocks or fakes for interfaces that reach out to external systems (repositories, event buses, HTTP clients). Do not mock value objects or domain logic—use real implementations for those.
2. **Implement mocks by hand**: Define small structs implementing the interface. Use exported fields to preset return values or errors and to record inputs. Avoid using heavy mocking frameworks.
3. **Locate mocks in tests**: Place mock types alongside your tests (e.g., in a `mocks` subpackage) rather than in production code. They should only exist to support tests.
4. **Inject mocks via setup**: When constructing the SUT in tests, use your setup functions to inject the mock dependencies. This keeps tests deterministic and emphasises the dependency graph.

Example mock implementing a repository:

```go
// SaveTelemetryMock implements TelemetryRepository for tests.
type SaveTelemetryMock struct {
    Recorded []Telemetry
    Err      error
}

func (m *SaveTelemetryMock) Save(ctx context.Context, e Telemetry) error {
    m.Recorded = append(m.Recorded, e)
    return m.Err
}

func (m *SaveTelemetryMock) FindByDeviceID(ctx context.Context, id string) (Device, error) {
    // Provide minimal behaviour for tests
    return Device{}, nil
}
```

### Testing Guidelines Recap

- Create fake implementations of interfaces for unit tests. Inject them via setup functions.
- Use table‑driven tests. Start with edge cases before happy paths.
- Follow Arrange–Act–Assert: structure each test with `// Arrange`, `// Act`, `// Assert` comments. Only one call to the system under test in the **Act** section.

## Using Google Wire (Optional)

These guidelines prioritise **manual dependency injection** for clarity and simplicity. However, if your project’s dependency graph becomes very complex you may adopt **Google Wire** for compile‑time dependency injection. If you do:

1. **Define provider functions and sets**: Create constructors (`NewSQLTelemetryRepository`, `NewTelemetryProcessor`) and group them with `wire.NewSet` in the package where the types are defined.
2. **Keep wiring separate**: Place your injector functions in a dedicated `wire.go` file that uses `wire.Build` to assemble providers for a given application or subsystem.
3. **Preserve explicit architecture**: Even with Wire, respect layer boundaries and keep interfaces defined in the domain/application. Provider functions live near the types they create.
4. **Manual as default**: Use Wire only if manual wiring becomes unwieldy. The default recommendation is to keep wiring explicit so it’s easy to understand and review.

## Configuration Handling
- Centralise configuration loading in the main package. Use environment variables or a config file to populate a `Config` struct.
- Do not read environment variables deep inside packages. Pass configuration values into setup functions.

## Summary
These rules outline a simple yet powerful pattern for dependency injection in Go:

1. **Define interfaces** in the domain/application layer.
2. **Implement them** in infrastructure packages.
3. **Provide `Setup` functions** per layer that take configuration and dependencies and return fully wired structs.
4. **Wire everything** together explicitly in the entrypoint (e.g., `main.go` or `cmd/...`).
5. **Avoid side effects** in setup; keep files concise (<150 lines) and names meaningful.

By following these guidelines, your Go projects remain modular, easy to reason about, and friendly to automated tools like Windsurf.
