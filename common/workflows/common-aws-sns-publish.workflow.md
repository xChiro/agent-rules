---
workflow_id: WORKFLOW-COMMON_AWS_SNS_PUBLISH_WORKFLOW
trigger: model_decision
description: "Add or evolve an AWS SNS publisher with stable event contracts, clean ports, reliability, and test-first evidence."
---

# Common AWS SNS Publish Workflow

Use for `domain-event` or application publication through Amazon SNS. Use SNS for fan-out/pub-sub; use a direct queue when there is one consumer and no fan-out requirement. This workflow does not authorize a Lambda relay by default.

## Required Order

1. Invoke `WORKFLOW-COMMON_BDD_SPECIFICATION_WORKFLOW` and describe the business outcome enabled by the event, not the broker operation.
2. Define the event contract, producer/consumer ownership, delivery guarantee, ordering need, retry/DLQ path, and compatibility policy in the spec.
3. Obtain Gate 1 and Gate 2; create Application RED for the publication policy/port and focused publisher `TEST-*` using a hand-written outgoing-port double when the language requires it.
4. Obtain Gate 3-APPLICATION, implement the application publisher port/policy, and pass `LAYER-GATE-APPLICATION`.
5. Create executable message-boundary RED and obtain Gate 3-BOUNDARY.
6. Add the infrastructure SNS adapter, then composition/IaC; make boundary evidence GREEN.
7. Create or update the SNS topic, subscriptions, filter policies, encryption, and least-privilege IAM only through checked-in IaC; validate it with the existing integration/quality suite and refactor only while green.

Every Application and message-boundary command follows `RULE-COMMON_TEST_LAYER_ISOLATION`. The message boundary provisions its own topic/queue namespace, seed/messages, readiness, and cleanup; it never consumes state produced by Application tests.

## Architecture And Contract

- Ports belong in `application`; SNS clients, topic ARNs, serialization, message attributes, and publish retries belong in `infrastructure`.
- Domain/application code emits a domain fact; it does not know topic names, queues, subscribers, Lambda names, or broker retry policy.
- The event DTO owns `FromDomain`/`ToWire` mapping functions. Keep them pure and free of I/O, policy, logging, and orchestration.
- Use a stable envelope: `event_id`, `event_type`, `event_version`, `source`, `occurred_at`, `correlation_id`, and business `payload`.
- Publish only after the state change succeeds. If publication is part of the business guarantee, use an outbox or equivalent durable handoff; never hide a failed publish.
- Use past-tense facts, consumer-independent payloads, explicit schema evolution, and no secrets/raw requests/large internal objects.

## SNS Decisions

- Choose Standard unless strict ordering/deduplication requires FIFO and the design accepts its constraints.
- Use message attributes for routing/filtering metadata; keep canonical event data in the envelope body.
- If an SNS -> SQS subscription enables raw message delivery, consumers receive the body without the SNS wrapper. Keep that choice explicit and test the actual body shape.
- When raw delivery targets SQS, keep attributes within the service limit and verify filter behavior in IaC/tests.
- Grant the publisher only the required topic action/resource. Configure encryption and subscription permissions according to the security review.
- Do not add one Lambda invocation per published event merely to forward a message. Publish from the existing application path or use a measured batch/worker design.

## Verification

- Unit-test envelope construction, schema validation, mapping, publish failure policy, and idempotency/retry decisions.
- Prove serialization, attributes, topic/subscription configuration, and SNS -> SQS body shape in the repository's existing integration/quality suite; do not create an extra runtime suite.
- Record event IDs, contract version, topic/subscription decisions, outbox decision, commands, gate evidence, and residual risk.

## Done When

The event is a stable business fact, the application is broker-independent, the publisher has an explicit reliability policy, consumers can evolve safely, IaC permissions are least-privilege, and RED/GREEN/REFACTOR evidence is traceable.

## AWS References

- [SNS raw message delivery](https://docs.aws.amazon.com/sns/latest/dg/sns-large-payload-raw-message-delivery.html)
- [SNS message attributes](https://docs.aws.amazon.com/sns/latest/dg/sns-message-attributes.html)
- [SNS, SQS, or EventBridge decision guide](https://docs.aws.amazon.com/pdfs/decision-guides/latest/sns-or-sqs-or-eventbridge/sns-or-sqs-or-eventbridge.pdf)
