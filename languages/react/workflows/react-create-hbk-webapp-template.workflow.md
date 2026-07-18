---
workflow_id: WORKFLOW-REACT_CREATE_HBK_WEBAPP_TEMPLATE_WORKFLOW
trigger: manual
description: "Workflow for creating the HBK React webapp template with theme, i18n, shared UI primitives, and AI-ready docs"
reference_project: hbk-identity-webapp
---

# React Create HBK Webapp Template Workflow

## SDD Baseline

This workflow specializes `WORKFLOW-COMMON_SDD_CHANGE_LIFECYCLE_WORKFLOW`; the parent owns Gates 1–3, the final evidence review, spec artifacts, routing, documentation, clean-up, security, coverage, and convergence. After Gate 2, create the smallest BDD-linked template behavior RED, apply the common test assertion/data rules, obtain Gate 3, implement minimally, and refactor only while tests stay green. Do not duplicate or reorder the parent lifecycle here.


This workflow defines how an AI coding agent should create a new HBK React webapp template.

Use this workflow when the requested output is the default HBK frontend foundation, not a one-off screen or feature.

`hbk-identity-webapp` is the canonical reference project. When it exists in the accessible workspace, inspect its current package versions, providers, theme contract, i18n setup, shared primitives, test setup, lint/build scripts, and directory structure before planning. Preserve newer proven conventions from that project unless the target repository has an explicit local standard. When it is unavailable, use the contract in this workflow and record that the reference comparison could not be performed.

The template must create:

- A Vite + React + TypeScript application foundation.
- A shared-first component structure.
- A typed theme system with CSS custom properties.
- The `hbk` theme as the default theme.
- Light and dark themes as available alternatives.
- i18n infrastructure with English and Spanish locales.
- Basic shared controls for language and theme switching.
- AI-readable project documentation.

This workflow intentionally does not turn the frontend into backend-style Clean Architecture. Keep the template simple, reusable, and easy to extend.

## Step 1 - Confirm Template Scope

Before writing code, identify:

- The app name and package name.
- Whether this is a new project or an existing React project receiving the HBK template.
- Whether the project already uses Vite, React, TypeScript, npm, ESLint, CSS modules, Tailwind, or a different styling stack.
- Whether the user wants only the template foundation or also a first business feature.

Default stack when the user does not specify otherwise:

- React 19 or the latest compatible React version already used by the workspace.
- TypeScript strict mode.
- Vite.
- npm.
- ESLint.
- Vitest and React Testing Library, or the current test stack from `hbk-identity-webapp`.
- `i18next` and `react-i18next`.
- `clsx` for class composition.
- `tailwind-merge` only when Tailwind utility classes are actually configured.

Do not introduce a component library by default. The HBK template starts with local UI primitives.

## Step 2 - Create The Project Skeleton

Create or normalize this structure:

```text
src/
├── components/
│   ├── shared/
│   │   ├── LanguageSwitcher.tsx
│   │   ├── ThemeToggle.tsx
│   │   └── index.ts
│   └── ui/
│       ├── Button.tsx
│       └── index.ts
├── hooks/
│   ├── index.ts
│   ├── useTheme.ts
│   └── useTranslation.ts
├── i18n/
│   ├── config.ts
│   └── locales/
│       ├── en/
│       │   ├── auth.json
│       │   └── common.json
│       └── es/
│           ├── auth.json
│           └── common.json
├── theme/
│   ├── context.tsx
│   ├── theme.css
│   ├── themes/
│   │   ├── dark.ts
│   │   ├── hbk.ts
│   │   ├── index.ts
│   │   └── light.ts
│   └── types.ts
├── utils/
│   └── cn.ts
├── App.css
├── App.tsx
├── index.css
└── main.tsx
```

Create tests before their production components. At minimum, start with failing tests for:

- the HBK theme being the default
- changing theme through the user control
- changing English/Spanish through the user control
- the default shell rendering translated text and accessible controls

Add feature folders only when there is an actual business feature. The base template should not create speculative `features/`, `services/`, or `types/` trees unless the app already needs them.

## Step 3 - Establish The Theme Contract

Create a single typed theme contract in `src/theme/types.ts`.

The contract must include:

- `colors`: `primary`, `primaryHover`, `secondary`, `background`, `surface`, `text`, `textSecondary`, `border`, `error`, `success`, `warning`.
- `typography`: `fontFamily`, `fontSize`, `fontWeight`, `lineHeight`.
- `spacing`: `xs`, `sm`, `md`, `lg`, `xl`, `2xl`.
- `borderRadius`: `sm`, `md`, `lg`, `full`.
- `shadows`: `sm`, `md`, `lg`.
- `ThemeName`: `dark`, `light`, `custom`, `hbk`.

Keep the theme contract stable. Components should consume CSS variables, not import individual theme objects directly.

## Step 4 - Define The HBK Theme

Create `src/theme/themes/hbk.ts` and make it the default theme in `src/theme/themes/index.ts`.

The HBK theme must preserve the brand direction:

- Orange primary: `#ff6b00`.
- Dark background: `#0a0a0a`.
- Dark surface: `#121212`.
- White text: `#ffffff`.
- Muted secondary text: `#a0a0a0`.
- Dark border: `#1a1a1a`.
- Typography preference: `Orbitron, Rajdhani, "Exo 2", Inter, -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif`.

Also create `light` and `dark` themes using the same contract. Keep `custom` mapped to `light` until backend-provided themes exist.

## Step 5 - Apply Theme Variables

Create `src/theme/context.tsx` with a `ThemeProvider` that:

- Stores `themeName`.
- Resolves the active `Theme`.
- Applies theme values to `document.documentElement`.
- Writes CSS custom properties with these prefixes:
  - `--theme-colors-*`
  - `--theme-typography-*`
  - `--theme-spacing-*`
  - `--theme-borderRadius-*`
  - `--theme-shadows-*`
- Exposes `theme`, `themeName`, and `setTheme`.
- Throws a clear error when `useTheme` is used outside the provider.

Create `src/theme/theme.css` with safe defaults so the app is readable before React applies runtime variables.

## Step 6 - Add Internationalization

Create `src/i18n/config.ts` using `i18next` and `react-i18next`.

Default locale behavior:

- `lng`: `en`.
- `fallbackLng`: `en`.
- Namespaces: `common` and `auth`.
- Languages: `en` and `es`.

Translation files must exist for every namespace in both languages:

```text
src/i18n/locales/en/common.json
src/i18n/locales/en/auth.json
src/i18n/locales/es/common.json
src/i18n/locales/es/auth.json
```

Rules:

- Do not hardcode user-facing text in reusable components.
- Keep matching keys across languages.
- Organize future translations by feature namespace.

## Step 7 - Create Common UI Building Blocks

Create `src/utils/cn.ts` using `clsx`. Add `tailwind-merge` only if Tailwind is installed and configured.

Do not copy Tailwind-looking utility classes into components unless the project has a working Tailwind setup. If Tailwind is not configured, implement component styling through CSS classes and theme CSS variables.

Create `src/components/ui/Button.tsx` as the first primitive:

- Variants: `primary`, `secondary`, `ghost`, `danger`.
- Sizes: `sm`, `md`, `lg`.
- `isLoading` support.
- Accessible disabled behavior.
- Theme-aware styling through CSS variables.
- `className` composition through `cn`.

Create shared controls:

- `src/components/shared/ThemeToggle.tsx`
- `src/components/shared/LanguageSwitcher.tsx`

Both should use the `Button` primitive and translation hooks.

## Step 8 - Wire Providers At The Root

In `src/main.tsx`:

- Import global CSS.
- Import `src/theme/theme.css`.
- Import `src/i18n/config`.
- Wrap `<App />` with `ThemeProvider`.

Keep provider order explicit and easy to extend. Add more providers only when the app actually needs them.

## Step 9 - Build The Default App Shell

Create a small default shell in `App.tsx` that proves the template works:

- Header with app title.
- `LanguageSwitcher`.
- `ThemeToggle`.
- A body section using translated copy.
- A sample `Button`.
- Styles that consume theme CSS variables.

The shell should demonstrate the template without becoming a marketing landing page or a fake business feature.

## Step 10 - Add Documentation

Create:

- `README.md`: project purpose, stack, scripts, structure, theme system, i18n, component architecture.
- `docs/README.md`: human-readable architecture and contribution guidelines.
- `docs/AI.md`: concise AI-optimized project context, stack, structure, and decisions.

The docs must mention:

- Shared-first component design.
- UI primitives vs shared components.
- Theme contract and CSS variable strategy.
- HBK as the default theme.
- i18n namespace conventions.
- TypeScript strictness.
- Accessibility expectations.
- Security expectations for frontend code.

## Step 11 - Verify The Template

Before completing the task:

- Run the package manager install if dependencies are missing and the user allows dependency installation.
- Run `npm run build`.
- Run `npm run lint`.
- Run the repository's unit/component test command.
- Confirm the app starts with the HBK theme by default.
- Confirm theme switching works.
- Confirm language switching works.
- Confirm there is no hardcoded user-facing text in reusable shared components.
- Confirm no secrets or environment-specific credentials were introduced.

For a new template, create the test setup and failing tests before the corresponding production code. For an existing project, preserve its established test runner unless the spec explicitly approves migration.

## Anti-Patterns

Avoid:

- Creating backend Clean Architecture folders in the React template.
- Adding ports, use cases, repositories, or adapters by default.
- Adding a global state library before there is real shared state pressure.
- Adding a UI component library before local primitives are insufficient.
- Creating generic `common` helpers without a clear frontend responsibility.
- Duplicating theme values directly inside components.
- Mixing feature-specific business logic into `components/shared`.
- Creating empty future folders that make the template look more mature than it is.
