---
description: Refactor test code following Go TDD/ATDD principles and Fowler's testing patterns
---

# Test Code Refactoring Workflow

## Prerequisites
- Understand production code
- Identify test smells
- Access to test suite

## Phase 1: Test Analysis
- **Long test methods**: >50 lines
- **Test duplication**: Repeated setup/teardown
- **Hard-coded data**: Magic numbers/strings, timestamps, IDs
- **Multiple assertions**: Unrelated checks
- **Unclear names**: Non-descriptive functions
- **Missing edge cases**: Only happy path
- **File size violations**: Files exceeding 150 lines (MANDATORY limit)
- **Manual if assertions**: Using `if err == nil` instead of assertion helpers
- **Repeated assertions**: Same condition checked across multiple tests

## Phase 2: Test Refactoring Patterns

### Extract Test Setup
```go
// Before: Repeated setup
func Test_given_valid_input_when_processing_then_succeeds(t *testing.T) {
    repo := &SaveTelemetryMock{}
    device := &GetDeviceMock{}
    sut := NewProcessor(repo, device)
}

// After: Extracted setup
func Test_given_valid_input_when_processing_then_succeeds(t *testing.T) {
    sut, mocks := setupProcessor(t)
    // test logic
}

func setupProcessor(t *testing.T) (*Processor, *mocks) {
    m := &mocks{repo: &SaveTelemetryMock{}, device: &GetDeviceMock{}}
    return NewProcessor(m.repo, m.device), m
}
```

### Test Data Builders
```go
// Before: Hard-coded unstable data
data := TelemetryRequest{
    MessageID: "msg-123", 
    DeviceID: "dev-456",
    Timestamp: time.Now(), // Unstable!
}

// After: Builder pattern with stable defaults
const (
    testMessageID = "msg-123"
    testDeviceID  = "dev-456"
)

data := aTelemetryRequest().
    WithMessageID(testMessageID).
    WithDeviceID(testDeviceID).
    Build()

type TelemetryRequestBuilder struct{ request TelemetryRequest }

func aTelemetryRequest() *TelemetryRequestBuilder {
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

func (b *TelemetryRequestBuilder) Build() TelemetryRequest {
    return b.request
}
```

### Table-Driven Tests
```go
func Test_given_invalid_input_when_processing_then_returns_error(t *testing.T) {
    cases := []struct{
        name string
        setup func() TelemetryRequest
        expectedError string
    }{
        {"empty device ID", func() TelemetryRequest { 
            return aTelemetryRequest().WithDeviceID("").Build() 
        }, "device ID cannot be empty"},
        {"negative speed", func() TelemetryRequest { 
            return aTelemetryRequest().WithSpeed(-1).Build() 
        }, "speed cannot be negative"},
    }
    
    for _, tc := range cases {
        t.Run(tc.name, func(t *testing.T) {
            sut, _ := setupProcessor(t)
            _, err := sut.Process(context.Background(), tc.setup())
            assert.Error(t, err)
            assert.Contains(t, err.Error(), tc.expectedError)
        })
    }
}
```

## Phase 3: Use testify/assert Library

Replace manual `if` checks with `testify/assert` assertions:

```go
import (
    "testing"
    "github.com/stretchr/testify/assert"
)

// Common assertions:
// assert.Error(t, err)                          - Checks error occurred
// assert.NoError(t, err)                        - Checks no error
// assert.Equal(t, expected, actual)             - Checks equality
// assert.True(t, condition)                     - Checks boolean true
// assert.False(t, condition)                    - Checks boolean false
// assert.Nil(t, value)                          - Checks nil
// assert.NotNil(t, value)                       - Checks not nil
// assert.Contains(t, str, substring)            - Checks substring
// assert.Len(t, list, expectedLen)              - Checks length
```

### Before/After Example
```go
// Before: Manual if checks
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

// After: testify/assert
func Test_given_invalid_input_when_processing_then_error(t *testing.T) {
    sut, _ := setupProcessor(t)
    _, err := sut.Process(context.Background(), request)
    
    assert.Error(t, err)
    assert.Contains(t, err.Error(), "invalid")
}
```

## Phase 4: Mock Improvements
```go
type SaveTelemetryMock struct {
    Saved []Telemetry
    CallCount int
    ReturnError error
}

func (m *SaveTelemetryMock) Save(ctx context.Context, t Telemetry) error {
    m.CallCount++
    m.Saved = append(m.Saved, t)
    return m.ReturnError
}

func (m *SaveTelemetryMock) AssertCalledWith(t *testing.T, expected Telemetry) {
    assert.NotEmpty(t, m.Saved, "expected Save to be called")
    last := m.Saved[len(m.Saved)-1]
    assert.Equal(t, expected, last)
}
```

## Phase 5: Test Organization

### File Size Rule (MANDATORY)
**Test files MUST NOT exceed 150 lines.** Split when limit is reached.

```
tests/
  [module]/
    [feature]_test.go                    # Main tests (≤150 lines)
    [feature]_edge_cases_test.go         # Edge case tests (≤150 lines)
    [feature]_integration_test.go        # Integration tests (≤150 lines)
    helpers.go                           # Assertion helpers
    builders.go                          # Test data builders
    testdata/                            # Test data files
```

### Splitting Strategy
```go
// When file exceeds 150 lines, split by:
// 1. Scenario (happy path, edge cases, errors)
// 2. Method/operation being tested
// 3. Integration vs unit tests

// Example:
// process_message_test.go           (happy path, ~100 lines)
// process_message_errors_test.go    (error cases, ~80 lines)
// process_message_edge_cases_test.go (edge cases, ~90 lines)
```

## Phase 6: Edge Case Testing
```go
func Test_edge_cases(t *testing.T) {
    cases := []struct{
        name string
        setup func() (*Processor, TelemetryRequest)
        expectedError string
    }{
        {"nil context", setupProcessorAndRequest, "context"},
        {"timeout context", setupWithTimeout, "deadline exceeded"},
    }
    
    for _, tc := range cases {
        t.Run(tc.name, func(t *testing.T) {
            sut, request := tc.setup()
            _, err := sut.Process(nil, request)
            assert.Error(t, err)
            assert.Contains(t, err.Error(), tc.expectedError)
        })
    }
}
```

## Phase 7: Performance Testing
```go
func BenchmarkProcessing(b *testing.B) {
    sut, _ := setupProcessor(b)
    request := aTelemetryRequest().Build()
    
    b.ResetTimer()
    for i := 0; i < b.N; i++ {
        sut.Process(context.Background(), request)
    }
}
```

## Phase 8: Quality Validation
```bash
go test -v -cover ./...
go test -race ./...
go test -bench=. ./...
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
    data := aTelemetryRequest().Build()
    
    // Act
    err := sut.Process(context.Background(), data)
    
    // Assert
    assert.NoError(t, err)
    assert.Len(t, mocks.repo.Saved, 1)
}
```

### Manual If Checks → Assertion Helpers
```go
// Before: Manual if statements
if err == nil {
    t.Fatalf("expected error")
}
if result.Success != true {
    t.Fatalf("expected success")
}

// After: testify/assert
assert.Error(t, err)
assert.True(t, result.Success)
```

### Repeated Assertions → Single Focused Tests
```go
// Before: Same assertion in multiple tests
func Test_scenario_1(t *testing.T) {
    // ...
    if err == nil { t.Fatal("expected error") } // Repeated!
}

func Test_scenario_2(t *testing.T) {
    // ...
    if err == nil { t.Fatal("expected error") } // Repeated!
}

// After: Each test verifies unique behavior
func Test_given_empty_id_when_validating_then_returns_error(t *testing.T) {
    // Arrange
    data := aTelemetryRequest().WithMessageID("").Build()
    
    // Act
    err := validate(data)
    
    // Assert
    assert.Error(t, err)
    assert.Contains(t, err.Error(), "message ID")
}

func Test_given_negative_speed_when_validating_then_returns_error(t *testing.T) {
    // Arrange
    data := aTelemetryRequest().WithSpeed(-1).Build()
    
    // Act
    err := validate(data)
    
    // Assert
    assert.Error(t, err)
    assert.Contains(t, err.Error(), "speed")
}
```

### Unstable Test Data → Stable Constants
```go
// Before: Unstable data
func Test_processing(t *testing.T) {
    data := Request{
        ID: uuid.New().String(),        // Changes every run!
        Timestamp: time.Now(),          // Changes every run!
    }
}

// After: Stable constants
const testRequestID = "test-req-123"

func Test_processing(t *testing.T) {
    data := Request{
        ID: testRequestID,
        Timestamp: time.Date(2024, 1, 1, 12, 0, 0, 0, time.UTC),
    }
}
```

### Large File → Split Files
```go
// Before: Single 300-line test file
// process_message_test.go (300 lines) ❌

// After: Split into focused files
// process_message_test.go (120 lines) ✅
// process_message_errors_test.go (90 lines) ✅
// process_message_integration_test.go (80 lines) ✅
```

## Safety Checks
- Tests pass before refactoring
- Small incremental changes
- Preserve test coverage
- Maintain test isolation

## Stop When
- ✅ Tests use `given_when_then` naming in snake_case
- ✅ Test data uses builders with stable defaults
- ✅ `testify/assert` replaces manual `if` checks
- ✅ All test files ≤150 lines (MANDATORY)
- ✅ No repeated assertions across tests
- ✅ Edge cases covered
- ✅ Tests isolated and fast
- ✅ Coverage maintained/improved
- ✅ No hardcoded timestamps, IDs, or changing values