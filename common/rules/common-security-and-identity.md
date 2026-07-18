---
rule_id: RULE-COMMON_SECURITY_AND_IDENTITY
trigger: model_decision
description: "Cross-language security, OAuth 2.0, OIDC, session-cookie, secret-handling, and security-review guardrails."
---

# Common Security And Identity Rules

Load this rule for every security gate and whenever a change touches identity, authentication, authorization, sessions, cookies, REST/Lambda boundaries, secrets, personal data, browser code, CI credentials, cloud permissions, or external providers.

## Declare The Security Role First

Every applicable spec must declare its security role and trust boundaries:

| Role | Responsibility | Required boundary |
|---|---|---|
| `oauth-client` | Requests delegated authorization for a user or service. | Uses an authorization server and never implements token validation policy as a substitute for the resource server. |
| `resource-server` | Protects an API or resource with access tokens. | Validates issuer, audience, signature, allowed algorithm, expiry, not-before, scopes/claims, and authorization policy server-side. |
| `identity-server` | Owns authentication and issues identity/authorization tokens. | Implements a standards-compliant OAuth 2.0 authorization server and OIDC Provider when it authenticates users. |
| `none` | No identity or security boundary is changed. | Evidence must explain why the changed surface has no new security impact. |

OAuth 2.0 is an authorization framework; use OpenID Connect (OIDC) for user authentication and identity claims. Do not treat an OAuth access token as an ID token or infer identity from an unvalidated client claim.

Do not combine client, resource-server, and identity-server responsibilities in one adapter or handler without an explicit spec decision, separate trust boundaries, and tests for each role.

## OAuth 2.0 And OIDC Baseline

- Use TLS for authorization, token, callback, discovery, JWKS, and resource endpoints. Local HTTP exceptions must be explicit, isolated to local test infrastructure, and never copied to production configuration.
- Use Authorization Code with PKCE for interactive user authorization. Use PKCE for public clients and prefer it for confidential clients as defense in depth.
- Do not use the implicit grant, Resource Owner Password Credentials grant, password exchange, or tokens in URL fragments for new behavior.
- Use `state` to bind authorization responses to the initiating browser session and prevent CSRF. Use an OIDC `nonce` and validate it when an ID token is returned.
- Register exact redirect URIs. Do not accept wildcard, substring, user-controlled, or environment-ambiguous redirect matching.
- Keep client secrets, private keys, refresh tokens, and authorization codes on trusted server-side boundaries. A browser client is public and must not contain a client secret.
- Use Client Credentials only for service-to-service authorization with no end-user context. It is not a browser login flow.
- Validate OIDC discovery and ID tokens using the configured issuer, exact audience, signature/JWKS, allowed algorithms, expiration, not-before, nonce, and required claims. Reject issuer or audience confusion.
- Validate resource-server access tokens using issuer, audience, signature/JWKS, allowed algorithms, expiration, not-before, scopes/roles, and tenant/resource authorization. Do not trust decoded claims before validation.
- Keep scopes least-privileged and map them to explicit application authorization policies. Authentication does not imply authorization.
- Rotate signing keys and refresh tokens according to the provider contract. Handle JWKS rotation without accepting arbitrary keys or algorithms.
- Do not log authorization codes, access tokens, refresh tokens, ID tokens, cookies, credentials, private keys, or complete sensitive request/response bodies.
- Use provider discovery, standards-compliant libraries, and the provider's documented revocation/introspection behavior. Do not hand-roll cryptography, JWT validation, OAuth parsing, or an identity protocol.

## Identity Server Rules

When the system is an `identity-server`:

- The spec must explicitly state why the product owns identity instead of delegating to an established provider.
- Expose standards-based authorization, token, discovery, and JWKS contracts as applicable; document issuer, supported grants, PKCE requirements, client authentication, scopes, claims, key rotation, token lifetime, revocation, logout, and redirect validation.
- Use OIDC for login and identity claims. OAuth-only behavior must not be described as authentication.
- Store passwords only with an approved adaptive password hashing scheme and parameters selected by the security owner; never store plaintext or reversible passwords.
- Protect authorization-code, consent, login, callback, token, recovery, and logout flows with rate limits, replay protection, CSRF protection where cookies are involved, secure error handling, and audit events without secrets.
- Treat signing-key rotation, client registration, recovery, logout, and account compromise as explicit operational behavior with rollback and incident procedures.

Do not implement an identity server as an incidental feature of a REST endpoint. If the product decision is not explicit, classify the system as an `oauth-client` or `resource-server` and use the external identity provider.

## Web Application Session Cookies

Authenticated web applications must use a server-managed session or BFF pattern by default:

- The browser receives an opaque session cookie, not an access token, refresh token, ID token, client secret, or private key.
- Set `HttpOnly` so browser JavaScript cannot read the session cookie.
- Set `Secure` in every non-local environment and use HTTPS. Local exceptions must be test-only and documented.
- Set `SameSite=Lax` or `SameSite=Strict` by default. Use `SameSite=None` only for an explicit cross-site requirement and only with `Secure` plus a documented CSRF design.
- Prefer the `__Host-` cookie prefix with `Path=/` and no `Domain` attribute. Do not widen a cookie to unrelated subdomains without a documented trust decision.
- Use short idle and absolute lifetimes, rotate the session after login and privilege changes, invalidate it on logout, and prevent session fixation and reuse after revocation.
- Protect all state-changing cookie-authenticated requests with CSRF defenses. SameSite is defense in depth, not a complete CSRF strategy.
- Never persist tokens in `localStorage`, `sessionStorage`, IndexedDB, query strings, URL fragments, DOM attributes, analytics payloads, or logs.
- Configure CORS with an explicit origin allowlist. Never combine credentialed requests with `Access-Control-Allow-Origin: *`.
- Add security headers appropriate to the web surface, including HSTS in HTTPS environments, a restrictive CSP, clickjacking protection, `X-Content-Type-Options: nosniff`, and a deliberate referrer policy.

If the application is a pure public client with no backend session boundary, the spec must explicitly document the alternative and its threat model. The default browser rule remains no token storage accessible to JavaScript.

## Authorization And Data Boundaries

- Enforce authorization in the backend/domain/application boundary, not only in UI routes or hidden controls.
- Scope authorization by tenant, resource, actor, operation, and state. Validate ownership and permission at the point of use.
- Return `401` for missing/invalid authentication and `403` for authenticated but unauthorized requests without leaking resource existence when policy forbids it.
- Validate untrusted input at the transport boundary and again at the owning business boundary when invariants require it.
- Keep secrets and personal data out of source control, snapshots, test artifacts, logs, error responses, screenshots, CI outputs, and generated documentation.
- Use least-privilege IAM, database, queue, storage, and CI permissions. Prefer short-lived credentials and OIDC federation over long-lived cloud keys.

## Security Evidence

The final security review must record:

- `security_review_id: SEC-*`, its human-readable title, artifact ID/title, status, scope, changed trust boundaries, and declared identity role.
- Exact static-analysis, dependency, secret, IaC, container, and security-test commands that were actually run.
- OAuth/OIDC provider, issuer/audience/scope assumptions, redirect policy, token validation, and key-rotation evidence when applicable.
- Cookie attributes, CSRF, CORS, security headers, and browser storage evidence when a web session is involved.
- Findings, severity, affected files, remediation, accepted residual risk, owner, expiry, and follow-up spec.
- No unresolved Critical or High findings. Any Medium/Low exception requires explicit security-owner approval, mitigation, expiry, and traceable follow-up; an agent cannot self-approve it.

Never claim a security gate passed because a scanner was unavailable. Record the unavailable control, manual review, residual risk, and required follow-up.
