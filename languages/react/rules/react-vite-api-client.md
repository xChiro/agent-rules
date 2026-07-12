---
rule_id: RULE-REACT_VITE_API_CLIENT
trigger: model_decision
description: React, TypeScript, and Vite rules for safe REST client boundaries and typed asynchronous behavior.
globs: **/*.ts,**/*.tsx,**/vite.config.*,**/.env*
---

# React + TypeScript + Vite API Client

## Boundary

- Keep API clients/services outside presentational JSX.
- Keep DTO types and their `fromApi`/`toViewModel`/`fromForm` mapping functions in the same DTO module.
- Parse untrusted response, storage, URL, and environment input before constructing UI models; use `unknown`, strict types, and narrowers instead of `any`.
- Keep server state, URL state, client state, and ephemeral UI state separate.
- Normalize transport errors once at the client boundary; do not make components interpret status codes or raw response shapes.

## HTTP Behavior

- Use one configured client boundary with base URL, headers, auth/session handling, timeout/cancellation, correlation, and error normalization.
- Use `AbortController` or the repository equivalent for unmount and superseded requests.
- Protect against stale responses when requests overlap.
- Retry only safe/idempotent operations, or commands with an explicit idempotency key.
- Keep request/response DTOs separate from UI models; never expose persistence or backend internals to components.

## Vite Safety

- Treat all bundled `import.meta.env` values as public. `VITE_*` is configuration, not a secret store.
- Allow only non-sensitive base URLs, feature flags, and public identifiers in client configuration.
- Validate required configuration at the app boundary and fail with an actionable safe error.
- Keep secrets, private tokens, signing keys, and privileged credentials on the server.
- Use the repository's dev proxy or deployment-relative URL strategy without embedding environment-specific private endpoints in feature code.

## React Quality

- Components render; hooks coordinate; services communicate; DTO modules map.
- Model async state as a discriminated union when states are mutually exclusive.
- Prefer composition and typed hooks before HOCs/providers; use advanced patterns only for a repeated, protected boundary.
- Test observable behavior, keyboard/accessibility behavior, mapping, validation, cancellation, stale-response protection, and retry policy without asserting private effect order. Keep every `expect`/`assert`/matcher call in `Then/Assert`.
