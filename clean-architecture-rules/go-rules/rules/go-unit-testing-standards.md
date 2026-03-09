---
trigger: always_on
description: 
globs: 
---

# Go Unit Testing Standards

Unit testing guidelines following TDD principles with manual mocks and clean architecture.

## Core Principles

- **TDD-First**: Always write failing test before production code
- **Red-Green-Refactor**: Write test → Make it pass → Improve structure
- **Behavior over Implementation**: Test what code does, not how it does it
- **Isolation**: Each test independent, no shared state
- **Deterministic**: Same results every run

## Test Structure

### Naming Convention
- **Pattern**: `Test_given_[scenario]_when_[action]_then_[expected]`
- **Format**: snake_case for function names
- **Examples**:
  - `Test_given_empty_email_when_validating_then_return_error`
  - `Test_given_valid_order_when_processing_then_success`

### Test Structure Template
```go
func Test_given_scenario_when_action_then_expected(t *testing.T) {
    // Arrange: Setup test data, mocks, and SUT
    // Act: Execute single action on SUT
    // Assert: Verify behavior and outcomes
}
```

### File Organization
```
tests/
  units/
    domain/
      entity_test.go
      value_object_test.go
    application/
      usecase_test.go
      service_test.go
  mocks/
    mock_repository.go
    mock_service.go
```

## TDD Workflow

### Red-Green-Refactor Cycle
1. **Red**: Write failing test describing desired behavior, focus on edge cases first
2. **Green**: Write minimal code to make test pass, no extra functionality
3. **Refactor**: Clean up code without changing behavior, remove duplication

## Quality Standards

### Mandatory Requirements
- **File size limit**: ≤150 lines per test file
- **Assertion library**: MUST use `github.com/stretchr/testify/assert` library instead of `if` statements for all assertions - this is non-negotiable
- **Single assertion concept**: Each test verifies one behavioral aspect
- **No repeated assertions**: Don't assert same condition in multiple tests
- **Clear failure messages**: Descriptive error messages explaining expected vs actual

## Mocking Strategy

### Manual Mocks Preferred
- Create small structs implementing interfaces
- Use exported fields for behavior configuration and verification
- Avoid heavy mocking frameworks

### Mock Implementation Pattern
```go
// Mock interface
type UserRepository interface {
    Save(ctx context.Context, user *User) error
    FindByID(ctx context.Context, id string) (*User, error)
}

// Manual mock implementation
type UserRepositoryMock struct {
    // Configuration
    SaveError    error
    FindUser     *User
    FindError    error
    
    // Verification
    SavedUsers   []*User
    FindCalls    []string
}

func (m *UserRepositoryMock) Save(ctx context.Context, user *User) error {
    m.SavedUsers = append(m.SavedUsers, user)
    return m.SaveError
}

func (m *UserRepositoryMock) FindByID(ctx context.Context, id string) (*User, error) {
    m.FindCalls = append(m.FindCalls, id)
    return m.FindUser, m.FindError
}
```

### Mock Usage Guidelines
- **Mock only outgoing ports**: External systems, databases, APIs
- **Don't mock domain logic**: Use real implementations
- **Configure behavior via fields**: Simple and explicit
- **Locate mocks in test package**: Not in production code

## Assertion Helpers

### Standard Assertions
```go
// Error assertions
func assertError(t *testing.T, err error, message string) {
    t.Helper()
    if err == nil {
        t.Fatalf("%s: expected error but got nil", message)
    }
}

func assertNoError(t *testing.T, err error) {
    t.Helper()
    if err != nil {
        t.Fatalf("unexpected error: %v", err)
    }
}

func assertErrorContains(t *testing.T, err error, substring string) {
    t.Helper()
    if err == nil {
        t.Fatalf("expected error containing %q but got nil", substring)
    }
    if !strings.Contains(err.Error(), substring) {
        t.Fatalf("expected error containing %q, got %q", substring, err.Error())
    }
}

// Value assertions
func assertEqual[T comparable](t *testing.T, got, want T, message string) {
    t.Helper()
    if got != want {
        t.Fatalf("%s: got %v, want %v", message, got, want)
    }
}

func assertNotEqual[T comparable](t *testing.T, got, want T, message string) {
    t.Helper()
    if got == want {
        t.Fatalf("%s: got %v, want different value", message, got)
    }
}

// Collection assertions
func assertSliceEqual[T comparable](t *testing.T, got, want []T, message string) {
    t.Helper()
    if len(got) != len(want) {
        t.Fatalf("%s: length mismatch - got %d, want %d", message, len(got), len(want))
    }
    for i := range got {
        if got[i] != want[i] {
            t.Fatalf("%s: at index %d - got %v, want %v", message, i, got[i], want[i])
        }
    }
}
```

## Testing Patterns

### Domain Entity Testing
```go
func Test_given_negative_amount_when_creating_money_then_error(t *testing.T) {
    // Arrange
    amount := -100
    currency := "USD"
    
    // Act
    money, err := NewMoney(amount, currency)
    
    // Assert
    assertError(t, err, "negative amount should return error")
    assertEqual(t, money, Money{}, "should return zero value on error")
}

func Test_given_valid_amount_when_creating_money_then_success(t *testing.T) {
    // Arrange
    amount := 100
    currency := "USD"
    
    // Act
    money, err := NewMoney(amount, currency)
    
    // Assert
    assertNoError(t, err)
    assertEqual(t, money.Amount(), amount, "should set amount correctly")
    assertEqual(t, money.Currency(), currency, "should set currency correctly")
}
```

### Use Case Testing
```go
func Test_given_existing_user_when_registering_then_error(t *testing.T) {
    // Arrange
    repo := &UserRepositoryMock{}
    repo.FindUser = &User{ID: "existing-id"}
    
    sut := NewUserRegistration(repo)
    
    cmd := RegisterUserCommand{
        Email: "existing@example.com",
        Name:  "Test User",
    }
    
    // Act
    err := sut.Execute(context.Background(), cmd)
    
    // Assert
    assertErrorContains(t, err, "user already exists")
    assertEqual(t, len(repo.SavedUsers), 0, "should not save user")
}

func Test_given_new_user_when_registering_then_success(t *testing.T) {
    // Arrange
    repo := &UserRepositoryMock{}
    
    sut := NewUserRegistration(repo)
    
    cmd := RegisterUserCommand{
        Email: "new@example.com",
        Name:  "Test User",
    }
    
    // Act
    err := sut.Execute(context.Background(), cmd)
    
    // Assert
    assertNoError(t, err)
    assertEqual(t, len(repo.SavedUsers), 1, "should save exactly one user")
    assertEqual(t, repo.SavedUsers[0].Email, cmd.Email, "should save correct email")
}
```

## Test Data Management

### Test Data Builders
```go
// Stable test data
func NewTestUser() *User {
    return &User{
        ID:    "test-user-123",
        Email: "test@example.com",
        Name:  "Test User",
    }
}

// Builder pattern for complex objects
type UserBuilder struct {
    user *User
}

func NewUserBuilder() *UserBuilder {
    return &UserBuilder{
        user: &User{
            ID:    "default-id",
            Email: "default@example.com",
        },
    }
}

func (b *UserBuilder) WithID(id string) *UserBuilder {
    b.user.ID = id
    return b
}

func (b *UserBuilder) WithEmail(email string) *UserBuilder {
    b.user.Email = email
    return b
}

func (b *UserBuilder) Build() *User {
    return b.user
}
```

## Performance Testing

### Benchmark Tests
```go
func BenchmarkOrderProcessing(b *testing.B) {
    processor := setupProcessor()
    order := fixtures.NewTestOrder()
    
    b.ResetTimer()
    for i := 0; i < b.N; i++ {
        _, err := processor.Process(context.Background(), order)
        if err != nil {
            b.Fatal(err)
        }
    }
}
```

### Test Duration Guidelines
- **Unit tests**: <1ms each
- Use timeouts for long-running operations

## Continuous Integration

### Test Execution Strategy
```bash
# Run unit tests only
go test ./tests/units/...

# Run all tests with coverage
go test -race -coverprofile=coverage.out ./...

# Generate coverage report
go tool cover -html=coverage.out -o coverage.html
```

### Quality Gates
- All tests must pass
- Coverage threshold: ≥80%
- No race conditions detected
- All static analysis passes

## Best Practices Summary

### Test Design
- Write failing test first
- Test behavior, not implementation
- Use descriptive test names
- Keep tests simple and focused

### Mock Usage
- Prefer manual mocks
- Mock only external dependencies
- Keep mocks simple
- Verify interactions, not implementation

### Test Organization
- Group related tests
- Use helper functions
- Maintain test data builders
- Keep test files under 150 lines

These standards ensure comprehensive, maintainable, and reliable unit test coverage for Go applications following Clean Architecture principles.
