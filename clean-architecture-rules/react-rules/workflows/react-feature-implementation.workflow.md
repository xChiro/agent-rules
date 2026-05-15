---
description: Standard workflow for implementing React features using feature-based architecture
---

# React Feature Implementation Workflow

This workflow defines how an AI coding agent should implement or modify React frontend features.

The workflow prioritizes:

- Readability
- Feature-based organization
- Separation of UI and behavior
- Good user experience
- Maintainable React patterns
- Avoiding unnecessary abstractions

This workflow intentionally does NOT enforce:

- TDD
- Automated testing
- Strict backend-style Clean Architecture

## Step 1 — Understand the Feature

Before writing code:

- Identify the user behavior.
- Identify async interactions.
- Identify loading, error, and empty states.
- Identify reusable UI vs feature-specific UI.
- Identify whether URL state should be preserved.
- Identify whether the feature belongs inside an existing feature folder.

## Step 2 — Organize by Feature

Prefer:

```text
features/
└── crew-search/
    ├── components/
    ├── hooks/
    ├── services/
    ├── mappers/
    └── types.ts
```

Avoid creating global shared code too early.

## Step 3 — Define Types First

Create explicit TypeScript types for:

- UI models
- API responses when needed
- Component props
- Async states

Avoid `any` unless absolutely necessary.

## Step 4 — Implement Services

Services should:

- Encapsulate API access.
- Keep HTTP details out of components.
- Return predictable data.
- Avoid leaking transport details to the UI.

## Step 5 — Create Hooks

Hooks orchestrate feature behavior.

Hooks may:

- Fetch or mutate data.
- Coordinate local state.
- Expose UI event handlers.
- Normalize async states.

Hooks should not:

- Render UI.
- Become giant service layers.
- Mix unrelated workflows.

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

## Anti-Patterns

Avoid:

- Huge page components.
- API logic directly inside JSX files.
- Global state for local behavior.
- Deep prop drilling when composition solves the issue.
- Premature abstractions.
- Strict backend Clean Architecture layers in frontend code.
- Overusing Context for frequently changing state.
