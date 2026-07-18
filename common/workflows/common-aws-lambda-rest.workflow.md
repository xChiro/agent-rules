---
workflow_id: WORKFLOW-COMMON_AWS_LAMBDA_REST_WORKFLOW
trigger: model_decision
description: "Design an API Gateway to AWS Lambda REST boundary with clean architecture, test-first evidence, and cost-aware defaults."
---

# Common AWS Lambda REST Workflow

Use after `WORKFLOW-COMMON_REST_API_DESIGN_WORKFLOW` for a REST endpoint implemented through API Gateway and Lambda. Go and C# workflows provide language execution; this workflow owns the AWS boundary and cost decisions.

## Required Order

1. Invoke `WORKFLOW-COMMON_BDD_SPECIFICATION_WORKFLOW` and `WORKFLOW-COMMON_REST_API_DESIGN_WORKFLOW`.
2. Record why Lambda fits the workload: request duration, traffic shape, concurrency, latency, state, and operational constraints. Do not assume serverless is automatically cheapest.
3. Define the API Gateway route, authorizer, payload format, timeout, memory, concurrency, environment, IAM, logging, and local emulation settings in checked-in IaC.
4. Complete affected domain/application `TEST-*` cycles and pass `LAYER-GATE-APPLICATION`.
5. Create public HTTP RED and obtain Gate 3-BOUNDARY.
6. Implement infrastructure, the thin Lambda delivery adapter, and composition/IaC in that order; make local HTTP evidence GREEN.
7. Refactor with tests green, validate IaC/package/build, and run mandatory security, quality, and coverage gates; mutation and critical-E2E gates remain selected by risk.

## Boundary And Contract Rules

- Prefer API Gateway HTTP API and explicitly configure payload format `2.0` unless existing compatibility or custom-domain mapping requires `1.0`.
- Treat API Gateway events and Lambda responses as transport DTOs. Map them immediately at the outer adapter.
- Keep AWS SDK, API Gateway, Lambda, IaC, and runtime types outside domain/application.
- Reuse the same application use case and ports for server/container and Lambda adapters; never duplicate business behavior.
- Put ports in `application`; put AWS SDK implementations in `infrastructure`; keep composition in one explicit root.
- Keep handler flow to parse -> trusted identity/context -> validate -> call one operation -> map response.
- Make retryable commands idempotent with a stable key and durable deduplication when the business operation is not naturally idempotent.

## Cost-Aware Lambda Defaults

- Prefer a cohesive function per bounded capability; do not create a function for every trivial method or a relay Lambda without a measured reason.
- Initialize SDK clients, connection pools, parsers, and immutable configuration outside the handler when safe; never retain request-specific state globally.
- Keep deployment packages and initialization small; remove unused dependencies and avoid network calls during initialization unless required.
- Propagate invocation deadlines/cancellation to downstream I/O and leave timeout headroom for response handling.
- Benchmark memory and duration together; CPU and network allocation follow memory. Consider ARM/Graviton only after compatibility and load evidence.
- Bound concurrency to protect databases and downstream services; use API throttling and Lambda/reserved concurrency as safety controls, not as a substitute for backpressure design.
- Use environment/configuration for resource identifiers; use least-privilege IAM; keep secrets in the repository's approved secret mechanism.
- Emit concise structured logs, correlation IDs, duration/outcome metrics, and alarms without logging sensitive payloads.

## Verification

- Acceptance evidence uses a real local HTTP boundary or the repository's equivalent API Gateway/Lambda emulator.
- HTTP integration tests exercise routing, serialization, auth context, composition root, local resources, and response/error contracts.
- Unit tests prove application/domain rules without AWS or framework types.
- IaC validation must cover route/method, authorizer, payload version, timeout/memory, IAM, environment, event source, and observability configuration.
- Record cost assumptions, benchmark command/results, idempotency strategy, rollback, and residual risk in `verification.md`.

## Done When

The Lambda boundary is thin, the application remains provider-independent, the same contract is proven through HTTP, retries are safe, concurrency is bounded, configuration is least-privilege, and measured resource choices support the required latency and cost.

## AWS References

- [Lambda best practices](https://docs.aws.amazon.com/lambda/latest/dg/best-practices.html)
- [HTTP API Lambda proxy integrations](https://docs.aws.amazon.com/apigateway/latest/developerguide/http-api-develop-integrations-lambda.html)
- [Lambda cost and performance optimization](https://docs.aws.amazon.com/wellarchitected/latest/serverless-applications-lens/cost-and-performance-optimization.html)
