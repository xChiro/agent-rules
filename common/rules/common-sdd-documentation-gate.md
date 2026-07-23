---
rule_id: RULE-COMMON_SDD_DOCUMENTATION_GATE
trigger: always_on
description: "Mandatory documentation convergence gate for every SDD lifecycle, evolution, bug fix, refactor, and validation review."
---

# Common SDD Documentation Gate

Every SDD change must pass a documentation gate before its validation status is recorded. This applies to `feature`, `bug-fix`, `refactor`, `pipeline`, and `documentation` changes, including spec creation, spec evolution, defect fixes, and refactors.

The gate always uses the canonical `WORKFLOW-COMMON_SDD_UPDATE_DOCUMENTATION_WORKFLOW` (`common-sdd-update-documentation.workflow.md`). Do not create language-specific or lifecycle-specific documentation workflows when this workflow exists.

## Required Planning Evidence

Before implementation or test execution, the active spec must contain:

- A `documentation` task with a stable `T-*` and `CHG-*` ID.
- `workflow_id: WORKFLOW-COMMON_SDD_UPDATE_DOCUMENTATION_WORKFLOW`.
- The task's `workflow_phase`, track ownership, dependencies, `done_when`, and verification command.
- A `workflow-routing.md` entry naming the documentation workflow and why it owns convergence.
- The documentation surfaces expected to change, or a provisional `no_documentation_change_reason` when no project documentation surface is expected.

The documentation task owns convergence of the SDD artifacts, project documentation, AI context, architecture/repository maps, contracts, testing guidance, CI/operations notes, and public documentation affected by the change. The task must not invent a new document when an existing document owns the topic.

## Gate Execution

After the behavior, tests, and relevant verification are green, and before final validation review:

1. Invoke `WORKFLOW-COMMON_SDD_UPDATE_DOCUMENTATION_WORKFLOW`.
2. Inspect the real repository and update only affected documentation surfaces.
3. Record each changed documentation artifact, source evidence, command/check, and remaining unverified claim in `verification.md` and `change-summary.md`.
4. Keep `spec.md`, `plan.md`, `tasks.md`, `workflow-routing.md`, `traceability.yaml`, `verification.md`, and append-only history consistent with the final behavior.
5. Run the available documentation/link/format/schema checks.

The gate is not passed by merely adding a documentation task or mentioning the workflow in chat. The workflow must be invoked and its result recorded. If the workflow determines that no project documentation surface is affected, record `no_documentation_change_reason` in `spec.md`, `verification.md`, and `change-summary.md`, including the inspected surfaces and evidence. This is an explicit gate outcome, not an omitted gate.

## Validation Rules

- `common-sdd-spec.workflow.md` must route the final documentation task before RED is started and rerun the gate when the approved spec, behavior, contract, architecture, risk, test strategy, or repository structure changes.
- `common-sdd-fix-bug.workflow.md` must run the gate for the defect record, regression evidence, affected docs, and append-only history.
- `common-sdd-refactor-lifecycle.workflow.md` must run the gate when structure, ownership, boundaries, repository maps, or developer guidance changes.
- `common-sdd-change-lifecycle.workflow.md` and language implementation/refactor adapters must preserve the documentation task and route it to this workflow.
- `common-sdd-verify-spec.workflow.md` must block `status: verified` until this workflow has passed or the explicit no-change outcome is recorded.

No SDD lifecycle may bypass this gate because a change appears small, mechanical, internal, or documentation-free.
