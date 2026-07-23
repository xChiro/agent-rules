---
workflow_id: WORKFLOW-COMMON_SDD_SECURITY_GATE_WORKFLOW
trigger: manual
description: "Mandatory final security review before an SDD spec enters verified status, including OAuth 2.0, OIDC, web session cookies, secrets, authorization, and supply-chain evidence."
---

# Common SDD Security Gate Workflow

Run this workflow after Green, Refactor, relevant tests, documentation convergence, and before final validation review. It is mandatory before an SDD spec enters verified status. A spec with no security-sensitive change still runs the scope review and records `security_role: none` with the reason security impact is unchanged.

Load `common-security-and-identity.md` for the detailed baseline. This workflow is language-neutral and applies to Go, C#, React, Web, REST, Lambda, CI, persistence, messaging, and local-resource changes. It supplements, but does not replace, the existing SDD, test, architecture, coverage, and PR-review workflows.

## Security Gate Principles

1. Security review is a validation gate, not an optional scanner step.
2. Review the diff, trust boundaries, identity role, data, configuration, dependencies, and operational behavior together.
3. Do not invent or hand-roll OAuth, OIDC, JWT validation, cryptography, session protocols, or password storage.
4. OAuth 2.0 authorization, OIDC authentication, resource-server token validation, and identity-server responsibilities must be explicitly separated.
5. Authenticated web applications use server-managed sessions or a BFF with `HttpOnly` cookies by default. Tokens must not be accessible to browser JavaScript.
6. Do not suppress, delete, weaken, or reclassify a security test or finding to obtain a green result.
7. Security findings must be fixed or explicitly accepted by an authorized security owner with expiry and mitigation; unresolved findings block final validation. The agent cannot approve its own exception.

## Phase 1: Prepare The Security Review

Read:

- The active spec or defect spec, `change-summary.md`, `plan.md`, `acceptance.feature`, `tasks.md`, `workflow-routing.md`, `traceability.yaml`, `verification.md`, and history.
- The complete diff from the approved baseline, including deleted files, generated files, dependency manifests, lockfiles, CI/IaC, environment configuration, schemas, contracts, and deployment settings.
- The applicable `common-security-and-identity.md`, REST rules, HTTP integration harness, language rules, and local project security policy.

Create or update the human-readable artifact:

```text
specs/features/<number>-<slug>-<status>/security-review.md
```

Use stable metadata:

```yaml
feature_id: FEAT-0001
feature_title: Enforce notification retry limits
spec_id: SPEC-0001
spec_title: Notification retry-limit behavior
artifact_id: ART-0001-SECURITY-REVIEW
artifact_title: Notification retry-limit security review
security_review_id: SEC-0001-001
security_review_title: Review retry-limit trust-boundary impact
status: proposed
security_role: oauth-client | resource-server | identity-server | none
```

Record:

- Review scope, source commit/baseline, reviewer/agent, date, and exact files/modules reviewed.
- Security role: `oauth-client`, `resource-server`, `identity-server`, or `none`.
- Actors, trust boundaries, entry points, data classification, tenants, secrets, external providers, local resources, and deployment environments.
- Authentication, authorization, session, cookie, CSRF, CORS, browser-storage, and security-header impact.
- OAuth/OIDC provider, issuer, audience, scopes, redirect URIs, token types, key sources, key rotation, and revocation assumptions when applicable.
- Threats and abuse cases relevant to the change. Use a lightweight STRIDE-style review for new or materially changed trust boundaries.
- Planned static, dependency, secret, IaC, container, and runtime security evidence.

## Phase 2: Identity And Protocol Review

Confirm that the spec declares exactly what the system is doing:

| Declared role | Review requirements |
|---|---|
| `oauth-client` | Authorization Code with PKCE, `state`, OIDC `nonce` when applicable, exact redirect URIs, no browser secrets, least-privileged scopes, secure callback and token handling. |
| `resource-server` | Server-side validation of issuer, audience, signature/JWKS, allowed algorithms, expiry, not-before, scopes/roles, tenant/resource authorization, and `401`/`403` behavior. |
| `identity-server` | Explicit product decision, standards-based OAuth endpoints, OIDC Provider behavior when authenticating users, client registration, PKCE, consent, key rotation, token lifetime/revocation, logout, recovery, rate limits, and operational ownership. |
| `none` | No changed trust boundary, identity behavior, secret, browser storage, public exposure, or security-sensitive dependency. Record the evidence. |

Required protocol checks:

- Authorization Code with PKCE is used for interactive user authorization. Reject new implicit or Resource Owner Password Credentials flows.
- Client Credentials is limited to service-to-service calls without end-user identity.
- `state` binds the callback to the initiating browser session; OIDC `nonce` is generated and validated for ID tokens.
- Redirect URI matching is exact and environment-specific. No wildcards, substring matching, or user-controlled redirect targets.
- ID tokens are not used as API access tokens. Validate issuer, exact audience, signature/JWKS, allowed algorithm, expiry, not-before, nonce, and required claims.
- Access tokens are validated by the resource server for issuer, audience, signature/JWKS, allowed algorithm, expiry, not-before, scopes/roles, tenant, and resource authorization.
- Signing keys, JWKS rotation, refresh-token rotation/reuse, revocation/introspection, and provider outage behavior are explicit when relevant.
- No access token, refresh token, ID token, authorization code, client secret, or private key is exposed in URLs, browser storage, logs, telemetry, snapshots, artifacts, or error messages.

If the system is an identity server, stop and request explicit verification when the spec does not state why the product owns identity and which OAuth/OIDC contracts it supports. Do not silently replace an external provider with custom authentication.

## Phase 3: Web Session And Browser Review

When a browser session is authenticated, verify:

- The browser receives an opaque server-managed session cookie or BFF session, not an OAuth/OIDC token.
- Session cookies have `HttpOnly`, `Secure` outside local-only tests, and `SameSite=Lax` or `SameSite=Strict` by default.
- Cross-site cookies use `SameSite=None` only for an explicit requirement, with `Secure`, explicit CORS origins, credentials rules, and a documented CSRF design.
- Prefer `__Host-` cookies with `Path=/` and no `Domain`; any wider domain scope has an explicit trust decision.
- Sessions rotate after login and privilege changes, expire by idle and absolute limits, invalidate on logout/revocation, and resist fixation and reuse.
- State-changing cookie-authenticated requests have CSRF protection. SameSite is defense in depth, not the only control.
- `localStorage`, `sessionStorage`, IndexedDB, URL query/fragment, DOM attributes, analytics, logs, and screenshots contain no tokens or secrets.
- Credentialed CORS never uses `Access-Control-Allow-Origin: *`; allowed origins are explicit and environment-specific.
- The web response has an appropriate CSP, HSTS in HTTPS environments, clickjacking protection, `X-Content-Type-Options: nosniff`, and deliberate referrer policy.
- UI authorization checks are not the only protection. Backend/domain/application authorization is tested at the owning boundary.

For a public client with no backend session boundary, require an explicit threat model and security-owner approval. The default rule remains that tokens are not stored where browser JavaScript can read them.

## Phase 4: Automated Security Evidence

Use repository-native commands and CI tools. Do not invent commands or report an estimate. Run the controls that apply:

- Secret and credential scanning on the diff and relevant history.
- SAST/static analysis and unsafe API checks.
- Dependency and lockfile vulnerability audit, including transitive dependencies.
- IaC, SAM, container, image, permission, and cloud configuration scanning when those files or resources are touched.
- OpenAPI/schema/auth compatibility checks when public contracts change.
- HTTP integration security scenarios for authentication, authorization, cookies, CSRF, CORS, headers, token validation, tenant isolation, error mapping, and revocation when applicable.
- Unit tests for security-sensitive domain/application authorization policies.
- Browser/component tests for cookie/session behavior where the frontend owns the visible flow.
- CI permission and secret-boundary review for workflow changes. Pull-request code must not receive deployment credentials.

The security workflow does not create a third backend runtime test suite. Security behavior belongs in the existing `unit` and `integration` suites, plus static/operational gates.

Record for each control:

```text
control_id: SEC-CHECK-001
control_title: Scan the changed scope for exposed secrets
command: <exact native command>
tool_version: <version>
scope: <files/modules/environment>
result: pass | fail | unavailable
artifact: <report path or CI artifact>
```

An unavailable scanner is not a pass. Record the manual alternative, residual risk, and follow-up owner.

## Phase 5: Findings And Remediation

For every finding record:

- `FINDING-*` ID, human-readable finding title, severity, source/control, affected file/module, exploit path, and evidence.
- Whether it is a real issue, false positive, accepted baseline, or duplicate, with reasoning.
- Fix task, owning track, test/security evidence, and verification result.
- Residual risk, security owner, expiry, mitigation, and follow-up spec for any accepted exception.

Validation rules:

- Critical and High findings block final validation until fixed and verified.
- Medium and Low findings block final validation when unresolved, unreviewed, unowned, or without mitigation and expiry. An authorized security owner may accept them explicitly; the agent may not.
- A scanner suppression must be narrow, justified, reviewed, expiry-bound when possible, and recorded. Do not suppress a finding merely because the code is inconvenient to change.
- If a security fix changes behavior, a public contract, authentication flow, permissions, data exposure, or architecture, return to the SDD spec/Gate 1 and then repeat the inside-out RED/scoped Gate 3 sequence for every affected layer.

## Phase 6: Human Security Verification

Show the user/security owner:

- `security-review.md`, declared role, trust boundaries, threat/abuse cases, and changed surface.
- OAuth/OIDC decisions, cookie attributes, CSRF/CORS/header evidence, and authorization boundaries when applicable.
- Exact commands, tool versions, reports, test IDs, findings, remediations, exceptions, and residual risk.
- Confirmation that no secrets, tokens, credentials, or private endpoints were exposed.
- Coverage result and relation to the mandatory coverage gate.

Ask explicitly:

```text
The final security review is verified. No unresolved Critical/High findings remain and all exceptions are explicitly owned. May I record the security gate as passed and continue to final validation?
```

If security verification is rejected, update only the authorized spec/security/test artifacts, remediate the finding through the SDD lifecycle, rerun evidence, and request verification again.

## Phase 7: Record And Route Validation

Update:

- `security-review.md` to `status: passed` or `status: blocked`.
- `verification.md` with `WORKFLOW-COMMON_SDD_SECURITY_GATE_WORKFLOW`, role, scope, commands, findings, exceptions, and decision.
- `change-summary.md` with a security review change/evidence row.
- `workflow-routing.md` and `traceability.yaml` with the security gate and `SEC-*`, `SEC-CHECK-*`, and `FINDING-*` IDs.
- `history/` with the review decision and any accepted residual risk.

Only after the security gate passes may `common-sdd-verify-spec.workflow.md` record `status: verified`.

## Definition Of Done

- The workflow ran for the spec, including `security_role: none` when no security surface changed.
- The final diff and changed trust boundaries were reviewed.
- OAuth 2.0/OIDC roles and protocol decisions are explicit when applicable.
- Web authentication uses `HttpOnly` secure session cookies by default and has CSRF/CORS/header evidence.
- No secrets, tokens, credentials, or private endpoints are exposed.
- Applicable security scans, dependency checks, IaC checks, and unit/HTTP integration security tests passed or have documented authorized exceptions.
- No unresolved Critical/High findings exist; all lower-severity exceptions are owned, mitigated, expiry-bound, and traceable.
- `security-review.md`, `verification.md`, `change-summary.md`, routing, traceability, and history converge.
- Final validation proceeds only after this workflow and any required coverage gate pass.
