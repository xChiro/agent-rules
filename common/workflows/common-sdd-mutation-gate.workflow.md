---
workflow_id: WORKFLOW-COMMON_SDD_MUTATION_GATE_WORKFLOW
trigger: manual
description: "Risk-based mutation testing gate for proving that tests detect meaningful changes to critical behavior."
---

# Common SDD Mutation Gate

Run this workflow after focused tests are GREEN and before final validation for L2 non-trivial business logic and every L3 change. L0 documentation and L1 changes are exempt unless the spec escalates them.

Mutation-killing assertions must remain in the test's `// Assert` section; do not hide assertions in setup, fixtures, or action helpers.

## Scope

Prioritize changed production code and its directly exercised domain/application/component behavior:

- conditionals and boundary comparisons;
- authorization, tenant, permission, and feature-flag decisions;
- state transitions, idempotency, retries, and concurrency guards;
- financial/quantity calculations and validation;
- DTO parsing/normalization when invalid input is security or contract relevant.

Do not mutate generated code, vendor code, CSS-only changes, framework glue, or pure DTO property holders unless the spec identifies meaningful behavior there.

## Phase 1 — Plan

Record in the spec:

- `risk_level`, `mutation_scope`, and `mutation_tool`;
- exact command discovered from the repository's build/CI configuration;
- packages/files included and documented exclusions;
- timeout, repeat, and resource limits;
- expected score or surviving-mutant policy.

Use the repository's native tool when available, for example Stryker for .NET/TypeScript or a Go mutation tool already used by the project. Do not invent a tool command that the repository cannot run.

## Phase 2 — Execute

1. Run the focused unit/component suite before mutation.
2. Run the mutation tool against the recorded scope.
3. Capture the command, tool version, score, killed/surviving mutants, timeout mutants, and exclusions.
4. Confirm the normal suite remains green after mutation.

Mutation testing is not a replacement for acceptance, HTTP integration, E2E, security, or coverage evidence.

## Phase 3 — Surviving Mutants

Every surviving or timed-out mutant must be:

- killed by a meaningful behavior test;
- documented as an intentional equivalent mutant with evidence;
- excluded by an existing repository rule with a reason; or
- recorded as an explicitly owned residual risk that blocks final validation for L3 changes.

Never delete or weaken a test merely to improve the mutation score. Prefer tests that assert business outcomes and edge partitions rather than implementation details.

## Done

- The mutation command and scope are reproducible.
- L2 non-trivial and L3 required mutants are resolved or explicitly justified.
- `verification.md`, `change-summary.md`, and `red-green-refactor.md` contain the evidence.
- Final validation is not requested while unexplained critical survivors remain.
