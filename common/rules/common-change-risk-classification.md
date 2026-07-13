---
rule_id: RULE-COMMON_CHANGE_RISK_CLASSIFICATION
trigger: always_on
description: Risk classification and quality-gate matrix for scaling SDD evidence without weakening architecture or test discipline.
---

# Change Risk Classification

Classify the change during the read-only SDD plan before choosing artifacts, tests, gates, or parallel tracks. The highest applicable level wins. A task may be escalated at any time when evidence reveals additional risk.

## Levels

### L0 — Documentation And Agent Configuration

Examples: Markdown, rules, workflows, skills, comments, formatting, repository maps, or non-executable documentation.

Required for a catalog/documentation-only change with no executable behavior change:

- documentation/link validation;
- `git diff --check`;
- shell/YAML/JSON syntax checks when those files change.

No product acceptance, unit, HTTP, E2E, mutation, or coverage gate is required for the L0 change itself unless executable behavior changes. If the change belongs to a completed SDD spec, the mandatory final security, clean-up, and coverage gates still apply; docs-only completion records `coverage_scope: none`.

### L1 — Low-Risk Local Behavior

Examples: isolated presentation changes, copy, styling, a local component refactor with characterization coverage, or non-critical configuration.

Required for a production or executable behavior change:

- owning spec or documented refactor intent;
- focused component/unit test or explicit manual QA evidence;
- typecheck/lint/build and relevant accessibility checks;
- Red → Green → Refactor report when production behavior changes.

E2E, mutation, security, and full HTTP integration are conditional on the touched boundary. The common SDD approval sequence still applies to behavior changes; risk selects additional evidence, not permission to edit production code before RED and Gate 3.

### L2 — Business, API, Persistence, Orchestration, Or Integration Behavior

Examples: domain/application rules, commands, queries, DTO contracts, persistence adapters, messaging, public endpoints, shared state, or non-critical user workflows.

Required:

- complete SDD artifacts and Gate 1–4;
- BDD acceptance scenario and executable acceptance/public-boundary evidence;
- focused unit/component test written and RED before production code;
- HTTP integration when a public or local-resource boundary changes;
- project-wide production coverage ≥90% and no touched-scope regression;
- mutation gate for non-trivial business logic;
- security review when a trust boundary changes;
- role contracts and handoffs for multi-agent work.

### L3 — Critical Or High-Impact Behavior

Examples: authentication, authorization, tenant isolation, payments, financial values, destructive operations, migrations, data loss, concurrency/idempotency, secrets, public security contracts, or critical end-to-end journeys.

Required:

- all L2 evidence;
- executable Gherkin-backed E2E through the real user/public boundary;
- mandatory mutation testing with no unexplained surviving mutants;
- security gate with explicit trust-boundary evidence;
- performance/concurrency/rollback evidence when relevant;
- independent Reviewer handoff before Gate 4;
- project-wide production coverage ≥90% and affected critical scope ≥90%.

## Gate Matrix

| Gate | L0 | L1 | L2 | L3 |
| --- | --- | --- | --- | --- |
| Spec / change classification | required | required | required | required |
| Gate 1–3 | no for catalog-only work; required if behavior emerges | required for production behavior | required | required |
| Gate 4 completion | no for non-SDD catalog work | required for SDD specs | required | required |
| BDD acceptance | no | when behavior changes | required | required |
| Unit/component RED | no | required for behavior changes | required | required |
| HTTP integration | no | boundary-dependent | boundary-dependent | required when applicable |
| Critical E2E | no | no | selected by risk | required |
| Mutation testing | no | optional | non-trivial logic | required |
| Security review | no | boundary-dependent | boundary-dependent | required |
| Project-wide coverage | no for catalog-only work | repository policy; mandatory at spec completion when production code is in scope | ≥90% at spec completion | ≥90% |
| Role handoffs | no | optional | multi-agent | Architect → Tester → Coder → Reviewer |

## Exceptions And Escalation

- Documentation, generated code, migrations, or emergency fixes must record the exception and the compensating verification in `verification.md`.
- A missing test harness is not permission to skip evidence; use the closest deterministic boundary and document the gap.
- A change that crosses levels uses the higher level's gates.
- Never lower a level to avoid a failing gate.
- This risk matrix selects additional evidence such as mutation and critical E2E. It does not override spec completion: every completed spec runs `common-sdd-coverage-gate.workflow.md`; when production code is in scope, the project-wide result must be `>= 90%` with no affected-scope regression. Docs-only specs record `coverage_scope: none` and prove that no production files changed.
