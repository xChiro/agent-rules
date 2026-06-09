---
description: Create E2E integration tests for HTTP handlers using real infrastructure
---

# Create E2E Test Workflow

Use this workflow whenever creating E2E integration tests for HTTP handlers.

## Phase 1: Setup Test Environment

**Goal**: Create test infrastructure setup.

**Checklist**:
- Create `tests/end2end/{domain}/` directory structure.
- Create `setup.go` with real infrastructure test setup.
- Create `test_session.go` or equivalent auth/session helper when needed.
- Create `fixtures/builders.go` with test data builders.
- Create `fixtures/value_object_helpers.go` with value object helpers.
- Reuse existing integration test infrastructure setup when available.

**Template for setup.go**:
```go
package orders

import (
    "testing"
)

type TestEnvironment struct {
    Store   *TestStore
    Cleanup func() error
}

func SetupTestEnvironment(t *testing.T) *TestEnvironment {
    store := SetupRealTestStore(t)

    return &TestEnvironment{
        Store:   store,
        Cleanup: store.Cleanup,
    }
}

func GetTestUserID() string {
    return "test-user-e2e"
}

func CreateUseCase(env *TestEnvironment, session *TestUserSession) *UseCase {
    query := NewRealQueryAdapter(env.Store)
    return NewUseCase(query, session)
}
```

**Template for test_session.go**:
```go
package orders

import "context"

type TestUserSession struct {
    UserID string
    Roles  []string
}

func (s *TestUserSession) GetUserID(ctx context.Context) string {
    return s.UserID
}

func (s *TestUserSession) HasAnyRole(ctx context.Context, roles ...string) bool {
    for _, requiredRole := range roles {
        for _, userRole := range s.Roles {
            if userRole == requiredRole {
                return true
            }
        }
    }
    return false
}
```

## Phase 2: Create E2E Test File

**Goal**: Create test file with real infrastructure.

**Checklist**:
- Create `{use_case}_e2e_test.go` in `tests/end2end/{domain}/`.
- Import handler, use case, and real infrastructure dependencies.
- Use comment separators: `// Arrange`, `// Act`, `// Assert`.
- Test against real infrastructure, not mocks.

**Test scenarios**:
- Success path with persisted test data.
- Empty results or not-found behavior.
- Pagination or filtering when applicable.
- Request parsing validation.

**Template**:
```go
package orders_test

import (
    "context"
    "testing"

    "github.com/stretchr/testify/assert"
)

func Test_given_data_in_store_when_handler_called_then_returns_records(t *testing.T) {
    // Arrange
    env := orders.SetupTestEnvironment(t)
    defer env.Cleanup()

    userID := orders.GetTestUserID()
    session := &orders.TestUserSession{UserID: userID}
    seedTestData(t, env.Store, userID)

    useCase := orders.CreateUseCase(env, session)
    handler := NewHandler(useCase)

    req := NewTestHTTPRequest(map[string]string{
        "limit":  "20",
        "offset": "0",
    })

    // Act
    resp, err := handler.Handle(context.Background(), req)

    // Assert
    assert.NoError(t, err)
    assert.Equal(t, 200, resp.StatusCode)
    assert.Contains(t, resp.Body, "expectedField")
}

func seedTestData(t *testing.T, store *TestStore, userID string) {
    // Seed test data in real infrastructure.
}
```

## Phase 3: Run and Validate Tests

**Goal**: Verify tests pass with real infrastructure.

**Checklist**:
- Run tests: `go test -v -tags=integration ./tests/end2end/...`
- Verify required infrastructure is running locally or in containers.
- Ensure cleanup functions work correctly.
- Verify all test scenarios pass.

## Phase 4: CI/CD Integration

**Goal**: Ensure tests can run in CI.

**Checklist**:
- Configure CI services or containers for required infrastructure.
- Ensure tests run with the expected build tags.
- Verify cleanup after tests in CI.

## Quality Standards

**Mandatory Requirements**:
- **Real infrastructure only**: handler + use case + real adapter.
- **File limit**: <=150 lines per test file.
- **Function limit**: <=20 lines per test function.
- **Assertions**: `github.com/stretchr/testify/assert`.
- **Comment separators**: MUST use `// Arrange`, `// Act`, `// Assert`.
- **Cleanup**: Always cleanup test data with `defer env.Cleanup()`.

**Test naming**: `Test_given_[scenario]_when_[action]_then_[expected]` (snake_case)

**Location**: `tests/end2end/{domain}/` with setup.go and test_session.go when needed.
