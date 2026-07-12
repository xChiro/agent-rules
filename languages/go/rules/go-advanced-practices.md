---
rule_id: RULE-GO_ADVANCED_PRACTICES
trigger: always_on
description: Idiomatic and advanced Go practices with YAGNI, SOLID, and Clean Architecture guardrails
globs: **/*.go
---

# Go Advanced Practices

## SDD Baseline

- Apply `common/rules/common-sdd-agentic-discipline.md` before this rule.
- Create or evolve the owning User Story based spec before production code when behavior, contracts, architecture, or risk changes.
- Apply mandatory Gate 1 before spec writes, Gate 2 before RED, and Gate 3 before Green, even for simple or low-risk changes.
- Keep artifact, task, track, and test IDs traceable through `traceability.yaml` and `parallel-tracks.md`.
- Write BDD Given/When/Then acceptance evidence first, then the unit-level ATDD-style focused failing test for the next rule or boundary before production code.
- Refactor only with tests green and converge spec history, tasks, parallel tracks, traceability, verification notes, and code.


Use Go's simple, explicit style first. Apply advanced patterns only when they solve a current, observable problem and improve the call sites, tests, or operational behavior.

## Senior Go Principles

- Prefer explicit code, small packages, and composition over framework-style abstractions.
- Keep domain code pure: no context, logging, transport tags, cloud SDKs, or persistence details.
- Define behavior by the consumer's need, not by the provider's implementation.
- Use the standard library before adding dependencies.
- Optimize after evidence from benchmarks, profiles, production metrics, or an obvious algorithmic issue.
- Treat every goroutine, interface, generic helper, cache, and worker pool as a design choice that needs a clear reason.

## Context Rules

- Pass `context.Context` as the first argument for I/O, network calls, persistence, queues, external APIs, and request-scoped work.
- Do not store context in structs.
- Do not pass `nil` context; use `context.Background()` or `context.TODO()` only at process/test boundaries.
- Do not put context in domain entities, value objects, or pure domain services.
- Propagate cancellation to downstream calls.
- Add timeouts at boundaries that own the deadline, not inside low-level helpers unless that helper owns the external operation.

## Error Handling

- Return errors; do not panic for business, validation, infrastructure, or user-input failures.
- Wrap technical errors once at the layer where useful context is known: `fmt.Errorf("failed to save order %s: %w", id, err)`.
- Use `errors.Is` and `errors.As` for decisions. Never branch on error strings.
- Keep domain errors stable and comparable when callers need decisions.
- Use typed errors only when callers need structured data.
- Do not wrap the same error at every layer with noisy messages.
- Log at final process/transport boundaries. Avoid logging and returning the same error repeatedly.

## Interfaces and Composition

- Define interfaces near the consumer, especially at application/domain boundaries.
- Prefer small interfaces that describe one consumer need.
- Do not create an interface only because a concrete type exists.
- Use concrete types when there is one implementation and no boundary, substitution, or test isolation need.
- Prefer composition over embedding for code reuse.
- Embed only when the outer type must intentionally expose the embedded type's behavior.
- Avoid generic repositories and broad CRUD abstractions unless the project already has a proven shared contract.

## Decorators

Use decorators as explicit composition, not as a framework. They are appropriate when the code has a current cross-cutting need around an existing use case or port: metrics, tracing, auditing, idempotency, read cache, transaction boundary, or retry around an external dependency.

Guardrails:

- The decorator must implement the same small interface as the inner type.
- The decorator must preserve the inner contract: same inputs, outputs, cancellation, and error meaning.
- The decorator may add operational behavior, not business rules.
- The composition root owns decorator order.
- Prefer one named decorator per current concern over a generic middleware pipeline.
- Do not add decorators unless a simpler direct call would mix concerns or duplicate the same wrapper behavior.

## Generics

Use generics only when all are true:

- The abstraction removes real duplication across concrete types.
- The call sites become clearer or safer.
- At least two current call sites need the same behavior.
- A named non-generic function or value object would not express the domain better.

Do not use generics for speculative repositories, use cases, domain services, or framework-style helpers.

## Concurrency

- Start goroutines only when ownership, cancellation, and error collection are explicit.
- Every goroutine must have a bounded lifetime.
- Prefer `errgroup.WithContext` for parallel I/O where one failure should cancel the group.
- Use channels to communicate ownership or streams of values, not as a default queue abstraction.
- The sender should usually close the channel.
- Protect shared mutable state with clear ownership, `sync.Mutex`, atomics, or channel serialization.
- Run `go test -race ./...` when touching concurrent code.
- Do not use worker pools, background loops, caches, or async fire-and-forget paths without operational need and shutdown behavior.

## Data, Receivers, and Zero Values

- Make zero values useful when practical.
- Use constructors when invariants, validation, dependencies, or non-zero defaults are required.
- Use value receivers for small immutable values; pointer receivers for mutation, large structs, or shared state.
- Do not expose mutable slices or maps directly. Return copies when exposing internal collections.
- Preallocate slices/maps when the size is known and it improves clarity or performance.
- Distinguish `nil` and empty slices only when the API contract requires it.

## Streaming and I/O

- Prefer `io.Reader`, `io.Writer`, and streaming APIs for large payloads.
- Avoid loading whole files, responses, or message batches into memory unless size is bounded.
- Always close resources you own.
- Use `defer` for local cleanup when it is safe and clear.

## Functional Options

Use functional options only for constructors with optional settings and stable defaults.

Do not use functional options for required dependencies. Required dependencies should be explicit constructor parameters.

## Observability and Security

- Log request IDs, actor IDs, resource IDs, and operation names when they help diagnose behavior.
- Do not log secrets, tokens, passwords, credentials, or sensitive personal data.
- Keep metrics at boundaries and high-value operations.
- Validate external input at boundaries; enforce business invariants in domain objects.
- Use constant-time comparison for secrets or tokens when timing leaks matter.

## Advanced Pattern Gate

Before adding an advanced pattern, confirm:

- The current code has a real change, scaling, reliability, performance, or clarity problem.
- The simpler explicit implementation was considered.
- The pattern has a domain or operational name, not a vague technical name.
- Tests prove the behavior the pattern protects.
- The pattern does not create unused extension points.

If this evidence is missing, keep the simpler Go implementation.
