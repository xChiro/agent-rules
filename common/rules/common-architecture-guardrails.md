---
rule_id: RULE-COMMON_ARCHITECTURE_GUARDRAILS
trigger: always_on
description: Cross-language SDD, architecture, testing, review, and token-loading guardrails for agent work.
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
- Apply mandatory Gate 1 before spec writes, Gate 2 before RED, and Gate 3 before Green, even for simple or low-risk changes.
- Record BDD Given/When/Then acceptance scenarios for meaningful User Stories.
- Define `parallel-tracks.md` for every feature spec, including `max_parallel_agents`, track ownership, dependencies, and merge order.
- Mark every task with `track_id`, `parallelizable`, dependencies, `can_run_with`, ownership, and execution wave; generate exact task-to-agent assignments for parallel work.
- Keep domain and application logic free of frameworks, transport DTOs, persistence models, cloud SDKs, logging implementations, and environment configuration.
- Use cases orchestrate behavior and own the consumer-side ports they need.
- Infrastructure implements ports and translates external systems into application concepts.
- Interface adapters handle request parsing, response mapping, authentication/session extraction, protocol errors, and transport-specific status codes.
- Dependencies point inward. Outer layers may depend on inner layers; inner layers do not know transport, persistence, messaging, or deployment details.
- Preserve CQRS separation where the project uses it: commands change state, queries read state, and projections are explicit.
- DTOs own the mapping functions for the external shape they represent. A persistence/DB DTO owns domain-to-schema and schema-to-domain mapping; an HTTP DTO owns transport-to-application and application-to-transport mapping; a message DTO owns message mapping.
- Keep DTO mapping functions colocated with the DTO type/module, named explicitly such as `FromDomain`, `ToDomain`, `FromRequest`, or `ToResponse`. Do not create a global mapper utility or unrelated mapper folder for a mapping owned by one DTO boundary.
- DTO mapping is structural translation only: it must not perform I/O, authorization, logging, orchestration, or new business decisions. Use domain constructors/value objects to enforce invariants and return mapping errors when external data is invalid.
- Domain and Application must not import persistence, transport, message, or generated DTOs. If a DTO is generated and cannot be edited, place its companion mapping functions in the same boundary module and document the generation constraint.
- Apply SOLID pragmatically: small responsibilities, consumer-owned interfaces, substitutable adapters, and inverted dependencies at boundaries.
- Prefer explicit code over framework magic when the boundary is part of the business flow.
- Declare the security role for changed identity boundaries as `oauth-client`, `resource-server`, `identity-server`, or `none`; load `common-security-and-identity.md` for the protocol baseline.
- Use Authorization Code with PKCE for interactive OAuth flows, OIDC for user identity, server-side token validation for APIs, and no browser-accessible token storage.
- Authenticated web apps use server-managed `HttpOnly`, `Secure`, `SameSite` session cookies by default, with CSRF protection and explicit credentialed CORS.

## SDD Testing Defaults

- Use ATDD first: write or update acceptance evidence before production code.
- Confirm acceptance evidence fails for the intended reason before implementation.
- Show the actual acceptance and focused unit-level RED evidence and obtain Gate 3 approval before implementation.
- Use TDD as the implementation loop after acceptance framing: Red, Green, Refactor.
- Red: capture the next actor-visible business rule with the smallest failing unit/component/domain/application test.
- Do not edit production code until that unit-level test is written, has or maps to a `TEST-*` ID, and fails for the intended reason.
- Test code should read in ATDD style where practical: Given business context, When actor action/command/query, Then observable outcome.
- Green: implement only enough production code to pass that test.
- Refactor: improve naming, duplication, boundaries, and size while tests stay green.
- Backend repositories use two suites: unit tests and HTTP integration tests.
- Every completed spec runs `common-sdd-coverage-gate.workflow.md`; when production code is in scope it requires `>= 90%` aggregate coverage across the complete project production scope, with no affected-scope regression.
- L2 non-trivial logic and every L3 change run `common-sdd-mutation-gate.workflow.md`; L3 critical journeys run `common-sdd-critical-e2e.workflow.md`.
- Every completed spec runs `common-sdd-security-gate.workflow.md` and records `security-review.md`, including a no-impact review when `security_role: none`.
- Every completed spec runs `common-sdd-clean-up-gate.workflow.md` and records `code-quality-review.md` for every created or modified file.
- Unit tests cover domain/application rules and run without external infrastructure.
- HTTP integration tests enter through the real server or API Gateway/Lambda HTTP boundary and cover routing, auth/session context, validation, response mapping, DI, persistence, schema, and local-resource wiring.
- Apply `common/rules/common-http-integration-harness.md` for resource setup, readiness, isolation, cleanup, diagnostics, and public-boundary evidence.
- Do not create separate repository, adapter, handler, infrastructure, API, end-to-end, or Lambda integration suites.
- A checked-in OpenAPI/schema compatibility check may be a static validation gate, but it is not a third runtime test suite.
- Name tests around behavior and observable outcomes, not implementation details.
- Apply `common-test-assertion-structure.md`: all assertion APIs belong in the test's `Then/Assert` section; setup/action helpers must return data or errors, never assert.
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

## Token Loading

- Load `common-sdd-agentic-discipline.md` first for behavior-changing work.
- Load `common-sdd-spec-structure.md` when creating or changing specs.
- Load `common-workflow-taxonomy.md` when creating, renaming, or reviewing rules, skills, workflows, or style artifact IDs.
- Load `common-security-and-identity.md` and `common-sdd-security-gate.workflow.md` for every security, identity, cookie, secret, REST auth, browser session, CI credential, or public exposure change.
- Load `common-code-quality-guardrails.md` and `common-sdd-clean-up-gate.workflow.md` for final naming, file-size, Clean Code, architecture, complexity, duplication, or refactor review.
- Load `common-test-assertion-structure.md` for every unit, HTTP integration, component, or acceptance-support test change.
- Load `common-context-continuity.md` for multi-step work, long investigations, or any task approaching the context checkpoint threshold.
- Load this file for cross-language architecture or review work.
- Add one language rule set only when code or examples require language-specific guidance.
- Add focused rules only for the touched boundary, such as REST API, EF Core, messaging, dependency injection, or test suites.
- Do not load all rules, workflows, and skills by default.
