---
rule_id: RULE-GO_BUSINESS_LOGIC_UNIT_TESTS
trigger: model_decision
description: "Go business logic unit test rules for domain and application behavior"
globs: "**/*_test.go"
---

# Go Business Logic Unit Tests

## SDD Integration

Apply `RULE-COMMON_SDD_AGENTIC_DISCIPLINE`, `RULE-COMMON_TEST_ASSERTION_STRUCTURE`, `RULE-COMMON_TEST_DATA_AND_DOUBLE_PATTERNS`, and `RULE-COMMON_TEST_LAYER_ISOLATION`. This rule adds Go unit-test mechanics only; the common lifecycle owns BDD, Domain/Application gates, traceability, and convergence.


**Principles**: ATDD acceptance behavior-first, TDD Red-Green-Refactor, behavior over implementation, isolation, deterministic, YAGNI testing

See `go-test-suites.md` for test suite tags. Unit tests should run by default without requiring a Go build tag.

## Layer Independence (MANDATORY)

- Document and run separate focused commands for affected Domain and Application packages; each command must pass alone with `-count=1`.
- Application tests may use Domain production types, but they must not import Domain test packages, execute Domain tests as setup, or consume their fixtures/output/state.
- Domain tests cannot import Application or any outer-layer production/test package.
- Instantiate builders, manual doubles, clocks, RNGs, IDs, and call captures per test. Shared helpers must be stateless and live in a neutral test-support package.
- A full `go test ./...` result is required regression evidence but never replaces the standalone layer results.
- Use `-shuffle=on`, repeated counts, and `t.Parallel()` only as risk-selected evidence; the layers remain independent even when run sequentially.

## acceptance behavior Coverage Objective

Use BDD plus TDD to drive implementation from actor-visible behavior into focused domain/application unit tests. Specify acceptance first, implement domain and application from unit RED/GREEN cycles, then prove the complete behavior at the executable boundary.

Coverage target:

- Maintain 90%+ aggregate project-wide production coverage, with domain/application unit coverage also at least 90%.
- Prioritize behavior and branch coverage for entities, value objects, domain services, use cases, and application ports.
- Do not inflate coverage with shallow tests for generated code, DTO-only files, wiring, or framework glue.
- Use HTTP integration tests for adapter and public-boundary wiring, but do not count them as a substitute for domain/application unit coverage.
- When project-wide coverage drops below 90% or touched domain/application coverage regresses, add meaningful tests before finishing.

## Test Structure

**Naming**: `Test_given_[scenario]_when_[action]_then_[expected]` (snake_case)
**Template**: `// Arrange` → `// Act` → `// Assert` (Given → When → Then)
**Organization**: Group test files by domain concern/action, not by test type
**MANDATORY**: Use comment separators `// Arrange`, `// Act`, `// Assert`; `// Act` must contain exactly one executable statement on one physical line that invokes the SUT/use case, and no assertion API may appear before `// Assert`.

## Approved Go Test Toolchain (MANDATORY)

- Use Go's `testing` package for the unit-test runner, `github.com/stretchr/testify/assert`/`require` for assertions, and hand-written doubles for outgoing ports. Importing a production API under test remains allowed.
- Do not use `require.NoError(t, err)`. Prefer `if err != nil { t.Fatalf("context: %v", err) }` when later assertions require a valid result; use `assert.NoError` only when the test can continue safely after the error.
- Do not add GoMock, Mockery, generated mocks, or third-party mocking frameworks. `testify/assert` and `testify/require` are the approved assertion libraries.
- In `// Assert`, compare expected and actual values explicitly and call `t.Error`, `t.Errorf`, `t.Fatal`, or `t.Fatalf` on mismatch.
- Domain tests use real entities/value objects and normally no doubles.
- Application tests use small hand-written stubs, fakes, spies, or mocks only for outgoing application-owned ports.
- Object Mothers and builders return fresh deterministic values; they do not assert, call production behavior, or share mutable state.

## Domain-Oriented Test File Organization (MANDATORY)

Test files MUST be organized by **business concern/action** being validated, NOT by test type (happy_path, error_cases, edge_cases).

**Structure**:
```
tests/unit/{domain}/application/{use_case}/
  {use_case}_test_setup.go         # Shared setup helpers and explicit doubles
  {use_case}_value_object_helpers.go # Helper functions for creating value objects
  {action_or_concern}_test.go        # Tests for one specific behavior
  {validation_concern}_test.go       # Tests for one validation rule
  fixtures/builders.go               # Test data builders (Builder pattern)
  doubles/{stub|fake|spy}_{port}.go
```

**Example** (transfer use case):
```
tests/unit/orders/application/order_transfer/
  order_transfer_test_setup.go    # Setup helpers
  order_transfer_value_object_helpers.go # Value object helpers
  item_existence_test.go                          # Item not found behavior
  quantity_validation_test.go                     # Insufficient quantity behavior
  transfer_success_test.go                        # Successful transfer behavior
  transfer_persistence_failure_test.go            # Persistence failure behavior
  fixtures/builders.go                            # Test data builders
  doubles/{stub|fake|spy}_{port}.go
```

**Rules**:
- File name describes WHAT business behavior is tested, not WHEN it fails
- ❌ AVOID: `happy_path_test.go`, `error_cases_test.go`, `edge_cases_test.go`
- ✅ PREFER: `quantity_validation_test.go`, `item_existence_test.go`, `transfer_success_test.go`
- One concern per file (single business rule, validation, or workflow path)
- File <150 physical lines
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

**Requirements**: <150 physical lines/file, ≤20 lines/function, 90%+ project-wide production coverage and domain/application unit coverage, standard `testing` runner, approved assertions, hand-written doubles, and one assertion concept

**Isolation**: Domain and Application focused commands each pass from a clean process with `depends_on_test_layer: none`; no mutable fixture, global, environment value, cache, or output crosses the layer boundary.
**YAGNI**: Test current functionality only, delete unused tests, focus on critical paths, simple setup

## Test Tags

- Unit tests are the default fast suite and should not require `//go:build unit`.
- Identify unit tests by path, naming, and isolation from infrastructure.
- If a repository intentionally uses build tags for every suite, use `//go:build unit` consistently and document `go test -tags=unit ./...`.
- Do not put HTTP integration tests in the default unit suite.

## CQRS Test Double Strategy

**Guidelines**: One hand-written double per outgoing port when useful; name it by its role (`Stub`, `Fake`, or `Spy`) and expose only scenario configuration or observable calls.
**Structure**: `tests/unit/{domain}/application/{use_case}/doubles/{role}_{port}.go`

```go
type CreateMemberCommandSpy struct {
    Error error
    Calls []CreateMemberCall
}

func (m *CreateMemberCommandSpy) Execute(ctx context.Context, member domain.Member) error {
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
    useCase, doubles := setupEnrollMember()
    doubles.UserSession.UserID = testUserID

    request := fixtures.NewEnrollMemberRequestBuilder().
        WithHandlerName("test-handler").
        WithExternalID("test-id").
        Build()

    // Act
    response, err := useCase.Execute(context.Background(), request)

    // Assert
    if err != nil {
        t.Fatalf("Execute() error = %v, want nil", err)
    }
    if response.MemberID == "" {
        t.Error("Execute() MemberID is empty, want a generated ID")
    }
    if got := len(doubles.CreateCmd.Calls); got != 1 {
        t.Errorf("CreateCmd calls = %d, want 1", got)
    }
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
type EnrollMemberTestDoubles struct {
    CreateCmd   *CreateMemberCommandSpy
    ValidateCmd *ValidateMemberUniquenessStub
    UserSession *UserSessionStub
}

func setupEnrollMember() (*MemberEnroller, *EnrollMemberTestDoubles) {
    createCmd := &CreateMemberCommandSpy{}
    validateCmd := &ValidateMemberUniquenessStub{Result: true}
    userSession := &UserSessionStub{UserID: "test-user-id"}
    useCase := NewMemberEnroller(createCmd, validateCmd, userSession)

    return useCase, &EnrollMemberTestDoubles{
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
**CQRS Test Doubles**: One per outgoing interface, hand-written only, verify interactions only when observable
**Organization**: Group tests by business concern/action (one concern per file), mirror production structure, use test data builders, <150 physical lines
**File Naming**: Domain-oriented (`quantity_validation_test.go`), NOT type-oriented (`error_cases_test.go`)
**Test Data Builders**: Use Builder pattern in `fixtures/builders.go` for fluent test data construction
**Setup Helpers**: Use dedicated setup files (`{use_case}_test_setup.go`) for test initialization
**Value Object Helpers**: Use dedicated helper files (`{use_case}_value_object_helpers.go`) for creating domain value objects
**CQRS Testing**: Commands (write ops), Queries (read ops), Validation (business rules), Integration (real infrastructure)
**YAGNI**: Test current functionality, delete unused tests, critical paths, simple setup

Ensures maintainable, reliable unit test coverage for Go applications following CQRS, Clean Architecture, YAGNI, and Screaming Architecture.
