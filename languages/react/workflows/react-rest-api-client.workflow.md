---
workflow_id: WORKFLOW-REACT_REST_API_CLIENT_WORKFLOW
trigger: model_decision
description: "Implement a React + TypeScript + Vite REST client boundary with typed DTO mapping, safe configuration, and ATDD/TDD evidence."
---

# React REST API Client Workflow

Use for React + TypeScript + Vite work that consumes a REST contract. This workflow does not implement Lambda or backend behavior; route backend tasks to the Go or C# adapter workflow under the same spec when the change is full-stack.

## Route The Supporting Workflows

Always load:

- `WORKFLOW-COMMON_BDD_SPECIFICATION_WORKFLOW`
- `WORKFLOW-COMMON_REST_API_DESIGN_WORKFLOW`
- `RULE-REACT_FEATURE_ARCHITECTURE`
- `RULE-REACT_VITE_API_CLIENT`

## Execution Order

1. Record this workflow as primary and the common REST workflow as supporting in `workflow-routing.md`.
2. Write the abstract business scenario and obtain Gate 1 before spec writes; obtain Gate 2 before RED.
3. Confirm the REST contract: resource, method, request/response DTOs, error codes, auth/session context, pagination, cancellation, retry/idempotency, and compatibility.
4. Create the smallest acceptance/component/route RED and the focused pure test RED for the next mapping, validator, reducer, or async-state rule. Apply `RULE-COMMON_TEST_ASSERTION_STRUCTURE` and `RULE-COMMON_TEST_DATA_AND_DOUBLE_PATTERNS`: use exact `// Arrange`, `// Act`, and `// Assert` sections, one physical-line Act interaction, fresh typed data, and assertions only in `// Assert`. Invoke the test-evidence workflow and obtain Gate 3.
5. Implement the narrow boundary: typed API client/service, runtime validation of untrusted data, DTO-owned mapping functions, and a focused hook that exposes UI-facing state/commands.
6. Keep HTTP and transport details out of JSX/presentational components. Components render; hooks coordinate; services communicate; DTO modules translate.
7. Use `unknown` at the external boundary, narrow it with a parser/type guard/schema already accepted by the repository, and preserve strict TypeScript. Do not use `any` to bypass a contract.
8. Handle initial/loading/refresh/empty/error/success, cancellation, stale responses, retry, and auth failures intentionally. Retry only safe/idempotent operations unless the contract supplies an idempotency key.
9. Validate Vite configuration: only public, non-secret values may be exposed through `import.meta.env`; never place credentials or private tokens in `VITE_*` variables or the bundle.
10. Make the focused tests GREEN, refactor with tests green, then run typecheck, lint, build, accessibility, boundary, security, and mandatory coverage gates; E2E remains selected by risk.

## Patterns

Prefer plain typed composition, then a custom hook, reducer/state machine, strategy, compound component, render prop, HOC, or provider only when the behavior requires it. Record the state owner, public TypeScript contract, and rejected simpler option for non-obvious patterns. Keep HOCs generic and ref-safe; keep providers low-frequency and private.

## Done When

The client consumes the agreed REST contract without leaking transport shapes into UI, DTO mapping is owned by DTO modules, configuration contains no secrets, async behavior is explicit, tests prove the observable outcome, and a backend change is routed to the correct Go/C# workflow rather than implemented in the frontend workflow.
