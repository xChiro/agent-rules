---
trigger: model_decision
description: C# dependency injection, composition root, options, service lifetime, and registration rules for Clean Architecture.
globs: **/*ServiceCollectionExtensions.cs,**/Program.cs,**/*.cs
---

# C# Dependency Injection

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

## Done Criteria

- Dependencies are explicit.
- No unused injected dependencies.
- No service locator.
- No hidden config reads in core code.
- Lifetimes match the dependency behavior.
- Registration is tested when wiring risk is non-trivial.
