---
description: Create integration test following Clean Architecture and testing principles
---

# Integration Test Creation Workflow

Create integration tests that verify real infrastructure behavior while maintaining clean code standards.

## Phase 1: Requirements Analysis
- Identify **Infrastructure Components**: Database, message queue, external APIs
- Define **Happy Path Scenario**: Primary success workflow
- List **Critical Edge Cases**: Infrastructure-specific failures
- Confirm **File Size**: ≤150 lines limit

## Phase 2: Test Environment Setup
Create reusable test environment:

```go
// tests/integration/[module]/setup/test_setup.go
package setup

type TestEnvironment struct {
    Database    *sql.DB
    Redis       *redis.Client
    APIServer   *httptest.Server
    Cleanup     func()
}

func SetupIntegrationTest(t *testing.T) *TestEnvironment {
    // Setup real infrastructure
    db := setupTestDatabase(t)
    redis := setupTestRedis(t)
    apiServer := setupTestAPIServer(t)
    
    cleanup := func() {
        cleanupTestDatabase(db)
        cleanupTestRedis(redis)
        apiServer.Close()
    }
    
    return &TestEnvironment{
        Database:  db,
        Redis:     redis,
        APIServer: apiServer,
        Cleanup:   cleanup,
    }
}
```

## Phase 3: Happy Path Integration Test
Focus on complete workflow verification:

```go
func Test_given_valid_setup_when_[component]_executed_then_[expected](t *testing.T) {
    t.Parallel()
    
    // Arrange: Setup real infrastructure and test data
    env := setup.SetupIntegrationTest(t)
    defer env.Cleanup()
    
    testData := fixtures.NewTest[Entity]()
    err := seedTestData(env.Database, testData)
    assertNoError(t, err, "failed to seed test data")
    
    // Act: Execute the actual workflow
    result, err := systemUnderTest.Execute(context.Background(), request)
    
    // Assert: Verify real infrastructure state
    assertNoError(t, err, "workflow execution failed")
    assertEqual(t, result.Status, "expected_status", "unexpected status")
    
    // Verify database state
    saved, err := repository.FindByID(context.Background(), testData.ID)
    assertNoError(t, err, "failed to retrieve saved data")
    assertEqual(t, saved.Field, expectedValue, "saved data mismatch")
}
```

## Phase 4: Critical Edge Cases
Test infrastructure-specific behaviors:

```go
func Test_given_[constraint]_when_duplicate_insert_then_error(t *testing.T) {
    t.Parallel()
    
    // Arrange: Setup real infrastructure
    env := setup.SetupIntegrationTest(t)
    defer env.Cleanup()
    
    entity := fixtures.NewTest[Entity]()
    err := repository.Save(context.Background(), entity)
    assertNoError(t, err, "failed to save initial entity")
    
    // Act: Attempt duplicate operation
    err = repository.Save(context.Background(), entity)
    
    // Assert: Verify infrastructure constraint
    assertError(t, err, "expected constraint violation")
    assertErrorContains(t, err, "unique constraint")
}
```

## Phase 5: Test Data Management
Create reusable fixtures:

```go
// tests/integration/[module]/fixtures/test_data.go
package fixtures

type Test[Entity] struct {
    ID    string
    Field string
}

func NewTest[Entity]() *Test[Entity] {
    return &Test[Entity]{
        ID:    uuid.New().String(),
        Field: "test-value",
    }
}

func (te *Test[Entity]) Seed(db *sql.DB) error {
    query := `INSERT INTO [table] (id, field) VALUES ($1, $2)`
    _, err := db.Exec(query, te.ID, te.Field)
    return err
}
```

## Phase 6: Infrastructure Assertions
Create specialized assertion helpers:

```go
// tests/integration/[module]/testutils/assertions.go
package testutils

func AssertDatabaseState(t *testing.T, db *sql.DB, expectedCount int) {
    var count int
    err := db.QueryRow("SELECT COUNT(*) FROM [table]").Scan(&count)
    assertNoError(t, err, "failed to query database")
    assertEqual(t, count, expectedCount, "record count mismatch")
}

func AssertMessageInQueue(t *testing.T, client redis.Client, queue, content string) {
    result, err := client.LPop(queue).Result()
    assertNoError(t, err, "failed to pop message")
    assertEqual(t, result, content, "message content mismatch")
}
```

## File Organization
```
tests/integration/[module]/
├── setup/
│   └── test_setup.go
├── fixtures/
│   └── test_data.go
├── testutils/
│   └── assertions.go
└── [component]_integration_test.go
```

## Key Principles

### Real Infrastructure Focus
- Use actual databases, message queues, external APIs
- Test real constraints, transactions, and performance
- Verify serialization/deserialization behavior

### Happy Path Priority
- Focus on successful workflows first
- Add critical edge cases only
- Test infrastructure-specific failures

### Environment Isolation
- Each test gets isolated environment
- Use unique identifiers for test data
- Complete cleanup after each test

### Performance Guidelines
- Tests should complete within 30 seconds
- Use `t.Parallel()` for independent tests
- Add timeouts for long-running operations

## Common Patterns

### Database Testing
```go
func Test_given_valid_data_when_persisted_then_retrievable(t *testing.T) {
    // Test actual database operations
    // Verify constraints and transactions
}
```

### Message Queue Testing
```go
func Test_given_message_when_published_then_consumable(t *testing.T) {
    // Test real message broker
    // Verify ordering and durability
}
```

### External API Testing
```go
func Test_given_api_request_when_sent_then_response_received(t *testing.T) {
    // Test HTTP client with real server
    // Verify retry logic and error handling
}
```

## Success Criteria
- Tests use real infrastructure
- Proper cleanup and isolation
- Clear failure messages
- File size ≤150 lines
- Parallel execution safe

Integration tests provide confidence that the complete system works correctly with real infrastructure components.
