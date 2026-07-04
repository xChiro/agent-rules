---
description: Implement a C# message consumer or hosted worker with clean mapping, application use case delegation, idempotency, and tested failure handling.
---

# C# Implement Message Consumer Workflow

Use this workflow for RabbitMQ or other message-driven processing.

## Phase 1: Contract

**Goal**: Define the external message.

Checklist:

- Identify queue/topic and message source.
- Identify message id/correlation id.
- Define message DTO in the adapter project.
- Decide poison message behavior.
- Decide idempotency requirement.

## Phase 2: Application Boundary

**Goal**: Keep broker details out of core.

Checklist:

- Create or reuse application request/use case.
- Map broker DTO to application request.
- Keep delivery tags, queue names, and ACK/NACK out of use cases.
- Use value objects for business inputs.

## Phase 3: Tests

**Goal**: Prove both behavior and adapter policy.

Checklist:

- Unit test application behavior.
- Integration test consumer with real broker when broker behavior matters.
- Test valid message processing.
- Test malformed/poison message classification.
- Test processing continues after a classified bad message when required.
- Test idempotency when duplicate messages are possible.

## Phase 4: Consumer Implementation

**Goal**: Own transport concerns at the boundary.

Checklist:

- Deserialize safely.
- Map to application request.
- Call one use case.
- ACK/NACK/requeue/drop based on classified outcome.
- Log final failures once with safe metadata.
- Respect cancellation.

## Phase 5: Hosted Service

**Goal**: Integrate lifecycle safely.

Checklist:

- Start consuming in `StartAsync` or execute loop.
- Stop gracefully with cancellation token.
- Create scopes when resolving scoped dependencies from a singleton hosted service.
- Avoid blocking calls in async flow.
- Register options and clients in composition root.

## Phase 6: Verify

**Goal**: Prove runtime behavior.

Checklist:

- Run message integration tests.
- Confirm application/domain does not reference broker packages.
- Confirm raw payloads/secrets are not logged.
- Confirm retry/DLQ/idempotency behavior is explicit.
