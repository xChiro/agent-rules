---
trigger: always_on
description: 
globs: 
---

# Go Integration Testing Standards

Integration testing guidelines for testing real infrastructure and component interactions.

## Core Principles

- **Real Infrastructure**: Test against actual databases, message queues, external APIs
- **Happy Path Focus**: Primary focus on successful workflows with critical edge cases
- **Layer Integration**: Verify proper interaction between Domain, Application, and Infrastructure layers
- **Environment Isolation**: Each test runs in isolated environment with cleanup
- **Deterministic Results**: Use seeded data and controlled external dependencies

## Mandatory Requirements (Non-Negotiable)

- **File size limit**: ≤150 lines per test file
- **Assertion library**: MUST use `github.com/stretchr/testify/assert` library instead of `if` statements for all assertions - this is non-negotiable

## Test Structure

### Naming Convention
- **Pattern**: `Test_given_[scenario]_when_[action]_then_[expected]`
- **Format**: snake_case for function names
- **Examples**:
  - `Test_given_valid_order_when_processing_then_persisted_and_published`
  - `Test_given_database_constraint_when_duplicate_insert_then_error`

### File Organization
```
tests/
  integration/
    infrastructure/
      repository_test.go
      external_api_test.go
      message_queue_test.go
    setup/
      test_setup.go
      cleanup.go
    fixtures/
      test_data.go
```

### Test Structure Template
```go
func Test_given_valid_setup_when_component_executed_then_expected_behavior(t *testing.T) {
    t.Parallel()
    
    // Arrange: Setup real infrastructure and test data
    // Act: Execute the actual workflow
    // Assert: Verify real infrastructure state
    // Cleanup: Restore environment
}
```

## Test Environment Setup

### Test Environment Structure
```go
type TestEnvironment struct {
    Database    *sql.DB
    Redis       *redis.Client
    APITestServer *httptest.Server
    Cleanup     func()
}

func SetupIntegrationTest(t *testing.T) *TestEnvironment {
    // Setup test database
    db := setupTestDatabase(t)
    
    // Setup test Redis
    redis := setupTestRedis(t)
    
    // Setup test API server
    apiServer := setupTestAPIServer(t)
    
    // Create cleanup function
    cleanup := func() {
        cleanupTestDatabase(db)
        cleanupTestRedis(redis)
        apiServer.Close()
    }
    
    return &TestEnvironment{
        Database:    db,
        Redis:       redis,
        APITestServer: apiServer,
        Cleanup:     cleanup,
    }
}
```

### Docker Compose for Tests
```yaml
# docker-compose.test.yml
version: '3.8'
services:
  postgres-test:
    image: postgres:15
    environment:
      POSTGRES_DB: test_db
    ports:
      - "5433:5432"
  
  redis-test:
    image: redis:7
    ports:
      - "6380:6379"
```

## Infrastructure Testing Guidelines

### Database Integration
- Use real database instances (PostgreSQL, MongoDB, etc.)
- Test actual repository implementations
- Verify transaction behavior and constraints
- Test query performance with realistic data volumes

### Message Queue Integration
- Test against real message brokers (RabbitMQ, Kafka, Redis)
- Verify message serialization/deserialization
- Test consumer/producer workflows
- Validate message ordering and durability

### External API Integration
- Use test instances or mock servers for external services
- Test HTTP client implementations
- Verify retry logic and error handling
- Test rate limiting and timeout behavior

### File System Integration
- Test actual file operations
- Verify permission handling
- Test concurrent file access
- Validate cleanup procedures

## Test Data Management

### Fixtures and Seeding
```go
// fixtures/test_data.go
package fixtures

type TestDatabase struct {
    DB *sql.DB
}

func (td *TestDatabase) SeedUsers() error {
    // Insert test users
    users := []User{
        {ID: "user-1", Email: "user1@example.com"},
        {ID: "user-2", Email: "user2@example.com"},
    }
    
    for _, user := range users {
        _, err := td.DB.Exec("INSERT INTO users (id, email) VALUES ($1, $2)", user.ID, user.Email)
        if err != nil {
            return err
        }
    }
    return nil
}

func (td *TestDatabase) Cleanup() error {
    // Clean all test data
    _, err := td.DB.Exec("DELETE FROM users WHERE email LIKE '%@example.com'")
    return err
}
```

### Isolation Strategy
- Each test gets unique database schema or namespace
- Use transactions with rollback for database tests
- Generate unique identifiers for message queues
- Clean up files and temporary resources

## Integration Testing Patterns

### Complete Workflow Testing
```go
func Test_given_valid_order_when_processing_then_persisted_and_published(t *testing.T) {
    t.Parallel()
    
    // Arrange
    env := SetupIntegrationTest(t)
    defer env.Cleanup()
    
    // Seed test data
    user := fixtures.NewTestUser()
    err := env.UserRepo.Save(context.Background(), user)
    assertNoError(t, err)
    
    order := &Order{
        ID:     uuid.New().String(),
        UserID: user.ID,
        Items:  []OrderItem{{ProductID: "prod-1", Quantity: 2}},
        Total:  100.0,
    }
    
    processor := application.NewOrderProcessor(
        env.OrderRepo,
        env.EventPublisher,
    )
    
    // Act
    result, err := processor.Process(context.Background(), order)
    
    // Assert
    assertNoError(t, err)
    assertEqual(t, result.Status, "processed")
    
    // Verify database state
    saved, err := env.OrderRepo.FindByID(context.Background(), order.ID)
    assertNoError(t, err)
    assertEqual(t, saved.ID, order.ID)
    assertEqual(t, saved.UserID, user.ID)
    
    // Verify event was published
    events := env.EventPublisher.GetPublishedEvents()
    assertEqual(t, len(events), 1, "should publish exactly one event")
    assertEqual(t, events[0].Type, "order.processed")
}
```

### Database Repository Testing
```go
func Test_repository_integration(t *testing.T) {
    t.Parallel()
    
    env := SetupIntegrationTest(t)
    defer env.Cleanup()
    
    repo := NewSQLOrderRepository(env.Database)
    
    // Test save
    order := fixtures.NewTestOrder()
    err := repo.Save(context.Background(), order)
    assertNoError(t, err)
    
    // Test find
    found, err := repo.FindByID(context.Background(), order.ID)
    assertNoError(t, err)
    assertEqual(t, found.ID, order.ID)
    assertEqual(t, found.UserID, order.UserID)
    
    // Test constraints
    duplicate := fixtures.NewTestOrder()
    duplicate.ID = order.ID
    err = repo.Save(context.Background(), duplicate)
    assertErrorContains(t, err, "unique constraint")
    
    // Test update
    order.Total = 200.0
    err = repo.Save(context.Background(), order)
    assertNoError(t, err)
    
    updated, err := repo.FindByID(context.Background(), order.ID)
    assertNoError(t, err)
    assertEqual(t, updated.Total, 200.0)
}
```

### Critical Edge Cases Testing
```go
func Test_given_database_constraint_when_duplicate_insert_then_error(t *testing.T) {
    t.Parallel()
    
    // Arrange
    env := SetupIntegrationTest(t)
    defer env.Cleanup()
    
    user := fixtures.NewTestUser()
    err := env.UserRepo.Save(context.Background(), user)
    assertNoError(t, err)
    
    // Act
    err = env.UserRepo.Save(context.Background(), user)
    
    // Assert
    assertError(t, err, "should return error for duplicate user")
    assertErrorContains(t, err, "unique constraint")
}

func Test_given_network_timeout_when_calling_external_api_then_error(t *testing.T) {
    t.Parallel()
    
    // Arrange
    env := SetupIntegrationTest(t)
    defer env.Cleanup()
    
    // Configure API server to timeout
    env.APITestServer.Config.Handler = http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
        time.Sleep(2 * time.Second) // Simulate slow response
        w.WriteHeader(http.StatusOK)
    })
    
    client := NewExternalAPIClient(env.APITestServer.URL, 1*time.Second)
    
    // Act
    err := client.CallAPI(context.Background())
    
    // Assert
    assertError(t, err, "should timeout on slow response")
    assertErrorContains(t, err, "timeout")
}
```

## Assertion Helpers for Integration Tests

### Infrastructure Assertions
```go
// Verify database state
func assertDatabaseState(t *testing.T, db *sql.DB, expectedCount int) {
    var count int
    err := db.QueryRow("SELECT COUNT(*) FROM users").Scan(&count)
    if err != nil {
        t.Fatalf("failed to query database: %v", err)
    }
    if count != expectedCount {
        t.Fatalf("expected %d users, got %d", expectedCount, count)
    }
}

// Verify message queue state
func assertMessageInQueue(t *testing.T, client redis.Client, queue string, expectedContent string) {
    result, err := client.LPop(queue).Result()
    if err != nil {
        t.Fatalf("failed to pop message: %v", err)
    }
    if result != expectedContent {
        t.Fatalf("expected message %q, got %q", expectedContent, result)
    }
}

// Verify HTTP response
func assertHTTPResponse(t *testing.T, resp *http.Response, expectedStatus int, expectedBody string) {
    if resp.StatusCode != expectedStatus {
        t.Fatalf("expected status %d, got %d", expectedStatus, resp.StatusCode)
    }
    
    body, err := io.ReadAll(resp.Body)
    if err != nil {
        t.Fatalf("failed to read response body: %v", err)
    }
    
    if string(body) != expectedBody {
        t.Fatalf("expected body %q, got %q", expectedBody, string(body))
    }
}
```

## Performance Testing

### Integration Performance Tests
```go
func BenchmarkOrderProcessingIntegration(b *testing.B) {
    env := SetupIntegrationTest(&testing.T{})
    defer env.Cleanup()
    
    processor := application.NewOrderProcessor(env.OrderRepo, env.EventPublisher)
    order := fixtures.NewTestOrder()
    
    b.ResetTimer()
    for i := 0; i < b.N; i++ {
        order.ID = uuid.New().String() // Unique ID for each iteration
        _, err := processor.Process(context.Background(), order)
        if err != nil {
            b.Fatal(err)
        }
    }
}
```

### Test Duration Guidelines
- **Integration tests**: <30 seconds total
- **End-to-end tests**: <60 seconds total
- Use timeouts for long-running operations
- Mark slow tests for investigation

## Continuous Integration

### Test Execution Strategy
```bash
# Run integration tests
go test -tags=integration ./tests/integration/...

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
- Use real infrastructure, not mocks
- Focus on success scenarios
- Test only critical failure modes
- Ensure proper cleanup

### Environment Management
- Isolate test environments
- Use Docker for consistency
- Clean up resources after tests
- Use parallel execution when possible

### Data Management
- Use deterministic test data
- Implement proper seeding
- Clean up test data after tests
- Avoid hardcoded values

Integration tests provide confidence that the complete system works correctly with real infrastructure components while maintaining focus on the most critical user scenarios.
