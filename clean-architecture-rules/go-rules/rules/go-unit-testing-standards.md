---
trigger: model_decision
description: Go unit testing standards for domain and application behavior
globs: **/*_test.go
---

# Go Unit Testing Standards - CQRS Enhanced with YAGNI

**Principles**: TDD-first, Red-Green-Refactor, behavior over implementation, isolation, deterministic, YAGNI testing

## Test Structure

**Naming**: `Test_given_[scenario]_when_[action]_then_[expected]` (snake_case)
**Template**: Arrange → Act → Assert
**Organization**: Group test files by domain concern/action, not by test type
**MANDATORY**: MUST use comment separators `// Arrange`, `// Act`, `// Assert` to divide test sections

## Domain-Oriented Test File Organization (MANDATORY)

Test files MUST be organized by **business concern/action** being validated, NOT by test type (happy_path, error_cases, edge_cases).

**Structure**:
```
tests/{domain}/application/{use_case}/
  {use_case}_test_setup.go         # Shared setup helpers (setup functions, mock structs)
  {use_case}_value_object_helpers.go # Helper functions for creating value objects
  {action_or_concern}_test.go        # Tests for one specific behavior
  {validation_concern}_test.go       # Tests for one validation rule
  fixtures/builders.go               # Test data builders (Builder pattern)
  mocks/mock_{interface}.go
```

**Example** (transfer use case):
```
tests/inventory/application/organization_inventory_item_transfer/
  organization_inventory_item_transfer_test_setup.go    # Setup helpers
  organization_inventory_item_transfer_value_object_helpers.go # Value object helpers
  item_existence_test.go                          # Item not found behavior
  quantity_validation_test.go                     # Insufficient quantity behavior
  transfer_success_test.go                        # Successful transfer behavior
  transfer_persistence_failure_test.go            # Persistence failure behavior
  fixtures/builders.go                            # Test data builders
  mocks/mock_{port}.go
```

**Rules**:
- File name describes WHAT business behavior is tested, not WHEN it fails
- ❌ AVOID: `happy_path_test.go`, `error_cases_test.go`, `edge_cases_test.go`
- ✅ PREFER: `quantity_validation_test.go`, `item_existence_test.go`, `transfer_success_test.go`
- One concern per file (single business rule, validation, or workflow path)
- File ≤150 lines
- Use `snake_case.go` matching the domain concept
- Use Builder pattern for test data in `fixtures/builders.go`
- Use setup helpers in `{use_case}_test_setup.go`
- Use value object helpers in `{use_case}_value_object_helpers.go`

## Anti-Patterns

**One-Class-One-Test**: Don't create separate test files just because every production type needs a matching test. Test behavior through the smallest meaningful public contract.

**Domain Entity Testing**: Domain entities and value objects may be tested directly when they own pure invariants, state transitions, or validation rules. Prefer use case tests for workflow orchestration and cross-dependency behavior.

**HTTP Handler Unit Tests**: Do not create mock-heavy handler unit tests when the handler's value is request parsing, status codes, auth/session extraction, and response mapping. Prefer end-to-end or integration tests with real wiring for HTTP contracts. For service-specific HBK Inventory rules, use DynamoDB-backed E2E tests.

**Loop-Based Testing**: Avoid loops when each scenario has distinct business meaning. Write individual test functions for important business cases.
- Exceptions: table-driven validation matrices, parser/formatter cases, character validation, permissions matrices, and performance benchmarks

## TDD Workflow

1. **Red**: Write failing test
2. **Green**: Minimal code to pass
3. **Refactor**: Clean up

## Quality Standards

**Requirements**: ≤150 lines/file, ≤20 lines/function, use `testify/assert`, single assertion concept
**YAGNI**: Test current functionality only, delete unused tests, focus on critical paths, simple setup

## CQRS Mock Strategy

**Guidelines**: One per interface, exported fields for config/verification, mock only outgoing ports
**Structure**: `tests/{domain}/application/{use_case}/mocks/mock_{interface}.go`

```go
type MockCreateMemberCommand struct {
    Error error
    Calls []CreateMemberCall
}

func (m *MockCreateMemberCommand) Execute(ctx context.Context, member domain.Member) error {
    m.Calls = append(m.Calls, CreateMemberCall{Member: member})
    return m.Error
}
```

## Testing Patterns

```go
// Use Case Test with Builder Pattern
func Test_given_valid_data_when_enrolling_member_then_success(t *testing.T) {
    t.Parallel()
    
    // Arrange
    useCase, mocks := setupEnrollMember(t)
    mocks.UserSession.UserID = testUserID
    
    request := fixtures.NewEnrollMemberRequestBuilder().
        WithHandlerName("test-handler").
        WithExternalID("test-id").
        Build()
    
    // Act
    response, err := useCase.Execute(context.Background(), request)
    
    // Assert
    assert.NoError(t, err)
    assert.NotEmpty(t, response.MemberID)
    assert.Len(t, mocks.CreateCmd.Calls, 1)
}

// Test Data Builder (fixtures/builders.go)
type EnrollMemberRequestBuilder struct {
    request requests.EnrollMemberRequest
}

func NewEnrollMemberRequestBuilder() *EnrollMemberRequestBuilder {
    return &EnrollMemberRequestBuilder{
        request: requests.EnrollMemberRequest{
            HandlerName: mustCreateHandlerName("test-handler"),
            ExternalID:  mustCreateExternalID("test-id", "test-provider"),
        },
    }
}

func (b *EnrollMemberRequestBuilder) WithHandlerName(name string) *EnrollMemberRequestBuilder {
    b.request.HandlerName = mustCreateHandlerName(name)
    return b
}

func (b *EnrollMemberRequestBuilder) WithExternalID(id string) *EnrollMemberRequestBuilder {
    b.request.ExternalID = mustCreateExternalID(id, "test-provider")
    return b
}

func (b *EnrollMemberRequestBuilder) Build() requests.EnrollMemberRequest {
    return b.request
}

// Value Object Helper ({use_case}_value_object_helpers.go)
func mustCreateHandlerName(name string) value_objects.HandlerName {
    handlerName, err := value_objects.NewHandlerName(name)
    if err != nil {
        panic(err)
    }
    return handlerName
}

func mustCreateExternalID(id string, provider string) value_objects.ExternalIdentifier {
    externalID, err := value_objects.NewExternalIdentifier(id, provider)
    if err != nil {
        panic(err)
    }
    return externalID
}

// Setup Helper ({use_case}_test_setup.go)
type EnrollMemberTestMocks struct {
    CreateCmd    *MockCreateMemberCommand
    ValidateCmd  *MockValidateMemberUniqueness
    UserSession *MockUserSession
}

func setupEnrollMember(t *testing.T) (*EnrollMemberUseCase, *EnrollMemberTestMocks) {
    createCmd := &MockCreateMemberCommand{}
    validateCmd := &MockValidateMemberUniqueness{Result: true}
    userSession := &MockUserSession{UserID: "test-user-id"}
    useCase := NewEnrollMemberUseCase(createCmd, validateCmd, userSession)
    
    return useCase, &EnrollMemberTestMocks{
        CreateCmd:    createCmd,
        ValidateCmd:  validateCmd,
        UserSession: userSession,
    }
}
```

## Quality Gates

All tests pass, ≥80% coverage, no race conditions, static analysis passes

## Best Practices

**Test Design**: TDD (failing test first), test behavior not implementation, descriptive names (ATDD), simple tests
**CQRS Mocks**: One per interface, mock only external dependencies, simple manual mocks, verify interactions
**Organization**: Group tests by business concern/action (one concern per file), mirror production structure, use test data builders, ≤150 lines
**File Naming**: Domain-oriented (`quantity_validation_test.go`), NOT type-oriented (`error_cases_test.go`)
**Test Data Builders**: Use Builder pattern in `fixtures/builders.go` for fluent test data construction
**Setup Helpers**: Use dedicated setup files (`{use_case}_test_setup.go`) for test initialization
**Value Object Helpers**: Use dedicated helper files (`{use_case}_value_object_helpers.go`) for creating domain value objects
**CQRS Testing**: Commands (write ops), Queries (read ops), Validation (business rules), Integration (real infrastructure)
**YAGNI**: Test current functionality, delete unused tests, critical paths, simple setup

Ensures maintainable, reliable unit test coverage for Go applications following CQRS, Clean Architecture, YAGNI, and Screaming Architecture.
