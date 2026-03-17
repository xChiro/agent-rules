---
trigger: always_on
description: Integration testing standards - ALWAYS test against REAL infrastructure, NEVER use mocks
globs: 
---

# Go Integration Testing Standards

**CRITICAL RULE**: Integration tests MUST ALWAYS use REAL infrastructure (databases, APIs, message queues, file systems). NEVER use mocks in integration tests.

## Core Principles

- **Real Infrastructure ONLY**: Test against actual databases, message queues, APIs, file systems - NO MOCKS
- **Happy Path Focus**: Successful workflows with critical edge cases
- **Environment Isolation**: Each test runs in isolated environment with cleanup
- **YAGNI Principles for Integration Tests**

**Do**:
- Test current functionality against REAL infrastructure
- Focus on critical integration points
- Test actual workflows that exist in production
- Use REAL infrastructure for all external dependencies

**Don't**:
- Test hypothetical future features
- Create integration tests for non-existent integrations
- Use mocks instead of real infrastructure
- Over-engineer test infrastructure

**Skip integration tests when**:
- Testing pure business logic (use unit tests)
- REAL infrastructure is truly unavailable (rare - use Docker/test instances)
- Test would be too slow (>60s) - consider splitting or optimizing

**Key distinction**: If it touches external systems (databases, APIs, message queues, file systems, external services) → integration test with REAL infrastructure

## Mandatory Requirements

- **Real Infrastructure**: ALWAYS use real databases, APIs, queues - NEVER mocks
- **File limit**: ≤150 lines per test file
- **Function limit**: ≤20 lines per test function
- **Assertions**: `github.com/stretchr/testify/assert`
- **YAGNI**: Test only existing features
- **Cleanup**: Always cleanup test data and resources

## Test Structure

### Naming Convention
- **Pattern**: `Test_given_[scenario]_when_[action]_then_[expected]` (snake_case)

### File Organization
```
tests/{domain}/integration/
├── {component}_integration_test.go
├── setup/
│   ├── database_setup.go
│   ├── api_setup.go
│   └── cleanup.go
└── fixtures/
    └── test_data.go
```

### Test Structure Template
```go
func Test_given_scenario_when_action_then_expected(t *testing.T) {
    t.Parallel()
    
    // Arrange: Setup REAL infrastructure (DB, API, queue, etc.)
    env := SetupRealInfrastructure(t)
    defer env.Cleanup() // ALWAYS cleanup
    
    // Act: Execute workflow against REAL infrastructure
    result := ExecuteAgainstRealInfrastructure(env)
    
    // Assert: Verify state in REAL infrastructure
    VerifyRealInfrastructureState(t, env, result)
}
```

## Test Environment Setup

### Test Environment Setup - REAL Infrastructure

**CRITICAL**: Setup functions MUST create connections to REAL infrastructure, NOT mocks.

```go
type TestEnvironment struct {
    // REAL infrastructure connections - NO MOCKS
    Database      *sql.DB           // Real database connection
    Cache         *redis.Client     // Real cache connection
    MessageQueue  MessageQueueClient // Real queue connection
    APIClient     *http.Client      // Real API client
    FileSystem    string            // Real temp directory
    Cleanup       func()            // Cleanup function
}

func SetupRealInfrastructure(t *testing.T) *TestEnvironment {
    // Connect to REAL database (Docker container, test instance, etc.)
    db := connectToRealDatabase(t)
    
    // Connect to REAL cache
    cache := connectToRealCache(t)
    
    // Connect to REAL message queue
    queue := connectToRealQueue(t)
    
    // Setup REAL API client
    apiClient := setupRealAPIClient(t)
    
    // Create REAL temp directory
    tempDir := createRealTempDir(t)
    
    return &TestEnvironment{
        Database: db,
        Cache: cache,
        MessageQueue: queue,
        APIClient: apiClient,
        FileSystem: tempDir,
        Cleanup: func() {
            cleanupDatabase(db)
            cleanupCache(cache)
            cleanupQueue(queue)
            cleanupFileSystem(tempDir)
        },
    }
}
```

### Docker Compose for Real Infrastructure
```yaml
version: '3.8'
services:
  test-database:
    image: postgres:15  # Or your DB
    environment:
      POSTGRES_DB: test_db
    ports:
      - "5433:5432"
  
  test-cache:
    image: redis:7
    ports:
      - "6380:6379"
  
  test-queue:
    image: rabbitmq:3-management  # Or your queue
    ports:
      - "5673:5672"
```

## Infrastructure Testing Guidelines

### Database Integration
- **Use real database instances**: PostgreSQL, MongoDB, etc.
- **Test actual repository implementations**: Verify mapping and constraints
- **Test transaction behavior**: Verify rollback and commit
- **Test with realistic data volumes**

### Message Queue Integration
- **Use real message brokers**: RabbitMQ, Kafka, Redis Streams, etc.
- **Test actual producer/consumer implementations**: Verify serialization, deserialization, ordering
- **Test message durability and acknowledgments**

### External API Integration
- **Use real test instances or staging environments**: Verify retry logic, timeouts, circuit breakers
- **Test authentication and authorization flows**: Use real API test servers, NOT mocks

### File System Integration
- **Use real file system operations**: Temp directories, verify permissions and concurrent access
- **Test cleanup procedures**: Delete after tests

### Cache Integration
- **Use real cache instances**: Redis, Memcached, etc.
- **Test actual cache operations**: Get, set, delete, TTL
- **Verify cache invalidation strategies**

## Test Data Management

### Seeding REAL Infrastructure
```go
type TestDataSeeder struct {
    DB    *sql.DB           // REAL database
    Cache *redis.Client    // REAL cache
    Queue MessageQueueClient // REAL queue
}

func (s *TestDataSeeder) SeedTestData() error {
    // Seed REAL database
    if err := s.seedDatabase(); err != nil {
        return err
    }
    
    // Seed REAL cache
    if err := s.seedCache(); err != nil {
        return err
    }
    
    // Seed REAL queue
    if err := s.seedQueue(); err != nil {
        return err
    }
    
    return nil
}

func (s *TestDataSeeder) CleanupTestData() error {
    // Cleanup from REAL database
    _, err := s.DB.Exec("DELETE FROM users WHERE email LIKE '%@test.example.com'")
    if err != nil {
        return err
    }
    
    // Cleanup from REAL cache
    s.Cache.FlushDB(context.Background())
    
    // Cleanup from REAL queue
    s.Queue.Purge()
    
    return nil
}
```

### Isolation Strategies for REAL Infrastructure
- **Database**: Unique schema/namespace per test, transaction rollback, or cleanup queries
- **Cache**: Unique key prefixes, flush test keys after tests
- **Queue**: Unique queue names, purge after tests
- **File System**: Unique temp directories, delete after tests
- **API**: Use test-specific identifiers, cleanup via API calls

## Best Practices - REAL Infrastructure

**ALWAYS Use REAL Infrastructure**:
- ✅ REAL databases (PostgreSQL, MySQL, MongoDB, etc.)
- ✅ REAL caches (Redis, Memcached, etc.)
- ✅ REAL message queues (RabbitMQ, Kafka, Redis Streams, etc.)
- ✅ REAL file systems (temp directories)
- ✅ REAL API test servers or staging environments
- ❌ NEVER use mocks in integration tests

**Test Design**:
- Test against REAL infrastructure only
- Focus on success scenarios + critical edge cases
- Always cleanup REAL infrastructure after tests
- Verify state in REAL infrastructure (DB queries, cache checks, etc.)

**Environment Setup**:
- Use Docker Compose for REAL infrastructure
- Parallel execution with isolated environments
- Deterministic seeded data in REAL infrastructure
- Proper cleanup of REAL resources

**Performance**:
- Integration tests: <30 seconds total
- End-to-end tests: <60 seconds total
- Use timeouts for REAL infrastructure operations
- Optimize REAL infrastructure setup (connection pooling, etc.)

**CI/CD**:
- Run with: `go test -tags=integration ./tests/integration/...`
- Ensure REAL infrastructure available in CI (Docker services)
- Coverage threshold: ≥80%
- No race conditions

**Key Principle**: If you're tempted to use a mock, you're writing a unit test, not an integration test. Integration tests MUST use REAL infrastructure.