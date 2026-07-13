---
workflow_id: WORKFLOW-GO_SDD_REFACTOR_CODE_WORKFLOW
trigger: manual
description: Refactor Go production or test code while preserving SDD behavior and the two-suite test strategy.
---

# Go SDD Refactor Code Workflow

This is a global workflow. Invoke it as `/go-sdd-refactor-code`; do not search for `.windsurf/workflows/go-sdd-refactor-code.workflow` in the project. Its common parent is the sibling global workflow `common-sdd-refactor-lifecycle.workflow.md`; load that sibling from the global/system catalog or follow its phases here.

- Protect current behavior with existing or new unit tests before production refactoring.
- Use HTTP integration protection before changing REST/Lambda routing, DI, persistence, schema, or local-resource wiring.
- Do not add direct infrastructure, repository, handler, or adapter integration tests.
- Refactor one responsibility or boundary at a time.
- Preserve Go package direction, context propagation, error identity, cancellation, and explicit composition.
- Run focused unit tests after each inner change and HTTP integration tests after outer-boundary changes.
- Update tasks, traceability, verification, history, and repository maps when ownership or structure changes.
- Before completion, pass `RULE-COMMON_SDD_DOCUMENTATION_GATE` through `WORKFLOW-COMMON_SDD_UPDATE_DOCUMENTATION_WORKFLOW`; record changed surfaces or its explicit no-change result.
