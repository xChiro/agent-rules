---
trigger: always_on
description: 
globs: 
---

# Go Project Structure - Screaming Architecture with CQRS

**Core Principles**: Tests mirror production, structure screams business purpose, YAGNI compliance

## Directory Layout

```
{service}/
cmd/{api|worker}/main.go
internal/{domain}/
  ├── domain/{entity}/{entity.go, value_objects/, errors.go, ports/}
  ├── application/{use_case}/{usecase.go, requests.go, ports/}
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
- `internal/{domain}/infrastructure/persistence/{entity}/` → `tests/{domain}/infrastructure/{entity}/`

## Benefits

Immediate business understanding, navigation by concept, clear boundaries, stakeholder alignment, fast onboarding

## One Type Per File

**Domain**: `{entity}.go`, `value_objects/{type}.go`, `errors.go`, `ports/{commands|queries|validation}/`
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

## Test Layers

**Domain** (`tests/{domain}/domain/`): Pure business logic, no mocks/infrastructure
**Application** (`tests/{domain}/application/{use_case}/`): Use case orchestration, mock dependencies, ATDD naming
**Infrastructure** (`tests/{domain}/infrastructure/`): Real DB/containers, verify mapping/integration
**Interface** (`tests/{domain}/interfaces/`): API contracts, e2e workflows

## Naming

**Files**: `{entity}_test.go`, `{use_case}_test.go` (snake_case)
**Functions**: `Test_given_{scenario}_when_{action}_then_{expected}` (ATDD pattern)

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

### Maximum File Sizes
- **Production files**: ≤150 lines
- **Test files**: ≤150 lines
- **Functions**: ≤20 lines preferred

## YAGNI Management

**Add**: When domain/use case/entity actually exists
**Remove**: Empty folders, unused files/tests, hypothetical features, over-engineered structures
**Regular cleanup**: Delete unused code, simplify complexity

## Summary

Enforces: Screaming Architecture, Clean Architecture, DDD, TDD, CQRS, YAGNI, one type per file
Ensures: Maintainable, testable, scalable applications that communicate business purpose