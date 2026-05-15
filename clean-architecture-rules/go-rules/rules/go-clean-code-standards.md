---
trigger: always_on
description: 
globs: 
---

# Go Clean Code Standards

Clean coding standards for writing idiomatic, maintainable Go code following Clean Architecture, YAGNI, and Screaming Architecture principles.

## Core Principles

- **Expressive code**: Names and structures clearly describe purpose
- **Small units**: Functions do one thing, are short, avoid deep nesting
- **Single Responsibility**: Each method must have exactly ONE functionality/responsibility
- **Encapsulation**: Hide data and behavior, expose minimum API needed
- **Consistency**: Apply same conventions across the project
- **YAGNI**: Only create what you need now
- **One type per file**: Each type in its own file

## SOLID Principles

**See**: `go-solid-principles.md` for detailed explanations and examples.

**Summary**:
- **SRP**: One module, one actor (one reason to change) - **STRICT: Each method has exactly ONE responsibility**
- **OCP**: Open for extension, closed for modification
- **LSP**: Subtypes substitutable for base types
- **ISP**: Small, focused interfaces (CQRS pattern)
- **DIP**: Depend on abstractions, not concrete types

## Mandatory Requirements

### File Size Limits
- **File size limit**: ≤150 lines per file (including imports and comments)
- **Function size limit**: ≤20 lines per function
- **One type per file**: Each type (struct, interface, etc.) in its own file

### Method Responsibility Rule (CRITICAL)
- **Single Functionality**: Each method must perform exactly ONE operation
- **No Mixed Responsibilities**: Methods cannot combine validation + extraction, creation + persistence, etc.
- **Examples**:
  - ❌ `validateAndExtractData()` - Does two things
  - ✅ `validateData()` - Does one thing
  - ✅ `extractData()` - Does one thing
  - ❌ `createAndSaveEntity()` - Does two things  
  - ✅ `createEntity()` - Does one thing
  - ✅ `saveEntity()` - Does one thing

### Testing Standards
- **Assertion library**: MUST use `github.com/stretchr/testify/assert` library instead of `if` statements for all assertions
- **No unused code**: Every function, variable, import, and type must be used
- **Remove unused imports**: Use compiler warnings and static analysis tools
- **Write code only when actually needed**: Avoid "just in case" code or dead code paths

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

### CQRS Naming Standards
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

## Code Organization

**File Order**: Package doc → Imports (stdlib, then external) → Constants → Types → Variables → Functions
**One Type Per File**: One interface/struct per file, snake_case.go, delete unused
**Structure**: `internal/{domain}/domain/{entity}/{entity.go, value_objects/, errors.go, ports/}`

## Data Structures

**Value Objects**: Immutable, unexported fields, validate in constructors, one per file
**Entities**: Mutable with identity, export methods that maintain invariants, private state
**Collections**: Don't expose directly, Items() returns copy, use methods
**Context**: First argument for I/O, don't store in structs, use only when needed

## Error Handling

**Types**: Sentinel errors (`var ErrNotFound = errors.New(...)`), custom errors for structured data
**Patterns**: Return zero value with error, use errors.Is/As, lowercase messages
**YAGNI**: Don't create hypothetical error types, use sentinel errors when possible
**Panic**: Only for unrecoverable programmer errors, never for business failures, recover() at boundaries

## Formatting

**Code**: Always run `go fmt`, let tools handle spacing
**Imports**: Group stdlib separately, remove unused
**Comments**: Full sentences, package-level above declaration, exported identifiers, remove obvious ones

## YAGNI Principles

**Core**: Create only what's needed now, delete unused code, simple over complex
**Practice**: Functions/types/interfaces only if currently used, test current functionality
**Exceptions**: Core domain concepts, public APIs, security (defensive programming)

## Refactoring

**Process**: Only when tests pass, one small change at a time, run tests frequently
**Techniques**: Eliminate duplication, prefer composition (embedding), use interfaces
**YAGNI**: Delete before adding, simplify before extending, focus on current needs

## Static Analysis

**Tools**: `go fmt`, `go vet`, `golangci-lint`, compiler warnings
**Quality Gates**: All tests pass, ≥80% coverage, no race conditions, static analysis passes

## CQRS Standards

**Interface Design**: Small (single responsibility), one per file, consumer-focused, no god interfaces
**Location**: Define in domain/application (near consumer), implement in infrastructure
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
    "fmt"
    "regexp"
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
- **Write failing test first**: TDD approach
- **Test behavior**: Not implementation
- **Use descriptive names**: Following ATDD pattern
- **Keep tests simple**: One assertion per concept

### CQRS Testing Standards
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

These standards ensure comprehensive, maintainable, and reliable unit test coverage for Go applications following Clean Architecture, YAGNI, and Screaming Architecture principles.