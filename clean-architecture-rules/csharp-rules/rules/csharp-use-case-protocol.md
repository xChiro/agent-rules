---
trigger: always_on
description: C# application use case protocol for TDD, Clean Architecture, DDD orchestration, CQRS ports, and actor-based responsibility.
globs: **/*.cs
---

# C# Use Case Protocol

Use cases are application-level actions. They coordinate domain objects and ports to satisfy one actor's business outcome.

## Sequence

When creating or changing a use case:

1. Identify the actor requesting the behavior.
2. Identify the single business outcome.
3. Frame the acceptance behavior with A-TDD.
4. Write or update the failing unit test first.
5. Create only the request/response records and ports needed now.
6. Implement the smallest orchestration that passes.
7. Move domain rules into entities/value objects/domain services when appropriate.
8. Add integration coverage for real adapters when the change touches infrastructure.
9. Refactor with tests green.

## Shape

A use case should:

- receive a clear request or primitive inputs already accepted by local convention
- validate through value objects/entities
- query needed state through focused ports
- call domain behavior
- persist through command ports
- return domain objects, IDs, or application response models
- throw typed exceptions for business failure

Example:

```csharp
public class BrandCreator(
    ICreateBrandCommand createBrand,
    IBrandExistsChecker brandExists) : IBrandCreator
{
    public async Task<Brand> Execute(string name, CancellationToken cancellationToken = default)
    {
        var brandName = BrandName.Create(name);

        if (await brandExists.Execute(brandName, cancellationToken))
            throw new DuplicateDataException($"Brand with name '{name}' already exists.", nameof(name));

        var brand = new Brand(brandName);
        await createBrand.Execute(brand, cancellationToken);

        return brand;
    }
}
```

## Boundaries

Use cases must not know:

- `ControllerBase`, `IActionResult`, `ProblemDetails`, headers, routes, or status codes
- `DbContext`, EF DTOs, `IQueryable`, SQL, migrations, or provider errors
- RabbitMQ channels, queue names, delivery tags, ACK/NACK details, or broker messages
- `ILogger`, except for a deliberate application-level audit/operation use case
- `IConfiguration`, environment variables, or options classes

## Ports

Create ports for real boundaries:

- persistence commands
- persistence queries
- external APIs
- message publishing
- clocks when time affects deterministic behavior
- ID generation when test determinism matters
- authorization/session context when the actor comes from runtime context

Do not create ports for:

- private helpers
- pure calculations
- value object factories
- simple constructors
- speculative future adapters

## Request And Response Records

Use request/response records when they clarify the boundary or keep signatures stable.

```csharp
public record TelemetryProcessorRequest(
    string MessageId,
    string DeviceId,
    Speed Speed,
    Position Position,
    bool GpsFixed,
    DateTime DeviceTimestamp);
```

Keep application records framework-free. No JSON attributes, EF attributes, broker fields, or validation attributes unless the project explicitly uses them in application code.

## Failure Policy

- Missing required dependency result becomes a typed business exception in the use case.
- Duplicate business key becomes conflict/duplicate exception.
- Invalid value object input throws from the value object.
- Technical exceptions normally bubble to the boundary.
- Wrap technical exceptions only when adding actionable context and preserving `InnerException`.

## Concurrency

- Use `Task.WhenAll` only when operations are independent and failure behavior is acceptable.
- Do not parallelize operations that must be transactional or ordered.
- Keep side effects explicit.
- Respect `CancellationToken` in new or touched async boundaries.

## Done Criteria

- The test failed before production behavior was added.
- The use case has one actor and one outcome.
- All ports are used and focused.
- Domain rules are not hidden in adapters or controllers.
- Tests cover success and meaningful failure.
- Domain/application unit coverage remains 90%+ or improves toward it in touched projects.
