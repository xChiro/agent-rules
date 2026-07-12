---
workflow_id: WORKFLOW-CSHARP_SDD_REFACTOR_CODE_WORKFLOW
trigger: manual
description: Refactor C# production or test code while preserving SDD behavior and the two-suite test strategy.
---

# C# SDD Refactor Code Workflow

This is a global workflow. Invoke it as `/csharp-sdd-refactor-code`; do not search for `.windsurf/workflows/csharp-sdd-refactor-code.workflow` in the project. Its common parent is the sibling global workflow `common-sdd-refactor-lifecycle.workflow.md`; load that sibling from the global/system catalog or follow its phases here.

- Protect current behavior with existing or new unit tests before production refactoring.
- Use HTTP integration protection before changing ASP.NET/Lambda routing, middleware, DI, EF mappings, migrations, schema, or local-resource wiring.
- Do not add direct infrastructure, repository, DbContext, controller, or adapter integration tests.
- Refactor one responsibility or boundary at a time.
- Preserve Clean Architecture dependency direction, CQRS separation, cancellation, exception identity, and explicit composition.
- Run focused unit tests after each inner change and HTTP integration tests after outer-boundary changes.
- Update tasks, traceability, verification, history, and repository maps when ownership or structure changes.
