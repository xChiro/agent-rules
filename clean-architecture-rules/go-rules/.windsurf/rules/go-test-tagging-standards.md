---
trigger: always_on
description: Go test tagging standards for unit, integration, and e2e test suites
globs: **/*_test.go
---

# Go Test Tagging Standards

Use consistent test categories so local runs and CI can choose the right test scope.

## Recommended Tags

- **unit**: Fast domain/application tests with no external infrastructure. Do not require a Go build tag by default.
- **integration**: Tests against real infrastructure or real adapters. Must use `//go:build integration`.
- **e2e**: End-to-end tests through transport/handler boundaries with real wiring and infrastructure. Must use `//go:build e2e`.

Keep `e2e` as the tag name. It is short, common, valid for Go build tags, and clear in CI commands. Use `contract` only for API/provider-consumer contract tests that are not full end-to-end flows.

## Unit Tests

Unit tests should run with the default command:

```bash
go test ./...
```

Do not add `//go:build unit` to unit tests unless the repository has intentionally configured all test suites around build tags. Requiring `unit` tags by default makes normal Go workflows skip unit tests accidentally.

Use path and file organization to identify unit tests:

```text
tests/{domain}/domain/...
tests/{domain}/application/{use_case}/...
```

## Integration Test Tag

Integration test files must start with:

```go
//go:build integration

package orders_test
```

Run integration tests with:

```bash
go test -v -tags=integration ./tests/...
```

## E2E Test Tag

E2E test files must start with:

```go
//go:build e2e

package orders_test
```

Run e2e tests with:

```bash
go test -v -tags=e2e ./tests/end2end/...
```

## Combined Test Runs

Use combined tags when CI intentionally runs multiple non-default suites:

```bash
go test -v -tags="integration e2e" ./...
```

## Rules

- Every integration test file must include `//go:build integration`.
- Every e2e test file must include `//go:build e2e`.
- Build tags must be the first non-blank line before the package declaration.
- Do not mix `integration` and `e2e` in the same test file.
- Keep unit tests fast, deterministic, and runnable without tags.
- Document CI commands when adding a new tagged test suite.
