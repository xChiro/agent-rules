---
rule_id: RULE-COMMON_ARCHITECTURE_GUARDRAILS
trigger: always_on
description: "Cross-language SDD, architecture, testing, review, and token-loading guardrails for agent work."
---

# Common Architecture Guardrails

Use this rule after `common-sdd-agentic-discipline.md`, `common-sdd-spec-structure.md`, and `common-workflow-taxonomy.md` when naming or workflow selection is part of the task. It keeps the agent focused on spec-driven behavior, explicit boundaries, and small reviewable changes without loading every file in the repository.

## Architecture Defaults

- Start from the requested business behavior and the actor-visible outcome.
- Create or update the owning User Story based spec before production code when behavior, contracts, architecture, or risk changes.
- Assign stable IDs for specs, artifacts, User Stories, requirements, scenarios, tasks, tracks, and tests.
- Classify every change with `common-change-risk-classification.md` before selecting gates; use the highest applicable risk level.
- Work one small `T-*` microtask at a time, with one outcome, done condition, verification command, and next step; update the spec before beginning another.
- At 60% consumed context, invoke `common-sdd-context-checkpoint.workflow.md` and leave an explicit resume handoff in the active spec before requesting a new context.
- For behavior or production-structure work, apply Gate 1 before spec writes, Gate 2 before RED/characterization evidence, and scoped Gate 3 before each affected layer Green/refactor, even when risk is low. L0 catalog/documentation-only work follows the L0 matrix and does not invent an SDD spec unless executable behavior emerges.
- Record BDD Given/When/Then acceptance scenarios for meaningful User Stories.
- Define `parallel-tracks.md` for every feature spec, including `max_parallel_agents`, track ownership, dependencies, and merge order.
- Mark every task with `track_id`, `parallelizable`, dependencies, `can_run_with`, ownership, and execution wave; generate exact task-to-agent assignments for parallel work.
- Keep domain and application logic free of frameworks, transport DTOs, persistence models, cloud SDKs, logging implementations, and environment configuration.
- Keep Domain and Application names provider-neutral and expressed in business language or consumer-owned capabilities. Do not use technology/provider names such as `Dynamo`, `DynamoDB`, `Cosmos`, `Cosmos DB`, `Kafka`, `SQS`, `SNS`, `Redis`, `PostgreSQL`, `EF`, `EF Core`, or `AWS` in Domain/Application file names, package/namespace names, types, interfaces, methods, fields, DTOs, events, or errors. Keep provider names in Infrastructure, Interface, or Composition adapters and their provider-specific mapping/configuration. For example, Application may own `EventPublisher` or `NotificationStore`, while Infrastructure may implement them as `KafkaEventPublisher` or `DynamoNotificationStore`.
- Use cases orchestrate behavior and own the consumer-side ports they need.
- Name use cases with an agent noun that expresses the capability and responsibility, such as `PartyCreator`, `MemberEnroller`, or `OrderCanceller`. Avoid verb-only or generic names such as `CreatePartyUseCase`, `PartyService`, `UseCase`, or `Handler`; the delivery adapter may use those technical names around the use case but must not rename its business responsibility.
- Use `party-creator` in human-facing slugs and `PartyCreator` in code identifiers; language-specific file naming follows the language convention (for Go, `party_creator.go`).
- Infrastructure implements ports and translates external systems into application concepts.
- Interface adapters handle request parsing, response mapping, authentication/session extraction, protocol errors, and transport-specific status codes.
- Dependencies point inward. Outer layers may depend on inner layers; inner layers do not know transport, persistence, messaging, or deployment details.
- Each business module owns its DI/composition contract. The executable root aggregates module entry points and host-wide concerns only; it does not register module internals individually.
- Production work follows `RULE-COMMON_INSIDE_OUT_DEVELOPMENT`: domain, application, infrastructure, delivery interface, then composition/IaC. Outer tasks wait for the application/core gate.
- Preserve CQRS separation where the project uses it: commands change state, queries read state, and projections are explicit.
- DTOs own the mapping functions for the external shape they represent. A persistence/DB DTO owns domain-to-schema and schema-to-domain mapping; an HTTP DTO owns transport-to-application and application-to-transport mapping; a message DTO owns message mapping.
- Keep DTO mapping functions colocated with the DTO type/module, named explicitly such as `FromDomain`, `ToDomain`, `FromRequest`, or `ToResponse`. Do not create a global mapper utility or unrelated mapper folder for a mapping owned by one DTO boundary.
- DTO mapping is structural translation only: it must not perform I/O, authorization, logging, orchestration, or new business decisions. Use domain constructors/value objects to enforce invariants and return mapping errors when external data is invalid.
- Domain and Application must not import persistence, transport, message, or generated DTOs. If a DTO is generated and cannot be edited, place its companion mapping functions in the same boundary module and document the generation constraint.
- Apply all five SOLID principles as mandatory checks: actor-based SRP, OCP only at real variation boundaries, LSP-compatible implementations, ISP through focused consumer-owned interfaces, and DIP from Domain/Application policy toward abstractions implemented by outer details. Do not add speculative abstractions or SOLID theater.
- Prefer explicit code over framework magic when the boundary is part of the business flow.
- Declare the security role for changed identity boundaries as `oauth-client`, `resource-server`, `identity-server`, or `none`; load `common-security-and-identity.md` for the protocol baseline.
- Use Authorization Code with PKCE for interactive OAuth flows, OIDC for user identity, server-side token validation for APIs, and no browser-accessible token storage.
- Authenticated web apps use server-managed `HttpOnly`, `Secure`, `SameSite` session cookies by default, with CSRF protection and explicit credentialed CORS.

## SDD Testing Defaults

- Use BDD first to specify abstract actor-visible acceptance before production code.
- Use inside-out TDD after acceptance framing: Domain Red/Green/Refactor, then Application Red/Green/Refactor.
- Show actual RED evidence and obtain Gate 3-DOMAIN or Gate 3-APPLICATION before that core scope's production code.
- After the core gate, create executable public-boundary RED when outer behavior changes and obtain Gate 3-BOUNDARY before outer production.
- Red: capture the next actor-visible business rule at the smallest owning layer.
- Do not edit production code until that unit-level test is written, has or maps to a `TEST-*` ID, and fails for the intended reason.
- Test code should read in ATDD style where practical: Given business context, When actor action/command/query, Then observable outcome.
- Green: implement only enough production code to pass that test.
- Refactor: improve naming, duplication, boundaries, and size while tests stay green.
- Backend repositories use two test folders/suites: `unit` and `integration`. Integration contains `http` and `infrastructure` scopes; these are not extra runtime suites.
- Every spec entering `verified` runs `common-sdd-coverage-gate.workflow.md`; when production code is in scope it requires `>= 90%` aggregate coverage across the project production scope, with no affected-scope regression.
- L2 non-trivial logic and every L3 change run `common-sdd-mutation-gate.workflow.md`; every L3 change also runs `common-sdd-critical-e2e.workflow.md`.
- Every spec entering `verified` runs `common-sdd-security-gate.workflow.md` and records `security-review.md`, including a no-impact review when `security_role: none`.
- Every spec entering `verified` runs `common-sdd-clean-up-gate.workflow.md` and records `code-quality-review.md` for every created or modified file.
- Unit tests cover domain/application rules and run without external infrastructure.
- Boundary integration tests enter through the real public mechanism for `integration/http`, or through the Application use case for `integration/infrastructure`; both cover real routing/use-case wiring, auth/session context when applicable, validation, response mapping, DI, persistence, schema, and local-resource behavior. HTTP integration is the public-entry specialization.
- Apply `common/rules/common-http-integration-harness.md` for resource setup, readiness, isolation, cleanup, diagnostics, and public-boundary evidence.
- Do not create separate repository, adapter, handler, API, end-to-end, or Lambda suites. Put HTTP/public-entry evidence in `integration/http` and real adapter/resource evidence in `integration/infrastructure`.
- A checked-in OpenAPI/schema compatibility check may be a static validation gate, but it is not a third runtime test suite.
- Name tests around behavior and observable outcomes, not implementation details.
- Apply `common-test-assertion-structure.md`: all assertion APIs belong in the test's `// Assert` section; setup/action helpers must return data or errors, never assert.
- Apply `common-test-data-and-double-patterns.md`: use fresh Object Mothers/Test Data Builders, focused SUT factories, scoped fixtures, and port-level doubles aligned with the test layer.
- Test code uses BDD `Given/When/Then` behavior naming and exact `// Arrange`, `// Act`, `// Assert` sections; `// Act` contains exactly one executable statement on one physical line, and that statement executes the layer-appropriate SUT/use case/public boundary.
- Apply `common-test-layer-isolation.md`: Domain, Application, and Boundary commands each run alone from clean state; production dependency direction never becomes test-execution dependency.
- Add or update tests when a realistic regression would otherwise pass unnoticed.
- For pure refactors, add or identify characterization tests before restructuring.

## Parallel Work Defaults

- Default to one active agent per spec.
- Allow multiple agents only when `parallel-tracks.md` assigns independent tasks and files/modules/spec sections.
- Do not overlap edits to the same file, public contract, migration, generated artifact, or spec section.
- Merge tracks sequentially and rerun the affected acceptance, unit, HTTP integration, and architecture checks after each merge.
- If ownership conflicts emerge, reduce concurrency and update the spec before continuing.

## Cross-Cutting Patterns

- Use decorators only for current operational concerns around an existing use case or port: metrics, tracing, auditing, idempotency, retries, transactions, or caching.
- A decorator must preserve the same business contract as the wrapped component.
- Keep business rules in the inner use case/domain, not in decorators.
- Keep decorator order explicit in the composition root or dependency injection module.
- Do not add generic pipelines, mediator layers, factories, or extension points for hypothetical future behavior.

## Review Defaults

- Prioritize correctness, behavioral regressions, architecture boundary violations, missing meaningful tests, operational risk, and security exposure.
- Report findings with file/location, risk, and concrete fix direction.
- Avoid broad refactors unless they are part of the verified spec or directly reduce risk in the requested change.
- Refactor only with relevant tests green and update spec/plan/docs when structure or boundaries change.
- Preserve local project conventions unless the task explicitly asks to standardize them.

## Instruction Precedence And Conflict Resolution

- Treat the installed global rules as the compact bootstrap, then load one primary workflow and only the rules selected by the task's phase, language, and boundary.
- Common mandatory lifecycle, security, test-isolation, and inward-dependency rules are the policy floor. A project-local rule may be more specific or stricter, but it cannot silently relax that floor.
- Language rules specialize common rules; focused REST, persistence, messaging, CI, or test rules specialize only their touched boundary. They must not redefine the common lifecycle or test taxonomy.
- When equally authoritative instructions conflict, cite both files and the exact conflict during read-only planning. Do not merge them into an invented rule or continue mutation until the conflict is resolved.
- Follow the narrowest applicable instruction when it is compatible with all broader mandatory rules.

## Token Loading

- Start from the compact global rules and load exactly one primary workflow. Do not load supporting workflows until their phase or boundary is reached.
- Load `common-sdd-agentic-discipline.md` first for behavior-changing work.
- Load `common-sdd-spec-structure.md` when creating or changing specs.
- Load `common-workflow-taxonomy.md` when creating, renaming, or reviewing rules, skills, workflows, or style artifact IDs.
- Load `common-security-and-identity.md` and `common-sdd-security-gate.workflow.md` for every security, identity, cookie, secret, REST auth, browser session, CI credential, or public exposure change.
- Load `common-code-quality-guardrails.md` and `common-sdd-clean-up-gate.workflow.md` for final naming, file-size, Clean Code, architecture, complexity, duplication, or refactor review.
- Load `common-test-assertion-structure.md`, `common-test-data-and-double-patterns.md`, and `common-test-layer-isolation.md` for every unit, HTTP integration, message/component, or acceptance-support test change.
- Load `common-context-continuity.md` for multi-step work, long investigations, or any task approaching the context checkpoint threshold.
- Load this file for cross-language architecture or review work.
- Load one active-language senior baseline, then add only the language rules selected by the task's `work_type` or changed boundary.
- Add focused rules only for the touched boundary, such as REST API, EF Core, messaging, dependency injection, or test suites.
- Do not reload a common lifecycle section merely because a language rule repeats or references it; the common rule remains canonical.
- Do not load all rules, workflows, and skills by default.
