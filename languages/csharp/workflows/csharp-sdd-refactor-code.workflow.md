---
workflow_id: WORKFLOW-CSHARP_SDD_REFACTOR_CODE_WORKFLOW
trigger: manual
description: "Refactor C# production or test code while preserving SDD behavior and the two-suite test strategy."
---

# C# SDD Refactor Code Workflow

This is a global workflow. Invoke it as `/csharp-sdd-refactor-code`; do not search for `.windsurf/workflows/csharp-sdd-refactor-code.workflow` in the project. Its common parent is the sibling global workflow `common-sdd-refactor-lifecycle.workflow.md`; load that sibling from the global/system catalog or follow its phases here.

- Protect current behavior with existing or new unit tests before production refactoring.
- Before editing, identify the named Application use case, its actor, owning ports, dependency direction, and evidence for all five SOLID principles: actor-based SRP, OCP, LSP, ISP, and DIP.
- Use HTTP integration protection before changing ASP.NET/Lambda routing, middleware, DI, EF mappings, migrations, schema, or local-resource wiring.
- Do not add a third integration project. Infrastructure, repository, DbContext, controller, and adapter integration tests belong in the existing integration project under its HTTP or Infrastructure scope.
- Refactor one responsibility or boundary at a time.
- Preserve ownership/development order Domain → Application → outer adapters → Composition and compile-time dependency direction Composition/Interface/Infrastructure → Application → Domain, plus CQRS separation, cancellation, exception identity, and explicit composition.
- Keep Domain/Application names abstract and provider-neutral during refactoring. Do not use DynamoDB, Cosmos, Kafka, or equivalent provider names in inner-layer files, namespaces, ports, types, DTOs, events, or errors; concrete names stay in outer adapters/configuration.
- Never move business policy out of the named use case/domain owner into a controller, adapter, repository, DTO, or composition root.
- Run focused unit tests after each inner change and the affected HTTP or Infrastructure scope of the integration project after outer-boundary changes.
- Update tasks, traceability, verification, history, and repository maps when ownership or structure changes.
- Before final validation, pass `RULE-COMMON_SDD_DOCUMENTATION_GATE` through `WORKFLOW-COMMON_SDD_UPDATE_DOCUMENTATION_WORKFLOW`; record changed surfaces or its explicit no-change result.
