---
description: Create integration tests - ALWAYS use REAL infrastructure, NEVER mocks
---

# Integration Test Creation Workflow

**CRITICAL**: Integration tests MUST use REAL infrastructure (databases, APIs, queues, file systems). NEVER use mocks.

Create new integration tests following `go-integration-testing-standards.md`.

## Phase 1: Determine Integration Points

**Identify**:
- External systems the code touches (databases, APIs, message queues, caches, file systems)
- Infrastructure components to test (repository implementations, external service clients)
- Critical workflows that need real infrastructure validation
- Current functionality that exists in production (YAGNI - no hypothetical features)

**Skip integration tests if**:
- Testing pure business logic (use unit tests instead)
- REAL infrastructure is unavailable (use Docker/test instances)
- Test would be too slow (>60s)

## Phase 2: Setup REAL Infrastructure

**Create Docker Compose** (if not exists):
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

**Create TestEnvironment struct**:
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
```

## Phase 3: Create Setup Functions

**Create REAL infrastructure setup** in `tests/{domain}/integration/setup/`:

```go
// setup/database_setup.go
func SetupRealDatabase(t *testing.T) *sql.DB {
    db, err := sql.Open("postgres", "postgres://user:pass@localhost:5433/test_db")
    assert.NoError(t, err, "failed to connect to REAL database")
    
    // Run migrations if needed
    err = runMigrations(db)
    assert.NoError(t, err, "failed to run migrations")
    
    return db
}

func cleanupDatabase(db *sql.DB) {
    db.Close()
}

// setup/cache_setup.go
func SetupRealCache(t *testing.T) *redis.Client {
    client := redis.NewClient(&redis.Options{
        Addr: "localhost:6380",
    })
    
    err := client.Ping(context.Background()).Err()
    assert.NoError(t, err, "failed to connect to REAL cache")
    
    return client
}

func cleanupCache(cache *redis.Client) {
    cache.FlushDB(context.Background())
    cache.Close()
}
```

**Create main setup function**:
```go
func SetupRealInfrastructure(t *testing.T) *TestEnvironment {
    db := SetupRealDatabase(t)
    cache := SetupRealCache(t)
    
    return &TestEnvironment{
        Database: db,
        Cache: cache,
        Cleanup: func() {
            cleanupDatabase(db)
            cleanupCache(cache)
        },
    }
}
```

## Phase 4: Create Test Data Seeder

**Create seeder** in `tests/{domain}/integration/fixtures/`:

```go
// fixtures/test_data.go
type TestDataSeeder struct {
    DB    *sql.DB
    Cache *redis.Client
}

func NewTestDataSeeder(db *sql.DB, cache *redis.Client) *TestDataSeeder {
    return &TestDataSeeder{DB: db, Cache: cache}
}

func (s *TestDataSeeder) SeedTestData() error {
    // Seed REAL database
    _, err := s.DB.Exec("INSERT INTO users VALUES ($1, $2)", "test-id", "test@example.com")
    if err != nil {
        return err
    }
    
    // Seed REAL cache
    return s.Cache.Set(context.Background(), "test-key", "test-value", 0).Err()
}

func (s *TestDataSeeder) CleanupTestData() error {
    // Cleanup from REAL database
    _, err := s.DB.Exec("DELETE FROM users WHERE email LIKE '%@test.example.com'")
    if err != nil {
        return err
    }
    
    // Cleanup from REAL cache
    s.Cache.FlushDB(context.Background())
    
    return nil
}
```

## Phase 5: Write Integration Test

**Create test file** in `tests/{domain}/integration/{component}_integration_test.go`:

**CRITICAL**: Use comment separators to clearly mark each AAA section:
- `// Arrange` - Setup REAL infrastructure, use case, request, and pre-existing data
- `// Act` - Only ONE line - the actual action being tested
- `// Assert` - Verify expected outcome in REAL infrastructure

```go
func Test_given_valid_user_when_create_user_then_saves_in_database(t *testing.T) {
    t.Parallel()
    
    // Arrange: Setup REAL infrastructure and use case
    env := SetupRealInfrastructure(t)
    defer env.Cleanup()
    
    seeder := NewTestDataSeeder(env.Database, env.Cache)
    defer seeder.CleanupTestData()
    
    useCase := NewCreateUserUseCase(env.Database) // REAL database
    request := CreateUserRequest{
        Email: "test@example.com",
        Name: "Test User",
    }
    
    // Act: Execute workflow against REAL infrastructure (ONE LINE ONLY)
    result, err := useCase.Execute(context.Background(), request)
    
    // Assert: Verify state in REAL infrastructure
    assert.NoError(t, err)
    assert.NotEmpty(t, result.ID)
    
    // Verify REAL database state
    var count int
    err = env.Database.QueryRow("SELECT COUNT(*) FROM users WHERE email = $1", "test@example.com").Scan(&count)
    assert.NoError(t, err)
    assert.Equal(t, 1, count)
}

func Test_given_existing_user_when_create_duplicate_user_then_returns_error(t *testing.T) {
    t.Parallel()
    
    // Arrange: Setup REAL infrastructure, use case, and pre-existing data
    env := SetupRealInfrastructure(t)
    defer env.Cleanup()
    
    seeder := NewTestDataSeeder(env.Database, env.Cache)
    defer seeder.CleanupTestData()
    
    // Seed existing user in REAL database (setup for duplicate test)
    _, err := env.Database.Exec("INSERT INTO users (id, email, name) VALUES ($1, $2, $3)", 
        "existing-id", "test@example.com", "Existing User")
    assert.NoError(t, err)
    
    useCase := NewCreateUserUseCase(env.Database) // REAL database
    request := CreateUserRequest{
        Email: "test@example.com", // Duplicate email
        Name: "New User",
    }
    
    // Act: Execute workflow against REAL infrastructure (ONE LINE ONLY - the duplicate action)
    result, err := useCase.Execute(context.Background(), request)
    
    // Assert: Verify error returned
    assert.Error(t, err)
    assert.Empty(t, result.ID)
}
```

**Follow naming convention**: `Test_given_[scenario]_when_[action]_then_[expected]`

## Phase 6: Add Isolation Strategies

**Ensure test isolation**:
```go
func Test_given_unique_namespace_when_parallel_then_no_conflicts(t *testing.T) {
    t.Parallel() // Safe with isolated REAL infrastructure
    
    // Use unique identifiers for isolation
    uniqueID := uuid.New().String()
    testEmail := fmt.Sprintf("user-%s@example.com", uniqueID)
    
    env := SetupRealInfrastructureWithUniqueNamespace(t, uniqueID)
    defer env.Cleanup()
    
    // Test with unique namespace
}
```

**Isolation strategies**:
- **Database**: Unique schema/namespace per test, transaction rollback, or cleanup queries
- **Cache**: Unique key prefixes, flush test keys after tests
- **Queue**: Unique queue names, purge after tests
- **File System**: Unique temp directories, delete after tests
- **API**: Use test-specific identifiers, cleanup via API calls

## Phase 7: Add Assertion Helpers

**Create assertion helpers** for REAL infrastructure verification:

```go
// helpers/assertions.go
func AssertDatabaseHasUser(t *testing.T, db *sql.DB, email string) {
    var count int
    err := db.QueryRow("SELECT COUNT(*) FROM users WHERE email = $1", email).Scan(&count)
    assert.NoError(t, err, "failed to query REAL database")
    assert.Equal(t, 1, count, "user not found in REAL database")
}

func AssertCacheContains(t *testing.T, cache *redis.Client, key, expected string) {
    val, err := cache.Get(context.Background(), key).Result()
    assert.NoError(t, err, "failed to get from REAL cache")
    assert.Equal(t, expected, val, "cache value mismatch in REAL cache")
}
```

## Phase 8: Run and Validate

**Run integration tests**:
```bash
# Start REAL infrastructure
docker-compose -f docker-compose.test.yml up -d

# Run integration tests with REAL infrastructure
go test -tags=integration -v ./tests/{domain}/integration/...

# Parallel execution
go test -parallel 4 -tags=integration -v ./tests/{domain}/integration/...

# Coverage
go test -cover -tags=integration ./tests/{domain}/integration/...
```

**Validate**:
- File sizes ≤150 lines (use `wc -l`)
- Function sizes ≤20 lines
- All tests pass
- REAL infrastructure only (NO MOCKS)
- Proper cleanup (no resource leaks)
- Parallel execution safe

## Phase 9: CI/CD Integration

**Add to CI pipeline**:
```yaml
# .github/workflows/integration-tests.yml
name: Integration Tests
on: [push, pull_request]

jobs:
  integration-tests:
    runs-on: ubuntu-latest
    services:
      postgres:
        image: postgres:15
        env:
          POSTGRES_DB: test_db
      redis:
        image: redis:7
    
    steps:
      - uses: actions/checkout@v3
      - uses: actions/setup-go@v4
      - name: Run integration tests
        run: go test -tags=integration -v ./tests/.../integration/...
```

## Success Criteria

- ✅ Tests use REAL infrastructure (databases, APIs, queues, caches, file systems)
- ✅ NO mocks in integration tests
- ✅ Files ≤150 lines
- ✅ Functions ≤20 lines
- ✅ Proper isolation (parallel safe)
- ✅ Complete cleanup of REAL resources
- ✅ `testify/assert` used for assertions
- ✅ ATDD naming: `Test_given_[scenario]_when_[action]_then_[expected]`
- ✅ Tests current functionality only (YAGNI)
- ✅ Integration tests <30 seconds total
- ✅ Coverage ≥80%

**Key Principle**: If you're tempted to use a mock, you're writing a unit test, not an integration test. Integration tests MUST use REAL infrastructure.
