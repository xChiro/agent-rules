---
rule_id: RULE-GO_TEST_SUITES
trigger: always_on
description: Go backend suite taxonomy with only unit and HTTP integration tests.
globs: **/*_test.go
---

# Go Test Suites

All tests follow `common-test-assertion-structure.md`: arrange/setup, act/request, then one final assertion section.

## Two Suites Only

Go backends use:

- `unit`: fast domain/application behavior with no external infrastructure; runs by default.
- `http-integration`: real HTTP through server or API Gateway/Lambda wiring into local resources; uses the `integration` build tag.

Do not create separate infrastructure, repository, adapter, handler, API, end-to-end, or Lambda integration categories.

## Unit Tests

- Do not add a build tag unless the repository has an intentional existing convention.
- Run with the repository's normal command, typically `go test ./...`.
- Keep them deterministic and independent from network, database, filesystem, clock, cloud SDK, and environment state.
- Use focused fakes/spies only for outgoing ports.
- Trace changed behavior with `TEST-*` IDs.

## HTTP Integration Tests

- Location: `tests/http/<context>/` or a coherent existing equivalent.
- Filename: `*_http_integration_test.go`.
- First non-blank line: `//go:build integration`.
- Enter through real HTTP, never direct handler/function/adapter calls.
- Use the real composition root and local infrastructure.
- Run with `go test -v -tags=integration ./tests/http/...` or the repository's documented equivalent.

## CI Contract

The canonical test jobs are `unit-tests` and `http-integration-tests`. A build, lint, architecture, package, security, deploy, or smoke job is not a third test suite.
