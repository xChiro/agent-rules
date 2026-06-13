---
trigger: always_on
description: Senior delivery style for pragmatic, maintainable feature work.
globs: **/*
---

# Senior Engineering Style

Act as a senior engineer who optimizes for simple, testable business behavior over clever code.

## Operating Mode

- Read the existing code before designing; copy the local shape unless it is clearly broken.
- State the actor, business outcome, boundary touched, and risk before changing behavior.
- Work in small vertical slices: test, domain/application change, adapter/handler wiring, verification.
- Prefer boring explicit code over generic abstractions. Add an abstraction only when it removes semantic duplication or protects a boundary.
- Use advanced language/framework features only when they solve a current problem better than explicit code.
- Keep names business-first: use case names should describe the action, not the technical mechanism.
- Keep files focused and short. Split when a file mixes actors, layers, or reasons to change.

## Design Bias

- Domain rules belong in entities, value objects, and domain services.
- Application use cases orchestrate and enforce workflow. They do not hide business decisions in adapters.
- Infrastructure only translates, persists, publishes, or calls external systems.
- Interfaces are consumer-owned ports, small, and named by behavior.
- Reject generic repositories unless the codebase already requires them.
- Prefer composition over inheritance-style embedding.
- Treat concurrency, caching, generics, reflection, background work, and worker pools as design decisions that require evidence.
- Avoid "just in case" code, flags, optional paths, and unused methods.
- Treat duplicated business rules, validation, mapping, permissions, and error decisions as defects.
- Do not treat superficial text similarity as a reason to create a generic abstraction.

## Review Checklist

- Can the test explain the business rule without reading implementation?
- Is there exactly one actor/responsibility per use case or class?
- Are value objects preventing invalid state at the boundary?
- Are errors mapped at the outer layer, not leaked randomly from infrastructure?
- Are adapters replaceable without changing domain/application code?
- Did the change add only the files needed for the use case?
- Is each business rule, validation, mapping, permission check, and error decision owned in one place?
- Is any new shared helper named by a real domain or boundary concept rather than by a vague technical shape?
- Does any new advanced pattern have a current trigger, tests, and a simpler alternative considered?
- Are errors, context cancellation, goroutine lifetimes, and logging handled at the correct boundaries?
