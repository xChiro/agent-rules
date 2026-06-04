---
trigger: always_on
description: Onnodo Fleet .NET skill for Clean Architecture, DDD, RabbitMQ/EF adapters, and TDD.
globs: **/*.cs,**/*.csproj,**/*.sln
---

# Onnodo .NET Senior Skill

Use the Onnodo Fleet Tracking style: clean core, explicit ports, manual mocks, xUnit tests, and small files.

## Project Shape

- Core/domain/application: `src/Onnodo.FleetTracking`.
- Persistence adapters: `src/Onnodo.FleetTracking.DataAccess`.
- RabbitMQ adapters: `src/Onnodo.FleetTracking.MessageBus.RabbitMQ`.
- API/composition root: `src/Onnodo.FleetTracking.WebApi`.
- Unit tests: `src/Onnodo.FleetTracking.Tests`.
- Integration tests: `src/Onnodo.FleetTracking.IntegrationTests`.

## .NET Style

- Value objects are immutable records when possible.
- Entities/classes protect invariants and expose named behavior.
- Ports are small interfaces named by behavior: `ISaveTelemetry`, `IGetDeviceSettingByDeviceId`, `ISendTelemetry`.
- Use constructor dependency injection and register dependencies in the composition root or service collection extension.
- Use manual mocks/fakes in tests before adding a mocking framework.
- Keep production files close to 150 lines and methods close to 20 lines.

## TDD Slice

1. Add a failing xUnit test in Given-When-Then form.
2. Name the SUT variable `SUT` for new tests.
3. Use real domain objects/value objects; use manual mocks for outgoing ports.
4. Add request/response records only when they clarify the use case boundary.
5. Keep business logic in entities/value objects/domain services; use cases orchestrate.
6. Add integration tests for EF Core mappings, RabbitMQ consumers/publishers, hosted services, and API wiring.

## Onnodo Boundaries

- `Onnodo.FleetTracking` must not depend on EF Core, RabbitMQ, ASP.NET, or infrastructure DTOs.
- DataAccess maps domain to DTO/configuration and back.
- MessageBus maps transport messages to application requests and handles ack/retry semantics.
- WebApi wires services and exposes external protocols only.

