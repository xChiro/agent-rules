---
rule_id: RULE-GO_SAM_GITHUB_ACTIONS
trigger: model_decision
description: Go and AWS SAM GitHub Actions profile for local HTTP integration, artifacts, and protected deployment gates.
globs: .github/workflows/**/*.yml,.github/workflows/**/*.yaml,template.yaml,samconfig.toml
---

# Go SAM GitHub Actions Profile

Load this profile with `common-sdd-create-github-actions-pipeline.workflow.md` when a Go service uses AWS SAM, API Gateway/Lambda, DynamoDB Local, LocalStack, or equivalent local AWS resources.

## Required Jobs

Keep the common backend jobs:

- `unit-tests`: `go test` without integration tags and without local infrastructure.
- `http-integration-tests`: `go test -tags=integration` through the local HTTP boundary.
- Coverage gate: run the native Go coverage command for the complete project production scope and fail below `90%`; also fail if the affected scope regresses.

Build, package, deploy, and smoke jobs are controls around those suites, not additional runtime test suites.

## Local HTTP Job

The job must:

1. Check out the repository and install the pinned Go and SAM CLI versions.
2. Start the repository's local resources, normally DynamoDB Local, LocalStack, containers, or Docker Compose.
3. Wait for each endpoint with bounded readiness checks.
4. Create or migrate tables using the repository's setup script or SAM/IaC definition.
5. Build with `sam build` when the local API requires the SAM artifact.
6. Start `sam local start-api` or the repository's equivalent local HTTP boundary.
7. Run the HTTP suite with test-safe environment values and dummy credentials.
8. Upload safe SAM build/log artifacts on failure and always clean up services.
9. Record coverage command, scope, percentage, exclusions, and report path in `verification.md`.

Use the actual repository commands and paths. Do not invent `tests/end2end`, notification-specific packages, table names, or environment variables.

## Artifact And Deploy Rules

- Deploy only from protected environment branches or explicit approved dispatch.
- Require both `unit-tests` and `http-integration-tests` before packaging/deploy.
- Reuse the exact validated SAM build artifact when practical.
- Use GitHub environments and OIDC with `id-token: write` only on the role-assuming job.
- Keep AWS credentials and deployment secrets away from pull request code.
- Run post-deploy health checks as operational smoke checks.

## Migration From Historical Pipelines

When an existing pipeline has separate `test-integration` or `test-e2e` jobs, move their public HTTP scenarios, local resource setup, table creation, and diagnostics into `http-integration-tests`. Preserve service-specific commands, artifacts, branch conditions, environment variables, and deployment dependencies in the generated repository workflow and `verification.md`.
