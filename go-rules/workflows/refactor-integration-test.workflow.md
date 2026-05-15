---
description: Refactor integration tests - ALWAYS use REAL infrastructure, NEVER mocks
---

# Integration Test Refactoring Workflow

**CRITICAL**: Integration tests MUST use REAL infrastructure (databases, APIs, queues, file systems). NEVER use mocks.

Improve maintainability while preserving behavior (see `go-integration-testing-standards.md`).

## Phase 1: Analysis

**Identify**:
- Code smells (long functions >20 lines, duplication)
- File size violations (>150 lines)
- Test isolation issues (shared state, cleanup)
- Infrastructure setup (REAL DB/API/queue/cache)
- Mock usage (❌ FORBIDDEN in integration tests)

## Phase 2: Extract REAL Infrastructure Setup

**Before**: Inline setup
**After**: Centralized REAL infrastructure setup

```go
type TestEnvironment struct {
    Database  *sql.DB        // REAL database
    Cache     *redis.Client  // REAL cache
    Queue     QueueClient    // REAL queue
    APIClient *http.Client   // REAL API client
    Cleanup   func()
}

func SetupRealInfrastructure(t *testing.T) *TestEnvironment {
    db := connectToRealDatabase(t)      // REAL connection
    cache := connectToRealCache(t)      // REAL connection
    queue := connectToRealQueue(t)      // REAL connection
    api := setupRealAPIClient(t)        // REAL client
    
    return &TestEnvironment{
        Database: db, Cache: cache, Queue: queue, APIClient: api,
        Cleanup: func() { cleanupAll(db, cache, queue) },
    }
}
```

## Phase 3: Extract Assertions for REAL Infrastructure

```go
// Verify REAL database state
func AssertDatabaseState(t *testing.T, db *sql.DB, expectedCount int) {
    var count int
    err := db.QueryRow("SELECT COUNT(*) FROM table").Scan(&count)
    assert.NoError(t, err)
    assert.Equal(t, expectedCount, count)
}

// Verify REAL cache state
func AssertCacheContains(t *testing.T, cache *redis.Client, key, expected string) {
    val, err := cache.Get(ctx, key).Result()
    assert.NoError(t, err)
    assert.Equal(t, expected, val)
}

// Verify REAL queue state
func AssertMessageInQueue(t *testing.T, queue QueueClient, expected string) {
    msg, err := queue.Consume()
    assert.NoError(t, err)
    assert.Equal(t, expected, msg)
}
```

## Phase 4: Split Large Files

**Rule**: Files MUST be ≤150 lines

**Split by**:
- Happy path tests (successful workflows)
- Edge cases (infrastructure failures)
- Performance tests (timing, resources)

**Example**: `component_integration_test.go` (200 lines) → Split into 3 files ≤150 lines each

## Phase 5: Test Data for REAL Infrastructure

```go
type TestDataSeeder struct {
    DB    *sql.DB        // REAL database
    Cache *redis.Client // REAL cache
}

func (s *TestDataSeeder) SeedTestData() error {
    // Seed REAL database
    _, err := s.DB.Exec("INSERT INTO users VALUES ($1, $2)", "test-id", "test@example.com")
    if err != nil { return err }
    
    // Seed REAL cache
    return s.Cache.Set(ctx, "test-key", "test-value", 0).Err()
}

func (s *TestDataSeeder) Cleanup() error {
    s.DB.Exec("DELETE FROM users WHERE email LIKE '%@test.example.com'")
    s.Cache.FlushDB(ctx)
    return nil
}
```

## Phase 6: Test Isolation with REAL Infrastructure

```go
func Test_isolated_with_real_infrastructure(t *testing.T) {
    t.Parallel() // Safe with isolated REAL infrastructure
    
    env := SetupRealInfrastructureWithUniqueNamespace(t)
    defer env.Cleanup()
    
    // Test against REAL infrastructure with unique namespace
}
```

**Isolation Strategies**:
- Parallel execution (`t.Parallel()`)
- Unique DB schemas/namespaces per test
- Unique cache key prefixes
- Unique queue names
- Complete cleanup of REAL resources

## Phase 7: Error Handling

**Use `testify/assert`** (MANDATORY):
```go
assert.NoError(t, err, "failed to setup REAL infrastructure")
assert.Error(t, err, "expected error from REAL infrastructure")
assert.Equal(t, expected, actual, "REAL infrastructure state mismatch")
```

## Phase 8: Performance with REAL Infrastructure

```go
// Timeout for REAL infrastructure operations
ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
defer cancel()
result, err := processor.ProcessWithRealInfrastructure(ctx, request)

// Parallel execution with isolated REAL infrastructure
func Test_parallel_with_real_infrastructure(t *testing.T) {
    t.Parallel()
    env := SetupRealInfrastructureWithUniqueID(t)
    defer env.Cleanup()
}
```

## Phase 9: Validation

```bash
# Verify file sizes ≤150 lines
find tests/integration -name "*_test.go" -exec wc -l {} \; | awk '$1 > 150'

# Run integration tests with REAL infrastructure
go test -tags=integration -v ./tests/integration/...

# Parallel execution
go test -parallel 4 -v ./tests/integration/...

# Coverage
go test -cover ./tests/integration/...
```

## Success Criteria

- ✅ All tests pass
- ✅ Files ≤150 lines
- ✅ REAL infrastructure only (NO MOCKS)
- ✅ Proper isolation (parallel safe)
- ✅ Complete cleanup
- ✅ Behavior preserved
- ✅ `testify/assert` used

**Key Principle**: Integration tests MUST use REAL infrastructure (databases, APIs, queues, caches, file systems). If using mocks, it's a unit test, not an integration test.
