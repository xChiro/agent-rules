---
trigger: always_on
description: Domain event publishing and consumption standards for Go services using SNS/SQS or equivalent messaging.
globs: **/*.go,template.yaml
---

# Domain Event Publishing

Use these rules for SNS/SQS, direct SQS, EventBridge, streams, or any equivalent message bus.

## Core Rules

- Publish only domain facts, never consumer-specific commands.
- Producers must not know consumer services, queues, notification channels, Lambda names, or retry behavior.
- Use the shared event bus, domain topic, queue, or stream defined by the architecture.
- Match the concrete resource contract exported by shared infrastructure; do not hardcode domain-specific topic export names unless those resources exist.
- Keep domain/application code independent from transport SDKs and wire formats.
- Keep publish logic in infrastructure adapters, not handlers.
- Keep consume/ACK/NACK/drop decisions in interface adapters, such as SQS Lambda handlers or worker boundaries.
- Follow `go-logging-and-error-boundaries.md`: lower layers return errors; the interface/process boundary logs unexpected failures once.
- Prefer an outbox pattern when event reliability is part of the business guarantee.

## Event Contract

The wire contract must use a stable envelope:

```json
{
  "event_id": "uuid",
  "event_type": "domain.fact",
  "event_version": "1.0",
  "source": "service-name",
  "occurred_at": "RFC3339 timestamp",
  "correlation_id": "uuid-or-request-id",
  "payload": {}
}
```

- `event_id` is globally unique and stable for idempotency.
- `event_type` is a past-tense domain fact, such as `requisition.created`, not `send.notification`.
- `event_version` is a wire-contract string such as `1.0`; internal code may use typed/int versions but infrastructure must serialize the public value consistently.
- `source` is the publishing service name.
- `occurred_at` is UTC RFC3339.
- `correlation_id` is propagated from the incoming request/message or generated once at the boundary.
- `payload` contains only business data required by consumers. Do not include secrets, auth tokens, raw request bodies, or large internal objects.
- Optional cross-cutting fields such as `visible_to` may be included only when they are part of the public contract and are documented.

## SNS/SQS Rules

- Publish the envelope as the SNS message body.
- Add SNS `MessageAttributes` for at least `event_type`, `event_version`, `source`, and `priority` when SNS is used.
- Use message attributes for filtering/routing; keep canonical event data in the envelope body.
- SNS -> SQS subscriptions consumed as raw event envelopes must set `RawMessageDelivery: true`.
- If `RawMessageDelivery` is false, the SQS consumer must unwrap the SNS envelope and parse its `Message` field explicitly.
- Every important SQS queue must have a real source-queue `RedrivePolicy`; a separate Lambda DLQ or permission is not enough for SQS event source failures.
- Use one queue per logical consumer. Do not share one queue across unrelated consumers.
- Consumers must be idempotent using `event_id` or another stable event/business key.

## Producer Rules

- Publish after the state change succeeds.
- If publish failure should fail the command, return the publish error to the boundary.
- If publish failure should not fail the command, document that the event is best-effort and consider an outbox. Do not silently hide the reliability tradeoff.
- Do not log publish errors in application decorators and again in handlers. Return errors or document best-effort behavior and log only at the final boundary.
- Infrastructure adapters may wrap publish failures with operation context, but should not emit per-event success logs by default.
- Validate required configuration at startup: region, topic ARN, queue URL, and local endpoints where applicable.

## Consumer Rules

- Validate the envelope before business processing.
- Reject or DLQ unsupported event versions according to the queue retry policy; do not process unknown versions as best-effort.
- For AWS Lambda SQS event sources:
  - Do not `continue` on per-record failures and then return `nil`; that acknowledges/deletes failed records.
  - Either return an error for the batch, or enable `FunctionResponseTypes: [ReportBatchItemFailures]` and return `events.SQSEventResponse` with failed message IDs.
  - Log failed records once at the SQS handler/worker boundary with `message_id`, `event_id`, `event_type`, `correlation_id`, and safe identifiers.
  - Let SQS redrive to DLQ handle poison messages.
- Consumers should not depend on producer internal structs. Use a consumer-owned DTO for the public envelope and payload.

## Testing Requirements

- Unit-test envelope construction and validation.
- Unit-test publish failure behavior: fail command or documented best-effort.
- Unit-test consumer behavior for malformed JSON, missing required fields, unsupported versions, duplicate events, and downstream failures.
- Integration-test SNS publish serialization and message attributes.
- Integration-test SNS -> SQS delivery when that is the production path. Verify the SQS body shape matches `RawMessageDelivery` assumptions.
- Integration-test SQS failure behavior when possible: batch error or partial batch response plus DLQ/redrive configuration.
