---
rule_id: RULE-GO_BUSINESS_LOGIC_UNIT_TESTS
trigger: model_decision
description: Go business logic unit test rules for domain and application behavior
globs: **/*_test.go
---

# Go Business Logic Unit Tests

## SDD Baseline

- Apply `common/rules/common-sdd-agentic-discipline.md` before this rule.
- Create or evolve the owning User Story based spec before production code when behavior, contracts, architecture, or risk changes.
- Apply mandatory Gate 1 before spec writes, Gate 2 before RED, and Gate 3 before Green, even for simple or low-risk changes.
- Keep artifact, task, track, and test IDs traceable through `traceability.yaml` and `parallel-tracks.md`.
- Write BDD Given/When/Then acceptance evidence first, then the unit-level ATDD-style focused failing test for the next rule or boundary before production code.
- Refactor only with tests green and converge spec history, tasks, parallel tracks, traceability, verification notes, and code.
- Apply `common-test-assertion-structure.md`: all `assert`/`require` calls belong only in `// Then / Assert`.


**Principles**: ATDD acceptance behavior-first, TDD Red-Green-Refactor, behavior over implementation, isolation, deterministic, YAGNI testing

See `go-test-suites.md` for test suite tags. Unit tests should run by default without requiring a Go build tag.

## acceptance behavior Coverage Objective

Use ATDD plus TDD to drive implementation from acceptance behavior into focused domain/application unit tests. Start from the behavior the actor needs, express it as executable tests, then implement the smallest domain/application code that satisfies those tests.

Coverage target:

- Maintain 90%+ aggregate project-wide production coverage, with domain/application unit coverage also at least 90%.
- Prioritize behavior and branch coverage for entities, value objects, domain services, use cases, and application ports.
- Do not inflate coverage with shallow tests for generated code, DTO-only files, wiring, or framework glue.
- Use HTTP integration tests for adapter and public-boundary wiring, but do not count them as a substitute for domain/application unit coverage.
- When project-wide coverage drops below 90% or touched domain/application coverage regresses, add meaningful tests before finishing.

## Test Structure

**Naming**: `Test_given_[scenario]_when_[action]_then_[expected]` (snake_case)
**Template**: Arrange → Act → Then / Assert
**Organization**: Group test files by domain concern/action, not by test type
**MANDATORY**: Use comment separators `// Arrange`, `// Act`, `// Then / Assert`; no assertion API may appear before the final section.

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
tests/orders/application/order_transfer/
  order_transfer_test_setup.go    # Setup helpers
  order_transfer_value_object_helpers.go # Value object helpers
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

**Coverage Theater**: Do not create trivial tests only to raise coverage. Avoid tests that only instantiate structs, call getters, verify constants, cover generated code, or assert framework wiring without behavior.

**Fragile Tests**: Avoid tests coupled to private methods, internal call order, exact timestamps, map iteration order, goroutine scheduling, log text, full error strings, or unrelated implementation details.

**Repeated Assertions**: Do not copy the same assertion set across many tests. Extract a named assertion helper only when the repeated checks represent one stable behavior contract.

**Over-Assertion**: Assert the behavior that matters for the scenario. Do not assert every field of a large response when only one business outcome is relevant.

**Overspecified Mocks**: Do not verify every collaborator call by default. Verify interactions only when the interaction is the observable behavior, such as a command executed, event published, or external port called.

**Domain Entity Testing**: Domain entities and value objects may be tested directly when they own pure invariants, state transitions, or validation rules. Prefer use case tests for workflow orchestration and cross-dependency behavior.

**HTTP Handler Unit Tests**: Do not create mock-heavy handler unit tests when the handler's value is request parsing, status codes, auth/session extraction, and response mapping. Prefer HTTP integration tests with real wiring and local resources for HTTP contracts.

**Loop-Based Testing**: Avoid loops when each scenario has distinct business meaning. Write individual test functions for important business cases.
- Exceptions: table-driven validation matrices, parser/formatter cases, character validation, permissions matrices, and performance benchmarks

## Business Logic Testing Workflow

1. **ATDD frame**: State the actor-visible behavior and acceptance outcome.
2. **Red**: Write the smallest failing test for the next business rule
3. **Green**: Add only the code needed to satisfy that behavior
4. **Refactor**: Clean up

## Quality Rules

**Requirements**: ≤150 lines/file, ≤20 lines/function, 90%+ project-wide production coverage and domain/application unit coverage, use `testify/assert`, single assertion concept
**YAGNI**: Test current functionality only, delete unused tests, focus on critical paths, simple setup

## Test Tags

- Unit tests are the default fast suite and should not require `//go:build unit`.
- Identify unit tests by path, naming, and isolation from infrastructure.
- If a repository intentionally uses build tags for every suite, use `//go:build unit` consistently and document `go test -tags=unit ./...`.
- Do not put HTTP integration tests in the default unit suite.

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

All tests pass, 90%+ project-wide production coverage and domain/application unit coverage, no race conditions, static analysis passes

## Best Practices

**Test Design**: acceptance behavior framing, expected behavior captured in tests, test behavior not implementation, descriptive names, simple tests
**Suite Quality**: Avoid fragile tests, repeated assertions, trivial coverage-only tests, overspecified mocks, and implementation-detail assertions
**CQRS Mocks**: One per interface, mock only external dependencies, simple manual mocks, verify interactions
**Organization**: Group tests by business concern/action (one concern per file), mirror production structure, use test data builders, ≤150 lines
**File Naming**: Domain-oriented (`quantity_validation_test.go`), NOT type-oriented (`error_cases_test.go`)
**Test Data Builders**: Use Builder pattern in `fixtures/builders.go` for fluent test data construction
**Setup Helpers**: Use dedicated setup files (`{use_case}_test_setup.go`) for test initialization
**Value Object Helpers**: Use dedicated helper files (`{use_case}_value_object_helpers.go`) for creating domain value objects
**CQRS Testing**: Commands (write ops), Queries (read ops), Validation (business rules), Integration (real infrastructure)
**YAGNI**: Test current functionality, delete unused tests, critical paths, simple setup

Ensures maintainable, reliable unit test coverage for Go applications following CQRS, Clean Architecture, YAGNI, and Screaming Architecture.
