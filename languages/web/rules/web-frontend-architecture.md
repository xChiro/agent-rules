---
rule_id: RULE-WEB_FRONTEND_ARCHITECTURE
trigger: model_decision
description: "Generic web frontend rules for static HTML/CSS/TypeScript projects without React-specific architecture."
globs: "**/*.html,**/*.css,**/*.ts,**/*.js,**/*.json"
---

# Web Frontend Architecture

## SDD Integration

Apply `RULE-COMMON_SDD_AGENTIC_DISCIPLINE` and `WORKFLOW-WEB_IMPLEMENT_FRONTEND_CHANGE_WORKFLOW`; this rule adds lightweight-web architecture only and cannot relax common gates or convergence. Load the common test rules for frontend tests and the security rule/gate only for auth, sessions, cookies, secrets, API calls, or public exposure.


Use these rules for static sites or lightweight TypeScript/web projects that are not React applications.

## Scope

- Keep HTML, CSS, and TypeScript simple and explicit.
- Preserve existing file structure unless the task requires a better organization.
- Do not introduce React, Next.js, routing frameworks, state managers, or build tooling unless the project already uses them or the task explicitly requires them.
- Prefer semantic HTML, accessible controls, responsive CSS, and small focused scripts.

## UI Quality

- Text must not overflow or overlap at mobile or desktop sizes.
- Use stable dimensions for fixed-format UI elements.
- Keep page sections unframed unless the design needs a real card/list item/modal.
- Avoid decorative complexity that makes the page harder to scan.

## JavaScript And TypeScript

- Keep DOM selection local and named by intent.
- Avoid global mutable state unless it is a small page-level script.
- Split code only when names and ownership stay clearer.
- Do not add test scaffolding only for static markup changes.
- Avoid nested `if/else`, ternary, or `switch` chains for UI modes; use early returns, explicit functions, or a small data/dispatch map.
- Keep simple guards when they are clearer. Refactor repeated/type-driven decisions with the common Fowler guidance, only with behavior-preserving tests green.

## External Boundaries

- Keep API URLs, keys, and environment-specific values outside hard-coded UI logic when the project has config support.
- Do not expose secrets in frontend code.
- Keep DTO types and their boundary mapping functions colocated in the DTO module. A database, HTTP, or message DTO owns conversion to/from the application/UI model; do not create a global mapper utility for one DTO boundary.
- Keep DTO mapping pure and structural. It must not perform I/O, authorization, logging, orchestration, or business policy. Use a boundary-local companion only for generated DTOs or deliberate multi-source projections.
- Handle loading, empty, and error states when the page calls an API.
- Apply `common-test-assertion-structure.md` to frontend tests: use BDD Given/When/Then behavior names and exact `// Arrange`, `// Act`, and `// Assert` comments; `// Act` has exactly one physical-line SUT/user action/public command, and assertion APIs stay only in `// Assert`.
- Use fresh typed Object Mothers/factory functions for UI data, small builders for variants, and scoped fixtures for browser/resource lifecycle. Helpers return data/state and never assert or perform hidden interactions.
- Authenticated web apps use server-managed `HttpOnly`, `Secure`, `SameSite` session cookies by default. Never store access, refresh, or ID tokens in browser-readable storage.
