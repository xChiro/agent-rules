---
trigger: model_decision
description: Go use case implementation protocol for Clean Architecture and CQRS
globs: **/*.go
---

# Go Use Case Implementation Protocol - CQRS Enhanced with YAGNI

When creating a new Use Case, follow this exact sequence for CQRS and Clean Architecture compliance with YAGNI principles.

Also follow `go-idiomatic-advanced-practices.md` for context, error handling, interfaces, concurrency, and advanced Go patterns.

## Phase 1: Requirements Analysis
- Identify the **Actor** requesting the change
- Define the **Responsibility** of the new component
- Confirm it adheres to the 150-line file limit
- Determine CQRS operations (commands/queries/validation)
- **YAGNI Check**: Only create what's actually needed now

## Phase 2: Failing A-TDD Test (Red)
Create test file in `tests/{domain}/application/{use_case}/` using snake_case function names.

### Mandatory Requirements
- **Assertion library**: MUST use `github.com/stretchr/testify/assert`
- **File size limit**: ≤150 lines per test file
- **Function size limit**: ≤20 lines per test function
- **Single Responsibility**: Each test function must test exactly ONE scenario
- **YAGNI**: Only test current functionality
- **Coverage target**: Maintain 90%+ unit coverage for domain/application layers

### Test Quality Guidelines
- **One assertion per concept**: Group related assertions only
- **Test behavior**: Not implementation
- **Use stable test data**: Avoid hardcoded timestamps/IDs
- **Clear failure messages**: Descriptive expected vs actual

### Test Structure Template
```go
func Test_given_[condition]_when_[action]_then_[expected](t *testing.T) {
    // Arrange: Setup CQRS mocks and request
    // Act: Execute single use case call
    // Assert: Verify behavior and mock interactions
}
```

## Phase 3: CQRS Port Definition
Define granular interfaces in `internal/{domain}/application/{use_case}/ports/`:

### Port Separation - One Interface Per File
```
ports/
├── commands/
│   ├── create_{entity}_command.go
│   └── update_{entity}_{property}_command.go
├── queries/
│   ├── get_{entity}_by_{criteria}.go
│   └── list_{entities}_by_{criteria}.go
└── validation/
    └── validate_{entity}_{property}_uniqueness.go
```

### Interface Naming Standards
- **Commands**: `{Action}{Entity}Command` → `CreateMemberCommand`
- **Queries**: `{Get/List/Search}{Entity}By{Criteria}` → `GetMemberByID`
- **Validation**: `Validate{Entity}{Property}Uniqueness` → `ValidateMemberEmailUniqueness`
- **Files**: `snake_case.go` matching interface name

### YAGNI Port Creation
- **Only create ports**: That are actually used by the use case
- **Delete unused ports**: Remove interfaces without implementations
- **Keep interfaces small**: Single responsibility per interface
- **One interface per file**: Following CQRS standards
- **Protect real boundaries**: Create ports for persistence, messaging, sessions, clocks, external APIs, or substitutable policies
- **Avoid decorative ports**: Do not create ports for private helpers or concrete collaborators that do not cross a boundary

## Phase 4: Use Case Implementation (Green)

### Request/Response Structs
```go
// requests.go
type CreateMemberRequest struct {
    ExternalID  string
    Provider    string
    HandlerName string
}

type CreateMemberResponse struct {
    MemberID string
    Status   string
}
```

### Use Case Struct
```go
// usecase.go
type CreateMemberUseCase struct {
    createMember CreateMemberCommand
    validateEmail ValidateMemberEmailUniqueness
}

func NewCreateMemberUseCase(
    createMember CreateMemberCommand,
    validateEmail ValidateMemberEmailUniqueness,
) *CreateMemberUseCase {
    return &CreateMemberUseCase{
        createMember: createMember,
        validateEmail: validateEmail,
    }
}
```

### Use Case Logic
```go
func (uc *CreateMemberUseCase) Execute(ctx context.Context, req CreateMemberRequest) (CreateMemberResponse, error) {
    member, err := uc.buildMember(req)
    if err != nil {
        return CreateMemberResponse{}, err
    }

    if err := uc.ensureEmailIsUnique(ctx, member.Email()); err != nil {
        return CreateMemberResponse{}, err
    }

    if err := uc.createMember.Execute(ctx, member); err != nil {
        return CreateMemberResponse{}, fmt.Errorf("failed to create member: %w", err)
    }

    return newCreateMemberResponse(member), nil
}

func (uc *CreateMemberUseCase) buildMember(req CreateMemberRequest) (domain.Member, error) {
    handlerName, err := domain.NewHandlerName(req.HandlerName)
    if err != nil {
        return domain.Member{}, fmt.Errorf("invalid handler name: %w", err)
    }

    externalID, err := domain.NewExternalIdentifier(req.ExternalID, req.Provider)
    if err != nil {
        return domain.Member{}, fmt.Errorf("invalid external id: %w", err)
    }

    return domain.NewMember(handlerName, externalID), nil
}

func (uc *CreateMemberUseCase) ensureEmailIsUnique(ctx context.Context, email domain.Email) error {
    isUnique, err := uc.validateEmail.Execute(ctx, email)
    if err != nil {
        return fmt.Errorf("failed to validate email uniqueness: %w", err)
    }
    if !isUnique {
        return domain.ErrEmailAlreadyExists
    }

    return nil
}

func newCreateMemberResponse(member domain.Member) CreateMemberResponse {
    return CreateMemberResponse{MemberID: member.ID().String(), Status: member.Status().String()}
}
```

## Phase 5: Manual Mock Implementation

### Mock File Structure
```
tests/{domain}/application/{use_case}/mocks/
├── types.go                              # Shared verification types
├── mock_create_member_command.go
└── mock_validate_member_email_uniqueness.go
```

### Mock Implementation Pattern
```go
// mock_create_member_command.go
type MockCreateMemberCommand struct {
    // Configuration
    Error error

    // Verification
    Calls []CreateMemberCall
}

type CreateMemberCall struct {
    Member domain.Member
}

func (m *MockCreateMemberCommand) Execute(ctx context.Context, member domain.Member) error {
    m.Calls = append(m.Calls, CreateMemberCall{Member: member})
    return m.Error
}
```

### YAGNI Mock Guidelines
- **Only mock ports**: That are actually used by the use case
- **Keep mocks simple**: Manual mocks preferred
- **Delete unused mocks**: Remove mocks for unused ports
- **One mock per interface**: Following CQRS standards

## Phase 6: Refactoring (Blue)
Check for:
- **File size limits**: ≤150 lines per file
- **Function size limits**: ≤20 lines per function
- **Single responsibility**: Each file has one purpose, each method has ONE responsibility
- **CQRS compliance**: Commands vs queries separated
- **Naming conventions**: Following standards
- **YAGNI compliance**: Delete unused code

## Go-Specific Best Practices

### Naming Conventions
- **Files**: `snake_case.go` for implementation, `snake_case_test.go` for tests
- **Functions**: `CamelCase` (exported), `camelCase` (private)
- **Test Functions**: `Test_given_condition_when_action_then_expected`
- **Structs**: `PascalCase` for exported types
- **Interfaces**: `PascalCase` describing behavior (e.g., `CreateMemberCommand`)

### Error Handling
- Always return `error` as last return value
- Use explicit error checking with `if err != nil`
- Wrap errors with context using `fmt.Errorf("operation: %w", err)`
- Define sentinel errors for common conditions
- Use `errors.Is/As` for branching decisions
- Never branch on error strings
- Do not log and return the same error inside use cases unless the use case is the final process boundary

### Dependency Injection
- Use constructor functions `NewUseCase(dep1, dep2) *UseCase`
- Depend on interfaces at real boundaries, not for every private helper
- Define interfaces in the application layer, implement in infrastructure
- Use concrete types inside the same package when no boundary or substitution exists

- Use individual tests for business-significant scenarios
- Use table-driven tests for compact validation matrices where each row follows the same rule
- Manual mocks over heavy mocking frameworks
- Arrange/Act/Assert structure with clear comments
- Test edge cases before happy paths

### Clean Architecture Compliance
- **Domain**: Pure business logic, no external dependencies
- **Application**: Use cases, ports, and DTOs
- **Infrastructure**: Implementation of ports
- **Interfaces**: HTTP handlers, CLI commands

## YAGNI Protocol Enhancements

### Phase 0: YAGNI Assessment
Before starting any phase, ask:
- **Is this needed now?** Or for a hypothetical future?
- **Can I simplify?** Remove unnecessary complexity
- **Can I delete?** Remove unused code or tests

### During Implementation
- **Stop when green**: Don't over-engineer
- **Delete before adding**: Remove unused code first
- **Simple over complex**: Prefer straightforward solutions

### After Implementation
- **Review for YAGNI**: Remove any "just in case" code
- **Delete unused dependencies**: Remove imports without usage
- **Simplify structure**: Remove unnecessary complexity

## Protocol Summary

This protocol ensures:

1. **A-TDD-First Development**: Frame actor-visible acceptance behavior, then start with failing tests
2. **Clean Architecture Compliance**: Proper layer separation
3. **CQRS Implementation**: Commands vs queries vs validation
4. **Domain-Driven Design**: Business logic in domain entities
5. **Manual Testing**: Simple, explicit mocks
6. **Code Quality**: Size limits and naming conventions
7. **YAGNI Compliance**: Only what's needed now
8. **Screaming Architecture**: Structure communicates purpose
9. **Core Coverage**: 90%+ unit coverage for domain/application layers

Follow this sequence exactly for consistent, high-quality use case implementations that are maintainable, testable, and follow all architectural principles.
