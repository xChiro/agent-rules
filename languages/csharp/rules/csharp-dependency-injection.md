---
rule_id: RULE-CSHARP_DEPENDENCY_INJECTION
trigger: model_decision
description: C# dependency injection, composition root, options, service lifetime, and registration rules for Clean Architecture.
globs: **/*ServiceCollectionExtensions.cs,**/Program.cs,**/*.cs
---

# C# Dependency Injection

## SDD Baseline

- Apply `common/rules/common-sdd-agentic-discipline.md` before this rule.
- Create or evolve the owning User Story based spec before production code when behavior, contracts, architecture, or risk changes.
- Apply mandatory Gate 1 before spec writes, Gate 2 before RED, and Gate 3 before Green, even for simple or low-risk changes.
- Keep artifact, task, track, and test IDs traceable through `traceability.yaml` and `parallel-tracks.md`.
- Write BDD Given/When/Then acceptance evidence first, then the unit-level ATDD-style focused failing test for the next rule or boundary before production code.
- Refactor only with tests green and converge spec history, tasks, parallel tracks, traceability, verification notes, and code.

DI should make dependencies explicit and composition clear. It must not hide design problems behind a container.

## Composition Root

The executable host owns composition:

- `Program.cs`
- WebApi project startup
- worker/host startup
- module-level `ServiceCollectionExtensions`

Library/core projects may expose registration methods, but they must not build the provider.

Do not call:

```csharp
services.BuildServiceProvider()
```

inside registration methods.

## Constructor Injection

- Use constructor injection for required dependencies.
- Primary constructors are acceptable when concise.
- Inject only what the class actually uses.
- Do not inject service providers into application/domain code.
- Do not use static mutable singletons for dependencies.

Good:

```csharp
public class TelemetryProcessor(
    ISaveTelemetry saveTelemetry,
    IGetDeviceSettingByDeviceId getDeviceSettingByDeviceId,
    ITelemetrySender telemetrySender) : ITelemetryProcessor
{
}
```

Bad:

```csharp
public class TelemetryProcessor(IServiceProvider services)
{
}
```

## Interfaces

Create interfaces for real boundaries:

- persistence
- messaging
- external APIs
- clock/time provider
- ID generation when deterministic tests need it
- current user/session/tenant
- authorization policy

Define these boundary interfaces as Application ports near the use case that consumes them. Infrastructure and hosts implement or adapt them; Domain does not own these contracts.

Do not create interfaces only because DI can register them.

## Lifetimes

- Register stateless application services as scoped or transient according to project convention.
- Register EF `DbContext` as scoped, or `IDbContextFactory<TContext>` when the project uses factories.
- Register options/configuration as singleton/options pattern.
- Register broker clients/connections with explicit lifecycle matching the client library and host.
- Avoid captive dependencies: singleton must not depend on scoped services.

## Options And Configuration

- Group related settings into options classes.
- Validate required configuration at startup.
- Do not read environment variables inside domain/application code.
- Avoid passing raw `IConfiguration` deep into adapters.
- Fail fast for missing required settings.

## ServiceCollectionExtensions

Registration methods should be small and focused:

```csharp
public static IServiceCollection AddFleetTracking(this IServiceCollection services)
{
    services.AddScoped<ITelemetryProcessor, TelemetryProcessor>();
    return services;
}
```

Rules:

- Register core services in the core module extension.
- Register DataAccess adapters in the DataAccess extension.
- Register message bus adapters in the message bus extension.
- Keep executable host responsible for calling the extensions in the final composition order.

## Decorator Wiring

Use explicit decorators only for current cross-cutting behavior around a use case or port. Do not introduce a generic pipeline framework.

```csharp
services.AddScoped<CreateBrand>();
services.AddScoped<ICreateBrand>(provider =>
{
    var inner = provider.GetRequiredService<CreateBrand>();
    var metrics = provider.GetRequiredService<IMetrics>();

    return new CreateBrandMetricsDecorator(inner, metrics);
});
```

Rules:

- Register the concrete inner service separately when the decorator needs to wrap it.
- Keep decorator order visible in the composition root or module registration.
- Do not call `BuildServiceProvider()` to resolve decorators.
- Avoid nested decorators unless each layer has a current, named operational concern.

## Done Criteria

- Dependencies are explicit.
- No unused injected dependencies.
- No service locator.
- No hidden config reads in core code.
- Lifetimes match the dependency behavior.
- Registration is tested when wiring risk is non-trivial.
