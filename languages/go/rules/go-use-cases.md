---
rule_id: RULE-GO_USE_CASES
trigger: model_decision
description: "Go use case rules for Clean Architecture and CQRS"
globs: "**/*.go"
---

# Go Use Cases

## SDD Integration

Apply `RULE-COMMON_SDD_AGENTIC_DISCIPLINE` and `RULE-COMMON_INSIDE_OUT_DEVELOPMENT`. This rule specializes Application use cases in Go; Gate 3-APPLICATION, traceability, and convergence remain owned by the common lifecycle.


When creating a new Use Case, follow this exact sequence for CQRS and Clean Architecture compliance with YAGNI principles.

## Use Case Naming

Name the Application use case with an agent noun that expresses the capability it owns:

- `PartyCreator`, not `CreatePartyUseCase`;
- `MemberEnroller`, not `CreateMemberUseCase`;
- `OrderCanceller`, not `CancelOrderService`.

Use `PascalCase` for the Go type and a matching `snake_case.go` file. Keep `UseCase`, `Service`, `Handler`, and verb-only names for technical adapters only when the repository has an established exception. A command/query request or port may retain its CQRS-oriented name, but the orchestrating use case must keep the agent-noun name.

Also follow `go-advanced-practices.md` for context, error handling, interfaces, concurrency, and advanced Go patterns.
Apply `common-test-data-and-double-patterns.md`: use fresh Object Mothers/Test Data Builders and a focused SUT factory; keep doubles at outgoing CQRS/application ports.

For changed backend business behavior, use ATDD plus TDD: Red, Green, Refactor.

## Phase 1: Requirements Analysis
- Identify the **Actor** requesting the change
- Define the **Responsibility** of the new component
- Confirm every in-scope file stays below the strict 150-physical-line limit
- Determine CQRS operations (commands/queries/validation)
- **YAGNI Check**: Only create what's actually needed now

## Phase 2: Red - Expected Behavior Test
Create the unit test file in `tests/unit/{domain}/application/{use_case}/` using snake_case function names.

### Mandatory Requirements
- **Test toolchain**: MUST use Go's standard `testing` package for the runner, `testify/assert` or `testify/require` for assertions, and hand-written doubles; production APIs under test may be imported, but no generated mocks or mocking frameworks
- **Error assertions**: MUST NOT use `require.NoError(t, err)`; use an explicit context-rich `if err != nil` check with `t.Fatalf` when continuation is unsafe, or `assert.NoError` when continuation is safe
- **Test doubles**: Hand-write only the outgoing-port stubs, fakes, spies, or mocks required by the scenario
- **File size limit**: <150 physical lines per test file
- **Function size limit**: ≤20 lines per test function
- **Single Responsibility**: Each test function must test exactly ONE scenario
- **YAGNI**: Only test current functionality
- **Coverage target**: Maintain 90%+ project-wide production coverage and at least 90% domain/application unit coverage

### Test Quality Rules
- **One assertion per concept**: Group related assertions only
- **Test behavior**: Not implementation
- **Use stable test data**: Avoid hardcoded timestamps/IDs
- **Clear failure messages**: Descriptive expected vs actual

### Test Structure Template
```go
func Test_given_[condition]_when_[action]_then_[expected](t *testing.T) {
    // Arrange
    // Act
    response, err := useCase.Execute(ctx, request)
    // Assert
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

- Each named CQRS `struct` and `interface` must be in its own `snake_case.go` file. Do not combine multiple named architectural types in one file.
- Each CQRS command, query, or validation interface must expose exactly one method representing one behavior. Compose multiple focused interfaces in the use case when more than one behavior is required.

### Interface Naming Rules
- **Commands**: `{Action}{Entity}Command` → `CreateMemberCommand`
- **Queries**: `{Get/List/Search}{Entity}By{Criteria}` → `GetMemberByID`
- **Validation**: `Validate{Entity}{Property}Uniqueness` → `ValidateMemberEmailUniqueness`
- **Files**: `snake_case.go` matching interface name

### YAGNI Port Creation
- **Only create ports**: That are actually used by the use case
- **Delete unused ports**: Remove interfaces without implementations
- **Keep interfaces small**: Single responsibility per interface
- **One interface per file**: Following CQRS rules
- **One method per CQRS interface**: Never create a multi-method command/query port or a god repository
- **Protect real boundaries**: Create ports for persistence, messaging, sessions, clocks, external APIs, or substitutable policies
- **Avoid decorative ports**: Do not create ports for private helpers or concrete collaborators that do not cross a boundary

## Phase 4: Green - Use Case Implementation

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
// member_enroller.go
type MemberEnroller struct {
    createMember CreateMemberCommand
    validateEmail ValidateMemberEmailUniqueness
}

func NewMemberEnroller(
    createMember CreateMemberCommand,
    validateEmail ValidateMemberEmailUniqueness,
) *MemberEnroller {
    return &MemberEnroller{
        createMember: createMember,
        validateEmail: validateEmail,
    }
}
```

### Use Case Logic
```go
func (uc *MemberEnroller) Execute(ctx context.Context, req CreateMemberRequest) (CreateMemberResponse, error) {
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

func (uc *MemberEnroller) buildMember(req CreateMemberRequest) (domain.Member, error) {
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

func (uc *MemberEnroller) ensureEmailIsUnique(ctx context.Context, email domain.Email) error {
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

## Manual Test Doubles Created During Phase 2

Create these test-only types before Gate 3-APPLICATION. They may initially fail compilation because the intended application API does not exist yet; record that narrow compile failure as RED.

### Test Double File Structure
```
tests/unit/{domain}/application/{use_case}/doubles/
├── types.go                              # Shared verification types
├── spy_create_member_command.go
└── stub_validate_member_email_uniqueness.go
```

### Hand-Written Double Pattern
```go
// spy_create_member_command.go
type CreateMemberCommandSpy struct {
    // Configuration
    Error error

    // Verification
    Calls []CreateMemberCall
}

type CreateMemberCall struct {
    Member domain.Member
}

func (m *CreateMemberCommandSpy) Execute(ctx context.Context, member domain.Member) error {
    m.Calls = append(m.Calls, CreateMemberCall{Member: member})
    return m.Error
}
```

### YAGNI Test Double Rules
- **Double only outgoing ports**: Use only ports actually consumed by the use case
- **Keep doubles simple**: Manual doubles are mandatory; do not use generators or mocking frameworks
- **Delete unused doubles**: Remove doubles for unused ports
- **One focused double per outgoing port when needed**: Name it by role and observable purpose
- **No test assertions in helpers**: Mothers, builders, fixtures, and doubles return data/errors/captured calls; they never call `testing.T` or assertion APIs

## Phase 6: Refactor
Check for:
- **File size limits**: <150 physical lines per file
- **Function size limits**: ≤20 lines per function
- **Actor-based SRP**: Each module/type serves one actor and one reason to change, following the Clean Architecture definition; do not reduce SRP to one method or one statement per type
- **CQRS compliance**: Commands vs queries separated
- **Naming conventions**: Following rules
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
- Use constructor functions named after the agent-noun type, such as `NewMemberEnroller(...) *MemberEnroller`
- Depend on interfaces at real boundaries, not for every private helper
- Define interfaces in the application layer, implement in infrastructure
- Use concrete types inside the same package when no boundary or substitution exists

- Use individual tests for business-significant scenarios
- Use table-driven tests for compact validation matrices where each row follows the same rule
- Small hand-written stubs, fakes, or spies over mocking frameworks
- Given/When/Then behavior with exact `// Arrange`, `// Act`, and `// Assert` comments; `// Act` has one executable statement on one physical line
- Test edge cases before happy paths

### Clean Architecture Compliance
- **Domain**: Pure business logic, no external dependencies
- **Application**: Use cases, ports, and DTOs
- **Infrastructure**: Implementation of ports
- **Interfaces**: HTTP handlers, CLI commands

## YAGNI Enhancements

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

## Summary

This protocol ensures:

1. **TDD with acceptance behavior framing**: Frame actor-visible acceptance behavior, then start with failing tests
2. **Clean Architecture Compliance**: Proper layer separation
3. **CQRS Implementation**: Commands vs queries vs validation
4. **Domain-Driven Design**: Business logic in domain entities
5. **Manual Test Doubles**: Simple, explicit hand-written doubles
6. **Code Quality**: Size limits and naming conventions
7. **YAGNI Compliance**: Only what's needed now
8. **Screaming Architecture**: Structure communicates purpose
9. **Core Coverage**: 90%+ project-wide production coverage and at least 90% domain/application unit coverage

Follow this sequence exactly for consistent, high-quality use case implementations that are maintainable, testable, and follow all architectural principles.
