---
description: Create E2E integration tests for HTTP handlers using REAL infrastructure (DynamoDB with Docker)
---

# Create E2E Test Workflow

Use this workflow whenever creating E2E integration tests for HTTP handlers in `hbk-inventory-service`.

## Phase 1: Setup Test Environment

**Goal**: Create test infrastructure setup.

**Checklist**:
- Create `tests/end2end/{domain}/` directory structure
- Create `setup.go` with DynamoDB test environment setup
- Create `test_session.go` with mock user session
- Import existing infrastructure setup from `tests/integration/inventory/infrastructure/persistence`

**Template for setup.go**:
```go
package personal

import (
    queries2 "hbk-inventory-service/internal/inventory/infrastructure/persistence/queries"
    "testing"
    
    appretriever "hbk-inventory-service/internal/inventory/application/{domain}/use_case"
    "hbk-inventory-service/internal/inventory/infrastructure/persistence"
    testpersistence "hbk-inventory-service/tests/integration/inventory/infrastructure/persistence"
)

type TestEnvironment struct {
    Client    *testpersistence.DynamoDBTestEnvironment
    Cfg       *persistence.Config
    TableName string
    Cleanup   func() error
}

func SetupTestEnvironment(t *testing.T) *TestEnvironment {
    env := testpersistence.SetupDynamoDBTestEnvironment()
    cfg := &persistence.Config{TableName: env.TableName}
    
    return &TestEnvironment{
        Client:    env,
        Cfg:       cfg,
        TableName: env.TableName,
        Cleanup:   env.Cleanup,
    }
}

func GetTestUserID() string {
    return "test-user-e2e"
}

func CreateUseCase(env *TestEnvironment, session *TestUserSession) appretriever.UseCaseInterface {
    query := queries2.NewDynamoDBQuery(env.Client.Client, env.Cfg)
    return appretriever.NewUseCase(query, session)
}
```

**Template for test_session.go**:
```go
package personal

import (
    "context"
)

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

**Goal**: Create test file with REAL infrastructure.

**Checklist**:
- Create `{use_case}_e2e_test.go` in `tests/end2end/{domain}/`
- Import handler, use case, and DynamoDB dependencies
- Use comment separators: `// Arrange`, `// Act`, `// Assert`
- Test against REAL DynamoDB (NO mocks)

**Test scenarios**:
- Success path with data in DynamoDB
- Empty results
- Pagination (limit/offset)
- Request parsing validation

**Template**:
```go
package personal_test

import (
    "context"
    "hbk-inventory-service/tests/end2end/inventory/application/personal"
    "testing"
    
    "github.com/aws/aws-sdk-go-v2/feature/dynamodb/attributevalue"
    "github.com/aws/aws-sdk-go-v2/service/dynamodb"
    "github.com/stretchr/testify/assert"
    
    "hbk-inventory-service/internal/inventory/interfaces/lambda/handlers/{handler}"
    "github.com/aws/aws-lambda-go/events"
)

func Test_given_data_in_dynamodb_when_handler_called_then_returns_records(t *testing.T) {
    // Arrange: Setup REAL infrastructure
    env := personal.SetupTestEnvironment(t)
    defer env.Cleanup()
    
    userID := personal.GetTestUserID()
    session := &personal.TestUserSession{UserID: userID}
    seedTestDataInDynamoDB(t, env.Client.Client, env.TableName, userID)
    
    // Create real use case with REAL DynamoDB
    useCase := personal.CreateUseCase(env, session)
    handler := handler.NewHandler(useCase)
    
    req := events.APIGatewayV2HTTPRequest{
        QueryStringParameters: map[string]string{
            "limit":  "20",
            "offset": "0",
        },
    }
    
    // Act: Execute handler with REAL infrastructure
    resp, err := handler.Handle(context.Background(), req)
    
    // Assert: Verify response from REAL infrastructure
    assert.NoError(t, err)
    assert.Equal(t, 200, resp.StatusCode)
    assert.Contains(t, resp.Body, "expectedField")
}

func seedTestDataInDynamoDB(t *testing.T, client *dynamodb.Client, tableName string, userID string) {
    // Seed test data in REAL DynamoDB
}
```

## Phase 3: Run and Validate Tests

**Goal**: Verify tests pass with REAL infrastructure.

**Checklist**:
- Run tests: `go test -v -tags=integration ./tests/end2end/...`
- Verify DynamoDB is running (Docker or local)
- Ensure cleanup functions work correctly
- Verify all test scenarios pass

**Docker setup** (if not already running):
```bash
docker run -d -p 8000:8000 --name dynamodb amazon/dynamodb-local:latest
```

## Phase 4: CI/CD Integration

**Goal**: Ensure tests run in GitHub Actions.

**Checklist**:
- Verify `.github/workflows/deploy-prod.yml` has DynamoDB setup
- Ensure tests run with `-tags=integration`
- Verify cleanup after tests in CI

**Note**: GitHub Actions already has DynamoDB Docker setup in lines 33-78 of `deploy-prod.yml`.

## Quality Standards

**Mandatory Requirements**:
- **REAL infrastructure ONLY**: Handler + Use Case + DynamoDB (NO mocks)
- **File limit**: ≤150 lines per test file
- **Function limit**: ≤20 lines per test function
- **Assertions**: `github.com/stretchr/testify/assert`
- **Comment separators**: MUST use `// Arrange`, `// Act`, `// Assert`
- **Cleanup**: Always cleanup test data with `defer env.Cleanup()`

**Test naming**: `Test_given_[scenario]_when_[action]_then_[expected]` (snake_case)

**Location**: `tests/end2end/{domain}/` with setup.go and test_session.go
