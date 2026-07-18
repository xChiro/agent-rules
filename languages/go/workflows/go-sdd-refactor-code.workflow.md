---
workflow_id: WORKFLOW-GO_SDD_REFACTOR_CODE_WORKFLOW
trigger: manual
description: "Refactor Go production or test code while preserving SDD behavior and the two-suite test strategy."
---

# Go SDD Refactor Code Workflow

This is a global workflow. Invoke it as `/go-sdd-refactor-code`; do not search for `.windsurf/workflows/go-sdd-refactor-code.workflow` in the project. Its common parent is the sibling global workflow `common-sdd-refactor-lifecycle.workflow.md`; load that sibling from the global/system catalog or follow its phases here.

- Protect current behavior with existing or new unit tests before production refactoring.
- Before editing, identify the named Application use case, its actor, owning ports, dependency direction, and evidence for all five SOLID principles: actor-based SRP, OCP, LSP, ISP, and DIP.
- Use HTTP integration protection before changing REST/Lambda routing, DI, persistence, schema, or local-resource wiring.
- Do not add a third integration suite. Infrastructure, repository, handler, and adapter integration tests belong in the appropriate `tests/integration/http/` or `tests/integration/infrastructure/` scope.
- Refactor one responsibility or boundary at a time.
- Preserve ownership/development order Domain → Application → outer adapters → Composition and compile-time dependency direction Composition/Interface/Infrastructure → Application → Domain, plus context propagation, error identity, cancellation, and explicit composition.
- Keep Domain/Application names abstract and provider-neutral during refactoring. Do not use DynamoDB, Cosmos, Kafka, or equivalent provider names in inner-layer files, packages, ports, types, DTOs, events, or errors; concrete names stay in outer adapters/configuration.
- Never move business policy out of the named use case/domain owner into a handler, adapter, repository, DTO, or composition root.
- Run focused unit tests after each inner change and the affected integration/http or integration/infrastructure scope after outer-boundary changes.
- Update tasks, traceability, verification, history, and repository maps when ownership or structure changes.
- Before final validation, pass `RULE-COMMON_SDD_DOCUMENTATION_GATE` through `WORKFLOW-COMMON_SDD_UPDATE_DOCUMENTATION_WORKFLOW`; record changed surfaces or its explicit no-change result.
