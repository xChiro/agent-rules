---
rule_id: RULE-REACT_FEATURE_ARCHITECTURE
trigger: always_on
description: Senior React and TypeScript feature architecture rules with SDD, ATDD-first behavior evidence, composable patterns, and no forced backend-style Clean Architecture.
globs: **/*.tsx,**/*.ts,**/*.css
---

# React Feature Architecture

## SDD Baseline

- Apply `common/rules/common-sdd-agentic-discipline.md` before this rule.
- Create or evolve the owning User Story based spec before production code when behavior, contracts, architecture, or risk changes.
- Apply mandatory Gate 1 before spec writes, Gate 2 before RED, and Gate 3 before Green, even for simple or low-risk changes.
- Apply Gate 4 before marking the spec complete, creating the AI snapshot, or renaming the feature to `specs/features/<number>-<slug>-completed/`.
- Keep artifact, task, track, and test IDs traceable through `traceability.yaml` and `parallel-tracks.md`.
- Write BDD Given/When/Then acceptance evidence first, then the unit-level ATDD-style focused failing test for the next rule or boundary before production code.
- Refactor only with tests green and converge spec history, tasks, parallel tracks, traceability, verification notes, and code.
- Run the security gate for authentication, authorization, cookies, browser storage, API boundaries, secrets, or public exposure.
- For REST-client work, apply `react-vite-api-client.md` and invoke `WORKFLOW-REACT_REST_API_CLIENT_WORKFLOW` with `WORKFLOW-COMMON_REST_API_DESIGN_WORKFLOW`.


These rules define how an AI coding agent must create, review, and refactor React applications.

React projects must not be forced into strict backend-style Clean Architecture. They still follow SDD: behavior starts in a spec, visible acceptance evidence comes before production code, and tests or documented QA prove the user flow. Prefer a standard React feature-based architecture with clear separation between UI, hooks, services, DTO modules, and types.

Use React's composition model as the primary architectural tool. A pattern is justified only when it protects a current boundary, removes meaningful duplication, or makes a difficult call site clearer. Record a non-obvious pattern choice in the feature `plan.md` and cover its observable behavior with tests.

## Core Decision

Do not enforce strict Clean Architecture in React applications.

Use Clean Architecture principles only when they reduce complexity:

- Keep UI independent from API response details.
- Keep data access outside presentational components.
- Keep transformation logic outside JSX.
- Keep feature code grouped by user behavior.
- Avoid unnecessary layers, ports, use cases, or abstractions.

## Frontend Test-First Rule

- For user-visible behavior, write or update the acceptance scenario before changing components.
- Prefer component interaction tests, route/page tests, accessibility checks, visual regression checks, or Playwright flows according to the project stack.
- When automation is not available, define a manual QA checklist in the spec `verification.md` before implementation.
- Unit-test pure mappers, reducers, validators, formatters, permission rules, and state transitions before changing production code.
- Test custom hooks through observable results and user actions; do not assert private hook implementation details or effect call counts.
- Test reusable component contracts through role-, label-, and text-based queries and keyboard interactions.
- Apply `common-test-assertion-structure.md`: keep `expect`/`assert`/matcher calls only in the final `Then/Assert` section; arrange helpers and action helpers do not assert.
- Use snapshot tests only for stable, intentional serialized output; do not use snapshots as a substitute for behavior assertions.
- Do not add backend-style use cases or ports just to satisfy testing discipline.

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
│       ├── dto/
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

### DTOs And Boundary Mapping

DTO modules define the external shape and own the functions that convert it to and from UI/application models. Keep `fromApi`, `toViewModel`, `fromForm`, or equivalent functions in the DTO module, not in a global `mappers/` folder.

Use DTO-owned mapping when:

- API names differ from UI names.
- The UI needs a simplified model.
- A screen should not depend on backend DTO details.
- Optional or nullable values need normalization.

For structural TypeScript DTOs, a module containing the DTO type and its mapping functions is the DTO boundary; do not introduce classes only to place methods on them. A separate mapper is allowed only for generated DTOs that cannot be edited or for deliberate multi-source projections documented by the feature.

DTO mapping must remain structural and pure. It must not perform API calls, authorization, logging, orchestration, or business decisions. Validate untrusted input before constructing the UI/application model.

### Types

Types define clear contracts for a feature.

Rules:

- Prefer explicit TypeScript types.
- Enable and preserve strict TypeScript settings when the project supports them.
- Avoid `any`; use `unknown` at external boundaries and narrow it with type guards, schemas, or safe parsers.
- Use discriminated unions for async state, component variants, and mutually exclusive props.
- Use `satisfies` to validate configuration and column/route maps without widening useful literal types.
- Prefer type-only imports, inferred types for local implementation details, and explicit exported types for public contracts.
- Constrain generics so reusable components preserve the caller's type instead of falling back to `unknown` or `any`.
- Keep domain/UI models separate from API DTOs; use runtime validation when data crosses an untrusted boundary.

## React And TypeScript Pattern Selection

Use this order before introducing an advanced pattern:

1. Plain component with typed props.
2. Composition with `children` or named slots.
3. Custom hook for reusable behavior.
4. Reducer or state machine for explicit state transitions.
5. Compound component when siblings share private state and context.
6. Render prop when a state owner must provide flexible rendering.
7. HOC when the same cross-cutting wrapper must preserve a component contract across unrelated component families.
8. Strategy object/component when behavior, permissions, columns, or commands vary by a discriminated mode.
9. Provider when low-frequency cross-cutting state/configuration must be shared by a subtree.

Do not select a pattern because it is fashionable. The feature plan must state the problem, the chosen owner of state, the public contract, and why a simpler option was insufficient.

## Conditional Rendering And Behavior

- Avoid nested ternaries, `if/else` trees, and `switch` chains in JSX or feature orchestration.
- Use early returns for guards, explicit variant components, composition, or a typed discriminated strategy map for real mode variation.
- Keep a simple two-state render decision when it is the clearest expression; do not add a HOC/provider/registry only to remove one branch.
- When conditional logic is repeated or mixes policy, data fetching, mapping, and rendering, apply the common Fowler refactoring guidance with tests green: Extract Function, Decompose Conditional, Consolidate Conditional Expression, Special Case, or Strategy/Polymorphism.

### Composition And Slots

- Prefer explicit composition over boolean-prop explosions and hidden control flow.
- Use semantic slots such as `header`, `actions`, `emptyState`, or `renderRow` when the parent owns layout and the caller owns content.
- Keep slot props typed and stable; do not pass an unbounded configuration object when a small component contract is enough.
- Use `ReactNode` for rendered content and generic render functions when the caller needs typed data.

### Custom Hooks

- Hooks own behavior, subscriptions, async coordination, and event commands; components own rendering.
- A hook must have one cohesive reason to change and expose a small UI-facing return contract.
- Do not call hooks conditionally, inside loops, or from ordinary functions.
- Prefer returning named fields and commands over positional tuples when the contract has more than two values.
- Keep effects for synchronizing with external systems. Do not use an effect to derive values that can be computed during render.
- Cancel or ignore stale async work and make retry, refresh, and unmount behavior explicit.

### Compound Components

- Use a private, typed context for cohesive families such as tabs, menus, tables, filters, and dialogs.
- Fail clearly when a child is rendered outside its provider.
- Keep child APIs semantic and small; do not expose the context object as the public API.
- Keep business decisions in feature hooks or services unless the compound component is intentionally feature-specific.

### Higher-Order Components

Use HOCs only for cross-cutting wrapping behavior such as authentication gates, permissions, feature flags, telemetry, or error boundaries when the same wrapper applies to multiple component families.

- Name HOCs `withX`, preserve wrapped props with generics, and make injected props explicit.
- Do not hide data fetching or unrelated state inside a HOC.
- Preserve refs with `React.forwardRef` when the wrapped component exposes an imperative DOM contract.
- Set a useful `displayName` in development.
- Avoid stacking anonymous HOCs; compose them with a named helper.
- Prefer hooks for behavior used by only one component family.

```tsx
function withPermission<P extends object>(
  Component: React.ComponentType<P>,
) {
  function WithPermission(props: P & { requiredRole: string }) {
    const { requiredRole, ...componentProps } = props;
    const allowed = useCanAccess(requiredRole);
    return allowed ? <Component {...(componentProps as P)} /> : null;
  }

  WithPermission.displayName = `withPermission(${Component.displayName ?? Component.name ?? "Component"})`;
  return WithPermission;
}
```

### Render Props And Strategies

- Use render props for measurement, keyboard navigation, controlled async state, or other cases where one component owns state and the caller owns rendering.
- Do not use render props when a hook provides the same contract with less nesting.
- Use a typed strategy interface or discriminated strategy map when behavior changes by mode or resource type.
- Keep the common shell stable and put mode-specific labels, permissions, columns, forms, and commands behind the strategy.
- Strategies must be concrete, testable, and close to the feature; do not create speculative plugin systems.

### Providers And Context

- Use providers for stable, low-frequency cross-cutting concerns such as theme, locale, session capabilities, or feature configuration.
- Keep provider composition in `AppProviders` or the app root; do not scatter global setup through feature components.
- Split contexts by update frequency and responsibility to avoid rerendering unrelated consumers.
- Expose custom hooks such as `useTheme` or `useSession`; keep context implementation private.
- Do not use Context as a server-state cache or a dumping ground for feature-local state.

### Controlled And Imperative APIs

- Prefer controlled props for normal form, selection, dialog, and tab state.
- If both controlled and uncontrolled usage is supported, define the contract explicitly and never switch modes after mount.
- Use refs for focus, measurement, media, or third-party integration; avoid imperative handles unless the parent needs a real command API.
- Keep imperative handles small, named, and typed.

## State Management

Use the simplest state strategy that solves the problem:

1. Local state for local UI behavior.
2. URL state for filters, pagination, tabs, and shareable navigation state.
3. Context for low-frequency cross-cutting state.
4. Server-state libraries only when already used or clearly justified.
5. Dedicated client-state libraries only when complexity requires them.

Do not put server data in global client state by default.

- Keep server state, URL state, client state, and ephemeral UI state separate.
- Prefer derived values over duplicated state; if two values can disagree, one should usually be derived.
- Use `useReducer` when transitions are related, sequential, or constrained by a state invariant.
- Model mutually exclusive states with a discriminated union instead of several booleans.
- Keep state as close as possible to the component or feature that owns the behavior.
- Use `useSyncExternalStore` for subscriptions to external stores instead of ad-hoc effects when the store supports it.

## Async UI Rules

Every async screen must intentionally handle:

- Initial state.
- Loading state.
- Empty state.
- Error state.
- Success state.
- Retry or refresh behavior when relevant.
- Cancellation, stale-response protection, and unmount behavior when requests can overlap.
- A visible distinction between initial loading, refreshing, optimistic update, and mutation failure when the workflow needs it.

Do not leave users with blank screens during async operations.

Use `Suspense` and `ErrorBoundary` only when the project's React version and data-loading strategy support them consistently. Every boundary must have a meaningful fallback and an error recovery path; do not hide errors with an empty render.

## Effects And External Synchronization

- Use `useEffect` to synchronize with an external system: network, subscriptions, timers, DOM APIs, browser storage, or third-party widgets.
- Do not use an effect to derive render data, mirror props into state, or respond to an event that can be handled in the event handler.
- Keep each effect focused on one synchronization concern and return cleanup for subscriptions, timers, listeners, and abortable work.
- Treat the exhaustive-deps rule as a design signal. Stabilize a dependency or restructure ownership rather than suppressing it without a documented reason.
- Use `useLayoutEffect` only for layout measurement or visual synchronization that must happen before paint; prefer `useEffect` otherwise.

## Performance Rules

- Do not use `useMemo` or `useCallback` everywhere by default.
- Use `memo`, `useMemo`, and `useCallback` only when profiling, a large subtree, referential equality, or an expensive calculation justifies them.
- Lazy-load heavy routes, maps, editors, charts, and admin-only sections.
- Avoid rendering large dynamic lists without pagination or virtualization.
- Check bundle impact before adding dependencies.
- Use stable domain keys; never use array indexes when item identity can change.
- Consider `useTransition` or `useDeferredValue` for non-urgent rendering work only after the interaction remains correct without them.
- Keep provider values stable and split providers by responsibility/update frequency.
- Measure with React DevTools Profiler or the project's performance tooling before making broad memoization changes.

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
- Add normalization functions to the DTO module that owns the external shape; use a boundary-local companion only for generated DTOs or deliberate multi-source projections.
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

- Apply `common/rules/common-security-and-identity.md` and `common-sdd-security-gate.workflow.md` for auth, sessions, cookies, API calls, secrets, or public exposure.
- Never expose secrets in frontend code.
- Authorization-sensitive behavior must be validated by the backend.
- Treat browser input as untrusted.
- Avoid `dangerouslySetInnerHTML`; use it only with trusted and sanitized content.
- Authenticated web apps use server-managed `HttpOnly`, `Secure`, `SameSite` session cookies or an explicitly reviewed BFF pattern. Never put access, refresh, or ID tokens in `localStorage` or `sessionStorage`.

## Explicit Exclusions

These React rules must not include:

- Backend-style Clean Architecture layers as mandatory structure.
- Ports and adapters as default frontend architecture.
- Speculative abstractions for future screens.

These exclusions do not remove SDD or ATDD. User-visible React behavior still starts from User Stories, BDD Given/When/Then acceptance evidence, and ATDD-style component/page/flow tests or documented manual QA when automation is not available yet.
