---
description: Refactor test code following TDD/ATDD standards
---

# Test Code Refactoring Workflow

Improve test maintainability while preserving behavior (see `go-unit-testing-standards.md`).

## Phase 1: Analysis

**Identify**:
- Long test functions (>20 lines)
- Test duplication (repeated setup/teardown)
- Hard-coded data (magic numbers, timestamps)
- Multiple unrelated assertions
- Unclear names (non-descriptive)
- Missing edge cases
- File size violations (>150 lines)
- Assertion violations (using `if` instead of `testify/assert`)
- SRP violations (test functions doing multiple things)

**MANDATORY**: MUST use `github.com/stretchr/testify/assert` for ALL assertions

## Phase 2: Extract Setup

```go
// Before: Inline setup
func Test_scenario(t *testing.T) {
    repo := &mocks.RepoMock{}
    sut := NewProcessor(repo)
}

// After: Extracted setup
func Test_scenario(t *testing.T) {
    sut, mocks := setupProcessor(t)
}

func setupProcessor(t *testing.T) (*Processor, *Mocks) {
    m := &Mocks{Repo: &mocks.RepoMock{}}
    return NewProcessor(m.Repo), m
}
```

## Phase 3: Test Data Builders

```go
// Before: Unstable data
data := Request{
    ID: uuid.New().String(),  // Changes!
    Timestamp: time.Now(),     // Unstable!
}

// After: Builder with stable defaults
const testID = "test-123"
data := fixtures.NewRequestBuilder().WithID(testID).Build()

type RequestBuilder struct { request Request }
func NewRequestBuilder() *RequestBuilder {
    return &RequestBuilder{
        request: Request{
            ID: testID,
            Timestamp: time.Date(2024, 1, 1, 12, 0, 0, 0, time.UTC), // Stable!
        },
    }
}
func (b *RequestBuilder) WithID(id string) *RequestBuilder {
    b.request.ID = id
    return b
}
```

## Phase 4: Use testify/assert (MANDATORY)

```go
// ❌ DON'T: Manual if checks
if err == nil { t.Fatalf("expected error") }
if !strings.Contains(err.Error(), "invalid") { t.Fatalf("...") }

// ✅ DO: Use testify/assert
assert.Error(t, err, "should return error")
assert.Contains(t, err.Error(), "invalid", "error should contain 'invalid'")
assert.NoError(t, err)
assert.Equal(t, expected, actual)
assert.Len(t, slice, expectedLen)
```

## Phase 5: Individual Test Functions (NO Loops)

**AVOID loops** (see `go-unit-testing-standards.md`):
```go
// ❌ DON'T: Loop-based testing
for _, tc := range cases {
    t.Run(tc.name, func(t *testing.T) { /* ... */ })
}

// ✅ DO: Individual test functions
func Test_given_empty_id_when_validating_then_error(t *testing.T) {
    sut, _ := setupProcessor(t)
    request := fixtures.NewBuilder().WithID("").Build()
    _, err := sut.Process(ctx, request)
    assert.Error(t, err)
    assert.Contains(t, err.Error(), "ID cannot be empty")
}

func Test_given_negative_value_when_validating_then_error(t *testing.T) {
    sut, _ := setupProcessor(t)
    request := fixtures.NewBuilder().WithValue(-1).Build()
    _, err := sut.Process(ctx, request)
    assert.Error(t, err)
    assert.Contains(t, err.Error(), "value cannot be negative")
}
```

**Exceptions** (loops acceptable):
- Theory-style tests (same validation rule for all cases)
- Performance benchmarks

## Phase 6: Mock Pattern

```go
type MockCommand struct {
    Calls []CallData
    Error error
}

func (m *MockCommand) Execute(ctx context.Context, data Data) error {
    m.Calls = append(m.Calls, CallData{Data: data})
    return m.Error
}

func (m *MockCommand) VerifyCalledWith(t *testing.T, expected Data) {
    assert.Len(t, m.Calls, 1)
    assert.Equal(t, expected, m.Calls[0].Data)
}
```

## Phase 7: File Organization

**MANDATORY**: Test files ≤150 lines

**Structure**:
```
tests/{domain}/application/{use_case}/
  usecase_test.go          # ≤150 lines
  usecase_edge_cases_test.go
  mocks/mock_{interface}.go
  fixtures/builders.go
```

**Split by**: Scenario (happy/edge/errors), method, test type

## Phase 8: Performance

```go
func BenchmarkProcessing(b *testing.B) {
    sut, _ := setupProcessor(b)
    request := fixtures.NewBuilder().Build()
    b.ResetTimer()
    for i := 0; i < b.N; i++ { sut.Process(ctx, request) }
}
```

## Phase 9: Validation

```bash
go test -v -cover ./...                                    # Coverage
go test -race ./...                                        # Race detection
find tests/ -name "*_test.go" -exec wc -l {} \; | awk '$1 > 150' # File sizes
```

**Quality Gates**:
- All tests pass
- Coverage threshold: ≥80%
- No race conditions
- Test files ≤150 lines
- Each test function: ≤20 lines, ONE responsibility

## Common Scenarios

**Fragile Tests**: Test behavior, not implementation
**Repeated Assertions**: Each test verifies unique behavior
**Large Files**: Split >150 lines by scenario
**Hard-coded Data**: Use builders with stable defaults
**Loop Tests**: Split into individual test functions

## Success Criteria

- ✅ `Test_given_when_then` naming (snake_case)
- ✅ Test data builders (stable defaults)
- ✅ `testify/assert` used (MANDATORY - no `if` statements)
- ✅ Files ≤150 lines (MANDATORY)
- ✅ No repeated assertions
- ✅ Edge cases before happy path
- ✅ Tests isolated and deterministic
- ✅ Coverage maintained/improved
- ✅ Individual test functions (no loops except exceptions)

**Safety**: Tests pass before refactoring, small incremental changes, preserve coverage