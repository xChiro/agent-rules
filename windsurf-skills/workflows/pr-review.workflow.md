---
trigger: manual
description: Review a pull request using Clean Architecture, DDD, CQRS, value objects, and TDD standards.
---

# PR Review Workflow

Use this workflow whenever reviewing a pull request, merge request, or local branch diff.

The review prioritizes correctness, business behavior, architecture boundaries, test quality, and maintainability. Style comments are secondary unless they hide a defect or create real maintenance cost.

## 1. Read and Frame

- Identify the PR goal, actor, bounded context, use case, and business outcome.
- Read the changed files before judging the design.
- Locate the closest existing tests, use cases, ports, value objects, adapters, handlers, and wiring.
- Determine whether the change is domain, application, infrastructure, interface, test-only, or documentation-only.
- State the main risk areas before listing findings.

## 2. Review Behavior

- Verify the changed behavior matches the PR description and existing domain language.
- Check happy path, edge cases, alternative flows, idempotency, authorization, duplicate keys, missing entities, and external dependency failures.
- Confirm invalid state is rejected at the boundary through value objects, entities, or explicit use case validation.
- Look for duplicated business rules, validation, mapping, permissions, and error decisions.
- Check that technical failures are not treated as business rules.

## 3. Review Architecture Boundaries

- Domain code must stay pure: no transport, persistence, framework, environment, logging, queue, or cloud SDK dependencies.
- Application use cases should orchestrate behavior and own consumer-side ports.
- Ports should be small, behavior-named, and owned near the consumer.
- Infrastructure should implement ports and translate persistence, messaging, external APIs, and operational concerns.
- Interface adapters should map transport DTOs, auth/session context, request parsing, response DTOs, and error status.
- Dependencies must point inward; handlers and adapters must not leak into domain/application code.
- Reject broad repositories, unused extension points, premature factories, unnecessary generics, and abstractions created only for style.

## 4. Review Tests

- Confirm behavior changes have tests that would fail without the production change.
- Tests should describe business rules in Given-When-Then form.
- Unit tests should use real domain objects/value objects and fake outgoing ports; do not mock domain objects.
- Integration tests should cover real adapters, persistence mappings, messaging, transactions, DI, routing, auth/session, and error mapping when those boundaries changed.
- Go integration tests must use `//go:build integration`; end-to-end tests must use `//go:build e2e`.
- Check that tests assert observable outcomes, persisted calls, emitted events, returned errors, and response mapping where relevant.
- Identify missing edge case coverage instead of asking for broad, unfocused coverage.

## 5. Review Operational and Language Risks

- For Go, verify `context.Context` use, error wrapping, `errors.Is/As`, goroutine ownership, cancellation, logging boundaries, and `gofmt`.
- For .NET, verify immutable value objects, explicit interfaces, constructor DI, service registration, EF/message/API boundary mapping, and focused xUnit tests.
- Check migrations, config, environment variables, feature flags, queues, topics, permissions, and generated DI files when affected.
- Look for concurrency, caching, background processing, worker pools, reflection, and advanced patterns without a current trigger or tests.

## 6. Produce Findings

- Lead with actionable findings ordered by severity.
- Each finding must include the file, line or narrow location, risk, and concrete fix direction.
- Do not list praise, summaries, or speculative concerns as findings.
- Prefer one clear finding over several comments for the same root cause.
- Mark missing tests as findings only when a realistic regression would not be caught.
- If no blocking issues are found, say that clearly and mention any residual test or operational risk.

## 7. Final Review Response

Use this structure:

1. Findings, ordered by severity.
2. Open questions or assumptions.
3. Short change summary only if it helps explain the review scope.
4. Tests reviewed or commands run, when known.

Keep the review concise, direct, and grounded in the diff.
