---
skill_id: SKILL-REACT_ADVANCED_PATTERNS_SKILL
name: react-advanced-patterns
trigger: model_decision
description: "Senior React and TypeScript pattern selection for composable, testable, accessible feature code."
globs: "**/*.tsx,**/*.ts"
---

# React Advanced Patterns

Use this skill with `react-feature-architecture.md` when a feature needs reusable behavior, flexible rendering, cross-cutting wrappers, shared subtree state, or mode-dependent behavior. The goal is a clear contract and a smaller change surface, not maximum abstraction.

## Pattern Decision Order

Choose the simplest pattern that protects the current requirement:

1. Plain component with explicit typed props.
2. Composition with `children` or named slots.
3. Custom hook for reusable behavior.
4. Reducer or state machine for explicit transitions and invariants.
5. Compound component for a cohesive family with private shared state.
6. Render prop when a state owner must allow caller-controlled rendering.
7. HOC for repeated cross-cutting wrapping behavior across component families.
8. Strategy for behavior that varies by a typed mode, role, or resource type.
9. Provider for stable cross-cutting state/configuration shared by a subtree.

Before choosing steps 5–9, record in the feature plan:

- the problem and repeated behavior being protected;
- the owner of state and side effects;
- the public TypeScript contract;
- why a component, hook, or composition-only solution is insufficient;
- the test that proves the observable contract.

## Composition

- Prefer composition over boolean-prop explosions and hidden control flow.
- Use named slots or render functions when the parent owns layout and the caller owns content.
- Keep slot props narrow and typed; do not expose an internal state object as a public API.
- Use discriminated unions for mutually exclusive component variants.
- Use polymorphic components only when multiple semantic elements are a current requirement; preserve the element's intrinsic props and ref type.

## Custom Hooks

- A hook owns one cohesive behavior and returns named data, status, and commands.
- Keep rendering out of hooks and transport details out of components.
- Return stable command functions only when consumers need referential stability or the hook is used by memoized children.
- Use effects only to synchronize with external systems. Derive render values directly or use memoization for expensive calculations.
- Abort or ignore stale async work and expose retry/refresh behavior when relevant.
- Test hooks through their observable state transitions and commands, not private effects or implementation calls.
- Apply `common-test-assertion-structure.md` and `common-test-data-and-double-patterns.md`: use exact `// Arrange`, `// Act`, and `// Assert` comments, one physical-line Act interaction, fresh typed Object Mothers/builders, and helpers that return state instead of asserting.

## Compound Components

- Keep context private to the component family and expose semantic children.
- Provide a descriptive error when a child is outside its parent.
- Split contexts when state updates have different consumer sets or frequencies.
- Keep business rules in a feature hook/service unless the component is intentionally feature-specific.

## Higher-Order Components

Use HOCs for cross-cutting concerns such as permission gates, auth gates, feature flags, telemetry, or error handling wrappers.

- Name them `withX` and preserve wrapped props using generics.
- Make injected props explicit and remove only the props owned by the HOC.
- Preserve refs with `forwardRef` when the wrapped component exposes a ref contract.
- Set `displayName` for useful development diagnostics.
- Do not fetch feature data, hide unrelated state, or create anonymous HOC stacks.
- Prefer a hook when the behavior belongs to one feature family or a component can compose it directly.

```tsx
type WithPermissionProps = { requiredRole: string };

export function withPermission<P extends object>(
  Component: React.ComponentType<P>,
) {
  function WithPermission(props: P & WithPermissionProps) {
    const { requiredRole, ...rest } = props;
    const allowed = useCanAccess(requiredRole);

    return allowed ? <Component {...(rest as P)} /> : null;
  }

  WithPermission.displayName = `withPermission(${Component.displayName ?? Component.name ?? "Component"})`;
  return WithPermission;
}
```

## Render Props

Use render props for measurement, keyboard navigation, controlled async state, or other cases where one component owns state and the caller owns rendering.

- Type the render function's argument and return value.
- Keep the render contract small and semantic.
- Do not use render props when a custom hook gives the same flexibility with less nesting.

## Strategy Pattern

- Use a discriminated union or typed strategy map for mode-dependent labels, permissions, columns, forms, and commands.
- Keep common rendering in a stable shell and delegate only the changing behavior.
- Make strategies pure where possible and keep I/O in the feature service/hook boundary.
- Test every supported mode and the nearest invalid/unsupported mode.
- Do not build a plugin registry or abstract factory for hypothetical future modes.

## Providers And Context

- Use providers for theme, locale, session capabilities, feature configuration, or other stable cross-cutting concerns.
- Keep provider composition in the app root or an `AppProviders` component.
- Expose a custom hook and fail clearly when used outside the provider.
- Keep context values typed and stable; split contexts by responsibility and update frequency.
- Do not use Context as a server-state cache or a replacement for feature-local state.

## TypeScript Contracts

- Use strict mode and avoid `any`; narrow `unknown` at external boundaries.
- Prefer `satisfies` for typed configuration maps while preserving literal inference.
- Use generic constraints to preserve caller types in reusable tables, lists, forms, and polymorphic components.
- Use `forwardRef` and `ComponentPropsWithoutRef`/`ComponentPropsWithRef` only when the component intentionally forwards a DOM contract.
- Prefer exported prop types for reusable components and local inferred types for implementation details.
- Use `ReactNode` for children/content and explicit function types for render props and callbacks.

## Verification

Before completing a pattern-based change:

- acceptance evidence proves the user-visible behavior;
- focused component/hook tests prove the reusable contract;
- keyboard and accessibility behavior is covered where relevant;
- TypeScript, lint, build, and the project's coverage gate pass;
- the feature spec records the selected pattern, ownership boundary, and any rejected simpler alternatives.
