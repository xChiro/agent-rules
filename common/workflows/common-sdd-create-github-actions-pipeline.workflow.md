---
workflow_id: WORKFLOW-COMMON_SDD_CREATE_GITHUB_ACTIONS_PIPELINE_WORKFLOW
trigger: manual
description: Create SDD-aligned GitHub Actions pipelines with only unit and HTTP integration test suites and explicit service profiles.
---

# Common Create GitHub Actions Pipeline Workflow

Use this workflow to create or change CI/CD. Pipeline behavior is versioned behavior: show the read-only SDD plan and obtain Gate 1 before spec writes, create/evolve BDD acceptance expectations, obtain Gate 2 before RED, obtain Gate 3 after RED evidence, and record validation in `verification.md`.

## Canonical Backend Test Jobs

Backend pipelines have exactly two test jobs:

1. `unit-tests`: fast domain/application tests with no external infrastructure.
2. `http-integration-tests`: real HTTP requests through server or API Gateway/Lambda wiring into local databases and resources.

Do not create separate `integration-tests`, `api-integration-tests`, `repository-tests`, `adapter-tests`, `handler-tests`, or `end-to-end-tests` jobs. Migrate their useful scenarios into `http-integration-tests`; keep business-rule combinations in `unit-tests`.

Build, lint, format, typecheck, architecture validation, security scanning, template validation, packaging, and deploy may remain as non-test jobs or steps when the repository requires them.

## Phase 1: Discover Real Commands

- Read existing workflows, build files, scripts, Docker Compose/Testcontainers setup, SAM/IaC templates, and deployment docs.
- Load the applicable language/service profile. For Go/SAM, load `go-sam-github-actions.md`.
- Locate the actual unit and HTTP integration test commands; do not invent paths.
- List local dependencies, readiness commands, migrations/table setup, seed data, dummy credentials, and cleanup.
- Identify whether HTTP integration runs a normal server, `sam local start-api`, or another local API Gateway emulator.
- Identify branches, GitHub environments, OIDC roles, variables, artifacts, and deployment targets.
- Preserve discovered service-specific commands, local table/resource setup, artifact paths, branch conditions, environment variables, and deploy dependencies in the generated workflow and `verification.md`.

## Phase 2: Pull Request Validation

- Trigger on pull requests to the repository's integration and production branches.
- Default to `permissions: contents: read` and `persist-credentials: false`.
- Use concurrency by workflow/ref with `cancel-in-progress: true`.
- Never expose deployment credentials or secrets to pull request code.
- Run `tools/validate-sdd-change.sh` as the read-only `sdd-policy` check before merge protection evaluates the pull request.
- Run `unit-tests`.
- Start isolated local resources and run `http-integration-tests`.
- Run the risk-selected `sdd-mutation` quality gate for L2 non-trivial logic and every L3 change; keep it separate from the two canonical backend runtime suites.
- Run the risk-selected `sdd-critical-e2e` quality gate for L3 journeys through the real browser or public boundary.
- Run the mandatory project-wide coverage gate for every completed spec with production code; fail below `90%` and if the affected scope regresses from the accepted baseline.
- Build/package only when HTTP integration or artifact validation requires it.
- Use dummy cloud credentials and localhost endpoints.

## Phase 3: Unit Tests

- Use the repository's fast default unit command.
- Do not start databases, queues, cloud emulators, or HTTP servers.
- Preserve focused unit coverage for domain/application code.
- For the coverage gate, generate coverage with the repository's native command across the complete project production scope, enforce `>= 90%` when production code is in scope, and upload only safe reports when useful. Report affected-scope baseline/current coverage separately.

Examples, only when they match the repository:

```text
Go:   go test ./...
.NET: dotnet test <UnitTests project or solution filter>
```

## Phase 4: HTTP Integration Tests

The job must:

1. Start local databases/resources or faithful emulators.
2. Wait with bounded readiness checks.
3. Apply production-equivalent migrations/tables/schema.
4. Build the service when required.
5. Start the real local HTTP boundary.
6. Seed minimal isolated data.
7. Send real HTTP requests.
8. Run cleanup and capture safe diagnostics on failure.

For Go:

- Use `//go:build integration` and the repository's `go test -tags=integration` HTTP suite.
- Prefer `tests/http/...` for new suites.

For .NET:

- Run the dedicated `HttpIntegrationTests` project or coherent local equivalent.
- Use `HttpClient` against `WebApplicationFactory`, a hosted local API, or the Lambda HTTP emulator.

For SAM/Lambda:

- Run `sam validate` and `sam build` when needed.
- Start `sam local start-api` with test-safe environment values.
- Wait for its HTTP endpoint before running tests.
- Use DynamoDB Local, LocalStack, containers, or the repository's established local resources.
- Do not invoke handlers directly as the integration gate.

## Phase 5: Deployment

- Deploy only on the repository's environment branch pushes or explicit dispatch.
- Use GitHub `environment` protection for staging and production.
- Grant `id-token: write` only to jobs that assume cloud roles.
- Prefer OIDC over long-lived keys.
- Require both `unit-tests` and `http-integration-tests` before deploy.
- Package or reuse the exact validated artifact when practical.
- Keep post-deploy health checks separate from the two test suites; they are operational smoke checks, not another integration suite.

## Security Boundaries

- Never use `pull_request_target` to execute untrusted code with secrets.
- Keep secrets out of global env, matrices, outputs, cache keys, artifacts, logs, screenshots, generated config, and PR comments.
- Pass secrets at the narrowest step scope and mask derived sensitive values.
- Pin untrusted third-party actions to full commit SHAs.
- Avoid privileged containers, broad Docker socket mounts, and public local-service bindings without a documented need.
- Use least-privilege deployment roles and separate staging/production environments.

## Migration Rules

- Merge old infrastructure and API integration jobs into `http-integration-tests`.
- Move direct adapter/repository assertions to unit tests when they express business behavior, or cover the risk through HTTP when they express wiring/persistence behavior.
- Remove obsolete tags, duplicate setup, duplicate coverage uploads, and deploy dependencies on deleted jobs.
- Update branch protection required-check names after job renames.
- Do not replace a service profile with generic placeholders. Generic rules define the contract; the generated repository workflow keeps its concrete commands and paths.

## Verification

- Validate YAML and action expressions with the repository's existing checker.
- Confirm PRs cannot deploy or assume cloud roles.
- Confirm `unit-tests` runs without infrastructure.
- Confirm the project-wide coverage total is `>= 90%` for every completed spec with production code and the affected scope does not regress.
- Confirm `sdd-policy` runs on every pull request and fails when required SDD artifacts or risk evidence are missing.
- Confirm `sdd-mutation` and `sdd-critical-e2e` are required only at their classified risk levels and block merge when their evidence fails.
- Confirm `http-integration-tests` enters through HTTP and reaches local resources.
- Confirm deploy depends on both canonical test jobs.
- Record commands, local services, required variables/secrets, job names, and manual GitHub settings in `verification.md` and the final report.
