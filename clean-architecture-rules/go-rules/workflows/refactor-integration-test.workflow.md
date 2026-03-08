---
description: Refactor integration test code following Clean Architecture testing principles
---

# Integration Test Refactoring Workflow

Improve integration test maintainability while preserving behavior and Clean Architecture compliance.

## Phase 1: Current State Analysis
- Identify **Code Smells**: Long functions, duplicated code, poor structure
- Check **File Size Violations**: Files >150 lines
- Analyze **Test Isolation**: Shared state, cleanup issues
- Review **Infrastructure Dependencies**: Proper setup and teardown

## Phase 2: Extract Test Setup

### Before: Inline Setup
```go
func Test_given_message_when_processed_then_success(t *testing.T) {
    db := setupDatabase()
    defer db.Close()
    redis := setupRedis()
    defer redis.Close()
    // ... test logic
}
```

### After: Centralized Setup
```go
func Test_given_message_when_processed_then_success(t *testing.T) {
    env := setup.SetupIntegrationTest(t)
    defer env.Cleanup()
    // ... test logic
}
```

### Setup Function Pattern
```go
// tests/integration/[module]/setup/test_setup.go
package setup

type TestEnvironment struct {
    Database  *sql.DB
    Redis     *redis.Client
    APIServer *httptest.Server
    Cleanup   func()
}

func SetupIntegrationTest(t *testing.T) *TestEnvironment {
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

## Phase 3: Extract Common Assertions

### Before: Repeated Assertion Code
```go
func Test_given_data_when_persisted_then_verifiable(t *testing.T) {
    var count int
    err := db.QueryRow("SELECT COUNT(*) FROM users").Scan(&count)
    if err != nil {
        t.Fatalf("failed to query database: %v", err)
    }
    if count != expectedCount {
        t.Fatalf("expected %d users, got %d", expectedCount, count)
    }
}
```

### After: Extracted Assertion Helper
```go
func Test_given_data_when_persisted_then_verifiable(t *testing.T) {
    testutils.AssertDatabaseState(t, env.DB, expectedCount)
}
```

### Assertion Helper Pattern
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

## Phase 4: Split Large Test Files

### Before: Single Large File
```bash
# message_processing_integration_test.go (200+ lines)
```

### After: Split by Scenario
```bash
# message_processing_happy_path_test.go (120 lines)
# message_processing_edge_cases_test.go (130 lines)
# message_processing_performance_test.go (110 lines)
```

### Splitting Strategy
- **Happy path tests**: Focus on successful workflows
- **Edge case tests**: Infrastructure-specific failures
- **Performance tests**: Timing and resource usage
- **Error handling tests**: Recovery and resilience

## Phase 5: Improve Test Data Management

### Before: Inline Test Data
```go
func Test_given_user_when_created_then_persisted(t *testing.T) {
    user := &User{
        ID:    uuid.New().String(),
        Name:  "Test User",
        Email: "test@example.com",
    }
    // ... test logic
}
```

### After: Reusable Fixtures
```go
func Test_given_user_when_created_then_persisted(t *testing.T) {
    user := fixtures.NewTestUser()
    assertNoError(t, user.Seed(env.DB), "failed to seed test user")
    // ... test logic
}
```

### Fixture Pattern
```go
// tests/integration/[module]/fixtures/test_data.go
package fixtures

type TestUser struct {
    ID    string
    Name  string
    Email string
}

func NewTestUser() *TestUser {
    return &TestUser{
        ID:    "test-user-" + uuid.New().String(),
        Name:  "Test User",
        Email: "test@example.com",
    }
}

func (tu *TestUser) Seed(db *sql.DB) error {
    query := `INSERT INTO users (id, name, email) VALUES ($1, $2, $3)`
    _, err := db.Exec(query, tu.ID, tu.Name, tu.Email)
    return err
}

func (tu *TestUser) Cleanup(db *sql.DB) error {
    query := `DELETE FROM users WHERE id = $1`
    _, err := db.Exec(query, tu.ID)
    return err
}
```

## Phase 6: Enhance Test Isolation

### Before: Shared State Risk
```go
var globalTestUser *User

func Test_given_shared_state_when_tested_then_interference(t *testing.T) {
    // Risk of test interference
}
```

### After: Complete Isolation
```go
func Test_given_isolated_state_when_tested_then_reliable(t *testing.T) {
    t.Parallel()
    
    env := setup.SetupIntegrationTestWithNamespace(t)
    defer env.Cleanup()
    
    user := fixtures.NewTestUser()
    defer user.Cleanup(env.Database)
    
    // ... test logic
}
```

### Isolation Strategies
- **Parallel execution**: Use `t.Parallel()` for independent tests
- **Unique namespaces**: Separate database schemas per test
- **Deterministic data**: Generate unique identifiers
- **Complete cleanup**: Remove all test artifacts

## Phase 7: Improve Error Handling and Documentation

### Before: Generic Failures
```go
if err != nil {
    t.Fatal(err)
}
```

### After: Contextual Failures
```go
assertNoError(t, err, "failed to setup test environment")
assertError(t, err, "expected error during operation")
```

### Documentation Enhancement
```go
func Test_given_valid_message_when_processed_then_persisted_and_published(t *testing.T) {
    // Verifies complete message processing workflow:
    // 1. Message validation and translation
    // 2. Persistence to database
    // 3. Publishing to message queue
    
    t.Parallel()
    env := setup.SetupIntegrationTest(t)
    defer env.Cleanup()
    
    // ... test implementation
}
```

## Phase 8: Performance and Reliability

### Add Timeouts and Context
```go
// Before: Potentially hanging
result, err := processor.Process(context.Background(), request)

// After: Controlled execution
ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
defer cancel()
result, err := processor.Process(ctx, request)
```

### Parallel Execution Safety
```go
func Test_given_parallel_execution_when_tests_run_then_no_interference(t *testing.T) {
    t.Parallel()
    
    env := setup.SetupIntegrationTestWithUniqueID(t)
    defer env.Cleanup()
    
    // ... test logic with unique resources
}
```

## Phase 9: Validation and Quality Checks

### File Size Validation
```bash
# Check all integration test files are ≤150 lines
find tests/integration -name "*_integration_test.go" -exec wc -l {} \;
```

### Test Execution Validation
```bash
# Run all integration tests to ensure nothing broken
go test -v ./tests/integration/...

# Verify tests work in parallel
go test -parallel 4 -v ./tests/integration/...
```

### Coverage and Quality
```bash
# Check test coverage
go test -cover ./tests/integration/...

# Static analysis
go vet ./tests/integration/...
go fmt ./tests/integration/...
```

## Refactoring Benefits

### Maintainability Improvements
- **Smaller files**: Focused, easier to navigate
- **Shared setup**: Reduced duplication
- **Clear assertions**: Better error messages
- **Proper isolation**: Reliable test execution

### Reliability Enhancements
- **Complete cleanup**: No resource leaks
- **Parallel safety**: No test interference
- **Timeouts**: Prevent hanging tests
- **Deterministic data**: Predictable results

### Performance Gains
- **Parallel execution**: Faster test runs
- **Optimized setup**: Reduced overhead
- **Resource reuse**: Efficient infrastructure use

## Success Criteria
- All tests pass after refactoring
- File sizes ≤150 lines
- Proper test isolation
- No behavior changes
- Improved maintainability
- Parallel execution safe

Integration test refactoring improves code quality while preserving test behavior and infrastructure verification.
