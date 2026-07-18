---
workflow_id: WORKFLOW-REACT_IMPLEMENT_FEATURE_WORKFLOW
trigger: manual
description: "Standard workflow for implementing React features using feature-based architecture"
---

# React Implement Feature Workflow

## SDD Baseline

This workflow specializes `WORKFLOW-COMMON_SDD_CHANGE_LIFECYCLE_WORKFLOW`; the parent owns Gates 1–3, the final evidence review, spec artifacts, routing, documentation, clean-up, security, coverage, and convergence. After Gate 2, create the smallest BDD-linked component/route RED, apply the common test assertion/data rules, obtain Gate 3, implement minimally, and refactor only while tests stay green. Do not duplicate or reorder the parent lifecycle here.


This workflow defines how an AI coding agent should implement or modify React frontend features.

## Workflow Routing For REST Clients

When the feature consumes or changes a REST contract, invoke `WORKFLOW-REACT_REST_API_CLIENT_WORKFLOW` as the supporting workflow and `WORKFLOW-COMMON_REST_API_DESIGN_WORKFLOW` for the contract. Record both in `workflow-routing.md` and on the affected task. If the same spec changes a Go or C# backend, route that task to the corresponding backend REST/Lambda workflow; do not implement backend behavior here.

The workflow prioritizes:

- Readability
- Feature-based organization
- Separation of UI and behavior
- Good user experience
- Maintainable React patterns
- Avoiding unnecessary abstractions

This workflow intentionally does not force backend-style Clean Architecture into React.

For advanced reusable behavior, load `languages/react/skills/react-advanced-patterns-skill.md` and record the selected pattern and rejected simpler alternatives in `plan.md`.

It still enforces SDD for behavior changes:

- User Stories before production code.
- BDD Given/When/Then acceptance evidence.
- Unit-level ATDD-style frontend test code or documented manual QA when automation is not available yet.
- Small vertical slices and explicit `parallel-tracks.md` ownership for concurrent agent work.

## Step 1 — Understand the Feature

Before writing code:

- Locate or create the owning User Story based spec.
- Confirm the BDD acceptance scenario and verification status.
- Check `parallel-tracks.md` before editing files.
- Identify the user behavior.
- Identify async interactions.
- Identify REST/API-client boundaries and route them through `WORKFLOW-REACT_REST_API_CLIENT_WORKFLOW` before service or hook code.
- Identify loading, error, and empty states.
- Identify reusable UI vs feature-specific UI.
- Identify whether URL state should be preserved.
- Identify whether the feature belongs inside an existing feature folder.
- Identify the current React/TypeScript version, compiler strictness, test runner, lint rules, styling system, and server-state approach before introducing APIs or dependencies.
- Identify the state owner, external systems, accessibility contract, and error/recovery boundaries.

## Step 2 — Organize by Feature

Prefer:

```text
features/
└── crew-search/
    ├── components/
    ├── hooks/
    ├── services/
    ├── dto/
    └── types.ts
```

Avoid creating global shared code too early.

## Step 3 — Define Types First

Create explicit TypeScript types for:

- UI models
- API responses when needed
- Component props
- Async states
- Discriminated component variants and mutually exclusive props
- Runtime parsing/narrowing types for untrusted API, storage, or URL input

Keep each external DTO type and its `fromApi`/`toViewModel` or equivalent mapping functions in the same DTO module. Use a boundary-local companion only for generated DTOs or deliberate multi-source projections; do not create a global mapper folder.

Use strict TypeScript where supported. Avoid `any`; use `unknown` and narrow it with type guards or a runtime schema. Use `satisfies` for typed configuration maps and generic constraints for reusable components.

## Step 4 — Implement Services

Services should:

- Encapsulate API access.
- Keep HTTP details out of components.
- Return predictable data.
- Avoid leaking transport details to the UI.
- Keep the configured client, cancellation, error normalization, runtime parsing, and DTO-owned mapping at the boundary defined by `WORKFLOW-REACT_REST_API_CLIENT_WORKFLOW`.

## Step 5 — Create Hooks

Hooks orchestrate feature behavior.

Hooks may:

- Fetch or mutate data.
- Coordinate local state.
- Expose UI event handlers.
- Normalize async states.
- Coordinate cancellation, stale-response protection, retry, and refresh behavior when requests overlap.

Hooks should not:

- Render UI.
- Become giant service layers.
- Mix unrelated workflows.
- Derive values through effects when they can be computed during render.

## Step 5a — Select Advanced Patterns Deliberately

Use the simplest pattern that satisfies the current contract:

1. Plain typed component.
2. Composition with children or named slots.
3. Custom hook.
4. Reducer/state machine for explicit transitions.
5. Compound component for private shared state.
6. Render prop when the caller must own rendering.
7. HOC for repeated cross-cutting wrappers such as permissions, auth, telemetry, or feature flags.
8. Strategy for typed mode-dependent behavior.
9. Provider for stable cross-cutting subtree state.

For patterns 5–9, document the state owner, public TypeScript contract, reason simpler composition was insufficient, and the focused test that protects the behavior. Preserve refs and wrapped props in HOCs, keep context private in compound components/providers, and avoid speculative registries or plugin systems.

## Step 6 — Build Components

Components should:

- Focus on rendering.
- Receive simple props.
- Avoid business orchestration.
- Avoid direct API calls.
- Keep JSX readable.

Extract components when JSX becomes difficult to scan.

## Step 7 — Handle All Async States

Every async screen must intentionally support:

- Initial state.
- Loading state.
- Empty state.
- Error state.
- Success state.
- Retry behavior when appropriate.
- Initial load versus refresh/mutation states when users need to distinguish them.
- Cancellation, stale response protection, and recovery from errors.

## Step 8 — Accessibility Review

Verify:

- Semantic HTML.
- Keyboard navigation.
- Accessible labels.
- Proper button and link usage.
- Dialog focus management.
- Meaningful alt text.

## Step 9 — Performance Review

Review:

- Large unnecessary renders.
- Unnecessary global state.
- Large dependencies.
- Heavy components that should be lazy-loaded.
- Very large lists without virtualization.
- Stable domain keys instead of array indexes for dynamic collections.
- React DevTools Profiler evidence before broad `memo`, `useMemo`, or `useCallback` changes.
- `useTransition`/`useDeferredValue` only for verified non-urgent rendering work.
- Stable provider values and split contexts when update frequency differs.

Do not add memoization everywhere by default.

## Step 10 — Final Cleanup

Before completing the task:

- Remove unused code.
- Remove dead state.
- Remove unnecessary abstractions.
- Remove duplicated logic.
- Simplify props.
- Keep files focused.
- Verify feature organization remains understandable.
- Run TypeScript, lint, build, focused tests, accessibility checks, and the repository's coverage command when available.
- Confirm the spec records pattern choices, architecture boundaries, verification evidence, and remaining risks.

## Anti-Patterns

Avoid:

- Huge page components.
- API logic directly inside JSX files.
- Global state for local behavior.
- Deep prop drilling when composition solves the issue.
- Premature abstractions.
- Strict backend Clean Architecture layers in frontend code.
- Overusing Context for frequently changing state.
