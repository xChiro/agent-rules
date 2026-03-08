---
description: Create failing TDD test following ATDD principles
---

# TDD Test Creation Workflow

Create failing tests that drive development using TDD and ATDD principles with manual assertions.

## Phase 1: Test Analysis
- Identify **Actor**: Who initiates the action
- Define **Responsibility**: What outcome is expected
- Specify **Edge Case**: Smallest failing scenario first
- Confirm **File Size**: ≤150 lines limit

## Phase 2: Test Structure
Create test following `given_when_then` pattern:

```go
func Test_given_[condition]_when_[action]_then_[expected](t *testing.T) {
    // Arrange: Setup test data, mocks, and SUT
    // Act: Execute single action on SUT
    // Assert: Verify expected behavior
}
```

## Phase 3: Arrange Section
Setup test data and manual mocks:

```go
// Arrange: Create manual mocks for outgoing dependencies
mockRepo := &mocks.UserRepositoryMock{}
mockRepo.SetFindByIDError(errors.New("user not found"))

// Arrange: Configure mock behavior
mockPublisher := &mocks.MessagePublisherMock{}
mockPublisher.SetPublishError(nil)

// Arrange: Create System Under Test
sut := NewUserService(mockRepo, mockPublisher)

// Arrange: Prepare input data (edge case)
userID := "" // Invalid ID for edge case test
```

## Phase 4: Act Section
Execute exactly one method call:

```go
// Act: Execute single action
result, err := sut.GetUser(context.Background(), userID)
```

## Phase 5: Assert Section
Verify expected failure:

```go
// Assert: Verify expected error
assertError(t, err, "should return error for invalid user ID")
assertErrorContains(t, err, "user not found")
assertEqual(t, result, User{}, "should return zero value on error")
```

## Phase 6: Follow-up Tests
Create happy path test after edge case:

```go
func Test_given_valid_user_id_when_getting_user_then_success(t *testing.T) {
    // Arrange: Setup valid scenario
    mockRepo := &mocks.UserRepositoryMock{}
    expectedUser := fixtures.NewTestUser()
    mockRepo.SetFindByIDResult(&expectedUser)
    
    sut := NewUserService(mockRepo, nil)
    
    // Act
    result, err := sut.GetUser(context.Background(), expectedUser.ID)
    
    // Assert
    assertNoError(t, err, "should not return error for valid user")
    assertEqual(t, result.ID, expectedUser.ID, "should return correct user")
    mockRepo.VerifyFindByIDCalled(t, 1)
}
```

## File Organization
```
tests/[module]/
├── [component]_test.go
└── mocks/
    ├── [dependency]_mock.go
    └── mock_helpers.go
```

## Complete Example

### User Service Test
```go
func Test_given_empty_user_id_when_getting_user_then_error(t *testing.T) {
    // Arrange: Setup mocks for edge case
    userRepo := &mocks.UserRepositoryMock{}
    userRepo.SetFindByIDError(errors.New("user not found"))
    
    sut := NewUserService(userRepo, nil)
    
    // Act: Execute with invalid input
    result, err := sut.GetUser(context.Background(), "")
    
    // Assert: Verify failure behavior
    assertError(t, err, "should return error for empty user ID")
    assertErrorContains(t, err, "user not found")
    assertEqual(t, result, User{}, "should return zero value on error")
}

func Test_given_valid_user_id_when_getting_user_then_success(t *testing.T) {
    // Arrange: Setup happy path
    userRepo := &mocks.UserRepositoryMock{}
    expectedUser := fixtures.NewTestUser()
    userRepo.SetFindByIDResult(&expectedUser)
    
    sut := NewUserService(userRepo, nil)
    
    // Act: Execute with valid input
    result, err := sut.GetUser(context.Background(), expectedUser.ID)
    
    // Assert: Verify success behavior
    assertNoError(t, err, "should not return error for valid user")
    assertEqual(t, result.ID, expectedUser.ID, "should return correct user")
    assertEqual(t, result.Name, expectedUser.Name, "should return correct name")
    userRepo.VerifyFindByIDCalled(t, 1)
    userRepo.VerifyFindByIDCalledWith(t, expectedUser.ID)
}
```

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
```

## Test Data Builders

### Fixtures Pattern
```go
// tests/[module]/fixtures/user.go
package fixtures

type User struct {
    ID   string
    Name string
    Email string
}

func NewTestUser() *User {
    return &User{
        ID:    "test-user-" + uuid.New().String(),
        Name:  "Test User",
        Email: "test@example.com",
    }
}
```

## TDD Principles

### Red-Green-Refactor Cycle
1. **Red**: Write failing test for smallest behavior
2. **Green**: Implement minimal code to pass test
3. **Refactor**: Improve structure without changing behavior

### Test Quality Rules
- **Edge cases first**: Test invalid inputs before happy paths
- **Single assertion concept**: Each test verifies one behavioral aspect
- **Deterministic**: No external dependencies or random data
- **Clear failure messages**: Descriptive error explanations

### Mock Usage Guidelines
- **Mock only outgoing ports**: External systems, databases, APIs
- **Manual mocks preferred**: Simple structs implementing interfaces
- **Configure via fields**: Set return values and errors explicitly
- **Verify interactions**: Check method calls and parameters

## Common Test Patterns

### Validation Tests
```go
func Test_given_invalid_[field]_when_creating_then_error(t *testing.T) {
    // Test validation rules
}
```

### Success Tests
```go
func Test_given_valid_input_when_creating_then_success(t *testing.T) {
    // Test happy path
}
```

### Interaction Tests
```go
func Test_given_dependency_when_calling_then_interaction_verified(t *testing.T) {
    // Test mock interactions
}
```

## Success Criteria
- Test fails initially (Red phase)
- Clear test intent and naming
- Proper mock configuration
- Manual assertions (no testify)
- File size ≤150 lines
- Functions ≤20 lines

TDD tests drive development by defining behavior before implementation, ensuring code meets requirements from the start.
