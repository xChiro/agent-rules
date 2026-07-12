---
rule_id: RULE-CSHARP_SOLID_DESIGN
trigger: always_on
description: C# SOLID rules for Clean Architecture projects, including actor-based SRP from Clean Architecture.
globs: **/*.cs
---

# C# SOLID Design

## SDD Baseline

- Apply `common/rules/common-sdd-agentic-discipline.md` before this rule.
- Create or evolve the owning User Story based spec before production code when behavior, contracts, architecture, or risk changes.
- Apply mandatory Gate 1 before spec writes, Gate 2 before RED, and Gate 3 before Green, even for simple or low-risk changes.
- Keep artifact, task, track, and test IDs traceable through `traceability.yaml` and `parallel-tracks.md`.
- Write BDD Given/When/Then acceptance evidence first, then the unit-level ATDD-style focused failing test for the next rule or boundary before production code.
- Refactor only with tests green and converge spec history, tasks, parallel tracks, traceability, verification notes, and code.

Apply SOLID to protect change boundaries, not to make the code look abstract. Prefer explicit, simple C# over design-pattern ceremony.

## Single Responsibility Principle

SRP definition from Clean Architecture: "A module should be responsible to one, and only one, actor."

Interpret "module" as a class, method, record, namespace, project, package, use case, controller, adapter, or service.

An actor is a person, role, external system, policy, standard, process, or operational concern that can request a change.

### Actor-Based SRP

Good modules serve one actor:

- `BrandCreator`: business actor that needs brand creation rules.
- `CreateBrandCommand`: persistence actor that stores a brand.
- `BrandsController`: HTTP client actor that sends/receives REST payloads.
- `ExceptionHandlingMiddleware`: operations/API actor that maps failures to HTTP responses.

Violations mix actors:

- A use case that validates business rules and writes EF Core directly.
- A controller that queries the database and maps exceptions.
- A domain entity that logs, reads configuration, or knows HTTP status codes.
- A repository that decides API responses.

### Method-Level SRP

Each method should have one cohesive reason to change.

Split when a method mixes:

- validation and persistence
- mapping and business decision
- HTTP binding and domain rule
- EF query and response formatting
- message ACK/NACK decision and domain processing

Do not split a cohesive method just because it has several statements. A clear 20-line workflow is better than vague helpers that hide the business process.

## Open/Closed Principle

Software should be open for extension and closed for modification when real variation exists.

Use extension points when there are current strategies, providers, policies, or adapters.

Good:

```csharp
public interface ITrackingEventEvaluator
{
    Task<TelemetryEvents> EvaluateAsync(DeviceSetting device, Telemetry telemetry);
}
```

This supports adding a new evaluator without modifying the processor.

Avoid speculative extension points:

```csharp
public interface IBrandNameProcessingStrategy
{
    string Process(string value);
}
```

Do not create strategy interfaces for one implementation and no current variation.

## Liskov Substitution Principle

Every implementation of a port must honor the same contract.

- Do not strengthen preconditions in one adapter.
- Do not return `null` when the interface promises a value.
- Do not swallow exceptions in one implementation while another propagates them.
- Use shared unit-test examples for substitutable port behavior; verify real adapter wiring through HTTP integration rather than a separate contract suite.
- Ensure manual test doubles behave like valid substitutes, not magic shortcuts.

## Interface Segregation Principle

Clients should not depend on members they do not use.

- Prefer small ports such as `ICreateBrandCommand`, `IGetBrandById`, `IBrandExistsChecker`.
- Keep commands, queries, and checkers separate when use cases consume them separately.
- Define port interfaces in Application, near the use case or application module that consumes them.
- Avoid "god" services like `IBrandRepository` when use cases need only one operation.
- Do not introduce an interface just to fake a private helper in tests.

## Dependency Inversion Principle

High-level policy must not depend on low-level details. Both depend on abstractions owned by the policy side.

- Use cases depend on ports, not EF Core or RabbitMQ clients.
- Infrastructure implements Application ports.
- WebApi composes concrete adapters and application services.
- Domain remains independent from frameworks and runtime services.
- Abstractions should speak domain/application language, not provider language.

Good:

```csharp
public class BrandCreator(
    ICreateBrandCommand createBrand,
    IBrandExistsChecker brandExists) : IBrandCreator
{
}
```

Bad:

```csharp
public class BrandCreator(OnnodoDbContext dbContext) : IBrandCreator
{
}
```

## SOLID Theater To Avoid

- Interfaces for every class by default.
- Generic repositories that hide business-specific queries.
- Factories for simple constructors.
- Base classes that couple unrelated tests or use cases.
- Manager/helper/service names that hide the real responsibility.
- Splitting code until the flow is harder to read.
- Pattern use without current pressure from tests, requirements, or existing variation.
