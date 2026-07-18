---
rule_id: RULE-COMMON_INSIDE_OUT_DEVELOPMENT
trigger: model_decision
description: "Mandatory inside-out development order and architectural layer gates for backend behavior changes."
---

# Common Inside-Out Development

Backend behavior is designed and implemented from stable policy toward volatile delivery details. BDD specifies the actor-visible contract first; executable public-boundary tests do not force outer-layer production code to exist before the domain and application core.

Apply `RULE-COMMON_TEST_LAYER_ISOLATION`. The sequence below controls when production layers open; it never permits one test layer to depend on another test layer's execution, fixtures, process, or mutable state.

## Acceptance Specification Is Not Boundary Implementation

- Write or evolve User Stories and abstract Given/When/Then scenarios before implementation planning.
- Define REST, event, CLI, or UI contracts in the spec before production code when the behavior exposes that boundary.
- Start executable implementation with domain and application unit tests.
- When outer production is affected, create executable HTTP/message/UI boundary RED only after the affected core is green and before implementing those outer layers; otherwise keep existing boundary evidence GREEN and mark the scope `not_affected`.
- A test that cannot compile because the next type or boundary is intentionally absent is valid RED only when the failure is narrow, expected, and recorded.

## Mandatory Development Sequence

For every backend behavior slice, discover the business model first and then execute only the affected layers in this order:

1. **Domain model and business policy**: identify the business capability/bounded context, ubiquitous terms, policy owner (aggregate, entity, value object, or domain service), invariants, state transitions, domain events, and counterexamples. Record `domain: not_affected` only when the behavior is genuinely orchestration or an outer concern.
2. **Scope map**: derive the technical map from that model; mark `domain`, `application`, `boundary`, `infrastructure`, `interface`, and `composition` as `affected` or `not_affected`, with a reason.
3. **Domain RED**: write the smallest unit test for one invariant, value object, entity transition, or domain service rule.
4. **Gate 3-DOMAIN**: review the actual RED evidence before domain production changes.
5. **Domain GREEN and refactor**: implement pure policy with no application, transport, persistence, cloud SDK, framework, or deployment dependency. Keep Domain names provider-neutral; `DynamoDB`, `Cosmos`, `Kafka`, and equivalent technology names belong only to outer adapters/configuration.
6. **`LAYER-GATE-DOMAIN`**: domain tests are green and dependency direction is clean.
7. **Application RED**: write the smallest use-case test. Define consumer-owned incoming/outgoing ports in application as required by the behavior.
8. **Gate 3-APPLICATION**: review the actual RED evidence before application production changes.
9. **Application GREEN and refactor**: implement orchestration against domain types and application-owned ports. Name ports, use cases, DTOs, events, errors, files, and packages by business capability, never by the selected provider or SDK.
10. **`LAYER-GATE-APPLICATION`**: domain/application unit tests are green; the core has no outer-layer dependency. This is the core gate and blocks all new outer production code.
11. **Conditional Boundary RED**: only when `boundary`, `infrastructure`, `interface`, or `composition` is affected, create the executable acceptance test at the approved HTTP, message, CLI, or UI boundary.
12. **Gate 3-BOUNDARY**: only for affected outer production, review the actual boundary RED before outer production changes.
13. **`LAYER-GATE-BOUNDARY-RED`**: the failure proves missing wiring or I/O behavior, not missing core policy.
14. **Infrastructure GREEN**: implement persistence, identity, clock, ID, SNS/SQS, service-bus, or external-client adapters for application-owned ports.
15. **`LAYER-GATE-INFRASTRUCTURE`**: adapters translate and perform I/O without owning business policy.
16. **Interface GREEN**: implement thin REST/Lambda/message/UI delivery adapters that validate and map boundary data, invoke one application use case, and map the result.
17. **`LAYER-GATE-INTERFACE`**: delivery code contains no domain decisions and depends inward.
18. **Composition GREEN**: add module-owned DI, router/handler registration, configuration, IAM/IaC, and deployment wiring last; the executable root only aggregates modules.
19. **`LAYER-GATE-COMPOSITION`**: the real composition root is complete and the boundary test is green through required local resources.
20. **Final refactor and gates**: run the full affected unit/boundary suites plus architecture, security, coverage, documentation, clean-up, mutation, and E2E gates selected by the spec.

At every Domain, Application, and Boundary gate, run that layer's documented standalone command from clean state before the combined verification command.

Application-owned ports are part of the core; the `interface` layer above means delivery/transport adapters, not those ports.

## Layer Scope And Exceptions

- Do not invent a domain change for an application-only behavior. Record `LAYER-GATE-DOMAIN: not_affected` and prove the existing domain suite remains green.
- Do not invent core behavior for a pure adapter or composition change. Characterize the existing core, record why it is unchanged, and begin new test code at the closest affected boundary.
- When every outer layer is `not_affected`, run the existing executable boundary as GREEN acceptance verification when one exists; record `Gate 3-BOUNDARY: not_affected` and do not manufacture a failing boundary test or outer production change.
- A layer may be skipped only with `status: not_affected`, an evidence-based reason, and its dependency precondition recorded in `plan.md`, `tasks.md`, and `verification.md`.
- Outer-layer tasks may be planned early but must depend on `LAYER-GATE-APPLICATION`. They may not create production handlers, adapters, clients, repositories, DI, or IaC while an affected inner gate is incomplete.
- Parallel work may occur within the same opened layer only when file ownership is independent. Do not parallelize outer production ahead of an incomplete inner gate.

## Unit Test Doubles

- Domain tests normally use real domain values and need no mocks.
- Application tests replace only outgoing ports with small hand-written stubs, fakes, spies, or mocks.
- Prefer state/result assertions. Verify calls only when the interaction is part of the observable contract, such as publishing an event or invoking an inventory transfer port.
- Test doubles contain configurable results and captured calls; they do not contain business rules or assertions.
- Do not add generated mocks or third-party mocking libraries/frameworks for new or changed tests; use small hand-written doubles. Third-party HTTP/API integration dependencies may use WireMock or a small hand-written HTTP stub. A language may keep its established test runner/assertion library; Go uses `testing` plus the approved `testify/assert` or `testify/require` assertion helpers.

## Required SDD Evidence

Each task declares:

- `development_layer: domain | application | boundary | infrastructure | interface | composition | verification | documentation`;
- `layer_gate` opened or required;
- `depends_on`, including the prior layer gate;
- test ID, RED/GREEN command, owned files, and done condition;
- `status: planned | red | green | passed | not_affected | blocked`.

`plan.md` contains a **Development Sequence And Layer Gates** section. `tasks.md` follows that sequence. `workflow-routing.md` routes Gate 3 once per affected RED scope. `verification.md` records every layer gate as `passed` or `not_affected` before final validation.

When composition is affected, the plan also names the owning business module and its single DI entry point. C# records `Add<Module>Domain`, `Add<Module>Application`, `Add<Module>Infrastructure`, `Add<Module>Interface`, and `Add<Module>Module`; Go records the module `di` package, initializer/output, lifecycle cleanup, and executable-root aggregation.
