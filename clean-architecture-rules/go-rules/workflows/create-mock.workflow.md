---
description: Create manual mock for interface following DI and testing principles
---

# Manual Mock Creation Workflow

Create deterministic manual mocks for interfaces to support unit testing without external dependencies.

## Phase 1: Interface Analysis
- Identify **Target Interface**: Fully qualified name and package
- Determine **Methods**: All interface methods and their signatures
- Define **Mock Requirements**: Input capture, output configuration, call tracking
- Confirm **File Size**: ≤150 lines limit

## Phase 2: Mock Struct Definition
Create mock struct with configuration and verification fields:

```go
type [Interface]Mock struct {
    // Configuration fields
    [Method]Result [ReturnType]
    [Method]Error  error
    
    // Verification fields
    [Method]Calls    [] [MethodCallParams]
    [Method]CallCount int
    
    // Optional: Call-specific configuration
    [Method]Results [][]interface{}
    CallIndex       int
}
```

## Phase 3: Interface Implementation
Implement all interface methods with input capture and configurable output:

```go
func (m *[Interface]Mock) [MethodName](param1 [Type1], param2 [Type2]) ([ReturnType], error) {
    // Record call for verification
    m.[MethodName]Calls = append(m.[MethodName]Calls, [MethodCallParams]{
        Param1: param1,
        Param2: param2,
    })
    m.[MethodName]CallCount++
    
    // Return configured result
    if m.[MethodName]Error != nil {
        return [ZeroValue], m.[MethodName]Error
    }
    
    // Support multiple results
    if len(m.[MethodName]Results) > 0 {
        result := m.[MethodName]Results[m.CallIndex%len(m.[MethodName]Results)]
        m.CallIndex++
        return result[0].([ReturnType]), result[1].(error)
    }
    
    return m.[MethodName]Result, nil
}
```

## Phase 4: Configuration Helpers
Add methods to configure mock behavior:

```go
func (m *[Interface]Mock) Set[MethodName]Result(result [ReturnType]) {
    m.[MethodName]Result = result
    m.[MethodName]Error = nil
}

func (m *[Interface]Mock) Set[MethodName]Error(err error) {
    m.[MethodName]Error = err
}

func (m *[Interface]Mock) Set[MethodName]Sequence(results ...interface{}) {
    m.[MethodName]Results = splitIntoPairs(results)
    m.CallIndex = 0
}

func (m *[Interface]Mock) Reset() {
    m.[MethodName]Calls = nil
    m.[MethodName]CallCount = 0
    m.CallIndex = 0
}
```

## Phase 5: Verification Helpers
Add methods to verify interactions:

```go
func (m *[Interface]Mock) Verify[MethodName]Called(t *testing.T, expectedCount int) {
    assertEqual(t, m.[MethodName]CallCount, expectedCount, 
        "expected %d calls to [MethodName], got %d", expectedCount, m.[MethodName]CallCount)
}

func (m *[Interface]Mock) Verify[MethodName]CalledWith(t *testing.T, expectedParams [MethodCallParams]) {
    assertEqual(t, len(m.[MethodName]Calls), 1, "expected exactly one call")
    if len(m.[MethodName]Calls) > 0 {
        assertEqual(t, m.[MethodName]Calls[0], expectedParams, "call parameters mismatch")
    }
}
```

## File Location
```
tests/[module]/mocks/
├── [interface]_mock.go
└── mock_helpers.go
```

## Complete Example

### Repository Interface
```go
// internal/application/ports/user_repository.go
type UserRepository interface {
    Save(ctx context.Context, user User) error
    FindByID(ctx context.Context, id string) (*User, error)
    FindByEmail(ctx context.Context, email string) (*User, error)
}
```

### Mock Implementation
```go
// tests/application/mocks/user_repository_mock.go
package mocks

import "context"

type UserRepositoryMock struct {
    // Configuration
    SaveResult       error
    FindByIDResult   *User
    FindByIDError    error
    FindByEmailResult *User
    FindByEmailError  error
    
    // Verification
    SaveCalls       []SaveCall
    FindByIDCalls   []FindByIDCall
    FindByEmailCalls []FindByEmailCall
    
    SaveCallCount       int
    FindByIDCallCount   int
    FindByEmailCallCount int
}

type SaveCall struct {
    Ctx  context.Context
    User User
}

type FindByIDCall struct {
    Ctx context.Context
    ID  string
}

type FindByEmailCall struct {
    Ctx   context.Context
    Email string
}

func (m *UserRepositoryMock) Save(ctx context.Context, user User) error {
    m.SaveCalls = append(m.SaveCalls, SaveCall{Ctx: ctx, User: user})
    m.SaveCallCount++
    return m.SaveResult
}

func (m *UserRepositoryMock) FindByID(ctx context.Context, id string) (*User, error) {
    m.FindByIDCalls = append(m.FindByIDCalls, FindByIDCall{Ctx: ctx, ID: id})
    m.FindByIDCallCount++
    if m.FindByIDError != nil {
        return nil, m.FindByIDError
    }
    return m.FindByIDResult, nil
}

func (m *UserRepositoryMock) FindByEmail(ctx context.Context, email string) (*User, error) {
    m.FindByEmailCalls = append(m.FindByEmailCalls, FindByEmailCall{Ctx: ctx, Email: email})
    m.FindByEmailCallCount++
    if m.FindByEmailError != nil {
        return nil, m.FindByEmailError
    }
    return m.FindByEmailResult, nil
}

// Configuration methods
func (m *UserRepositoryMock) SetSaveError(err error) {
    m.SaveResult = err
}

func (m *UserRepositoryMock) SetFindByIDResult(user *User) {
    m.FindByIDResult = user
    m.FindByIDError = nil
}

func (m *UserRepositoryMock) SetFindByIDError(err error) {
    m.FindByIDError = err
}

// Verification methods
func (m *UserRepositoryMock) VerifySaveCalled(t *testing.T, expectedCount int) {
    assertEqual(t, m.SaveCallCount, expectedCount, 
        "expected %d calls to Save, got %d", expectedCount, m.SaveCallCount)
}

func (m *UserRepositoryMock) VerifySaveCalledWith(t *testing.T, expectedUser User) {
    assertEqual(t, len(m.SaveCalls), 1, "expected exactly one Save call")
    if len(m.SaveCalls) > 0 {
        assertEqual(t, m.SaveCalls[0].User, expectedUser, "Save call user mismatch")
    }
}

func (m *UserRepositoryMock) Reset() {
    m.SaveCalls = nil
    m.FindByIDCalls = nil
    m.FindByEmailCalls = nil
    m.SaveCallCount = 0
    m.FindByIDCallCount = 0
    m.FindByEmailCallCount = 0
}
```

## Usage in Tests

```go
func Test_given_valid_user_when_saving_then_success(t *testing.T) {
    // Arrange: Configure mock
    userRepo := &mocks.UserRepositoryMock{}
    userRepo.SetSaveError(nil) // Configure success
    
    sut := NewUserService(userRepo)
    user := fixtures.NewTestUser()
    
    // Act: Execute test
    err := sut.Save(context.Background(), user)
    
    // Assert: Verify behavior and interactions
    assertNoError(t, err, "user save failed")
    userRepo.VerifySaveCalled(t, 1)
    userRepo.VerifySaveCalledWith(t, user)
}
```

## Key Principles

### Manual Mock Benefits
- No external dependencies or reflection
- Explicit configuration and verification
- Simple, predictable behavior
- Easy to debug and maintain

### Mock Design Rules
- Implement all interface methods
- Capture all input parameters
- Support configurable outputs
- Provide clear verification methods

### Testing Integration
- Use mocks only for outgoing ports
- Keep mocks in test packages
- Configure behavior before each test
- Verify interactions after execution

## Success Criteria
- All interface methods implemented
- Input capture and output configuration working
- Verification helpers provide clear failure messages
- File size ≤150 lines
- No external dependencies

Manual mocks provide deterministic, lightweight test doubles that enable fast, reliable unit testing.
