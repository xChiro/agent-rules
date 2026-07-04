---
trigger: model_decision
description: C# message bus, RabbitMQ, hosted service, SignalR sender, idempotency, and worker boundary rules.
globs: **/*MessageBus*/**/*.cs,**/*HostedService.cs,**/*Consumer*.cs,**/*Producer*.cs,**/*SignalR*.cs
---

# C# Messaging And Hosted Services

Messaging adapters translate external messages into application requests and own broker concerns.

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
- Test senders with fakes where possible and integration tests when contract risk is high.

## Done Criteria

- Broker contracts do not leak inward.
- ACK/NACK ownership is clear.
- Failures are logged once.
- Poison message behavior is deterministic.
- Consumer tests cover valid, invalid, and continuation behavior when relevant.
