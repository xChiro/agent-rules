---
trigger: always_on
description: 
globs: 
---

# Go Project Structure Template

Project structure following Clean Architecture, DDD and TDD principles with mirrored test architecture.

## Core Principle

**Tests MUST mirror the structure of the production code.**

This rule makes navigation, maintenance and AI-generated code easier.

## Directory Layout

```
your-service/

cmd/
├── api/
│   └── main.go        # Composition root: load configuration, wire dependencies and start HTTP server
└── worker/
    └── main.go        # Background workers / async processors

internal/

├── domain/
│   └── <subdomain>/
│       ├── entity.go        # Entities and Value Objects
│       ├── repository.go    # Domain ports (interfaces)
│       └── service.go       # Domain services if required

├── application/
│   └── <subdomain>/
│       ├── usecase.go       # Application use case orchestration
│       ├── requests.go      # Request / Response DTOs
│       └── ports.go         # Interfaces used by the use case

├── infrastructure/
│   ├── persistence/
│   │   └── <subdomain>/
│   │       └── repository.go
│   ├── messaging/
│   │   └── <subdomain>/
│   │       └── publisher.go
│   └── config.go           # Configuration loading

└── interfaces/
    ├── http/
    │   ├── handler.go
    │   └── routes.go
    └── grpc/
        └── handler.go

pkg/
└── util/                    # Shared utilities

scripts/
└── generate.sh

tests/
├──domain/
│   └── <subdomain>/
│       ├── entity_test.go
│       └── value_object_test.go

├── application/
│   └── <subdomain>/
│       ├── usecase_test.go
│       └── mocks/
│           ├── repository_mock.go
│           └── service_mock.go

├── infrastructure/
│   └── persistence/
│       └── <subdomain>/
│           └── repository_integration_test.go

└── interfaces/
    └── http/
        └── handler_integration_test.go
```

## Mirror Rules

Tests MUST mirror the production layer structure.

### Example 1: Domain Layer
**Production**
```
internal/domain/orders/order.go
```

**Test**
```
tests/domain/orders/order_test.go
```

### Example 2: Application Layer
**Production**
```
internal/application/orders/create_order.go
```

**Test**
```
tests/application/orders/create_order_test.go
```

## Benefits of Mirrored Structure

- Clear mapping between code and tests
- Faster navigation
- AI agents can locate tests automatically
- Clean Architecture boundaries remain visible

## Test Layer Responsibilities

### Domain Tests
**Location**: `tests/domain/<subdomain>`

**Purpose**
- Validate Entities
- Validate Value Objects
- Enforce domain invariants
- Test business behavior

**Rules**
- No mocks
- No infrastructure
- Pure business logic

### Application Tests
**Location**: `tests/application/<subdomain>`

**Purpose**
- Test use case orchestration

**Rules**
- Mock outgoing dependencies (repositories, message buses)
- Follow ATDD
- Only one SUT call in Act

**Mocks live in**: `tests/application/<subdomain>/mocks`

### Infrastructure Tests
**Location**: `tests/infrastructure/`

**Purpose**
- Integration tests
- Persistence verification
- External system verification

**Rules**
- Real DB or test container
- No mocks
- Validate mapping

### Interface Tests
**Location**: `tests/interfaces/http` and `tests/interfaces/grpc`

**Purpose**
- API contract verification
- End-to-end behavior

## Naming Conventions

### Test Files
Follow Go conventions:
```
order_test.go
create_order_test.go
email_value_object_test.go
```

### Test Functions
MUST follow ATDD pattern:
```
Test_given_invalid_email_when_creating_email_then_return_error
Test_given_existing_user_when_registering_then_return_duplicate_error
```

## Architectural Rules

### Dependency Direction
Follow Clean Architecture dependency direction:
```
Infrastructure → Application → Domain
```

### Domain Layer Restrictions
**Domain must never import**:
- infrastructure
- interfaces
- frameworks

### Application Layer Rules
- Must depend only on domain interfaces
- Use dependency injection
- Keep use cases focused

### Infrastructure Layer
- Implements domain/application interfaces
- Contains external dependencies
- No business logic

## Code Size Rules

**Files MUST NOT exceed 150 lines.**

**Functions should remain under 20 lines when possible.**

**If a file approaches the limit, split it into smaller components.**

## Key Principles

The structure enforces:

- Clean Architecture
- Domain Driven Design
- Test Driven Development
- Deterministic test organization
- AI-friendly code navigation

## File Organization Best Practices

### One Type Per File
When reasonable, define one high-level type or concept per file.

### Package Organization
- **Domain packages**: Pure business logic
- **Application packages**: Use cases and orchestration
- **Infrastructure packages**: External implementations
- **Interface packages**: Transport layer

### Import Organization
1. Standard library
2. External packages
3. Internal packages (in dependency order)

This structure ensures maintainable, testable, and scalable Go applications following industry best practices.
