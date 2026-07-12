---
rule_id: RULE-WEB_FRONTEND_ARCHITECTURE
description: Generic web frontend rules for static HTML/CSS/TypeScript projects without React-specific architecture.
globs: **/*.html,**/*.css,**/*.ts,**/*.js,**/*.json
---

# Web Frontend Architecture

## SDD Baseline

- Apply `common/rules/common-sdd-agentic-discipline.md` before this rule.
- Create or evolve the owning User Story based spec before production code when behavior, contracts, architecture, or risk changes.
- Apply mandatory Gate 1 before spec writes, Gate 2 before RED, and Gate 3 before Green, even for simple or low-risk changes.
- Keep artifact, task, track, and test IDs traceable through `traceability.yaml` and `parallel-tracks.md`.
- Write BDD Given/When/Then acceptance evidence first, then the unit-level ATDD-style focused failing test for the next rule or boundary before production code.
- Refactor only with tests green and converge spec history, tasks, parallel tracks, traceability, verification notes, and code.
- Apply `common/rules/common-security-and-identity.md` and `common-sdd-security-gate.workflow.md` for auth, sessions, cookies, secrets, API calls, or public exposure.


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
- Apply `common-test-assertion-structure.md` to frontend tests: keep all assertion APIs in `Then/Assert`, never in setup or action helpers.
- Authenticated web apps use server-managed `HttpOnly`, `Secure`, `SameSite` session cookies by default. Never store access, refresh, or ID tokens in browser-readable storage.
