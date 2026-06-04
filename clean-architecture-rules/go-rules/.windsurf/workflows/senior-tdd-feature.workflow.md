---
trigger: manual
description: Implement a feature in senior TDD style using DDD, Clean Architecture, CQRS, and value objects.
---

# Senior TDD Feature Workflow

Use this workflow whenever implementing or changing business behavior.

## 1. Read and Frame

- Identify the bounded context, actor, use case, and business outcome.
- Locate the closest existing use case, tests, ports, value objects, and adapters.
- State which layer owns the rule.

## 2. Red

- Write the smallest failing test first.
- Prefer an edge case if it defines an invariant; otherwise start with the happy path.
- Keep Given setup clear, When as one behavior call, Then as observable assertions.

## 3. Domain/Application Green

- Add value objects/entities/domain methods before duplicating primitive validation.
- Add one command/query/validation port per dependency.
- Implement only the orchestration and behavior required by the failing test.

## 4. Adapters and Wiring

- Implement infrastructure adapters after ports are stable.
- Map DTOs at boundaries only.
- Wire DI/composition last.

## 5. Refactor and Verify

- Remove unused helpers, ports, request fields, and duplicate validations.
- Check file size, naming, and dependency direction.
- Run targeted tests, then broader tests when adapters or wiring changed.
- Summarize behavior added, tests run, and residual risk.

