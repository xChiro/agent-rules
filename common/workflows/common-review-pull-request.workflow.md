---
workflow_id: WORKFLOW-COMMON_REVIEW_PULL_REQUEST_WORKFLOW
trigger: manual
description: "Review a pull request for correctness, business behavior, architecture boundaries, test quality, operations, and security."
---

# Common Review Pull Request Workflow

Use this workflow when reviewing a pull request, merge request, or local branch diff.

The review prioritizes defects, behavioral regressions, architecture boundary violations, missing tests, operational risk, and security exposure. Style comments are secondary unless they hide a real defect or maintenance cost.

## Phase 1: Frame The Change

Goal: understand the intended outcome before judging the implementation.

Checklist:

- Identify the PR goal, actor, business outcome, and affected bounded context.
- Read the changed files before forming findings.
- Locate the closest existing tests, use cases, adapters, handlers, configuration, and deployment files.
- Determine whether the change is domain, application, infrastructure, interface, frontend, CI, test-only, or documentation-only.
- State the main risk areas before listing findings when the review scope is broad.

## Phase 2: Review Behavior

Checklist:

- Verify the behavior matches the PR description and local domain language.
- Check happy path, edge cases, alternative flows, idempotency, authorization, duplicate keys, missing entities, and external dependency failures.
- Confirm invalid state is rejected at the correct boundary.
- Look for duplicated business rules, validation, mapping, permissions, and error decisions.
- Confirm technical failures are not treated as business rules.
- For frontend changes, verify loading, empty, error, disabled, and permission states when the flow exposes them.

## Phase 3: Review Architecture Boundaries

Checklist:

- Domain/application code stays free of transport, persistence, framework, environment, logging, queue, and cloud SDK dependencies.
- Use cases orchestrate behavior and own consumer-side ports.
- Ports are small, behavior-named, and owned near the consumer.
- Infrastructure implements ports and translates persistence, messaging, external APIs, and operational concerns.
- Interface adapters map transport DTOs, auth/session context, request parsing, response DTOs, and error status.
- Dependencies point inward.
- Controllers, handlers, workers, and adapters do not hide business rules.
- Reject broad repositories, unused extension points, speculative factories, unnecessary generics, and abstractions created only for style.

## Phase 4: Review Tests

Checklist:

- Behavior changes have tests that would fail without the production change.
- Backend behavior changes should reflect ATDD/TDD intent: actor-visible behavior first, then tests that prove the rule.
- Business logic tests assert observable rules and outcomes.
- Unit tests use real domain objects/value objects and small project-local fakes, stubs, or spies for outgoing ports.
- Integration tests cover real use-case execution through adapters, persistence mappings, messaging, transactions, dependency injection, routing, auth/session, and error mapping when those boundaries changed.
- Backend test suites are limited to `unit` and `integration`; HTTP/public-entry and Infrastructure are scopes of `integration`, not extra suites.
- Boundary integration tests cover request/message parsing, routing or worker mapping, authorization/session context, validation, response mapping, DI, persistence, and local-resource wiring when the public boundary changed.
- Go integration tests use `//go:build integration` when the repository follows the shared Go test rules.
- Flag new direct repository, adapter, handler, infrastructure, API, end-to-end, or Lambda integration suites as taxonomy violations.
- Missing tests are reported only when a realistic regression would not be caught.

## Phase 5: Review Operational And Security Risk

Checklist:

- Verify migrations, config, feature flags, environment variables, queues, topics, permissions, generated clients, and deployment manifests when affected.
- Check logging boundaries, duplicate logging, sensitive data exposure, retry behavior, cancellation, timeouts, and idempotency.
- For CI changes, confirm pull request jobs cannot deploy or access deployment credentials.
- For cloud changes, review IAM policy scope, public API exposure, CORS origins, cookie settings, JWT settings, OAuth redirect URLs, and secret references.
- For concurrency or background processing, check ownership, shutdown, retries, poison messages, and test coverage.

## Phase 6: Apply Language-Specific Review Lens

Checklist:

- For Go, verify `context.Context` use, error wrapping, `errors.Is/As`, goroutine ownership, cancellation, logging boundaries, `gofmt`, and race risk when shared state changed.
- For .NET, verify immutable value objects, explicit Application interfaces, constructor DI, EF/message/API boundary mapping, cancellation tokens on async I/O, and focused xUnit tests.
- For React, verify accessible UI states, controlled async behavior, component/service separation, URL state when relevant, and no backend-style architecture imposed by default.
- For CI/CD, verify pull request jobs cannot deploy, deployment jobs have explicit branch/environment gates, and secrets are not available to untrusted code.

## Phase 7: Produce Findings

Rules:

- Lead with actionable findings ordered by severity.
- Each finding includes file, line or narrow location, risk, and concrete fix direction.
- Do not list praise, summaries, or speculative concerns as findings.
- Prefer one clear finding over several comments for the same root cause.
- If no blocking issues are found, say that clearly and mention residual test or operational risk.

## Final Response

Use this structure:

1. Findings, ordered by severity.
2. Open questions or assumptions.
3. Short change summary only if it helps explain review scope.
4. Tests reviewed or commands run, when known.

Keep the review concise, direct, and grounded in the diff.
