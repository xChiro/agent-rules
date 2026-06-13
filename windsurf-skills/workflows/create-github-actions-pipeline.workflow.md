---
trigger: manual
description: Create or update HBK GitHub Actions pipelines using the identity-service pattern with GitFlow-safe PR checks and environment deploys.
---

# Create GitHub Actions Pipeline Workflow

Use this workflow when creating or refactoring GitHub Actions pipelines for HBK repositories.

The baseline pattern comes from `hbk-identity-service`: Go tests, DynamoDB Local integration setup, SAM build artifacts, AWS OIDC deployment roles, staging and production environments, and explicit deploy gates. Improve that pattern by separating PR review checks from build/deploy work.

## 1. Read the Repository Shape

- Identify whether the repository is Go/SAM Lambda, shared SAM infrastructure, React/Azure Static Web App, static web page, or another shape.
- Read existing `.github/workflows`, `go.mod`, `Makefile`, `template.yaml`, `samconfig.toml`, `docker-compose.test.yml`, package scripts, and deployment docs before writing YAML.
- Locate test directories and commands instead of assuming standard paths.
- Identify local infrastructure needed for tests: DynamoDB Local, LocalStack, seeded tables, queues, topics, or service-specific scripts.
- List required secrets, repository variables, GitHub environments, deployment buckets, stack names, and cloud roles before editing the pipeline.

## 2. Use GitFlow Branch Rules

- `main` is production.
- `staging` is staging.
- Feature, fix, and task branches open pull requests into `staging`.
- Release or hotfix branches may open pull requests into `main` when production promotion is needed.
- PR workflows must run on pull requests targeting `staging` and `main`.
- Deploy workflows must run only on pushes to their target branch and explicit `workflow_dispatch`.
- Never deploy from `pull_request` events.

## 3. Split PR Review from Deploy

Create a dedicated PR review workflow, normally `.github/workflows/pr-review.yml`.

The PR review workflow should:

- Trigger on `pull_request` to `staging` and `main`.
- Use `permissions: contents: read`.
- Use concurrency by workflow and PR ref, with `cancel-in-progress: true`.
- Checkout with `actions/checkout@v4`, `fetch-depth: 1`, and `persist-credentials: false`.
- Install only the toolchain required for tests.
- Download dependencies.
- Run unit tests.
- Start local infrastructure only when integration tests need it.
- Run integration tests with local endpoints and dummy AWS credentials.
- Run end-to-end tests only when they do not require deploy artifacts, cloud deploy, or production-like credentials.
- Upload test artifacts only when the repo already produces useful reports.

The PR review workflow must not:

- Run `sam build`.
- Upload SAM build artifacts.
- Configure cloud deployment credentials.
- Assume AWS/Azure deployment roles.
- Deploy stacks, static apps, functions, or infrastructure.
- Run production smoke tests against deployed URLs.

## 4. Create Environment Deploy Workflows

Prefer separate deploy workflows when the repository already uses split files:

- `.github/workflows/deploy-stg.yml` for pushes to `staging`.
- `.github/workflows/deploy-prod.yml` for pushes to `main`.

Use one deploy workflow only when the repository already has that convention and the branch conditions are explicit.

Deploy workflows should:

- Trigger on `push` to one environment branch and `workflow_dispatch`.
- Use GitHub `environment` names: `staging` and `production`.
- Set `permissions` narrowly: `id-token: write` and `contents: read` only when OIDC is required.
- Use `concurrency` per workflow and ref.
- Run unit and integration tests before build/deploy, or depend on a reusable test job in the same workflow.
- Run `sam build` only in deploy workflows for SAM services.
- Upload build artifacts with short retention only when deploy jobs need cross-job artifacts.
- Configure AWS with `aws-actions/configure-aws-credentials@v4` and `role-to-assume` secrets, not long-lived access keys, when the account supports OIDC.
- Verify caller identity with `aws sts get-caller-identity` before deploy.
- Deploy with environment-specific stack names, config envs, S3 buckets, parameters, and secrets.
- Run smoke tests only after production deploy when the service has a stable public health or root endpoint.

## 5. Go/SAM Service Pattern

For Go Lambda services using SAM:

- Use `actions/setup-go@v5` with `go-version-file: go.mod` when possible. Use an explicit version only when the repository requires it.
- Enable Go module cache.
- Run `go mod download` before tests.
- Unit tests should use the repo's fast command, for example `make test` or `go test -v ./tests/unit_tests/...`.
- Integration tests should use `//go:build integration` and run with `-tags=integration`.
- End-to-end tests should use `//go:build e2e` and run with `-tags=e2e`.
- Start DynamoDB Local with the repository's existing `docker-compose.test.yml` or documented Docker command.
- Wait for local infrastructure with a bounded loop and fail clearly if it never becomes ready.
- Create tables and seed data through existing scripts.
- Always clean up Docker containers in `if: always()` steps when containers are started directly.

## 6. Shared Infrastructure Pattern

For infrastructure-only SAM repositories:

- Do not create fake test jobs when no tests exist.
- Add validation steps before deploy when useful: `sam validate`, template linting, or policy checks already supported by the repo.
- Keep staging and production deploy workflows separated by branch and environment.
- Keep deployment bucket creation idempotent when the repo already owns that bucket.
- Do not run PR deploys for infrastructure changes.

## 7. React or Static Web Pattern

For React and static web repositories:

- Create PR review checks that install dependencies and run available checks: typecheck, lint, unit tests, and build only if build is the project's validation step and does not deploy.
- Keep Azure Static Web App deploy workflows restricted to pushes to `staging` or `main`, plus `workflow_dispatch` when needed.
- Do not use Azure deploy actions on PR review workflows.
- Keep environment variables branch-specific and avoid mixing staging URLs into production workflows.

## 8. Security Requirements

- Use least-privilege workflow permissions. Start with `permissions: contents: read`; add `id-token: write` only in jobs that assume cloud roles.
- Do not use `pull_request_target` for code checkout or test execution unless the workflow has a documented security reason and never runs untrusted PR code with secrets.
- Do not expose secrets, cloud credentials, deployment tokens, OIDC tokens, or production-like environment variables to PR workflows.
- Do not echo secrets, generated tokens, signed URLs, cookies, JWTs, OAuth credentials, or full AWS identities that include sensitive account context.
- Do not define secrets in workflow-level `env`. Put secrets only on the specific job or step that needs them, and prefer step-level `env` for the shortest possible lifetime.
- Do not pass secrets through global variables, matrix values, job outputs, reusable workflow outputs, artifact names, cache keys, commit statuses, PR comments, or `$GITHUB_OUTPUT`.
- Do not write secrets into `.env` files, generated config files, SAM build artifacts, test fixtures, screenshots, logs, coverage reports, or uploaded artifacts.
- Do not run shell scripts that print environment variables, enable `set -x`, call `env`, `printenv`, `export`, `aws configure list`, or dump command arguments while secrets are in scope.
- Pass secrets to scripts through environment variables rather than command-line arguments when possible, because process arguments and traced commands are easier to leak.
- Keep secret-consuming scripts checked in, reviewed, and narrowly scoped. Do not pipe remote scripts into a shell with secrets in the environment.
- Mask derived sensitive values with `::add-mask::` when a script generates tokens, URLs, cookies, or credentials that GitHub cannot automatically mask.
- Clear or overwrite temporary secret files in an `if: always()` cleanup step when a tool requires a file-based secret.
- Prefer AWS OIDC role assumption over long-lived AWS access keys. Scope trust policies by repository, branch, environment, and audience where possible.
- Use separate cloud roles for staging and production. Production roles must not be usable from `staging`, feature branches, or pull requests.
- Protect GitHub environments with required reviewers for production and any staging environment that can affect shared data.
- Keep deployment secrets in environment secrets when they are environment-specific; use repository secrets only when the same value is intentionally shared.
- Treat forked PRs as untrusted. They should receive tests that use public dependencies, dummy credentials, and local services only.
- Avoid caching paths that may contain secrets, generated credentials, `.env` files, cloud config, or build outputs with sensitive embedded values.
- Keep `persist-credentials: false` on checkout unless a workflow explicitly needs to push back to the repository.
- Pin third-party actions to a full commit SHA when the action is not official or not already standardized by HBK.
- Use official actions by major version only when the action is trusted and already accepted in the organization.
- Do not install tools with unverified remote shell scripts in CI. Prefer package managers, official setup actions, or checked-in scripts.
- Do not use broad Docker socket access, privileged containers, or host mounts unless the repository has a documented reason.
- Keep test services local to the runner and bind only required ports.
- Validate SAM templates before deploy when changing infrastructure-sensitive resources, IAM policies, API auth, secrets, or public endpoints.
- Review IAM policy changes, public API exposure, CORS origins, cookie settings, JWT settings, OAuth redirect URLs, and Secrets Manager references as security-sensitive changes.
- Use branch protection and required PR review checks so deploy branches cannot be updated without the PR review workflow passing.

## 9. Required YAML Standards

- Pin official actions to current major versions used in HBK unless the repository has a reason to stay older.
- Use clear job names: `unit-tests`, `integration-tests`, `e2e-tests`, `build`, `deploy-staging`, `deploy-production`.
- Keep job permissions explicit.
- Add `timeout-minutes` to jobs that start local services or deploy.
- Avoid duplicated setup blocks only when a reusable workflow or composite action already exists; otherwise keep YAML explicit and readable.
- Use repository variables for non-secret environment values and secrets only for credentials, tokens, role ARNs, and sensitive parameters.
- Keep branch and environment names literal and easy to audit.

## 10. Review Before Finishing

- Confirm PR review cannot build, upload deploy artifacts, assume cloud roles, or deploy.
- Confirm staging deploy runs only from `staging`.
- Confirm production deploy runs only from `main`.
- Confirm deploy jobs require successful tests in the same workflow.
- Confirm local test infrastructure uses dummy credentials and local endpoints.
- Confirm every secret or variable referenced by YAML is listed in the final summary.
- Confirm workflow file names match their purpose.
- Confirm every job has the minimum permissions required.
- Confirm no PR workflow can access deployment secrets or cloud role credentials.
- Confirm production deploys require GitHub environment protection or an equivalent approval gate.

## 11. Final Summary

Report:

- Workflow files created or changed.
- Branch triggers for PR, staging, and production.
- Test commands used.
- Local infrastructure used by tests.
- Deployment credentials, secrets, variables, environments, and buckets required.
- Security controls added or preserved.
- Any remaining manual setup needed in GitHub repository settings.
