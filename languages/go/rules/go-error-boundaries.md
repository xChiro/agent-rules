---
rule_id: RULE-GO_ERROR_BOUNDARIES
trigger: model_decision
description: "Go logging and error boundary rules to avoid log hell and preserve clean error propagation."
globs: "**/*.go"
---

# Go Error Boundaries

## SDD Integration

Apply `RULE-COMMON_SDD_AGENTIC_DISCIPLINE` before this focused error rule. Error behavior follows the owning layer's existing RED/GREEN/gate sequence; this file does not restate or alter that lifecycle.


Use explicit Go error returns. Go does not have exceptions or throws; do not emulate them with `panic`, global log exits, or hidden control flow.

## Core Rule

- Return errors from domain, application, and infrastructure layers.
- Log only at the boundary that decides the outcome: HTTP/gRPC handlers, CLI commands, queue consumers, scheduled jobs, process bootstrap, or another interface adapter.
- Do not log and return the same error from lower layers.
- Do not log inside pure domain code, value objects, entities, or domain services.
- Do not add logger dependencies to use cases unless the use case is itself the final process boundary.
- Treat error handling as part of the public contract. Expected business failures must be typed or sentinel errors that can be mapped deterministically.

## Error Taxonomy

- **Validation errors**: malformed input, invalid query/path/body values, missing required fields, or invalid domain values.
- **Not found errors**: requested aggregate/resource does not exist.
- **Conflict errors**: uniqueness, ownership, version, idempotency, or invalid state transition conflicts.
- **Authorization/authentication errors**: missing identity, forbidden role, tenant/organization ownership mismatch.
- **Dependency errors**: database, SDK, network, queue, filesystem, or third-party failures.
- **Cancellation/timeout errors**: preserve `context.Canceled` and `context.DeadlineExceeded`.
- **Programmer errors**: impossible states caused by bugs. Avoid panic in normal paths.

## Error Type Selection

- Use sentinel errors for stable business decisions: `var ErrNotFound = errors.New("not found")`.
- Use typed errors only when callers need structured fields, such as `Field`, `Code`, or `ResourceID`.
- Use joined errors only for true aggregate validation/reporting where callers inspect with `errors.Is/As`.
- Do not create broad `AppError` or `HTTPError` types in domain/application just to carry status codes.
- Keep error messages for logs/internal diagnosis; keep response messages separate and safe for users.

## Layer Ownership

**Domain**
- Owns business rules and stable domain errors.
- Returns sentinel or typed domain errors when callers need decisions.
- Has no `context.Context`, logger, transport status, persistence detail, SDK error, or environment dependency.

**Application/use case**
- Orchestrates domain and ports.
- Returns known domain/application errors unchanged when useful for `errors.Is/As`.
- Wraps technical port failures only when adding use-case context helps operators.
- Does not log normal failures that the caller can map.

**Infrastructure**
- Converts SDK/database/client failures into returned errors.
- Wraps with adapter context close to the failing operation.
- Does not decide HTTP status codes, CLI exit codes, or user-facing messages.
- Does not log every failed call. Return the error to the interface boundary.

**Interface adapters**
- Own request parsing, response DTOs, status codes, CLI exit codes, retry/drop decisions, and final logging.
- Log unexpected/internal failures once with operation name and safe identifiers.
- Map expected business errors to responses without noisy error logs.
- Own centralized error mapping. Prefer one mapper/helper per transport so handlers do not duplicate status-code decisions.

## HTTP/API Error Mapping

HTTP handlers must convert application/domain errors to the service error contract in one boundary mapper.

- Invalid JSON/body/query/path: `400`.
- Validation/domain value errors: `400`, unless the valid input conflicts with existing state.
- Authentication missing/invalid: `401`.
- Authorization/ownership/tenant mismatch: `403`.
- Missing resource: `404`.
- Uniqueness, idempotency, version, or invalid state transition conflict: `409`.
- Context canceled by client: use the framework's client-canceled behavior when available; otherwise avoid noisy error logs.
- Deadline exceeded: `504` when the upstream/dependency timed out, or `503` when the service is temporarily unavailable.
- Unknown dependency/internal failure: `500` with safe message only.

Expected 4xx business errors should not be error-level logs by default. Unexpected 5xx failures should be error-level logs once.

## Panic and Recover

- Do not use panic for business rules, validation, dependency failures, or missing user input.
- Panic is acceptable only for unrecoverable programmer errors, impossible invariants, or test helper failures.
- Recover only at process/transport boundaries, log once with stack/context if available, and return a safe 500 response.
- Do not recover in lower layers because it hides defects and makes tests less precise.

## Logging Levels

- `debug`: diagnostic detail for development or temporary investigation.
- `info`: lifecycle events and successful high-value operations, such as service start, import completed, or batch finished.
- `warn`: expected but notable conditions that still complete or are safely rejected.
- `error`: operation failed and the boundary is returning an error response, non-zero exit, NACK, or failed job.
- `fatal`: only in `main`/process bootstrap after the final log, immediately before process exit.

Never use `log.Fatal` in libraries, domain, application, infrastructure, handlers, or tests.

## Error Practices

- Error messages are lowercase and without trailing punctuation unless they include a proper noun or formatted external message.
- Wrap with `%w` when preserving the cause matters.
- Avoid wrapping at every layer. Add context where it changes the operator's ability to diagnose.
- Use `errors.Is/As`; never branch on string contents.
- Preserve cancellation so callers can still detect it with `errors.Is`.
- Keep user-facing messages separate from internal errors.
- Tests should assert error type/category with `errors.Is/As`, not full error strings, except for stable response contracts.

## What To Log

Log safe operational context:

- operation name
- request ID/correlation ID
- actor ID or organization ID when safe
- resource IDs, batch IDs, table names, dependency names
- counts, duration, retry count, status code

Never log:

- secrets, tokens, passwords, credentials, private keys
- raw authorization headers or cookies
- full payloads by default
- sensitive personal data
- huge rows, database items, or request/response bodies unless explicitly redacted and bounded

## Examples

Lower layer returns with context, no log:

```go
func (w *Writer) Put(ctx context.Context, table string, item Item) error {
    if err := w.client.Put(ctx, table, item); err != nil {
        return fmt.Errorf("put item into %s: %w", table, err)
    }
    return nil
}
```

Interface boundary logs once and decides outcome:

```go
func (h *Handler) ServeHTTP(w http.ResponseWriter, r *http.Request) {
    if err := h.useCase.Execute(r.Context(), req); err != nil {
        if errors.Is(err, domain.ErrNotFound) {
            writeProblem(w, http.StatusNotFound, "resource not found")
            return
        }

        h.logger.Error("request failed",
            "operation", "create_resource",
            "request_id", requestIDFrom(r.Context()),
            "error", err,
        )
        writeProblem(w, http.StatusInternalServerError, "internal server error")
        return
    }
}
```

Avoid:

```go
func (r *Repository) Save(ctx context.Context, e Entity) error {
    if err := r.client.Save(ctx, e); err != nil {
        log.Printf("save failed: %v", err)
        return fmt.Errorf("repository save failed: %w", err)
    }
    return nil
}
```
