---
description: React feature-based architecture standards without strict Clean Architecture, TDD, or testing requirements
---

# React Feature Architecture Standards

These rules define how an AI coding agent must create, review, and refactor React applications.

React projects must not be forced into strict backend-style Clean Architecture. Prefer a standard React feature-based architecture with clear separation between UI, hooks, services, mappers, and types.

## Core Decision

Do not enforce strict Clean Architecture in React applications.

Use Clean Architecture principles only when they reduce complexity:

- Keep UI independent from API response details.
- Keep data access outside presentational components.
- Keep transformation logic outside JSX.
- Keep feature code grouped by user behavior.
- Avoid unnecessary layers, ports, use cases, or abstractions.

## Recommended Structure

Use feature-based organization for medium and large React applications:

```text
src/
├── app/
│   ├── providers/
│   ├── router/
│   └── config/
├── shared/
│   ├── components/
│   ├── hooks/
│   ├── utils/
│   └── types/
├── features/
│   └── example-feature/
│       ├── components/
│       ├── hooks/
│       ├── services/
│       ├── mappers/
│       └── types.ts
└── pages/ or routes/
```

## Responsibility Rules

### Components

Components render UI and expose user interactions.

They should not:

- Call APIs directly.
- Contain complex data transformation logic.
- Know raw backend response shapes.
- Manage unrelated workflows.
- Become large screen-level scripts.

### Hooks

Hooks orchestrate behavior for a component, screen, or feature.

Hooks may:

- Coordinate local state.
- Call feature services.
- Adapt data for components.
- Handle loading, empty, error, and success states.
- Expose event handlers to the UI.

Hooks should stay focused and should not become hidden service layers.

### Services

Services communicate with external systems such as HTTP APIs, browser APIs, storage, or SDKs.

Rules:

- Keep HTTP details inside services or API clients.
- Do not leak request implementation details to components.
- Do not hide UI state inside services.
- Keep services simple and project-specific.

### Mappers

Mappers convert external data into UI-friendly models.

Use mappers when:

- API names differ from UI names.
- The UI needs a simplified model.
- A screen should not depend on backend DTO details.
- Optional or nullable values need normalization.

### Types

Types define clear contracts for a feature.

Rules:

- Prefer explicit TypeScript types.
- Avoid `any` unless there is no practical alternative.
- Use `unknown` for external input until it is narrowed.
- Use discriminated unions for UI states when useful.

## State Management

Use the simplest state strategy that solves the problem:

1. Local state for local UI behavior.
2. URL state for filters, pagination, tabs, and shareable navigation state.
3. Context for low-frequency cross-cutting state.
4. Server-state libraries only when already used or clearly justified.
5. Dedicated client-state libraries only when complexity requires them.

Do not put server data in global client state by default.

## Async UI Rules

Every async screen must intentionally handle:

- Initial state.
- Loading state.
- Empty state.
- Error state.
- Success state.
- Retry or refresh behavior when relevant.

Do not leave users with blank screens during async operations.

## Performance Rules

- Do not use `useMemo` or `useCallback` everywhere by default.
- Use memoization only when it solves a real readability, dependency, or rendering problem.
- Lazy-load heavy routes, maps, editors, charts, and admin-only sections.
- Avoid rendering large dynamic lists without pagination or virtualization.
- Check bundle impact before adding dependencies.

## Duplication Rules

Avoid duplicated behavior and decisions, not just repeated text.

### Must Not Be Duplicated

- API request construction, auth headers, retry/error handling, or response parsing.
- DTO-to-UI mapping logic.
- Permission and feature-flag checks.
- Form validation rules.
- Table column behavior, sorting, filtering, pagination, and row actions.
- Loading, empty, error, and success state handling for the same async workflow.
- Formatting for dates, numbers, status labels, and domain-specific display values.

### Allowed Temporary Duplication

- Two similar components while UX requirements are still diverging.
- Small explicit JSX when abstraction would hide intent.
- Local test or story data that keeps a scenario readable.
- Similar UI layout with different business meaning.

### Extraction Rules

- Extract a custom hook for repeated behavior.
- Extract a mapper for repeated DTO normalization.
- Extract a UI primitive for repeated visual structure.
- Extract a HOC only for repeated cross-cutting wrappers such as auth, permissions, telemetry, or feature flags.
- Extract compound components only when a component family shares state.
- Do not create generic "common" helpers without a clear domain, UI, or boundary name.

## Accessibility Rules

- Use semantic HTML first.
- Buttons perform actions; links navigate.
- Inputs must have accessible labels.
- Dialogs must manage focus.
- Menus and dropdowns must support keyboard interaction.
- Images need meaningful alt text, or empty alt text when decorative.
- Do not rely only on color to communicate meaning.

## Security Rules

- Never expose secrets in frontend code.
- Authorization-sensitive behavior must be validated by the backend.
- Treat browser input as untrusted.
- Avoid `dangerouslySetInnerHTML`; use it only with trusted and sanitized content.

## Explicit Exclusions

These React rules must not include:

- TDD requirements.
- Automated testing requirements.
- Backend-style Clean Architecture layers as mandatory structure.
- Ports and adapters as default frontend architecture.
- Speculative abstractions for future screens.
