# Global SDD Engineering Rules

Canonical: `~/.codeium/windsurf/common`. No managed project copies. Specs: `specs/`.

## Required Lifecycle

- Start from a traceable User Story and abstract BDD scenario using business language, examples, and observable outcomes.
- Route defects through `common-sdd-fix-bug.workflow.md`: reproduce, classify, preserve the contract, and record `BUG-*`/`REG-*`; never weaken acceptance to make a bug pass.
- Create/evolve the owning spec before code. If discovery changes intent, plan, architecture, risk, or tests, pause and seek approval through `common-sdd-spec.workflow.md`.
- Create `workflow-routing.md` in every feature spec with primary/supporting workflow IDs for each phase and task.
- Give every SDD ID one concise title. Display `<ID> — <title>`; store `*_id`/`*_title` separately. Task/change titles start with an action verb.
- Before writing `specs/**`, show the complete plan and ask for approval; after writing it, show traceability, tasks, waves, ownership, and planned tests before RED.
- Do not write specs before Gate 1, tests before Gate 2, or scoped production before its Gate 3 RED review. Never skip gates for low risk.
- Work one small `T-* — <action and outcome>` microtask at a time; record its outcome, verification, and next step before starting another.
- At 60% context, run `common-sdd-context-checkpoint.workflow.md`, update the spec, and request a new context.
- Follow `RULE-COMMON_INSIDE_OUT_DEVELOPMENT`: domain model → Domain RED/GREEN/gate → Application RED/GREEN/core gate → conditional boundary RED. Domain uses real values; Application uses hand-written outgoing-port doubles.
- Tests: fresh Mothers/builders in Arrange; one-line Act; assertions only in Assert.
- Invoke `common-sdd-review-test-evidence.workflow.md` after RED and record the decision in `verification.md` before Green.
- Implement minimally; refactor only with tests green.
- Run `tools/validate-sdd-change.sh` in every PR and before final validation; record risk and result.
- For L2 non-trivial logic and all L3 changes, run the mutation gate; every L3 change, including any journey marked critical, also runs the critical-E2E gate.
- Run the SDD documentation gate before the final evidence review; record changed surfaces/evidence or `no_documentation_change_reason` in the spec artifacts.
- Run clean-up before final validation; apply Fowler refactorings and keep in-scope maintained source, tests, configuration, CI, and scripts below 150 physical lines.
- Then run the security gate; record role, trust-boundary evidence, and no Critical/High findings.
- Run the coverage gate for every spec; production scope requires `>= 90%` and no affected-scope regression.
- After required gates converge, run `common-sdd-verify-spec.workflow.md`; only its approved final evidence review may record `status: verified` and rename the folder to its `-verified` suffix. Create no external lifecycle artifact.
- Each task declares ownership, dependencies, wave, outcome, verification, and next step; default to one agent.

## Architecture

- Preserve the repository's existing architecture and stricter local product constraints.
- Load `common-security-and-identity.md` for identity, OAuth/OIDC, auth, sessions, secrets, exposure, or CI credentials.
- Apply SOLID (SRP/OCP/LSP/ISP/DIP), Clean Architecture, CQRS, and YAGNI; no speculative abstractions.
- Keep domain/application independent from transport, persistence, frameworks, cloud SDKs, UI, logging implementations, and deployment details.
- Keep Domain/Application names provider-neutral; technology names such as DynamoDB, Cosmos, or Kafka belong only in outer adapters/configuration.
- Keep delivery, adapters, and composition thin; behavior stays in named use cases/domain policy.
- Open production layers in order: domain, application, infrastructure, delivery interface, composition/IaC. Outer tasks wait for `LAYER-GATE-APPLICATION`.
- Avoid speculative abstractions and nested/repeated if/switch; use Fowler refactoring with green tests.

## Backend Tests

- Use exactly two folders/suites: `tests/unit/` and `tests/integration/`.
- Integration uses `tests/integration/http/` as the compatible public-entry scope and `tests/integration/infrastructure/` for real adapter/resource wiring.
- Use Docker, Testcontainers, or faithful emulators for local databases, queues, caches, and storage. Simulate third-party APIs with WireMock or equivalent; keep the application client and integration wiring real.
- Run every affected scope independently from clean state. Do not create a third runtime suite.
- Canonical CI jobs are `unit-tests` and `integration-tests`.

## Loading

- Use this file as bootstrap. Load one primary workflow, one language baseline, and only rules for the active phase/boundary; never load the whole catalog.
- Common mandatory rules are the policy floor. Local rules may be more specific or stricter; report equal-level conflicts instead of inventing a merged rule.
- Resolve common IDs in `common/workflows/`; language IDs in `common/languages/<language>/workflows/`; then global/system assets. Use exact `.md`; never project `.windsurf/workflows/`.
- Load common SDD/context continuity, the active language, and focused REST/Lambda/SNS/SQS assets only when applicable; record routes in the spec.
- Optional AI context summaries are hints; verify the latest relevant one against the stable spec and repository.
- Use `go-sdd-implement-change` or `csharp-sdd-implement-change` for backend changes and the matching refactor workflow for behavior-preserving cleanup.
- Preserve `react-create-hbk-webapp-template` for HBK React foundations and use `hbk-identity-webapp` as reference.

## IDE And Agent Scope

- This global configuration is the source for Windsurf, Devin Desktop's fallback, and the GoLand, WebStorm, and Rider plugins.
- Devin cloud uses organization/repository Skills & Rules; this store serves Windsurf/Devin Desktop.
