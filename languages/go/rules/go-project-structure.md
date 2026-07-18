---
rule_id: RULE-GO_PROJECT_STRUCTURE
trigger: model_decision
description: "Go project structure rules for Clean Architecture, CQRS, and Screaming Architecture"
globs: "**/*.go"
---

# Go Project Structure

## SDD Integration

Apply `RULE-COMMON_SDD_AGENTIC_DISCIPLINE` and `RULE-COMMON_INSIDE_OUT_DEVELOPMENT`. This file specializes repository layout for Go and does not redefine lifecycle gates, test taxonomy, or convergence.


**Core Principles**: Tests mirror production, structure screams business purpose, YAGNI compliance

## Directory Layout

```
{service}/
cmd/{api|worker}/main.go
internal/{domain}/
  ├── domain/{entity}/{entity.go, value_objects/, errors.go}
  ├── application/{use_case}/ports/{commands|queries|validation}/
  ├── application/{capability}/{agent_noun}.go
  │   └── requests.go
  ├── infrastructure/{persistence|messaging|external}/
  └── interfaces/{http|grpc}/{entity}/
pkg/util/
tests/unit/{domain}/  # Mirrors domain/application production
  ├── domain/{entity}/
  └── application/{capability}/{agent_noun}_test.go
      └── doubles/
tests/integration/
  ├── http/{domain}/
  └── infrastructure/{domain}/
```

## Mirror Rules

Tests mirror production structure exactly:
- `internal/{domain}/domain/{entity}/entity.go` → `tests/unit/{domain}/domain/{entity}/entity_test.go`
- `internal/{domain}/application/{capability}/{agent_noun}.go` → `tests/unit/{domain}/application/{capability}/{agent_noun}_test.go`
- HTTP integration → `tests/integration/http/{domain}/`; infrastructure integration → `tests/integration/infrastructure/{domain}/`

## Benefits

Immediate business understanding, navigation by concept, clear boundaries, stakeholder alignment, fast onboarding

## One Type Per File

**Domain**: `{entity}.go`, `value_objects/{type}.go`, `errors.go`
**Application**: `{agent_noun}.go`, `requests.go`, `ports/{commands|queries|validation}/`
**Rule**: One interface per file, <150 physical lines per file

## CQRS Ports

```
ports/
├── commands/create_{entity}_command.go
├── queries/get_{entity}_by_{criteria}.go
└── validation/validate_{entity}_{property}_uniqueness.go
```

## YAGNI Structure

**Do**: Create only what exists now, delete unused folders, keep simple
**Don't**: Create hypothetical future domains/use cases, empty directories

## Test Suites

**Unit** (`tests/unit/{domain}/domain/`, `tests/unit/{domain}/application/{use_case}/`): Pure domain/application behavior with focused outgoing-port fakes and no infrastructure.

**Integration tests**: `tests/integration/http/{domain}/` enters through the real HTTP/public boundary; `tests/integration/infrastructure/{domain}/` invokes the use case and exercises adapters against real local databases, brokers, caches, storage, or emulators. Do not create a third integration folder; third-party APIs use WireMock or small hand-written HTTP stubs.

## Naming

**Files**: `{entity}_test.go`, `{use_case}_test.go` (snake_case for shared setup)
**Per-Behavior Files**: `{action_or_concern}_test.go` describing the business concern (e.g., `quantity_validation_test.go`, `item_existence_test.go`, `transfer_success_test.go`)
**Functions**: `Test_given_{scenario}_when_{action}_then_{expected}` (acceptance behavior pattern)

**MANDATORY**: Test file names MUST be domain-oriented, NOT type-oriented:
- ❌ AVOID: `happy_path_test.go`, `error_cases_test.go`, `edge_cases_test.go`, `infrastructure_errors_test.go` (generic types)
- ✅ PREFER: `quantity_validation_test.go`, `member_enrollment_success_test.go`, `category_uniqueness_test.go` (business behavior)

## Architectural Rules

**Dependency Flow**: Composition/Interface/Infrastructure → Application → Domain
**Domain**: No infrastructure/interfaces/frameworks imports, pure business only
**Application**: Depends on Domain, owns consumer-focused outgoing ports, and contains no DI/framework wiring
**Infrastructure**: Implements interfaces, external dependencies, no business logic
**Interface**: Transport-specific, organized by business concept, no business logic

## Screaming Architecture

**Business-Driven**: Top-level = business domains (`membership/`), use cases = business names (`enroll_member/`)
**Technical Support**: Clean Architecture/DDD within business domains, technical concerns secondary
**Navigation**: By business feature, not technical layer

## Size Rules

**Files**: <150 physical lines
**Functions**: ≤20 lines
**Split**: When approaching limits

## CQRS Organization

**Ports**: `ports/{commands|queries|validation}/{action}_{entity}_{type}.go`
**Doubles**: hand-written fakes/spies under `tests/unit/{domain}/application/{use_case}/doubles/`

## File Organization Best Practices

### One Type Per File
- **One interface per file**: Each CQRS port in its own file
- **One double per file**: Each hand-written fake or spy in its own file
- **File naming**: `snake_case.go` matching the interface name
- **Closely coupled private types**: May stay beside the one primary type when splitting would reduce clarity

### Interface Layer DTO Organization (CRITICAL)
**One Type Per File**: Each DTO struct must be in its own file
- **Request DTOs**: `{entity}_request_dto.go` (e.g., `create_order_request_dto.go`)
- **Response DTOs**: `{entity}_response_dto.go` (e.g., `create_order_response_dto.go`)
- **Naming**: File name must match the struct name in snake_case
- **Package**: DTOs belong to their handler's package (e.g., `package create_order`)

**Examples**:
- ❌ `create_order_dto.go` containing both request and response structs
- ✅ `create_order_request_dto.go` containing only `CreateOrderRequestDTO`
- ✅ `create_order_response_dto.go` containing only `CreateOrderResponseDTO`

### Maximum File Sizes
- **Production files**: <150 physical lines
- **Test files**: <150 physical lines
- **Functions**: ≤20 lines preferred

## YAGNI Management

**Add**: When domain/use case/entity actually exists
**Remove**: Empty folders, unused files/tests, hypothetical features, over-engineered structures
**Regular cleanup**: Delete unused code, simplify complexity

## Summary

Enforces: Screaming Architecture, Clean Architecture, DDD, business logic testing, CQRS, YAGNI, one type per file
Ensures: Maintainable, testable, scalable applications that communicate business purpose
