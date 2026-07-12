---
rule_id: RULE-GO_PROJECT_STRUCTURE
trigger: always_on
description: Go project structure rules for Clean Architecture, CQRS, and Screaming Architecture
globs: **/*.go
---

# Go Project Structure

## SDD Baseline

- Apply `common/rules/common-sdd-agentic-discipline.md` before this rule.
- Create or evolve the owning User Story based spec before production code when behavior, contracts, architecture, or risk changes.
- Apply mandatory Gate 1 before spec writes, Gate 2 before RED, and Gate 3 before Green, even for simple or low-risk changes.
- Keep artifact, task, track, and test IDs traceable through `traceability.yaml` and `parallel-tracks.md`.
- Write BDD Given/When/Then acceptance evidence first, then the unit-level ATDD-style focused failing test for the next rule or boundary before production code.
- Refactor only with tests green and converge spec history, tasks, parallel tracks, traceability, verification notes, and code.


**Core Principles**: Tests mirror production, structure screams business purpose, YAGNI compliance

## Directory Layout

```
{service}/
cmd/{api|worker}/main.go
internal/{domain}/
  ├── domain/{entity}/{entity.go, value_objects/, errors.go}
  ├── application/{use_case}/ports/{commands|queries|validation}/
  ├── application/{use_case}/{usecase.go, requests.go}
  ├── infrastructure/{persistence|messaging|external}/
  └── interfaces/{http|grpc}/{entity}/
pkg/util/
tests/{domain}/  # Mirrors production
  ├── domain/{entity}/
  ├── application/{use_case}/{usecase_test.go, mocks/}
  ├── infrastructure/{entity}/
  └── interfaces/{http|grpc}/
```

## Mirror Rules

Tests mirror production structure exactly:
- `internal/{domain}/domain/{entity}/entity.go` → `tests/{domain}/domain/{entity}/entity_test.go`
- `internal/{domain}/application/{use_case}/usecase.go` → `tests/{domain}/application/{use_case}/usecase_test.go`
- HTTP/persistence wiring → `tests/http/{domain}/`

## Benefits

Immediate business understanding, navigation by concept, clear boundaries, stakeholder alignment, fast onboarding

## One Type Per File

**Domain**: `{entity}.go`, `value_objects/{type}.go`, `errors.go`
**Application**: `{use_case}.go`, `requests.go`, `ports/{commands|queries|validation}/`
**Rule**: One interface per file, ≤150 lines per file

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

**Unit** (`tests/{domain}/domain/`, `tests/{domain}/application/{use_case}/`): Pure domain/application behavior with focused outgoing-port fakes and no infrastructure.

**HTTP integration** (`tests/http/{domain}/`): Real HTTP through router or API Gateway/Lambda, real composition, and local databases/resources. Do not create separate infrastructure or API test folders.

## Naming

**Files**: `{entity}_test.go`, `{use_case}_test.go` (snake_case for shared setup)
**Per-Behavior Files**: `{action_or_concern}_test.go` describing the business concern (e.g., `quantity_validation_test.go`, `item_existence_test.go`, `transfer_success_test.go`)
**Functions**: `Test_given_{scenario}_when_{action}_then_{expected}` (acceptance behavior pattern)

**MANDATORY**: Test file names MUST be domain-oriented, NOT type-oriented:
- ❌ AVOID: `happy_path_test.go`, `error_cases_test.go`, `edge_cases_test.go`, `infrastructure_errors_test.go` (generic types)
- ✅ PREFER: `quantity_validation_test.go`, `member_enrollment_success_test.go`, `category_uniqueness_test.go` (business behavior)

## Architectural Rules

**Dependency Flow**: Infrastructure → Application → Domain
**Domain**: No infrastructure/interfaces/frameworks imports, pure business only
**Application**: Depend on domain interfaces, DI, CQRS pattern
**Infrastructure**: Implements interfaces, external dependencies, no business logic
**Interface**: Transport-specific, organized by business concept, no business logic

## Screaming Architecture

**Business-Driven**: Top-level = business domains (`membership/`), use cases = business names (`enroll_member/`)
**Technical Support**: Clean Architecture/DDD within business domains, technical concerns secondary
**Navigation**: By business feature, not technical layer

## Size Rules

**Files**: ≤150 lines
**Functions**: ≤20 lines
**Split**: When approaching limits

## CQRS Organization

**Ports**: `ports/{commands|queries|validation}/{action}_{entity}_{type}.go`
**Mocks**: `tests/{domain}/application/{use_case}/mocks/mock_{port}.go`

## File Organization Best Practices

### One Type Per File
- **One interface per file**: Each CQRS port in its own file
- **One mock per file**: Each mock implementation in its own file
- **File naming**: `snake_case.go` matching the interface name
- **Group related types**: Value objects can be grouped if tightly coupled

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
- **Production files**: ≤150 lines
- **Test files**: ≤150 lines
- **Functions**: ≤20 lines preferred

## YAGNI Management

**Add**: When domain/use case/entity actually exists
**Remove**: Empty folders, unused files/tests, hypothetical features, over-engineered structures
**Regular cleanup**: Delete unused code, simplify complexity

## Summary

Enforces: Screaming Architecture, Clean Architecture, DDD, business logic testing, CQRS, YAGNI, one type per file
Ensures: Maintainable, testable, scalable applications that communicate business purpose
