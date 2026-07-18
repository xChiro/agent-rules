---
rule_id: RULE-COMMON_TEST_DATA_AND_DOUBLE_PATTERNS
trigger: model_decision
description: "Test-data, fixture, SUT-factory, and test-double patterns aligned with SOLID, Clean Architecture, CQRS, and isolated test layers."
---

# Common Test Data And Double Patterns

Apply this rule with `common-test-assertion-structure.md` for every unit, integration, boundary, component, hook, or acceptance-support test change.

## Test Architecture

Test evidence progresses from inner behavior to outer boundaries in this order; this is test scope progression, not compile-time dependency direction:

```text
real domain values
        ↓
application/use-case SUT + outgoing-port doubles
        ↓
real adapters and local infrastructure
        ↓
real public delivery boundary
```

- Domain tests use real entities, value objects, policies, and domain services. Do not mock the behavior being proven.
- Application tests instantiate one use-case/actor responsibility and replace only its consumer-owned outgoing ports with small hand-written doubles.
- Infrastructure tests invoke the Application use case with the real adapter wiring and real local databases, queues, caches, or storage. Simulate only third-party APIs with WireMock or a small hand-written HTTP stub.
- Public-boundary tests enter through the real HTTP, message, worker, CLI, route, or user interaction boundary and use the real composition path appropriate to the project.
- CQRS tests keep command/write fixtures and query/read-model fixtures separate. Do not use a command-side result as a substitute for observing the query-side contract.
- A test double never owns business policy, assertions, hidden retries, or production orchestration.

## Test Data Patterns

Use the smallest pattern that protects readability and isolation:

- **Object Mother**: a named creator for one canonical valid domain concept, such as `MotherActiveMember()` or `MotherValidOrder()`. It returns fresh data on every call, owns valid defaults only, performs no I/O, and never asserts.
- **Test Data Builder**: a fluent, functional, or stepwise builder for meaningful scenario variations. Defaults are valid; each test overrides only the fields relevant to its behavior. Builders are test-only and must not become production domain builders.
- **SUT Factory**: a focused `CreateSut`/`NewSut` helper that wires the unit under test and returns its explicit doubles. It does not hide business decisions, assertions, or external resources.
- **Fixture**: lifecycle and resource ownership for a test scope. Fixtures own setup, readiness, cleanup, and diagnostics; they do not become global mutable state or a second composition root.
- **Scenario factory**: use only when a complete named scenario is clearer than a long builder chain. Keep one scenario factory per business concern, not a universal `TestDataFactory`.

Object Mothers and builders must be composable and single-purpose. Do not create boolean-flag factories, inheritance-heavy fixture hierarchies, random data that obscures the scenario, or a shared mutable mother object. Prefer deterministic IDs, timestamps, clocks, and seeds supplied by the test.

## Test Double Selection

- **Stub**: returns a configured result needed to drive the scenario.
- **Fake**: provides a simple in-memory implementation when stateful behavior is part of the contract.
- **Spy**: captures calls only when the interaction is an observable outcome, such as publishing an event or invoking a transfer port.
- **Mock**: use sparingly and only for an interaction contract that cannot be observed through state/result. Hand-write it; do not add a mocking library or generated mock framework.

Keep one double per outgoing port when useful. Do not mock domain objects, the SUT, value objects, local infrastructure under test, or internal methods. Generated mocks and mocking libraries/frameworks are prohibited for new or changed tests. The only permitted external test double for a third-party HTTP/API is a controlled WireMock-style simulator or a small hand-written HTTP stub. Testify, xUnit, and equivalent assertion libraries are assertion tools, not mocking libraries.

## Language Adaptation

- Go uses fresh `Mother...`/`New...` functions or small builder structs, the standard `testing` runner, approved `testify` assertions, and hand-written outgoing-port doubles. Test helpers return data/errors and never call `t.Error`, `t.Fatal`, `assert`, or `require`.
- C# uses fresh `Mother...` methods, immutable records/value objects where appropriate, small Test Data Builder classes or methods, explicit SUT factories, and manual fakes/stubs/spies for application ports. `WebApplicationFactory`, Testcontainers, and the real composition root belong to integration tests; infrastructure integration invokes the use case with real adapters and local resources.
- TypeScript/React/Web uses typed factory functions or Object Mothers returning fresh objects, small builders for variants, Testing Library/user-event or the repository's equivalent for observable interaction, and a controlled HTTP simulator for client boundaries. Do not assert component internals, hook call counts, or implementation order.

## Review Checklist

- The test name and scenario state Given/When/Then behavior.
- `// Arrange` creates fresh data/doubles without assertions; `// Act` has exactly one physical-line call that executes the SUT appropriate to the layer; `// Assert` observes the outcome.
- Test data names reveal the business concept and the scenario override.
- The pattern has one owner and one reason to change under actor-based SRP.
- Fixtures do not leak state across tests or layers.
- The chosen double protects a port/boundary and does not erase the behavior under test.
- CQRS command and query contracts are tested independently.
