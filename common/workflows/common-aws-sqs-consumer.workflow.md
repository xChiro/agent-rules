---
workflow_id: WORKFLOW-COMMON_AWS_SQS_CONSUMER_WORKFLOW
trigger: model_decision
description: "Add or evolve an AWS SQS consumer backed by Lambda with idempotent batch processing, safe retries, DLQ handling, and TDD."
---

# Common AWS SQS Consumer Workflow

Use for `message-consumer` work where Lambda consumes Amazon SQS. Invoke `WORKFLOW-COMMON_AWS_SNS_PUBLISH_WORKFLOW` first when the queue is subscribed to SNS.

## Required Order

1. Invoke `WORKFLOW-COMMON_BDD_SPECIFICATION_WORKFLOW` and describe the business outcome of processing a valid message.
2. Define queue ownership, message contract, idempotency key, batch behavior, retry/DLQ policy, ordering, concurrency limit, and downstream capacity.
3. Obtain Gate 1 and Gate 2; create focused Domain/Application RED for valid, invalid, duplicate, and failure policies.
4. Obtain Gate 3-DOMAIN and/or Gate 3-APPLICATION as affected, implement the core operation, and pass `LAYER-GATE-APPLICATION`.
5. Create executable consumer-boundary RED and obtain Gate 3-BOUNDARY.
6. Implement infrastructure dependencies, the thin event-source adapter, and composition/IaC in that order; make boundary evidence GREEN.
7. Create or update the source queue, DLQ, redrive policy, event-source mapping, IAM, alarms, and IaC settings only through checked-in infrastructure; validate them, then run mandatory quality, security, coverage, and operational gates, with mutation selected by risk.

Every Domain, Application, and consumer-boundary command follows `RULE-COMMON_TEST_LAYER_ISOLATION`. The consumer boundary owns queue/DLQ namespace, messages, event-source lifecycle, readiness, and cleanup and must pass without any core test process running first.

## Queue And Lambda Configuration

- Use one queue per logical consumer; do not share unrelated consumers.
- Configure a source-queue redrive policy and DLQ. A separate Lambda DLQ does not replace SQS redrive.
- Set visibility timeout to at least `6 x function timeout + maximum batching window`; keep function timeout no greater than visibility timeout.
- Start with a measured batch size/window. Larger batches reduce invocation overhead but increase latency, memory, retry scope, and downstream pressure.
- Bound event-source/Lambda concurrency to protect databases and external systems. Do not use a long-running poller inside the function; the event-source mapping polls SQS.
- Use Standard unless strict order/deduplication requires FIFO. Respect FIFO group ordering and its batch constraints.
- Set `maxReceiveCount` to a value that allows useful retries; AWS recommends at least `5` for Lambda event-source processing.

## Consumer Boundary

- Treat the SQS event and record as transport DTOs; map immediately to a consumer-owned message DTO/application command.
- Keep SQS/Lambda SDK types, ACK/delete decisions, batch response shape, and logging at the outer adapter.
- Process records independently when safe and return only failed message identifiers with `ReportBatchItemFailures`.
- Never catch a record failure, continue, and return success; that acknowledges a failed record.
- Validate schema/version before business processing. Route malformed or unsupported messages according to the documented poison-message policy.
- Assume at-least-once delivery. Persist idempotency using `event_id` or a stable business key, with a bounded retention/TTL strategy when appropriate.
- Log one safe failure record at the boundary with message/event/correlation identifiers; do not log full payloads or duplicate lower-layer errors.

## Cheap And Safe Processing

- Reuse clients and immutable configuration across warm invocations; do not retain request-specific state.
- Prefer batch work and bounded concurrency over one invocation per message.
- Keep message payloads small and fetch large data by an authorized reference when necessary.
- Make downstream writes idempotent and avoid unbounded retries, recursive re-enqueue, and poison-message loops.
- Alarm on age of oldest message, visible message count, DLQ depth, throttles, errors, duration, and partial failures.

## Verification

- Unit-test mapping, schema/version validation, valid processing, duplicate processing, partial failure, retry classification, and DLQ/poison decisions.
- Prove the event-source and queue contract through the repository's existing integration/quality suite; do not create a third backend runtime suite.
- Validate IaC for queue, DLQ, redrive, visibility timeout, batch size/window, partial batch response, filtering, concurrency, IAM, and alarms.
- Record batch/cost assumptions, downstream capacity, idempotency evidence, commands, gate decisions, and residual risk.

## Done When

The consumer is thin and idempotent, failed records are retried without acknowledging successes, poison messages reach a controlled DLQ, queue timing/concurrency protects dependencies, and all behavior is proven through ATDD/TDD evidence.

## AWS References

- [Configuring an SQS event source mapping](https://docs.aws.amazon.com/lambda/latest/dg/services-sqs-configure.html)
- [Handling SQS event-source errors](https://docs.aws.amazon.com/lambda/latest/dg/services-sqs-errorhandling.html)
- [Using Lambda with SQS](https://docs.aws.amazon.com/lambda/latest/dg/with-sqs.html)
