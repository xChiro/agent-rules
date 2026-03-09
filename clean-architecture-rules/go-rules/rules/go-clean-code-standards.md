---
trigger: always_on
description: Core Go coding standards and conventions
globs: ["**/*.go"]
---

# Go Clean Code Standards

Comprehensive coding standards for writing idiomatic, maintainable Go code following Clean Architecture principles.

## Core Principles

- **Expressive code**: Names and structures clearly describe purpose without redundant comments
- **Small units**: Functions do one thing, are short (≤20 lines), avoid deep nesting
- **Encapsulation**: Hide data and behavior; expose minimum API needed
- **Consistency**: Apply same conventions across the project

## Mandatory Requirements (Non-Negotiable)

- **File size limit**: ≤150 lines per file (including imports and comments)
- **Function size limit**: ≤20 lines per function
- **Assertion library**: MUST use `github.com/stretchr/testify/assert` library instead of `if` statements for all assertions - this is non-negotiable
- **No unused code**: Every function, variable, import, and type must be used
  - Remove unused imports, variables, and functions
  - Avoid "just in case" code or dead code paths
  - Use compiler warnings and static analysis tools
  - Write code only when actually needed

## Naming Conventions

### General Rules
- **Packages**: Short, lowercase, single word (e.g., `telemetry`, `order`)
- **Files**: `snake_case.go` for implementation, `snake_case_test.go` for tests
- **Functions**: `CamelCase` (exported), `camelCase` (private)
- **Structs**: `PascalCase` for exported types
- **Variables**: `lowerCamelCase` (e.g., `deviceID`, `dbPool`, `ctx`)
- **Constants**: `PascalCase`, group related constants in iota blocks

### Interface Naming
- Name interfaces by behavior they represent (e.g., `TelemetryRepository`)
- Avoid `Manager`/`Processor` unless role is clear
- Use descriptive names over generic ones

### Abbreviations
- Avoid abbreviations unless ubiquitous (e.g., `ID`, `URL`)
- Keep consistent (always `ID`, not mixing `Id` and `ID`)

## Function Design

### Single Responsibility
- Each function performs one operation
- If description contains "and", split it
- Prefer small, well-named functions over monolithic ones

### Parameters
- Pass only what function needs
- Avoid long parameter lists (>3 parameters → use struct)
- Use structs for related parameters

### Error Handling
- Return `error` as last return value
- Handle errors immediately (guard clauses)
- Wrap errors with context using `fmt.Errorf("operation: %w", err)`
- Never ignore errors (`_ = foo()` is forbidden)

## Code Organization

### File Structure
Order top-level declarations as:
1. Package documentation/comment
2. Imports (standard library, then external)
3. Constants
4. Types
5. Variables
6. Functions/methods

### One Type Per File
- Define one high-level type per file when reasonable
- Group related small types (e.g., value objects) if tightly coupled

## Data Structures

### Value Objects
- Immutable domain concepts
- Unexported fields with exported constructor functions
- Validate input in constructors

### Entities
- Mutable objects with identity
- Export only methods that maintain invariants
- Keep internal state private

### Collections
- Do not expose slices/maps directly
- Provide methods that copy or encapsulate collections
- `Items()` should return a copy

### Context Usage
- Pass `context.Context` as first argument for I/O or cancellable operations
- Do not store context in structs

## Error Handling Standards

### Error Types
- **Sentinel errors**: Package-level variables for common conditions
  ```go
  var ErrNotFound = errors.New("entity not found")
  ```
- **Custom errors**: For structured error data
  ```go
  type ValidationError struct {
      Field string
      Msg   string
  }
  ```

### Error Patterns
- Always return zero value with error
- Use `errors.Is()` for sentinel errors
- Use `errors.As()` for custom error types
- Error messages: lowercase, no punctuation, concise

### Panic Usage
- Reserve `panic` for unrecoverable programmer errors
- Never panic for expected business failures
- Use `recover()` only at application boundaries

## Formatting and Style

### Code Formatting
- Always run `go fmt` on code
- Let automated tools handle spacing and alignment

### Import Management
- Group standard library imports separately from external packages
- Avoid unnecessary imports
- Remove unused imports

### Comments
- Use full sentences with proper punctuation
- Package-level comments above package declaration
- Exported identifiers should have comments
- Remove "obvious" comments - let code document itself

## Refactoring Guidelines

### Process
- Refactor only when tests are passing
- Make one small change at a time
- Run tests frequently

### Techniques
- Eliminate duplication by extracting common logic
- Prefer composition over inheritance (embedding in Go)
- Use interfaces to assemble behaviors

## Dependency Management

### Interface Design
- Keep interfaces small and focused
- Consumer should depend only on methods it needs
- Define interfaces in domain/application layer
- Implementations live in infrastructure

### Constructor Pattern
```go
func NewUseCase(dep1 Port1, dep2 Port2) *UseCase {
    return &UseCase{
        port1: dep1,
        port2: dep2,
    }
}
```

## Pointer Semantics

### Rules
- **Entities**: Use pointers (`*Entity`) - identity-based, mutable
- **Value Objects**: Use values (`ValueObject`) - immutable, copy semantics
- **Pointer receivers**: Only for methods that modify state
- **Value receivers**: Default for immutable types

## Static Analysis

### Required Tools
- `go fmt` for formatting
- `go vet` for static analysis
- `golangci-lint` for comprehensive linting
- Use compiler warnings to identify unused code

### Quality Gates
- All code must pass static analysis
- No unused imports, variables, or functions
- All functions must be ≤20 lines
- All files must be ≤150 lines

## Examples

### Clean Function Example
```go
func (p *Processor) ProcessMessage(ctx context.Context, msg Message) error {
    if msg.ID == "" {
        return errors.New("message ID required")
    }
    
    if err := p.validator.Validate(msg); err != nil {
        return fmt.Errorf("validation failed: %w", err)
    }
    
    return p.repository.Save(ctx, msg)
}
```

### Value Object Example
```go
type Email struct {
    value string
}

func NewEmail(val string) (Email, error) {
    if val == "" || !strings.Contains(val, "@") {
        return Email{}, errors.New("invalid email")
    }
    return Email{value: val}, nil
}
```

This standard ensures consistent, maintainable, and readable Go code that follows Clean Architecture principles and industry best practices.
