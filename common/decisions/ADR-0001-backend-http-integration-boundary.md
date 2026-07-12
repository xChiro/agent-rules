# ADR-0001: Backend HTTP Integration Boundary

- Status: Accepted
- Date: 2026-07-10
- Scope: Go and C# backend test workflows and GitHub Actions pipelines

## Context

The repository previously described separate infrastructure integration, API integration, handler E2E, persistence adapter, and other runtime test workflows. Those workflows duplicated setup and made it unclear which test proved the public behavior. The desired backend model is ATDD-first SDD with focused unit tests and one real boundary suite.

## Decision

Backend repositories use exactly two runtime test suites:

1. `unit`: domain/application behavior without external infrastructure.
2. `http-integration`: real HTTP through the server or API Gateway/Lambda boundary into local databases and resources.

The HTTP suite absorbs the public scenarios and infrastructure wiring previously described as E2E, API, handler, repository, adapter, or infrastructure integration tests. It must use the real composition root, local resources or faithful emulators, production-equivalent schema/migrations, isolated data, and deterministic cleanup.

Build, lint, architecture, schema, security, package, deploy, and post-deploy smoke checks remain valid CI controls but are not additional runtime test suites.

## Consequences

- Business rules remain fast and precise in unit tests.
- Public wiring, persistence mapping, local resource behavior, and Lambda/API Gateway translation are proven through HTTP.
- Direct handler, Lambda, repository, DbContext, or adapter calls are not HTTP integration evidence.
- Historical E2E and infrastructure workflows are represented by the common HTTP harness and work type `http-integration-test`.
- Existing service-specific setup, commands, artifacts, and deployment conditions must be retained in a service or language CI profile.

## Verification

- `common-http-integration-harness.md` defines the shared setup, isolation, evidence, and cleanup contract.
- Go and C# HTTP integration rules adapt the contract to their test runners.
- GitHub Actions uses `unit-tests` and `http-integration-tests` as the canonical backend jobs.
- Any exception requires a new ADR or an explicit feature-spec decision.
