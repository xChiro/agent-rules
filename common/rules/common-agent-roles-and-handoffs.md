---
rule_id: RULE-COMMON_AGENT_ROLES_AND_HANDOFFS
trigger: always_on
description: Role contracts and evidence handoffs for Architect, Tester, Coder, and Reviewer agents working under SDD.
---

# Agent Roles And Handoffs

Use these contracts when more than one agent participates in a change. A single agent may perform multiple roles sequentially, but it must still produce the same evidence and must not bypass a gate by changing role names.

## Shared Contract

Every handoff identifies:

- `handoff_id: HANDOFF-<FEAT>-<sequence>`;
- `from_role`, `to_role`, `agent_id`, `task_id`, `track_id`, and `risk_level`;
- owned files/modules/contracts and explicit must-not-touch boundaries;
- decisions, assumptions, blockers, commands, test evidence, and next action;
- spec/traceability links and the receiving agent's acceptance status.

Handoffs are append-only under `specs/features/<number>-<slug>/handoffs/` or in the feature's `red-green-refactor.md` when the repository uses a single evidence artifact.

When context usage reaches 60%, create a context continuation handoff under `handoffs/context-checkpoints/` using `common/templates/context-handoff.md`. It must name the current and next `T-*` task, exact first action, completed evidence, blockers, gates, owned/must-not-touch files, and the user decision needed to resume. The next AI reads the latest checkpoint before opening unrelated files.

## Architect

Owns:

- read-only diagnosis and change classification;
- User Story, requirements, scenarios, architecture boundaries, risk, tasks, tracks, and workflow routing;
- explicit Clean Architecture/CQRS/SOLID impact and non-goals;
- discovery impact analysis and any approved `spec-adjustment-request`;
- Gate 1 proposal and handoff to Tester.

Must not:

- edit production code;
- silently change the approved behavior;
- assign overlapping file ownership;
- declare tests or implementation complete.

Handoff output: approved plan, risk level, owned boundaries, test strategy, and `ARCHITECT -> TESTER` decision.

## Tester

Owns:

- BDD/acceptance scenario evidence;
- focused unit/component RED test;
- HTTP integration or critical E2E RED when the boundary applies;
- deterministic fixtures, fakes, isolation, and `TEST-*` traceability;
- Gate 2 preparation and Gate 3 evidence.

Must not:

- edit production behavior before Gate 3;
- weaken an assertion to make it pass;
- mock away the boundary the test is supposed to prove;
- claim GREEN from a compile-only or shallow test.

Handoff output: failing tests, commands, intended failure explanation, fixtures, and `TESTER -> CODER` approval request.

## Coder

Owns:

- the smallest production change after Gate 3;
- preserving the approved architecture and public contract;
- GREEN implementation, DTO/adapter boundaries, and test-driven refactoring;
- focused verification and updated Red → Green → Refactor evidence.

Must not:

- change the spec or acceptance expectation to fit the implementation;
- continue after discovering a plan, intent, boundary, risk, or test-strategy mismatch without pausing for an approved adjustment;
- add speculative layers, ports, mediators, or abstractions;
- hide failures with retries, swallowed errors, or broad mocks;
- edit files owned by another track without an updated handoff.

Handoff output: production diff, GREEN results, refactor summary, residual risk, and `CODER -> REVIEWER` request.

## Reviewer

Owns:

- independent review of behavior, architecture, security, test quality, mutation/E2E evidence, and scope;
- checking that the RED test preceded production code where applicable;
- confirming project-wide coverage, touched-scope non-regression, and required gates;
- confirming the active spec and latest context checkpoint are synchronized before a context handoff or resume;
- confirming no plan/intent drift was silently absorbed and required adjustment gates were repeated;
- recording findings by severity and approving or rejecting Gate 4 readiness.

Must not:

- silently fix the change while reviewing;
- approve with unresolved Critical/High findings;
- accept tests that only mirror implementation details;
- ignore missing handoffs or ownership conflicts.

Handoff output: review findings, evidence links, required actions, and `REVIEWER -> CONVERGENCE` decision.

## Role Transition Rules

- Architect → Tester requires Gate 1 approval.
- Tester → Coder requires Gate 3 approval with actual RED evidence.
- Coder → Reviewer requires GREEN, refactor, security, mutation/E2E, and coverage evidence appropriate to the risk level.
- Reviewer → completion requires all findings resolved or explicitly accepted by the authorized owner; Gate 4 still requires human approval.
- A rejected handoff returns only to the role that owns the missing evidence; it does not skip backward gates.
