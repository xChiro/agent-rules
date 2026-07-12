# Global SDD Engineering Rules

Canonical assets: `~/.codeium/windsurf/common`. Do not copy managed assets into project-local agent folders. Specs stay in `specs/`.

## Required Lifecycle

- Start behavior changes from a traceable User Story and BDD Given/When/Then acceptance scenario.
- BDD scenarios use business language, concrete examples, and observable outcomes; keep delivery and implementation details outside them.
- Route reported defects through `common-sdd-fix-bug.workflow.md` before implementation: reproduce, classify, preserve the approved contract, and record `BUG-*`/`REG-*` evidence. Never weaken an acceptance scenario to make a bug pass.
- Create/evolve owning spec before code; active specs mutate. If discovery changes intent, plan, architecture, risk, or tests, pause, analyze, seek approval via `common-sdd-evolve-spec.workflow.md`, then update artifacts/gates.
- Create `workflow-routing.md` in every feature spec with primary/supporting workflow IDs for each phase and task.
- Before writing `specs/**`, show the complete plan and ask for approval; after writing it, show traceability, tasks, waves, ownership, and planned tests before RED.
- Do not write specs before Gate 1, test code before Gate 2, or production code before Gate 3 reviews actual RED evidence. No gate may be skipped for simple or low-risk work.
- Work one small `T-*` microtask at a time; record its outcome, verification, and next step before starting another.
- At 60% consumed context, run `common-sdd-context-checkpoint.workflow.md`, update the active spec, and ask the user to change context before new work.
- After Gate 2, confirm acceptance or backend HTTP integration RED first.
- Write the smallest focused test; confirm RED before production code.
- Put all assertions in `Then/Assert`; setup, action, and helpers never assert.
- Invoke `common-sdd-review-test-evidence.workflow.md` after RED and record the decision in `verification.md` before Green.
- Implement minimally; refactor only with tests green.
- Run `tools/validate-sdd-change.sh` as the read-only `sdd-policy` check on every pull request and before final completion; record its risk classification and result.
- Before completion, run `common-sdd-code-quality-gate.workflow.md`: review files, names, limits, Clean Code, SOLID/Clean Architecture/CQRS, and required refactors.
- Before completion, invoke `common-sdd-coverage-gate.workflow.md` for every spec; when production code is in scope, the complete project production scope must reach `>= 90%`, the affected scope must not regress, and the result must be recorded.
- For L2 non-trivial logic and all L3 changes, invoke `common-sdd-mutation-gate.workflow.md`; for L3 critical journeys, invoke `common-sdd-critical-e2e.workflow.md`.
- Before completion, invoke `common-sdd-security-gate.workflow.md`; record `security_role`, trust-boundary evidence, and no unresolved Critical/High findings.
- Run gates; converge spec, code, tests, contracts, docs.
- After final verification and human completion approval, invoke `common-sdd-complete-spec.workflow.md`; move the folder to `specs/features/completed/<number>-<slug>/` and create/update the AI context snapshot/index.
- Each task declares ownership, dependencies, wave, outcome, verification, and next step; default to one agent.

## Architecture

- Preserve the repository's existing architecture and stricter local product constraints.
- Load `common-security-and-identity.md` for identity, OAuth/OIDC, REST auth, browser sessions, cookies, secrets, public exposure, or CI credentials.
- Apply SOLID, Clean Architecture, CQRS, YAGNI, and dependency inversion pragmatically.
- Keep domain/application independent from transport, persistence, frameworks, cloud SDKs, UI, logging implementations, and deployment details.
- Keep controllers, REST/Lambda handlers, adapters, and composition roots thin. Business decisions belong to domain/application behavior.
- Avoid speculative abstractions and nested/repeated if/switch; use Fowler refactoring with green tests.

## Backend Tests

- Use exactly two runtime suites: unit tests and HTTP integration tests.
- Unit tests cover domain/application behavior without external infrastructure.
- HTTP integration tests enter through a real local server or API Gateway/Lambda HTTP endpoint and exercise routing, auth/session, validation, use cases, DI, persistence, schema, and local resources.
- Do not create separate repository, adapter, handler, infrastructure, API, end-to-end, Lambda, or contract runtime suites.
- Canonical CI test jobs are `unit-tests` and `http-integration-tests`.

## Loading

- Resolve common IDs in `common/workflows/`; language IDs in `common/languages/<language>/workflows/`; then global/system assets. Use exact `.md`; never project `.windsurf/workflows/`.
- C#: `csharp-sdd-implement-change` -> `common/languages/csharp/workflows/`; common REST -> `common/workflows/common-rest-api-design.workflow.md`; C# REST -> `common/languages/csharp/workflows/csharp-rest-api.workflow.md`.
- Rules/skills: `common/rules/` and `common/languages/<language>/`; load focused boundary assets and record routes.
- Load common SDD/context continuity, active language, and focused REST/Lambda/SNS/SQS boundary workflows/rules; record routes in the spec.
- When a project has `specs/context/ai-snapshots/index.md`, read the latest relevant snapshot as bounded context before planning; verify current active specs before relying on it.
- Use `go-sdd-implement-change` or `csharp-sdd-implement-change` for backend changes and the matching refactor workflow for behavior-preserving cleanup.
- Preserve `react-create-hbk-webapp-template` for HBK React foundations and use `hbk-identity-webapp` as reference.

## IDE And Agent Scope

- This global configuration is the source for Windsurf, Devin Desktop's fallback, and the GoLand, WebStorm, and Rider plugins.
- Devin cloud uses organization/repository Skills & Rules; this store serves Windsurf/Devin Desktop.
