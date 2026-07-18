---
rule_id: RULE-CSHARP_DEPENDENCY_INJECTION
trigger: model_decision
description: "C# dependency injection, composition root, options, service lifetime, and registration rules for Clean Architecture."
globs: "**/*ServiceCollectionExtensions.cs,**/Program.cs,**/*.cs"
---

# C# Dependency Injection

## SDD Integration

Apply `RULE-COMMON_SDD_AGENTIC_DISCIPLINE` and `RULE-COMMON_INSIDE_OUT_DEVELOPMENT`. This rule adds .NET composition details only; DI remains an outer concern and cannot bypass common gates or layer order.

DI should make dependencies explicit and composition clear. It must not hide design problems behind a container.

## Module-Owned Composition

Every business module owns its dependency graph. The executable host is only the final aggregator:

- each module defines layer-specific extension methods for Domain, Application, Infrastructure, and Interface;
- each module defines one `Add<Module>Module` extension that invokes those layer methods in composition order;
- `Program.cs`, WebApi startup, Lambda bootstrap, or worker startup calls module entry points and host-wide concerns only;
- the host must not enumerate a module's use cases, repositories, clients, handlers, or consumers individually;
- modules must not resolve or register another module's internals; integration occurs through explicit public application contracts or messages.

To keep both inner layers framework-free, place the Domain and Application `IServiceCollection` extension files in a module-local outer composition assembly/project such as `<Product>.<Module>.Composition`. Those methods may register concrete inner services, but Domain and Application never reference Microsoft DI. Infrastructure and Interface extensions may live in their owning outer projects when that does not reverse dependencies, or beside the inner-layer extensions in Composition.

Library/layer registration methods must not build the provider.

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

## Required Extension Method Per Layer

Every module provides these four extension methods, even when one currently has no registrations. A no-op Domain extension documents intentional purity and gives the module one stable composition contract; do not add fake services to make it non-empty.

```csharp
public static class FleetTrackingDependencyInjection
{
    public static IServiceCollection AddFleetTrackingDomain(
        this IServiceCollection services)
    {
        return services;
    }

    public static IServiceCollection AddFleetTrackingApplication(
        this IServiceCollection services)
    {
        services.AddScoped<ITelemetryProcessor, TelemetryProcessor>();
        return services;
    }

    public static IServiceCollection AddFleetTrackingInfrastructure(
        this IServiceCollection services,
        IConfiguration configuration)
    {
        services.AddFleetTrackingDataAccess(configuration);
        services.AddFleetTrackingMessaging(configuration);
        return services;
    }

    public static IServiceCollection AddFleetTrackingInterface(
        this IServiceCollection services)
    {
        services.AddScoped<TelemetryEndpoint>();
        return services;
    }

    public static IServiceCollection AddFleetTrackingModule(
        this IServiceCollection services,
        IConfiguration configuration)
    {
        return services
            .AddFleetTrackingDomain()
            .AddFleetTrackingApplication()
            .AddFleetTrackingInfrastructure(configuration)
            .AddFleetTrackingInterface();
    }
}
```

Rules:

- Use the canonical names `Add<Module>Domain`, `Add<Module>Application`, `Add<Module>Infrastructure`, `Add<Module>Interface`, and `Add<Module>Module`.
- A layer extension registers only types owned by that module and layer.
- The Domain layer method registers domain services, the Application method registers use cases, Infrastructure registers port implementations/clients, and Interface registers controllers/endpoints/consumers; the extension source itself remains in an allowed outer project.
- Infrastructure may delegate to smaller module-local DataAccess or Messaging extensions; those remain implementation details of `Add<Module>Infrastructure`.
- The module extension invokes layer extensions in Domain → Application → Infrastructure → Interface order.
- The executable host invokes `Add<Module>Module` once per installed module; it never reaches into layer-specific registrations.
- Keep module registration deterministic and idempotent where the underlying Microsoft registrations allow it; use `TryAdd*` for shared module services when duplicate calls are possible.
- Validate module options at startup and keep configuration sections module-owned.

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

## Module Wiring Verification

- Test each `Add<Module><Layer>` extension against a fresh `ServiceCollection`; assert only registrations owned by that layer/module.
- Test `Add<Module>Module` by building a provider in test code, creating every public module entry point, and verifying configured lifetimes when wiring risk is non-trivial.
- Verify the executable host calls each installed `Add<Module>Module` once and contains no module-internal service registration.
- A no-op Domain extension is verified by confirming it succeeds without adding framework dependencies to the Domain assembly.
- Registration tests belong to the existing integration project, normally its Infrastructure scope; they do not create a third suite or project.

## Done Criteria

- Dependencies are explicit.
- No unused injected dependencies.
- No service locator.
- No hidden config reads in core code.
- Lifetimes match the dependency behavior.
- Registration is tested when wiring risk is non-trivial.
- Every installed module exposes and tests its four layer extension methods plus its `Add<Module>Module` aggregator.
- `Program.cs` contains no individual registrations for module-owned domain, application, infrastructure, or interface types.
