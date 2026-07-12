---
workflow_id: WORKFLOW-WEB_IMPLEMENT_FRONTEND_CHANGE_WORKFLOW
description: Implement a static or lightweight web frontend change without React-specific assumptions.
---

# Web Implement Frontend Change Workflow

## SDD Baseline

This workflow inherits `common-sdd-agentic-discipline.md`, `common-sdd-spec-structure.md`, and `common-sdd-change-lifecycle.workflow.md`.

Before production code:

1. Create or evolve the owning User Story based spec, append a history entry, and update `parallel-tracks.md` for conceptual changes.
2. Obtain Gate 1 approval for the proposed spec writes, including sequential/parallel tasks and execution waves.
3. Create or update the approved spec artifacts.
4. Obtain Gate 2 approval before creating, modifying, or running tests.
5. Add or update BDD Given/When/Then acceptance evidence and confirm it fails for the intended reason.
6. Add the smallest unit-level ATDD-style focused failing test for the next rule, component, or boundary before production code.
7. Invoke `common-sdd-review-test-evidence.workflow.md` and obtain Gate 3 before production code.
8. Implement only enough code to pass, then refactor with tests green.
9. Run `common-sdd-coverage-gate.workflow.md` before completion and record `>= 90%` project-wide production coverage with no affected-feature regression when production code is in scope.
10. Run relevant gates and converge spec, tasks, parallel tracks, traceability, verification notes, and code.

Apply `RULE-COMMON_TEST_ASSERTION_STRUCTURE`: arrange/fixtures and actions do not assert; all assertion APIs belong in the final `Then/Assert` section.


Use this workflow for HTML, CSS, JavaScript, or TypeScript frontend changes in projects that are not React apps.

## 1. Understand The Page

- Identify the user-visible behavior or content change.
- Locate or create the owning User Story based spec.
- Confirm the BDD Given/When/Then acceptance scenario and verification status.
- Check `parallel-tracks.md` before editing files.
- Identify whether the change affects layout, navigation, forms, assets, API calls, or deployment.
- Inspect the existing HTML/CSS/script organization before editing.
- Preserve the current visual language unless the task asks for a redesign.

## 2. Implement Narrowly

- Change the smallest set of files that owns the behavior.
- Keep semantic HTML and accessible labels.
- Keep CSS responsive with explicit constraints.
- Keep scripts small and event-driven.
- Do not add backend-style layers, ports, or use cases to static frontend work.
- Keep the SDD/ATDD loop for behavior changes: BDD acceptance first, ATDD-style test code or documented manual QA, then production edits.

## 3. Validate

- Check mobile and desktop layout when visual behavior changed.
- Run the project build or static check if one exists.
- Verify links, forms, assets, and API calls touched by the change.
- Make sure no secrets or environment-only values were committed into frontend code.
