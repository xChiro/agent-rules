---
trigger: always_on
description: 
globs: 
---

# Go Use Case Implementation Protocol

When instructed to create a new Use Case, follow this exact sequence without deviation.

## Phase 1: Requirements Analysis
- Identify the **Actor** requesting the change
- Define the **Responsibility** of the new component
- Confirm it adheres to the 150-line file limit

## Phase 2: Failing ATDD Test (Red)
Create a test file in `tests/` using **snake_case** for the function names. Use **Manual Mocks** from the `mocks/` folder.

### Mandatory Requirements (Non-Negotiable)
- **Assertion library**: MUST use `github.com/stretchr/testify/assert` library instead of `if` statements for all assertions - this is non-negotiable

### Test Quality Guidelines
- **Avoid repeated assertions across tests**: Don't assert the same condition in multiple test methods
- **Test behavior, not implementation**: Focus on observable outcomes, not internal details
- **Use stable test data**: Avoid hardcoded timestamps, IDs, or values that might change
- **Clear failure messages**: Provide descriptive error messages that explain expected vs actual
- **One assertion per concept**: Group related assertions but avoid multiple unrelated checks

### Test Structure Template
```go
func Test_given_[condition]_when_[action]_then_[expected_result](t *testing.T) {
    // Arrange (Setup manual mocks)
    // Act (Execute Use Case)
    // Assert (Verify behavior)
}
```

## Phase 3: Port Definition
Define necessary interfaces (Ports) in the **Application** layer (`internal/application/[module]/ports/`).

## Phase 4: Use Case Implementation (Green)
1. Define the Request/Response structs (Application layer)
2. Implement the Use Case struct
3. **Important**: Business logic belongs in the **Domain Entity**, the Use Case only orchestrates

## Phase 5: Manual Mock Implementation
Update or create Manual Mocks in the test project to support the new Port.

## Phase 6: Refactoring (Blue)
Check for:
- 150-line limit
- 20-line function limit
- Meaningful names
- Layered dependency rules

## Example Workflow: Process Device Telemetry

### Phase 1: Analysis
- **Actor**: IoT Device
- **Responsibility**: Validate, evaluate and persist incoming telemetry

### Phase 2: Red Test
File: `tests/telemetry/processing/telemetry_processing_test.go`

```go
func Test_given_valid_telemetry_when_processed_then_record_data_successfully(t *testing.T) {
    // Arrange
    messageID := uuid.New().String()
    telemetryData := TelemetryProcessorRequest{
        MessageID:      messageID,
        DeviceID:       "device-123",
        Speed:          80,
        Position:       Position{Latitude: 45, Longitude: 90},
        GPSFixed:       true,
        DeviceTimestamp: time.Now(),
    }
    
    saveTelemetryMock := &SaveTelemetryMock{}
    getDeviceMock := &GetDeviceSettingMock{}
    sut := NewTelemetryProcessor(saveTelemetryMock, getDeviceMock, []TrackingEventEvaluator{})

    // Act
    result, err := sut.Process(context.Background(), telemetryData)

    // Assert
    asserts.True(t, err == nil, "unexpected error: %v", err)
    asserts.True(t, result.Success, "expected success, got failure")
    asserts.Equal(t, saveTelemetryMock.TelemetryRecorded.MessageID, messageID, "expected message ID %s, got %s", messageID, saveTelemetryMock.TelemetryRecorded.MessageID)
    asserts.Equal(t, saveTelemetryMock.TelemetryRecorded.DeviceID, "device-123", "expected device ID device-123, got %s", saveTelemetryMock.TelemetryRecorded.DeviceID)
}
```

### Phase 3: Port Definition
File: `internal/application/telemetry/ports/telemetry_repository.go`

```go
package ports

import "context"

type TelemetryRepository interface {
    Save(ctx context.Context, telemetry Telemetry) (ID, error)
}
```

### Phase 4: Implementation
File: `internal/application/telemetry/usecases/telemetry_processor.go`

```go
package usecases

import "context"

type TelemetryProcessor struct {
    saveTelemetry    ports.TelemetryRepository
    getDeviceSetting ports.GetDeviceSettingByDeviceID
    strategies       []TrackingEventEvaluator
}

func NewTelemetryProcessor(
    saveTelemetry ports.TelemetryRepository,
    getDeviceSetting ports.GetDeviceSettingByDeviceID,
    strategies []TrackingEventEvaluator,
) *TelemetryProcessor {
    return &TelemetryProcessor{
        saveTelemetry:    saveTelemetry,
        getDeviceSetting: getDeviceSetting,
        strategies:       strategies,
    }
}

func (tp *TelemetryProcessor) Process(ctx context.Context, data TelemetryProcessorRequest) (TelemetryProcessorResponse, error) {
    // 1. Fetch dependencies
    device, err := tp.getDeviceSetting.Execute(ctx, data.DeviceID)
    if err != nil {
        return TelemetryProcessorResponse{}, err
    }
    
    // 2. Create Domain Entity
    telemetry := NewTelemetry(
        data.MessageID,
        data.DeviceID,
        data.Speed,
        data.Position,
        data.GPSFixed,
        data.DeviceTimestamp,
    )

    // 3. Delegate logic to Entity (SRP)
    err = telemetry.Evaluate(device, tp.strategies)
    if err != nil {
        return TelemetryProcessorResponse{}, err
    }

    // 4. Persist via Port
    _, err = tp.saveTelemetry.Save(ctx, telemetry)
    if err != nil {
        return TelemetryProcessorResponse{}, err
    }

    return TelemetryProcessorResponse{
        Success: true,
        Events:  telemetry.Events(),
    }, nil
}
```

### Phase 5: Manual Mock
File: `tests/telemetry/mocks/save_telemetry_mock.go`

```go
package mocks

import "context"

type SaveTelemetryMock struct {
    TelemetryRecorded Telemetry
    SaveError         error
}

func (m *SaveTelemetryMock) Save(ctx context.Context, telemetry Telemetry) (ID, error) {
    m.TelemetryRecorded = telemetry
    if m.SaveError != nil {
        return ID{}, m.SaveError
    }
    return NewID(), nil
}
```

## Go-Specific Best Practices

### Naming Conventions
- **Files**: `snake_case.go` for implementation, `snake_case_test.go` for tests
- **Functions**: `CamelCase` for exported, `camelCase` for unexported
- **Test Functions**: `Test_given_condition_when_action_then_expected`
- **Structs**: `PascalCase` for exported types
- **Interfaces**: `PascalCase` describing behavior (e.g., `TelemetryRepository`)

### Error Handling
- Always return `error` as the last return value
- Use explicit error checking with `if err != nil`
- Wrap errors with context using `fmt.Errorf("operation: %w", err)`
- Define sentinel errors for common conditions

### Dependency Injection
- Use constructor functions `NewUseCase(dep1, dep2) *UseCase`
- Depend on interfaces, not concrete types
- Define interfaces in the application layer, implement in infrastructure

### Testing
- Use table-driven tests for multiple scenarios
- Manual mocks over heavy mocking frameworks
- Arrange/Act/Assert structure with clear comments
- Test edge cases before happy paths

### Clean Architecture Compliance
- **Domain**: Pure business logic, no external dependencies
- **Application**: Use cases, ports, and DTOs
- **Infrastructure**: Implementation of ports
- **Interfaces**: HTTP handlers, CLI commands

### File Organization
```
internal/
  domain/
    [module]/
      entity.go
      value_object.go
      repository.go  # Port interfaces
  application/
    [module]/
      usecases/
        use_case.go
      ports/
        repository.go
      requests.go    # DTOs
  infrastructure/
    [module]/
      repository_impl.go
  interfaces/
    http/
      handler.go

tests/
  [module]/
    usecase_test.go
    mocks/
      mock_repository.go
```

## Protocol Summary

This protocol ensures:

1. **TDD-First Development**: Always start with failing tests
2. **Clean Architecture Compliance**: Proper layer separation
3. **Domain-Driven Design**: Business logic in domain entities
4. **Manual Testing**: Simple, explicit mocks
5. **Code Quality**: Size limits and naming conventions
6. **Maintainability**: Clear structure and responsibilities

Follow this sequence exactly for consistent, high-quality use case implementations.
