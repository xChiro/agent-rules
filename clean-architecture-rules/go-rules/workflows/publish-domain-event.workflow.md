---
description: Add or change a domain event publisher/consumer through the service messaging infrastructure.
---

# Domain Event Publishing Workflow

Use this workflow when a Go service publishes a domain event to SNS/SQS or consumes one from SQS.

Also follow:

- `domain-event-publishing.md`
- `go-logging-and-error-boundaries.md`
- `go-use-case-protocol.md`
- `go-dependency-injection.md`

## Phase 1: Define The Domain Fact

- Name the event as a past-tense domain fact, not a command.
- Confirm the event is reusable outside the current consumer. If it is only a private implementation detail, do not publish it as a domain event.
- Define `event_type`, `event_version`, `source`, `occurred_at`, `correlation_id`, and `payload`.
- Treat the wire `event_version` as a string such as `1.0`.
- Document required payload fields, optional fields, examples, and compatibility rules.
- Decide whether the event is best-effort or business-critical.

## Phase 2: Pick The Transport

- Use SNS Standard when fanout exists or is likely.
- Use direct SQS only when there is one consumer and reuse is unlikely.
- Use SQS Standard for durable processing and backpressure.
- Use EventBridge only when advanced routing, cross-account routing, SaaS integration, or schema registry requirements are real.
- Do not create a new topic or queue in a service stack when the shared infrastructure already owns it.

## Phase 3: Wire Shared Infrastructure

- Export topic ARNs and queue ARNs/URLs from shared infrastructure.
- Match the actual export/parameter names in the shared stack before writing SAM snippets.
- For SNS -> SQS subscriptions, set `RawMessageDelivery: true` if consumers parse `record.Body` directly as the domain envelope.
- If `RawMessageDelivery` is false, require consumer code to unwrap the SNS envelope.
- Add queue policies allowing only the expected SNS topic to send messages.
- Add a real SQS `RedrivePolicy` on the source queue for important consumers.
- Configure visibility timeout longer than the Lambda timeout.
- Add SNS filter policies only using stable `MessageAttributes`.

## Phase 4: Implement The Producer

- Keep the use case focused on the business state change.
- Build the public event envelope after the state change succeeds.
- Publish through an application port implemented by an infrastructure adapter.
- Do not import AWS SDK types in domain/application.
- Publish the envelope as the message body and add `MessageAttributes`: `event_type`, `event_version`, `source`, and `priority`.
- Do not include consumer-specific fields unless they are documented public contract fields.
- Decide failure semantics:
  - Business-critical event: return publish errors to the handler boundary.
  - Best-effort notification event: document the tradeoff and plan outbox if reliability becomes critical.
  - Strong consistency: use an outbox persisted with the state change and publish asynchronously.
- Do not log publish failures in the use case/decorator and again in the handler. Let the boundary own final logging.

## Phase 5: Implement The Consumer

- Consume from a consumer-owned SQS queue.
- Parse the body according to the subscription shape:
  - Raw SNS delivery: body is the domain envelope.
  - Non-raw SNS delivery: body is the SNS wrapper; parse `Message`.
- Validate envelope fields before processing.
- Route by `event_type` and `event_version`.
- Use consumer-owned DTOs for payload parsing.
- Make processing idempotent using `event_id` or a stable business key.
- For Lambda SQS handlers, never `continue` after record failure and return `nil`.
- Either return an error for the whole batch or enable `ReportBatchItemFailures` and return failed item IDs.
- Log unexpected failures once at the SQS handler boundary with safe fields.

## Phase 6: Tests

- Add unit tests for envelope construction and message attributes.
- Add unit tests for publish failure behavior.
- Add unit tests for consumer validation, unsupported versions, duplicate events, and downstream failures.
- Add integration tests for SNS publish serialization and attributes.
- Add integration tests for SNS -> SQS delivery if that is the production route.
- Add infrastructure/template assertions or review checks for `RawMessageDelivery`, queue policy, visibility timeout, and DLQ redrive.

## Phase 7: Review Checklist

- Producer does not know consumers.
- Domain/application do not import AWS SDK or transport DTOs.
- Public event contract is documented.
- `event_version` type is consistent on the wire and in consumers.
- SNS attributes support filtering.
- SQS consumer cannot accidentally acknowledge failed records.
- DLQ/redrive is attached to the source queue, not only declared separately.
- Logging follows boundary ownership and avoids raw payloads/secrets.
- Tests cover success, malformed event, duplicate/idempotent event, unsupported version, publish failure, and consumer failure.
