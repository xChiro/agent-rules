---
workflow_id: WORKFLOW-COMMON_SDD_VALIDATE_CHANGE_WORKFLOW
trigger: automatic
description: "Deterministic CI/PR validation of SDD artifacts, risk classification, required evidence, and change scope."
---

# Common SDD Validate Change Workflow

Run `tools/validate-sdd-change.sh` on every pull request and before requesting final validation review. The validator is a policy check, not a replacement for tests, code review, coverage, mutation testing, or E2E execution.

## CI/PR Invocation

Use the repository's actual base and head references. A GitHub Actions job may invoke:

```bash
bash tools/validate-sdd-change.sh \
  --base "${BASE_REF:-origin/main}" \
  --head "${GITHUB_SHA:-HEAD}"
```

The job should be named `sdd-policy`, run with read-only repository permissions, and execute before merge protection is evaluated. Projects may pass an explicit `--risk L0|L1|L2|L3` when a human has classified the change; otherwise the validator infers the highest risk from changed paths.

For local validation, use:

```bash
bash tools/validate-sdd-change.sh --base origin/main --head HEAD
```

When the validator itself changes, run its contract suite as part of `sdd-policy`:

```bash
bash tools/tests/validate-sdd-change.test.sh
```

When rules, workflows, skills, or their catalog documentation change, also run:

```bash
bash tools/validate-agent-catalog.sh
bash tools/tests/validate-agent-catalog.test.sh
```

## Required Checks

The validator must fail when applicable evidence is absent or inconsistent:

- A production behavior change has no changed test artifact.
- An L2 or L3 change has no spec, acceptance scenario, traceability, and Red → Green → Refactor evidence.
- An L3 change has no critical E2E evidence and no mutation evidence.
- The explicit risk is lower than the risk implied by the changed paths.
- A parallel execution plan has no corresponding role handoff.

L0 documentation and agent-catalog changes still run syntax and path checks, but do not require production tests. L1 changes use the focused evidence described by `common-change-risk-classification.md`.

## CI Boundary

- Do not expose secrets, credentials, deployment permissions, or cloud write access to the validator.
- Do not let the validator infer success from a test name alone; it checks artifact paths and evidence presence, while test runners prove behavior and stable-ID traceability remains part of review.
- Keep project-specific commands in the repository workflow. This workflow defines the policy contract and canonical job name.
- A failed `sdd-policy` check blocks merge until the artifact is corrected or the risk is explicitly reclassified by the authorized human gate.

## Evidence

Record in `verification.md`:

- validator command, base/head revisions, and inferred or approved risk;
- changed-file scope and any explicit exclusions;
- pass/fail output and the CI job URL or run identifier;
- any approved exception, owner, expiry, and residual risk.

The validator must be rerun after spec, test, production, risk, or evidence changes.

Changed `acceptance.feature` files are also checked by `tools/validate-bdd-spec.sh` for stable scenario IDs, `Given/When/Then` structure, and implementation-language leakage.

When the host exposes consumed-context usage, pass `--context-used "$CONTEXT_USED_PERCENT"`. At `>=60`, `sdd-policy` requires the changed spec to contain a context-checkpoint handoff plus synchronized verification evidence. This structural check does not estimate model context itself; the host or agent supplies the observed value.
