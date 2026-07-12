---
rule_id: RULE-CSHARP_MESSAGING_WORKERS
trigger: model_decision
description: C# message bus, RabbitMQ, hosted service, SignalR sender, idempotency, and worker boundary rules.
globs: **/*MessageBus*/**/*.cs,**/*HostedService.cs,**/*Consumer*.cs,**/*Producer*.cs,**/*SignalR*.cs
---

# C# Messaging Workers

## SDD Baseline

- Apply `common/rules/common-sdd-agentic-discipline.md` before this rule.
- Create or evolve the owning User Story based spec before production code when behavior, contracts, architecture, or risk changes.
- Apply mandatory Gate 1 before spec writes, Gate 2 before RED, and Gate 3 before Green, even for simple or low-risk changes.
- Keep artifact, task, track, and test IDs traceable through `traceability.yaml` and `parallel-tracks.md`.
- Write BDD Given/When/Then acceptance evidence first, then the unit-level ATDD-style focused failing test for the next rule or boundary before production code.
- Refactor only with tests green and converge spec history, tasks, parallel tracks, traceability, verification notes, and code.
- Route `sns-publisher` through `WORKFLOW-COMMON_AWS_SNS_PUBLISH_WORKFLOW` and `sqs-consumer` through `WORKFLOW-COMMON_AWS_SQS_CONSUMER_WORKFLOW`; record the selected workflow in `workflow-routing.md`.

Messaging adapters translate external messages into application requests and own broker concerns.

For AWS SNS/SQS work, route through `WORKFLOW-COMMON_AWS_SNS_PUBLISH_WORKFLOW` or `WORKFLOW-COMMON_AWS_SQS_CONSUMER_WORKFLOW`. The common workflow owns IaC and Lambda event-source decisions; this rule owns C# boundary execution.

## Boundaries

Message bus projects own:

- broker clients and connections
- producers and consumers
- message DTOs/contracts
- serialization/deserialization
- queue/topic names
- ACK/NACK/retry/drop decisions
- safe operational logging

Application/domain must not know broker details.

## Consumers

Consumers should:

- deserialize and validate transport shape
- map message DTO to application request/value objects
- call one use case/application service
- decide ACK/NACK/requeue/drop at the boundary
- log final failure once with safe metadata
- keep processing after classified poison messages when appropriate

Consumers should not:

- put domain rules in message DTO mapping
- log raw full payloads by default
- swallow exceptions without deciding message outcome
- requeue poison messages forever
- pass broker delivery details into use cases

## Producers

Producers should:

- publish stable message contracts
- include message id/correlation id when useful
- keep serialization in the adapter
- hide broker client details behind a port when called by application code
- keep event/message DTO mapping functions on the DTO module; do not create a global mapper service

## AWS SNS/SQS Lambda Boundaries

- Keep SNS/SQS/Lambda SDK types in the outer adapter and map to application commands immediately.
- For SNS, publish stable facts through an application port; keep topic, subscription, filter, attribute, retry, and IAM details in infrastructure.
- For SQS event sources, process the batch through one application operation per valid record and return only failed identifiers when partial batch responses are enabled.
- Never swallow a record exception and return success; that acknowledges a failed message.
- Configure source-queue redrive/DLQ, visibility timeout, batch window/size, and concurrency in checked-in IaC. Apply the common workflow formula and idempotency rules.

## Idempotency

Use idempotency when duplicate messages are possible.

- Prefer message ids.
- Enforce uniqueness in the database when persistence is involved.
- Make repeated processing safe.
- Add tests for duplicate messages when the business risk is real.

## Hosted Services

- Respect `CancellationToken`.
- Keep start/stop logs concise.
- Catch exceptions at the top loop only when the service owns recovery.
- Avoid blocking calls in async loops.
- Avoid resolving scoped services from root provider without creating a scope.
- Keep worker orchestration separate from domain/application behavior.

## SignalR And Realtime Senders

- Treat SignalR as an interface adapter.
- Map domain/application output to client DTOs.
- Do not leak hub context into domain/application.
- Test sender/consumer decisions with unit tests. When the outcome is exposed by the service, verify local broker and persistence wiring through the HTTP integration suite; do not add a separate messaging integration suite.

## Done Criteria

- Broker contracts do not leak inward.
- ACK/NACK ownership is clear.
- Failures are logged once.
- Poison message behavior is deterministic.
- Consumer tests cover valid, invalid, and continuation behavior when relevant.
