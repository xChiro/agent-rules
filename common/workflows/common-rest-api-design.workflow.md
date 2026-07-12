---
workflow_id: WORKFLOW-COMMON_REST_API_DESIGN_WORKFLOW
trigger: model_decision
description: Design or evolve a resource-oriented REST contract with ATDD/TDD, compatibility, and clean boundary rules.
---

# Common REST API Design Workflow

Use this as a supporting workflow for `rest-endpoint`, `lambda-rest-endpoint`, and frontend REST-client tasks. It defines the contract; language workflows define execution details.

## Order And Test-First Boundary

1. Invoke `WORKFLOW-COMMON_BDD_SPECIFICATION_WORKFLOW` and write the business-readable scenario from value and concrete examples.
2. Obtain Gate 1 for the spec and Gate 2 before creating or running tests.
3. Define the smallest resource/contract partition: one behavior, one endpoint change, or one compatibility decision.
4. Create acceptance/public-boundary RED, then the focused unit-level `TEST-*` RED.
5. Invoke `WORKFLOW-COMMON_SDD_REVIEW_TEST_EVIDENCE_WORKFLOW`; obtain Gate 3 before production code.
6. Implement the smallest adapter/application change, make the boundary test GREEN, and refactor only while green.
7. Run the applicable HTTP integration, contract, security, quality, and mandatory coverage gates; mutation and critical-E2E gates remain selected by risk.

No controller, router, handler, DTO, schema, or infrastructure production code is changed before the current failing unit-level test exists and Gate 3 is recorded.

## Contract Checklist

Record these decisions in the owning spec and public contract documentation:

- Resource nouns, stable identifiers, shallow relationships, and route ownership.
- Method semantics: `POST` create/command, `GET` read, `PUT` replacement, `PATCH` partial update, `DELETE` removal.
- Request representation, content type, path/query rules, validation, and trusted identity/tenant context.
- Response representation, collection envelope, deterministic ordering, pagination bounds, and status codes.
- Machine-readable errors with a stable code, safe message, and correlation/request identifier.
- Authentication, authorization, rate limits, idempotency, concurrency, and retry behavior for the operation.
- Compatibility impact: additive change, versioned change, migration, deprecation, or breaking change.
- Observability: correlation, safe structured fields, latency, outcome, and dependency failure signals.

Prefer resource state transitions or sub-resources over verb-shaped paths. Do not expose domain entities, persistence shapes, framework types, secrets, or internal failure details.

## Clean Boundary

The dependency direction is:

```text
transport adapter -> application port/use case -> domain
        |                    |
   transport DTO        infrastructure port adapter
```

- Transport DTOs own transport-to-application and application-to-transport mapping functions.
- Persistence DTOs own domain-to-database and database-to-domain mapping functions in the persistence boundary.
- Mapping is pure structural translation; it performs no I/O, authorization, logging, orchestration, or business policy.
- Controllers, routers, and handlers parse, authenticate, validate transport shape, call one application operation, and map the result.
- CQRS command/query separation remains explicit when the repository uses CQRS.

## Evidence And Completion

- Acceptance evidence proves the observable public contract through the closest stable boundary.
- Unit tests prove domain/application rules; HTTP integration tests prove routing, serialization, auth context, DI, persistence wiring, and error mapping.
- Update OpenAPI/schema or equivalent checked-in contract artifacts when the public contract changes.
- Record RED -> GREEN -> REFACTOR in `red-green-refactor.md`, with one entry per behavior partition.
- Record workflow routing, test IDs, commands, gate decisions, compatibility impact, and residual risk in the active spec.

## Language Routing

| Surface | Required supporting workflow |
| --- | --- |
| Go REST/Lambda adapter | `WORKFLOW-GO_REST_API_WORKFLOW` |
| C# REST/Lambda adapter | `WORKFLOW-CSHARP_REST_API_WORKFLOW` |
| React + TypeScript + Vite client | `WORKFLOW-REACT_REST_API_CLIENT_WORKFLOW` |

## Done When

The contract is unambiguous, the business scenario and tests are traceable, boundaries preserve dependency direction, public compatibility is reviewed, required evidence is green, and no implementation detail has leaked into the BDD scenario.
