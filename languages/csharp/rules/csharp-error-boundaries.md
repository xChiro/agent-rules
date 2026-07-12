---
rule_id: RULE-CSHARP_ERROR_BOUNDARIES
trigger: always_on
description: C# exception, error propagation, HTTP mapping, worker boundary, and structured logging rules.
globs: **/*.cs
---

# C# Error Boundaries

## SDD Baseline

- Apply `common/rules/common-sdd-agentic-discipline.md` before this rule.
- Create or evolve the owning User Story based spec before production code when behavior, contracts, architecture, or risk changes.
- Apply mandatory Gate 1 before spec writes, Gate 2 before RED, and Gate 3 before Green, even for simple or low-risk changes.
- Keep artifact, task, track, and test IDs traceable through `traceability.yaml` and `parallel-tracks.md`.
- Write BDD Given/When/Then acceptance evidence first, then the unit-level ATDD-style focused failing test for the next rule or boundary before production code.
- Refactor only with tests green and converge spec history, tasks, parallel tracks, traceability, verification notes, and code.

Use exceptions as the normal .NET failure mechanism. Log once at the boundary that decides the operational outcome.

## Core Rule

- Domain/application throw or propagate exceptions.
- Infrastructure throws or translates only when translation adds a useful domain/application meaning.
- Boundaries map exceptions to protocols.
- Log only where the failure is handled or classified.

Do not log and rethrow the same exception from lower layers.

## Boundary Owners

Boundary owners include:

- ASP.NET exception middleware or exception filter
- controller/endpoint only when it fully handles the failure
- message consumer that decides ACK/NACK/requeue/drop
- hosted service top-level loop
- CLI command boundary
- `Program.cs` startup

Domain entities, value objects, and ordinary use cases should not take `ILogger`.

## Exception Taxonomy

- Invalid input/value object: `400`
- Not found: `404`
- Duplicate/conflict/invalid state transition: `409`
- Unauthorized/forbidden: `401` or `403`
- Dependency unavailable: `503` when classified
- Timeout: `504` when classified
- Unexpected technical failure: `500`
- Cancellation: preserve `OperationCanceledException`

Map exceptions centrally. Do not duplicate mapping in each controller.

## HTTP Responses

- Preserve existing response contracts.
- Prefer `ProblemDetails` for new APIs when the project has no custom contract.
- Do not expose stack traces, SQL, connection strings, broker payloads, provider messages, internal type names, or secrets.
- Return stable error codes when clients need classification.

## Messaging And Workers

- The ACK/NACK owner logs the final per-message failure.
- Lower message handlers should either fully handle the message or let exceptions bubble.
- Log safe metadata: message id, correlation id, queue/topic, retry count, delivery tag.
- Do not log raw full broker payloads by default.
- Use deterministic reject/DLQ for poison messages instead of infinite requeue.

## Structured Logging

Good:

```csharp
logger.LogError(exception,
    "Failed to process telemetry message {MessageId} from {Queue}",
    messageId,
    queueName);
```

Bad:

```csharp
logger.LogError($"Failed: {exception.Message} {rawPayload}");
throw;
```

Never log:

- passwords, tokens, cookies, auth headers, private keys
- connection strings
- unredacted personal data
- full request or broker payloads by default
- large EF entities or domain graphs

## Catching Exceptions

Catch exceptions to:

- map to protocol response
- decide retry/ACK/NACK
- add meaningful context and rethrow
- compensate a completed side effect
- translate provider errors into domain/application exceptions when required

Do not catch exceptions to:

- return `null`
- return `false`
- hide dependency failures
- make tests pass
- log and rethrow

## Done Criteria

- Same failure is logged once.
- Business failures are typed and map cleanly.
- Unexpected failures preserve exception details in logs, not responses.
- Core code does not know transport protocols.
- Cancellation is respected.
