---
rule_id: RULE-COMMON_SDD_SPEC_EVOLUTION
trigger: model_decision
description: "Controlled mutation of active SDD specs when new evidence changes the plan or approved intent."
---

# Mutable SDD Spec

An active spec is a living, versioned source of intent. It may change when repository evidence, tests, domain discovery, architecture review, or user feedback reveals a missing requirement, wrong assumption, boundary impact, risk change, or better plan. History is append-only; the spec is not silently mutable.

## Discovery Protocol

When new evidence may require a plan, scope, behavior, contract, architecture, risk, test, task, dependency, or gate adjustment:

1. Pause the current microtask. Do not continue production work or weaken tests to fit the discovery.
2. Classify the finding: clarification, behavior/contract, architecture/boundary, risk/security, test/harness, scope, or sequencing.
3. Analyze impact before editing: User Stories/BDD, requirements, invariants, plan, tasks/tracks, ownership, contracts/data, tests, gates, documentation, rollback, and context budget.
4. Record a concise, human-titled `spec-adjustment-request` with evidence, proposed delta, alternatives, affected IDs/titles/files, gate reset, and resume action.
5. Show the analysis and ask the authorized human for approval to update the spec. No silent plan drift.
6. After approval, invoke `common-sdd-spec.workflow.md`, update only affected artifacts, append history, and rebaseline tasks and traceability before continuing.

## Gate Reset

- Intent, behavior, contract, architecture, risk, or test-strategy changes require Gate 1 re-approval, then a new Gate 2/3 cycle before tests or production code continue.
- Task ordering or implementation-detail changes that preserve approved behavior still require approval and traceable plan/task updates; repeat other gates when the impact analysis requires it.
- Preserve the canonical title for each stable ID across artifacts. A wording-only title improvement keeps its ID and is recorded in append-only history; a material intent change follows the normal rebaseline and gate rules.
- A spec with `status: verified`, `superseded`, or `retired` is audit evidence. Do not edit it silently; use a new active evolution or defect spec linked to the source.

Never rewrite old history, change the risk level to avoid evidence, or mark a deviation as planned before approval.
