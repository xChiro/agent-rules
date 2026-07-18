---
rule_id: RULE-GO_CLEAN_CODE
trigger: model_decision
description: "Go clean code rules for Clean Architecture projects"
globs: "**/*.go"
---

# Go Clean Code

## SDD Integration

Apply `RULE-COMMON_SDD_AGENTIC_DISCIPLINE`, `go-clean-architecture.md`, and `go-solid-design.md`. This file adds Go quality constraints only; the common lifecycle remains the source of gates, traceability, inside-out order, and convergence.


Clean coding rules for writing idiomatic, maintainable Go code following Clean Architecture, YAGNI, and Screaming Architecture principles.

## Mandatory Architecture And Use Cases

- Use Clean Architecture ownership from Domain policy through Application to outer adapters and Composition; compile-time dependencies point inward as Composition/Interface/Infrastructure → Application → Domain.
- Every actor-visible backend behavior must have one owning Application use case. The use case orchestrates Domain behavior through ports and never imports transport, persistence, cloud SDK, or framework details.
- Before completing a clean-code change, review all five SOLID principles: actor-based SRP, OCP, LSP, ISP, and DIP. Record the actor and change reasons for SRP and the relevant contract/ownership evidence for the other four.

## Core Principles

- **Expressive code**: Names and structures clearly describe purpose
- **Small units**: Functions do one thing, are short, avoid deep nesting
- **Single Responsibility**: A module should be responsible to one, and only one, actor. Methods must be cohesive and must not mix unrelated actors or layer concerns; do not force artificial one-operation methods.
- **Encapsulation**: Hide data and behavior, expose minimum API needed
- **Consistency**: Apply same conventions across the project
- **YAGNI**: Only create what you need now
- **One type per file**: Each type in its own file

## SOLID Principles

**See**:
- `go-solid-design.md` for detailed explanations and examples.
- `go-advanced-practices.md` for idiomatic Go, concurrency, context, errors, generics, performance, and observability.

**Summary**:
- **SRP**: One module, one actor (one reason to change), following Robert C. Martin's *Clean Architecture* definition. Method cohesion supports the module's responsibility but does not replace actor-based SRP.
- **OCP**: Open for extension, closed for modification
- **LSP**: Subtypes substitutable for base types
- **ISP**: Small, focused interfaces (CQRS pattern)
- **DIP**: Depend on abstractions, not concrete types

## Mandatory Requirements

### File Size Guardrails
- **Mandatory file size**: <150 physical lines per in-scope file
- **Target function size**: ≤20 lines per function when practical
- **One type per file**: Required for domain entities, value objects, CQRS ports, DTOs, and exported architectural types
- **Exception**: Small private helper types may stay with their only consumer when splitting would reduce clarity
- **Senior judgment**: Exceed a size target only when the code remains cohesive, readable, and tested; split when size hides mixed responsibilities

### Go CQRS File And Port Granularity (CRITICAL)
- Every named `struct` and `interface` declaration used by CQRS has its own `snake_case.go` file; do not place a second named struct or interface in that file. Anonymous structs are not file-level type declarations.
- Every CQRS command, query, and validation interface exposes exactly one method for exactly one behavior. If a consumer needs two behaviors, define two consumer-owned interfaces and compose them in the use case; never widen a port into a god repository.
- The file name must match the primary struct or interface, and the interface must remain next to the consumer that owns the required behavior.

### Method Responsibility Rule (CRITICAL)
- **Single Cohesive Responsibility**: Each method must have one reason to change and one clear purpose
- **No Mixed Concerns**: Methods cannot combine unrelated concerns such as validation + persistence, authorization + mapping, business decision + transport response, etc.
- **Do Not Micro-Split**: Do not split code only because it has multiple statements. Split when a named concept, test boundary, layer boundary, or repeated semantic rule appears.
- **Examples**:
  - ❌ `validateAndExtractData()` - Does two things
  - ✅ `validateData()` - Does one thing
  - ✅ `extractData()` - Does one thing
  - ❌ `createAndSaveEntity()` - Does two things
  - ✅ `createEntity()` - Does one thing
  - ✅ `saveEntity()` - Does one thing

### Testing Rules
- **Approved test toolchain**: Use Go's `testing` package for the runner, `testify/assert` or `testify/require` for assertions, and hand-written doubles. Production APIs under test may be imported; do not add generated mocks or mocking frameworks.
- **Error assertions**: Do not use `require.NoError(t, err)`. Use an explicit `if err != nil` check with a context-rich `t.Fatalf` when the test cannot continue, or `assert.NoError` only when continuation is safe.
- **Assertions**: Keep explicit expected/actual checks in `// Assert` (Then); an `if` that immediately calls `t.Error`, `t.Errorf`, `t.Fatal`, or `t.Fatalf` is the idiomatic assertion form.
- **Test doubles**: Domain tests use real values. Application tests use small hand-written doubles only for outgoing ports.
- **No unused code**: Every function, variable, import, and type must be used
- **Remove unused imports**: Use compiler warnings and static analysis tools
- **Write code only when actually needed**: Avoid "just in case" code or dead code paths

### Conditional Logic
- Avoid `if/else` trees and `switch` chains for changing business behavior.
- Keep idiomatic guard clauses such as `if err != nil` and simple validation; do not replace clear local checks with patterns.
- For repeated or growing type/status variation, prefer named functions, function tables, or a consumer-owned strategy with real implementations.
- Apply the common conditional-refactoring matrix: extract/decompose, guard clauses, consolidate predicates, special case, or polymorphism/state/strategy. Refactor only with tests green.

## Naming Conventions

### General Rules
- **Packages**: Short, lowercase, single word (e.g., `telemetry`, `order`)
- **Files**: `snake_case.go` for implementation, `snake_case_test.go` for tests
- **Functions**: `CamelCase` (exported), `camelCase` (private)
- **Structs**: `PascalCase` for exported types
- **Variables**: `lowerCamelCase` (e.g., `deviceID`, `dbPool`, `ctx`)
- **Constants**: `PascalCase`, group related constants in iota blocks

### Screaming Architecture Naming
- **Folder names**: Should communicate business purpose
- **File names**: Should match the type they contain
- **Value objects**: In `value_objects/` folder, one per file
- **Entities**: One per file, named after the entity
- **Errors**: In `errors.go` file, grouped by domain

### CQRS Naming Rules
- **Commands**: `{Action}{Entity}Command` → `CreateMemberCommand`
- **Queries**: `{Get/List/Search}{Entity}By{Criteria}` → `GetMemberByID`
- **Validation**: `Validate{Entity}{Property}Uniqueness` → `ValidateMemberEmailUniqueness`
- **Files**: `snake_case.go` matching interface name

### Abbreviations
- Avoid abbreviations unless ubiquitous (e.g., `ID`, `URL`)
- Keep consistent (always `ID`, not mixing `Id` and `ID`)

## Function Design

**SRP**: One actor, one reason to change, split if description contains "and"
**Parameters**: Pass only what's needed, >3 params → use struct
**Error Handling**: Return error as last value, handle immediately, wrap with context, never ignore
**YAGNI**: Don't create "just in case", delete unused, ≤20 lines, single purpose

## Idiomatic Go

**Context**: First argument for I/O and request-scoped work, never stored in structs, never used in pure domain objects.
**Errors**: Wrap technical failures with `%w`, use `errors.Is/As` for decisions, do not compare error strings.
**Interfaces**: Define near consumers, keep small, avoid interfaces with only speculative implementations.
**Composition**: Prefer composition over embedding for reuse; embed only to intentionally expose behavior.
**Generics**: Use only for real reusable type-safe behavior across current call sites; avoid generic repositories/use cases.
**Concurrency**: Every goroutine needs ownership, cancellation, and error handling. Use `errgroup` for grouped parallel I/O.
**Performance**: Benchmark/profile before optimizing, except for obvious algorithmic improvements.
**Observability**: Log at process/transport boundaries, avoid repeated logging of the same returned error, never log secrets.

## Code Organization

**File Order**: Package doc → Imports (stdlib, then external) → Constants → Types → Variables → Functions
**One Type Per File**: One interface/struct per file, snake_case.go, delete unused
**Structure**: `internal/{domain}/domain/{entity}/{entity.go, value_objects/, errors.go}` and `internal/{domain}/application/{use_case}/ports/{commands|queries|validation}/`

## Data Structures

**Value Objects**: Immutable, unexported fields, validate in constructors, one per file
**Entities**: Mutable with identity, export methods that maintain invariants, private state
**Collections**: Don't expose directly, Items() returns copy, use methods
**Context**: First argument for I/O, don't store in structs, use only when needed

### DTO Organization (CRITICAL)
**One Type Per File**: Each DTO struct must be in its own file
- **Request DTOs**: `{entity}_request_dto.go` (e.g., `create_order_request_dto.go`)
- **Response DTOs**: `{entity}_response_dto.go` (e.g., `create_order_response_dto.go`)
- **Naming**: File name must match the struct name in snake_case
- **Package**: DTOs belong to their handler's package (e.g., `package create_order`)

**Examples**:
- ❌ `create_order_dto.go` containing both request and response structs
- ✅ `create_order_request_dto.go` containing only `CreateOrderRequestDTO`
- ✅ `create_order_response_dto.go` containing only `CreateOrderResponseDTO`

**DTO Mapping Ownership**: Keep `FromDomain`, `ToDomain`, `FromRequest`, and `ToResponse` functions with the DTO type that owns the external schema. Do not move one DTO's mapping into a global mapper package. A separate mapper is allowed only for generated DTOs that cannot be edited or for a deliberate multi-source projection documented by the boundary.

## Error Handling

**Types**: Sentinel errors (`var ErrNotFound = errors.New(...)`), custom errors for structured data
**Patterns**: Return zero value with error, use errors.Is/As, lowercase messages
**YAGNI**: Don't create hypothetical error types, use sentinel errors when possible
**Panic**: Only for unrecoverable programmer errors or test helpers such as `mustCreate...`, never for business failures, recover() at boundaries

## Formatting

**Code**: Always run `go fmt`, let tools handle spacing
**Imports**: Group stdlib separately, remove unused
**Comments**: Full sentences, package-level above declaration, exported identifiers, remove obvious ones

## YAGNI Principles

**Core**: Create only what's needed now, delete unused code, simple over complex
**Practice**: Functions/types/interfaces only if currently used, test current functionality
**Exceptions**: Core domain concepts, public APIs, security (defensive programming)

## Duplication Rules

Avoid duplicated business logic, validation rules, mapping logic, error handling decisions, permission checks, and infrastructure setup. Duplication is not only identical text; it is the same decision or rule implemented in multiple places.

### What Counts as Duplication

- The same business rule repeated in handlers, use cases, entities, or adapters.
- The same validation repeated with primitives instead of a value object or shared validator.
- The same DTO-to-domain mapping repeated across handlers or clients.
- The same error mapping repeated instead of being handled at the boundary.
- The same test setup copied across many tests when a builder or setup helper would express intent.
- The same query, filter, sorting, pagination, or authorization decision repeated in separate functions.

### What Does Not Automatically Count as Duplication

- Similar-looking code with different business meaning.
- Small explicit code that is clearer than a generic abstraction.
- Repetition in two places while the shape is still changing.
- Test data that is intentionally local to keep a scenario readable.
- Separate implementations for different layers when each layer owns a different concern.

### Required Response to Duplication

- If the duplicated code represents one domain concept, move the rule into a value object, entity method, domain service, or focused application helper.
- If the duplicated code represents boundary mapping, add the mapping method/constructor to the DTO that owns the external shape, or use a boundary-local companion only for generated DTOs or deliberate multi-source projections.
- If the duplicated code represents test setup, create a builder, fixture, or setup helper with stable defaults.
- If the duplicated code represents infrastructure setup, create a provider or setup function.
- If the duplicated code is only syntactic similarity, keep it explicit and document no abstraction.

### Abstraction Threshold

Do not create a generic abstraction just because two blocks look similar. Extract only when at least one is true:

- The duplicated logic encodes the same business rule.
- A change to one copy would require changing the other copy.
- The repeated code has already appeared in three places.
- The abstraction has a clear domain name.
- The abstraction reduces call-site complexity.
- The abstraction protects a layer boundary.

Prefer a named function, value object, mapper, or builder before introducing generic interfaces, reflection, type parameters, or framework-style abstractions.

## Refactoring

**Process**: Only when tests pass, one small change at a time, run tests frequently
**Techniques**: Eliminate semantic duplication, prefer composition, use interfaces only when they protect a boundary or enable real substitution
**YAGNI**: Delete before adding, simplify before extending, focus on current needs

## Static Analysis

**Tools**: `go fmt`, `go vet`, `golangci-lint`, compiler warnings
**Quality Gates**: All tests pass, 90%+ project-wide production coverage and domain/application unit coverage, no race conditions, static analysis passes

## CQRS Rules

**Interface Design**: Small (single responsibility), one per file, consumer-focused, no god interfaces
**Location**: Define in Application (near the consumer), implement in infrastructure
**Naming**: Commands (`CreateMemberCommand`), Queries (`GetMemberByID`), Validation (`ValidateMemberEmailUniqueness`)
**Files**: `snake_case.go` matching interface name

## Examples

### Clean Function Example
```go
func (p *Processor) ProcessMessage(ctx context.Context, msg Message) error {
    if msg.ID == "" {
        return errors.New("message ID required")
    }

    if err := p.validator.Validate(msg); err != nil {
        return fmt.Errorf("validations failed: %w", err)
    }

    return p.repository.Save(ctx, msg)
}
```

### Value Object Example - One Per File
```go
// handler_name.go
package value_objects

import (
    "errors"
    "strings"
)

type HandlerName struct {
    value string
}

func NewHandlerName(val string) (HandlerName, error) {
    if val == "" || !strings.Contains(val, "@") {
        return HandlerName{}, errors.New("invalid email")
    }
    return HandlerName{value: val}, nil
}
```

### YAGNI Example
```go
// ❌ DON'T DO THIS - Creating unused functions
func (p *Processor) ProcessBatch(ctx context.Context, msgs []Message) error {
    // This function is never used but was created "just in case"
    return nil
}

func (p *Processor) ProcessSingle(ctx context.Context, msg Message) error {
    // This is all that's actually needed
    if msg.ID == "" {
        return errors.New("message ID required")
    }
    return p.repository.Save(ctx, msg)
}
```

## Best Practices Summary

### Test Design
- **Frame acceptance behavior first**: acceptance behavior approach from actor outcome to executable tests
- **Write failing test first**: business logic testing approach
- **Test behavior**: Not implementation
- **Use descriptive names**: Test names must express Given-When-Then behavior; existing non-conforming names are changed when the test is touched or the migration workflow is invoked.
- **Keep tests simple**: One assertion per concept
- **Protect coverage**: Maintain 90%+ project-wide production coverage and at least 90% domain/application unit coverage

### CQRS Testing Rules
- **Command tests**: Verify write operations and side effects
- **Query tests**: Verify read operations and data transformation
- **Validation tests**: Verify business rule enforcement
- **Integration tests**: Verify real infrastructure interactions

### Code Organization
- **Group by business concept**: Not technical layer
- **One type per file**: Following Screaming Architecture
- **Clear folder structure**: That communicates purpose
- **YAGNI compliance**: Only what's needed now

### YAGNI Compliance
- **Delete unused code**: Regular cleanup
- **Simple solutions**: Over complex ones
- **Current needs focus**: Not hypothetical futures
- **Regular refactoring**: To maintain simplicity

### Duplication Control
- **Remove duplicated decisions**: Business rules, validation, mapping, permissions, and error handling must have one owner
- **Avoid premature DRY**: Do not extract abstractions from superficial similarity
- **Name shared behavior by domain concept**: If the shared code has no clear name, the abstraction is probably premature

These rules support comprehensive, maintainable, and reliable unit test coverage for Go applications following Clean Architecture, YAGNI, and Screaming Architecture principles.
