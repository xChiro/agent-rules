---
description: Refactor test code following Go TDD/ATDD and manual assertion principles
---

# Test Code Refactoring Workflow

Improve test code maintainability while preserving behavior and following our unified testing standards.

## Phase 1: Test Analysis
- **Long test methods**: Functions >20 lines
- **Test duplication**: Repeated setup/teardown patterns
- **Hard-coded data**: Magic numbers, timestamps, IDs
- **Multiple assertions**: Unrelated checks in single test
- **Unclear names**: Non-descriptive test functions
- **Missing edge cases**: Only happy path testing
- **File size violations**: Files >150 lines (MANDATORY)
- **Manual assertions**: Using proper assertion helpers
- **Repeated assertions**: Same condition checked across tests

## Phase 2: Extract Test Setup

### Before: Inline Setup
```go
func Test_given_valid_input_when_processing_then_succeeds(t *testing.T) {
    repo := &mocks.SaveTelemetryMock{}
    device := &mocks.GetDeviceMock{}
    sut := NewProcessor(repo, device)
    // test logic
}
```

### After: Extracted Setup
```go
func Test_given_valid_input_when_processing_then_succeeds(t *testing.T) {
    sut, mocks := setupProcessor(t)
    // test logic
}

func setupProcessor(t *testing.T) (*Processor, *mocks.ProcessorMocks) {
    m := &mocks.ProcessorMocks{
        Repo:   &mocks.SaveTelemetryMock{},
        Device: &mocks.GetDeviceMock{},
    }
    return NewProcessor(m.Repo, m.Device), m
}
```

## Phase 3: Test Data Builders

### Before: Hard-coded Unstable Data
```go
data := TelemetryRequest{
    MessageID: uuid.New().String(), // Changes every run!
    DeviceID:  "dev-456",
    Timestamp: time.Now(),          // Unstable!
}
```

### After: Builder Pattern with Stable Defaults
```go
const (
    testMessageID = "msg-123"
    testDeviceID  = "dev-456"
)

data := fixtures.NewTelemetryRequestBuilder().
    WithMessageID(testMessageID).
    WithDeviceID(testDeviceID).
    Build()

// fixtures/telemetry_request_builder.go
type TelemetryRequestBuilder struct {
    request TelemetryRequest
}

func NewTelemetryRequestBuilder() *TelemetryRequestBuilder {
    return &TelemetryRequestBuilder{
        request: TelemetryRequest{
            MessageID: testMessageID,
            DeviceID:  testDeviceID,
            Timestamp: time.Date(2024, 1, 1, 12, 0, 0, 0, time.UTC), // Stable!
        },
    }
}

func (b *TelemetryRequestBuilder) WithMessageID(id string) *TelemetryRequestBuilder {
    b.request.MessageID = id
    return b
}

func (b *TelemetryRequestBuilder) WithDeviceID(id string) *TelemetryRequestBuilder {
    b.request.DeviceID = id
    return b
}

func (b *TelemetryRequestBuilder) Build() TelemetryRequest {
    return b.request
}
```

## Phase 4: Manual Assertion Patterns

### Assertion Helpers (Following Our Standards)
```go
// testutils/assertions.go
func assertError(t *testing.T, err error, message string) {
    t.Helper()
    if err == nil {
        t.Fatalf("%s: expected error but got nil", message)
    }
}

func assertNoError(t *testing.T, err error) {
    t.Helper()
    if err != nil {
        t.Fatalf("unexpected error: %v", err)
    }
}

func assertEqual[T comparable](t *testing.T, got, want T, message string) {
    t.Helper()
    if got != want {
        t.Fatalf("%s: got %v, want %v", message, got, want)
    }
}

func assertErrorContains(t *testing.T, err error, substring string) {
    t.Helper()
    if err == nil {
        t.Fatalf("expected error containing %q but got nil", substring)
    }
    if !strings.Contains(err.Error(), substring) {
        t.Fatalf("expected error containing %q, got %q", substring, err.Error())
    }
}
```

### Before: Manual If Checks
```go
func Test_given_invalid_input_when_processing_then_error(t *testing.T) {
    sut, _ := setupProcessor(t)
    _, err := sut.Process(context.Background(), request)
    
    if err == nil {
        t.Fatalf("expected error but got nil")
    }
    if !strings.Contains(err.Error(), "invalid") {
        t.Fatalf("expected 'invalid' in error, got %v", err)
    }
}
```

### After: Manual Assertions
```go
func Test_given_invalid_input_when_processing_then_error(t *testing.T) {
    sut, _ := setupProcessor(t)
    _, err := sut.Process(context.Background(), request)
    
    assertError(t, err, "should return error for invalid input")
    assertErrorContains(t, err, "invalid")
}
```

## Phase 5: Table-Driven Tests

### Edge Case Testing Pattern
```go
func Test_given_invalid_input_when_processing_then_returns_error(t *testing.T) {
    cases := []struct {
        name          string
        setup         func() TelemetryRequest
        expectedError string
    }{
        {
            name: "empty device ID",
            setup: func() TelemetryRequest {
                return fixtures.NewTelemetryRequestBuilder().WithDeviceID("").Build()
            },
            expectedError: "device ID cannot be empty",
        },
        {
            name: "negative speed",
            setup: func() TelemetryRequest {
                return fixtures.NewTelemetryRequestBuilder().WithSpeed(-1).Build()
            },
            expectedError: "speed cannot be negative",
        },
    }
    
    for _, tc := range cases {
        t.Run(tc.name, func(t *testing.T) {
            sut, _ := setupProcessor(t)
            _, err := sut.Process(context.Background(), tc.setup())
            
            assertError(t, err, "should return error for "+tc.name)
            assertErrorContains(t, err, tc.expectedError)
        })
    }
}
```

## Phase 6: Mock Improvements

### Enhanced Mock Pattern
```go
// mocks/save_telemetry_mock.go
type SaveTelemetryMock struct {
    Saved     []Telemetry
    CallCount int
    ReturnError error
}

func (m *SaveTelemetryMock) Save(ctx context.Context, t Telemetry) error {
    m.CallCount++
    m.Saved = append(m.Saved, t)
    return m.ReturnError
}

func (m *SaveTelemetryMock) VerifyCalledWith(t *testing.T, expected Telemetry) {
    assertEqual(t, len(m.Saved), 1, "expected exactly one call")
    if len(m.Saved) > 0 {
        assertEqual(t, m.Saved[0], expected, "call parameters mismatch")
    }
}

func (m *SaveTelemetryMock) VerifyCallCount(t *testing.T, expected int) {
    assertEqual(t, m.CallCount, expected, "call count mismatch")
}

func (m *SaveTelemetryMock) Reset() {
    m.Saved = nil
    m.CallCount = 0
    m.ReturnError = nil
}
```

## Phase 7: Test Organization

### File Size Rule (MANDATORY)
**Test files MUST NOT exceed 150 lines.** Split when limit is reached.

```
tests/
  [module]/
    [feature]_test.go                    # Main tests (≤150 lines)
    [feature]_edge_cases_test.go         # Edge case tests (≤150 lines)
    [feature]_integration_test.go        # Integration tests (≤150 lines)
    fixtures/
      [entity]_builder.go               # Test data builders
    mocks/
      [interface]_mock.go               # Mock implementations
    testutils/
      assertions.go                     # Assertion helpers
```

### Splitting Strategy
When file exceeds 150 lines, split by:
1. **Scenario**: Happy path, edge cases, errors
2. **Method/operation**: Different methods being tested
3. **Test type**: Unit vs integration tests

#### Example Split
```go
// Before: process_message_test.go (200 lines) ❌

// After: Split into focused files ✅
// process_message_test.go           (happy path, ~100 lines)
// process_message_errors_test.go    (error cases, ~80 lines)
// process_message_edge_cases_test.go (edge cases, ~90 lines)
```

## Phase 8: Performance Testing

### Benchmark Pattern
```go
func BenchmarkProcessing(b *testing.B) {
    sut, _ := setupProcessor(b)
    request := fixtures.NewTelemetryRequestBuilder().Build()
    
    b.ResetTimer()
    for i := 0; i < b.N; i++ {
        sut.Process(context.Background(), request)
    }
}
```

## Phase 9: Quality Validation

### Test Execution
```bash
# Run all tests with coverage
go test -v -cover ./...

# Race condition detection
go test -race ./...

# Benchmark tests
go test -bench=. ./...

# Check file sizes
find tests/ -name "*_test.go" -exec wc -l {} \; | awk '$1 > 150'
```

## Common Refactoring Scenarios

### Fragile Tests → Behavior Tests
```go
// Before: Testing implementation details
func Test_calls_repository_once(t *testing.T) {
    if mocks.repo.CallCount != 1 { t.Fatal() }
}

// After: Testing observable behavior
func Test_given_valid_data_when_processing_then_persists_successfully(t *testing.T) {
    // Arrange
    sut, mocks := setupProcessor(t)
    data := fixtures.NewTelemetryRequestBuilder().Build()
    
    // Act
    err := sut.Process(context.Background(), data)
    
    // Assert
    assertNoError(t, err, "processing should succeed")
    mocks.Repo.VerifyCallCount(t, 1)
    mocks.Repo.VerifyCalledWith(t, data)
}
```

### Repeated Assertions → Single Focused Tests
```go
// Before: Same assertion in multiple tests
func Test_scenario_1(t *testing.T) {
    // ...
    assertError(t, err, "expected error") // Repeated pattern
}

func Test_scenario_2(t *testing.T) {
    // ...
    assertError(t, err, "expected error") // Repeated pattern
}

// After: Each test verifies unique behavior
func Test_given_empty_id_when_validating_then_returns_error(t *testing.T) {
    data := fixtures.NewTelemetryRequestBuilder().WithMessageID("").Build()
    err := validate(data)
    
    assertError(t, err, "should return error for empty message ID")
    assertErrorContains(t, err, "message ID")
}

func Test_given_negative_speed_when_validating_then_returns_error(t *testing.T) {
    data := fixtures.NewTelemetryRequestBuilder().WithSpeed(-1).Build()
    err := validate(data)
    
    assertError(t, err, "should return error for negative speed")
    assertErrorContains(t, err, "speed")
}
```

### Large File → Split Files
```go
// Before: Single 300-line test file ❌
// process_message_test.go (300 lines)

// After: Split into focused files ✅
// process_message_test.go (120 lines)
// process_message_errors_test.go (90 lines)
// process_message_integration_test.go (80 lines)
```

## Success Criteria

### Test Quality Standards
- ✅ Tests use `given_when_then` naming in snake_case
- ✅ Test data uses builders with stable defaults
- ✅ Manual assertion helpers (no testify)
- ✅ All test files ≤150 lines (MANDATORY)
- ✅ No repeated assertions across tests
- ✅ Edge cases covered before happy path
- ✅ Tests isolated and deterministic
- ✅ Coverage maintained/improved
- ✅ No hardcoded timestamps or changing values

### File Organization
- ✅ Proper fixture organization
- ✅ Mock implementations in dedicated packages
- ✅ Assertion helpers centralized
- ✅ Clear separation of concerns

## Safety Checks
- Tests pass before refactoring
- Small incremental changes
- Preserve test coverage
- Maintain test isolation
- Verify file size compliance

Test refactoring improves maintainability while preserving behavior and following our unified testing standards.
