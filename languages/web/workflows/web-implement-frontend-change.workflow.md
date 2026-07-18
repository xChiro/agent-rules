---
workflow_id: WORKFLOW-WEB_IMPLEMENT_FRONTEND_CHANGE_WORKFLOW
trigger: manual
description: "Implement a static or lightweight web frontend change without React-specific assumptions."
---

# Web Implement Frontend Change Workflow

## SDD Baseline

This workflow specializes `WORKFLOW-COMMON_SDD_CHANGE_LIFECYCLE_WORKFLOW`; the parent owns Gates 1–3, the final evidence review, spec artifacts, routing, documentation, clean-up, security, coverage, and convergence. After Gate 2, create the smallest BDD-linked UI RED or record the approved automation gap, apply the common test rules, obtain Gate 3 before production behavior, and refactor only while evidence stays green. Do not duplicate or reorder the parent lifecycle here.


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
