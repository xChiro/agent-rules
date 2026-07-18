# ADR-0001: Backend Executable Integration Boundary

- Status: Accepted
- Date: 2026-07-10
- Scope: Go and C# backend test workflows and GitHub Actions pipelines

## Context

The repository previously described separate infrastructure integration, API integration, handler E2E, persistence adapter, and other runtime test workflows. Those workflows duplicated setup and made it unclear which test proved the public behavior. The desired backend model is ATDD-first SDD with focused unit tests and one real boundary suite.

## Decision

Backend repositories use exactly two runtime test folders/suites:

1. `unit`: domain/application behavior without external infrastructure.
2. `integration`: executable integration evidence, organized into `http/` and `infrastructure/` scopes.

The integration suite absorbs public scenarios and infrastructure wiring previously described as E2E, API, message, handler, repository, adapter, or infrastructure integration tests. For compatibility, `integration/http` is the canonical public-entry scope path: HTTP systems send a real request, while message/worker/CLI systems use their equivalent real entry and call the result a boundary integration test rather than an HTTP test. `integration/infrastructure` starts from the Application use case and exercises the real application port, adapter, and local persistence/messaging/storage resource. Both scopes use Docker/Testcontainers or faithful local emulators, production-equivalent schema/migrations, isolated data, and deterministic cleanup. Third-party APIs are replaced by controlled simulators such as WireMock or small hand-written HTTP stubs; this is boundary simulation, not a unit-test mock.

Build, lint, architecture, schema, security, package, deploy, and post-deploy smoke checks remain valid CI controls but are not additional runtime test suites.

## Consequences

- Business rules remain fast and precise in unit tests.
- Public wiring, persistence mapping, local resource behavior, and HTTP/message translation are proven through the integration suite.
- HTTP scope enters through the public boundary; infrastructure scope enters through the use case and exercises the real adapter with a real local resource. Neither scope may replace an owned local resource with a mock.
- Historical E2E and infrastructure workflows are represented by the appropriate integration scope and work type `boundary-integration-test`.
- Existing service-specific setup, commands, artifacts, and deployment conditions must be retained in a service or language CI profile.

## Verification

- `common-http-integration-harness.md` defines the HTTP scope; the integration infrastructure contract covers real local resources and controlled third-party simulators.
- Go and C# boundary rules adapt the contract to their test runners and entry mechanisms.
- GitHub Actions uses `unit-tests` and `integration-tests` as the canonical backend jobs.
- Any exception requires a new ADR or an explicit feature-spec decision.
