---
description: Create a reliable C# integration test for EF Core, WebApi, message bus, hosted service, or DI wiring.
---

# C# Create Integration Test Workflow

Use this workflow when a behavior depends on real infrastructure or public runtime wiring.

## Phase 1: Risk

**Goal**: Identify why unit tests are insufficient.

Checklist:

- EF mapping/schema?
- HTTP contract/middleware?
- message broker behavior?
- hosted service lifecycle?
- DI composition?
- transaction/idempotency?

## Phase 2: Fixture

**Goal**: Use existing infrastructure setup.

Checklist:

- Reuse existing fixture/container manager.
- Start only required dependencies.
- Reset state between tests.
- Keep configuration local to the test environment.
- Avoid relying on developer machine services.

## Phase 3: Test

**Goal**: Exercise the real boundary.

Checklist:

- Use real adapter/client/host.
- Seed minimal data.
- Execute one behavior.
- Assert observable external result.
- Assert persistence/message/API contract, not private implementation.

## Phase 4: Reliability

**Goal**: Remove flakiness.

Checklist:

- Avoid unbounded sleeps.
- Prefer polling with timeout or deterministic signal for async processing.
- Clean up connections and data.
- Avoid shared mutable static state.
- Keep tests independent.

## Phase 5: Verify

**Goal**: Ensure the test is useful.

Checklist:

- It fails when mapping/wiring is broken.
- It does not duplicate a pure unit test.
- It runs with the documented command.
- It leaves infrastructure clean.
