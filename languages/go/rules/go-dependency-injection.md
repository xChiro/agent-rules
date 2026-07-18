---
rule_id: RULE-GO_DEPENDENCY_INJECTION
trigger: model_decision
description: "Go dependency injection and Wire rules for Clean Architecture projects"
globs: "**/*.go"
---

# Go Dependency Injection

## SDD Integration

Apply `RULE-COMMON_SDD_AGENTIC_DISCIPLINE` and `RULE-COMMON_INSIDE_OUT_DEVELOPMENT`. This rule adds Go composition details only; DI remains the last production layer and cannot bypass common gates or layer order.


**Principles**: Separation of concerns, explicit dependencies via providers, testability with interfaces, minimal side effects, YAGNI, compile-time DI when Wire is used

Prefer direct constructor injection until the object graph is large enough that Wire improves clarity. DI must make dependencies explicit; it must not create artificial interfaces or empty packages.

Composition is the last production layer. Do not add providers, router/Lambda registrations, generated wiring, or configuration bindings before `LAYER-GATE-APPLICATION`, Gate 3-BOUNDARY when outer production is affected, and any affected infrastructure/interface gates.

## Module-Owned DI Structure

Every business module owns its object graph. Keep constructors with the types they construct, and keep cross-layer wiring in that module's outer `di` package. The executable root combines module outputs; it must not list a module's repositories, clients, use cases, handlers, or consumers individually.

**Directory Structure**:
```
internal/
├── membership/
│   ├── domain/                   # Pure business types; no DI package
│   ├── application/              # Use cases and consumer-owned ports
│   ├── infrastructure/           # Port implementations and provider constructors
│   ├── delivery/                 # HTTP/message interface-layer constructors
│   └── di/
│       ├── module.go             # Module output + manual composition
│       └── wire.go               # Optional module-local Wire set/injector
├── inventory/
│   └── di/                       # Inventory owns its graph independently
└── di/
    └── application.go            # Aggregates module outputs only
```

Do not create `domain/di`, `application/di`, or `infrastructure/di` directories merely to mirror layers. A module DI package is an outer adapter and may import its Domain, Application, Infrastructure, and delivery/interface packages; none of those packages import the module DI package.

**Manual Composition Pattern**:

```go
// internal/membership/di/module.go
package di

type Module struct {
    EnrollMember http.Handler
    Close        func(context.Context) error
}

func NewModule(ctx context.Context, cfg Config) (*Module, error) {
    store, err := infrastructure.NewMemberStore(ctx, cfg.Database)
    if err != nil {
        return nil, fmt.Errorf("create membership store: %w", err)
    }

    enroll := application.NewEnrollMember(store)
    handler := delivery.NewEnrollMemberHandler(enroll)

    return &Module{
        EnrollMember: handler,
        Close: store.Close,
    }, nil
}

// cmd/service/internal/di/application.go
func NewApplication(ctx context.Context, cfg Config) (*Application, error) {
    membershipModule, err := membershipdi.NewModule(ctx, cfg.Membership)
    if err != nil {
        return nil, fmt.Errorf("compose membership module: %w", err)
    }
    inventoryModule, err := inventorydi.NewModule(ctx, cfg.Inventory)
    if err != nil {
        _ = membershipModule.Close(ctx)
        return nil, fmt.Errorf("compose inventory module: %w", err)
    }
    return NewApplicationFromModules(membershipModule, inventoryModule), nil
}
```

**Critical Rules**:
- Each business module exposes one `New<Module>Module`/`NewModule` entry point or one focused module-local Wire injector.
- The module output exposes only public delivery registrations, explicit cross-module application contracts, lifecycle cleanup, and health/readiness hooks needed by the host.
- Root composition receives module outputs and registers them; it never reconstructs module internals.
- Constructors and provider functions remain in their owning layer packages; the module DI package only sequences them and handles partial-construction cleanup.
- Configuration is partitioned per module and validated before or during module construction.
- Cross-module dependencies use narrow public application contracts or messages, never imports of another module's infrastructure or DI package internals.
- Do not create empty DI packages for layers or symmetry.
- Do not create interfaces only to satisfy Wire or tests
- Use concrete constructors inside one package when no boundary or substitution exists

## Provider Rules

**Pattern**: `func Provide{Type}(deps ...) (Type, error)` or `func New{Type}(deps ...) Type`
**Rules**: Validate config, return descriptive errors, make resource acquisition explicit, return cleanup when needed, avoid global mutation or unmanaged background work, and stay below 150 physical lines

## Interface Design (CQRS)

**Guidelines**: Single responsibility, one per file, consumer-focused, no god interfaces
**Location**: Define in Application (near the consumer), implement in infrastructure
**Naming**: Commands (`CreateOrderCommand`), Queries (`GetOrderByID`), Validation (`ValidateOrderUniqueness`)
**Files**: `snake_case.go`
**YAGNI**: Interfaces protect boundaries; they are not required for every service/helper

```go
// ✅ Small focused interfaces
type CreateOrderCommand interface { Execute(ctx context.Context, cmd CreateOrderRequest) (OrderID, error) }
type GetOrderByID interface { Execute(ctx context.Context, id OrderID) (*OrderDTO, error) }

// ❌ Large unfocused interface
type OrderRepository interface { Save(); FindByID(); ListByCustomer(); Delete(); UpdateStatus() }
```

## Provider/Constructor Pattern

```go
// Provider functions (in providers.go)
func ProvideOrderCreator(createCmd CreateOrderCommand, validateCmd ValidateOrderUniqueness, eventBus EventBus) *OrderCreator {
    return &OrderCreator{createCmd: createCmd, validateCmd: validateCmd, eventBus: eventBus}
}

// Constructors (can be used directly by Wire)
func NewOrderCreator(createCmd CreateOrderCommand, validateCmd ValidateOrderUniqueness, eventBus EventBus) *OrderCreator {
    return &OrderCreator{createCmd: createCmd, validateCmd: validateCmd, eventBus: eventBus}
}

func NewOrderRetriever(getQuery GetOrderByID) *OrderRetriever {
    return &OrderRetriever{getQuery: getQuery}
}
```

## YAGNI in DI

**Philosophy**: Only inject what's used, delete unused dependencies, simple providers, avoid over-engineering
**Required dependencies**: Pass required dependencies explicitly in constructors. Do not hide them behind functional options.
**Optional settings**: Use config structs or functional options only when defaults and optional values are real.

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

**Rules**: Load environment/files once at the executable edge, partition the resulting config by business module, validate at startup, and pass only the module config to its initializer or `wire.Value(cfg)`.

## Lifetime Management

**Types**: Singletons (connections, servers), Request-scoped (transactions), avoid globals
**YAGNI**: Simple lifetimes, explicit creation via providers, Wire handles singleton behavior automatically

## Optional Module-Local Wire

Wire is optional and stays module-owned. A module may export one focused provider set to its own injector; the executable root consumes the generated module initializer, never the module's individual providers.

```go
// internal/membership/di/wire.go
var moduleProviders = wire.NewSet(
    infrastructure.NewMemberStore,
    application.NewEnrollMember,
    delivery.NewEnrollMemberHandler,
    NewModuleOutput,
)
```

## Wire Injector

```go
// internal/membership/di/wire.go
func InitializeMembershipModule(cfg Config) (*Module, error) {
    wire.Build(
        wire.Value(cfg),
        moduleProviders,
    )
    return nil, nil
}

// Wire generates wire_gen.go with the actual implementation
```

## Composition Root

```go
func main() {
    cfg, err := LoadConfig()
    if err != nil { log.Fatalf("failed to load config: %v", err) }

    // Root aggregates module-owned graphs.
    app, err := di.NewApplication(context.Background(), cfg)
    if err != nil { log.Fatalf("failed to setup application: %v", err) }

    server := SetupServer(app)
    log.Printf("Starting server on port %d", cfg.HTTPPort)
    if err := server.ListenAndServe(); err != nil { log.Fatalf("server failed: %v", err) }
}
```

## Wire Generation

```bash
# Generate wire_gen.go
wire gen ./internal/membership/di ./internal/inventory/di

# Verify wire generation
wire check ./internal/membership/di ./internal/inventory/di
```

## Testing with Wire

**Test Double Rules**: One per outgoing interface, hand-written only, configurable results and captured calls; no third-party mocking frameworks or generated mocks. Unit assertions use the approved `testify/assert` or `testify/require` helpers.
**Structure**: `tests/unit/{domain}/application/{use_case}/doubles/{stub|fake|spy}_{port}.go`

**IMPORTANT**: Do NOT use Wire in tests. Use manual constructor injection for test setup.

Test the module `NewModule`/generated initializer separately from the executable root with module-local test configuration and real local resources. Verify its public output, cleanup on success, and cleanup of already-created dependencies when a later constructor fails. Test the executable root as an aggregator: replacing a module initializer/output must not require knowledge of that module's internal providers. Keep this evidence in `tests/integration/infrastructure/` as a focused scope; do not create a third suite.

```go
type CreateOrderCommandSpy struct {
    Error error
    Calls []CreateOrderCall
}

func (m *CreateOrderCommandSpy) Execute(ctx context.Context, order Order) error {
    m.Calls = append(m.Calls, CreateOrderCall{Order: order})
    return m.Error
}

// Test - manual DI (NOT Wire)
func TestOrderCreator(t *testing.T) {
    createCmd := &CreateOrderCommandSpy{}
    validateCmd := &ValidateOrderUniquenessStub{}
    useCase := NewOrderCreator(createCmd, validateCmd)
    _, err := useCase.Execute(ctx, request)

    // Assert
    if err != nil {
        t.Fatalf("Execute() error = %v, want nil", err)
    }
    if got := len(createCmd.Calls); got != 1 {
        t.Errorf("CreateOrder calls = %d, want 1", got)
    }
}
```

## YAGNI Testing

**Philosophy**: Test current functionality, simple hand-written doubles, delete unused tests, focus on behavior, manual DI for tests

```go
// ❌ Over-engineered
type ConfigurableOrderServiceDouble struct { mu sync.RWMutex; calls map[string][]interface{}; config DoubleConfig; hooks []DoubleHook }

// ✅ Simple
type OrderServiceSpy struct { Error error; Calls []CreateOrderCall }
func (m *OrderServiceSpy) CreateOrder(ctx context.Context, order Order) error {
    m.Calls = append(m.Calls, CreateOrderCall{Order: order})
    return m.Error
}
```

## Wire Best Practices

**Provider Functions**:
- Naming: `Provide{Type}` for providers, `New{Type}` for constructors
- Return single value or (value, error)
- Keep simple, ≤20 lines
- One responsibility per provider

**Wire Build**:
- Use `wire.Value()` for constant values (config, primitives)
- Use `wire.Struct()` for struct field binding
- Use `wire.Interface()` for interface binding
- Wire auto-detects dependencies from function signatures

**Provider Sets**:
- Keep each set inside one business module
- Export a module initializer/output, not individual cross-layer providers, to the executable root
- Keep sets focused and small when used

## Summary

**Test Design**: acceptance behavior framing, expected behavior captured in tests, test behavior not implementation, descriptive names, simple tests, manual DI for tests, 90%+ project-wide production coverage and domain/application unit coverage
**CQRS DI**: One interface per file, implement in infrastructure, module-owned pure construction, optional module-local Wire, hand-written doubles for tests
**YAGNI DI**: Simple providers, delete unused dependencies, avoid over-engineering, focus on current needs
**Lifetime**: Singletons (shared resources), request-scoped (per-request), avoid globals, Wire handles singleton behavior
**Principles**: CQRS interfaces, infrastructure implements, module-owned construction with explicit lifecycle side effects, optional Wire generation, YAGNI compliance

Ensures maintainable, testable, scalable Go applications following Clean Architecture, CQRS, YAGNI, and Wire.
