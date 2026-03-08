---
trigger: always_on
description: 
globs: 
---

# Go TDD & ATDD Guidelines

These rules define how to apply **Test‑Driven Development (TDD)** and **Acceptance Test‑Driven Development (ATDD)** in Go. They draw inspiration from Uncle Bob’s guidance and adapt the patterns described in the provided Onnodo project guidelines to Go’s testing idioms.

## Fundamental Principles

1. **Red‑Green‑Refactor Cycle**: Always begin with a failing test. Write just enough test code to demonstrate a missing behaviour (Red). Implement the simplest code to make the test pass (Green). Then refactor to improve structure without changing behaviour (Refactor).
2. **ATDD naming**: Name your test functions using the `given_when_then` pattern in **snake_case** to describe the precondition, action and expected outcome. For example:

```go
func Test_given_valid_input_when_process_telemetry_then_persists_to_repository(t *testing.T) { /* … */ }
```

3. **Edge cases first**: Start by testing edge cases (invalid input, empty collections, missing entities) before moving to happy paths. This “golden step” strategy ensures robustness.
4. **AAA / GWT structure**: Organise tests into three clearly separated sections:
   - `// Arrange`: Create test data, configure mocks or fakes and the System Under Test (SUT).
   - `// Act`: Perform exactly **one call** on the SUT. No other work belongs in this section.
   - `// Assert`: Verify the observable behaviour. Use assertions to check results or interactions.
5. **SUT naming**: Always name the variable holding the System Under Test `sut` (lowercase). Keep the SUT obvious (one struct or function). Dependencies should be injected via interfaces.
6. **One reason to fail**: Each test should check a single behavioural aspect. Avoid asserting multiple unrelated outcomes; split into separate tests if needed.

## Test Types and Scopes

- **Unit Tests**: Exercise functions or methods in isolation. For domain and application layers, avoid touching infrastructure: no database connections, file system or network access. Use fakes or manual mocks for outgoing interfaces.
- **Integration Tests**: Verify wiring between layers and integration with real infrastructure (database, message bus, HTTP server). These tests may live in a separate `_integration_test.go` file or a dedicated package.
- **Table‑Driven Tests**: For functions with multiple input/output combinations, use table‑driven tests. Define a slice of test cases and iterate over them using subtests (`t.Run`).

## Mocking Guidelines

- **Manual mocks**: Create small structs that implement the required interface. Capture inputs via fields and return preset values. Place them in a `/internal/mocks` or `/test/mocks` package.
- **Only mock outgoing ports**: Mock interfaces for external systems (e.g., repositories, message buses). Do not mock value objects, entities or domain logic; use real implementations for those.
- **Simple fakes over dynamic mocks**: Prefer simple fakes or spies implemented by hand. Avoid deep mocking frameworks. Fakes often lead to clearer tests and expose the contract better.
- **Configure behaviour via fields**: Use exported fields to set return values or errors and to capture what the SUT calls. For example:

```go
type SaveTelemetryMock struct {
    Recorded []Telemetry
    Err      error
}

func (m *SaveTelemetryMock) Save(ctx context.Context, t Telemetry) error {
    m.Recorded = append(m.Recorded, t)
    return m.Err
}
```

## Test Organisation

- **File names**: Test files end with `_test.go`. Keep each test file under **150 lines**. When a use case requires many tests, split them into separate files grouped by scenario or method.
- **Test package**: Place tests in the same package as the code under test for unexported access (`package telemetry`). You may use a separate `package telemetry_test` to write black‑box tests when only public API is needed.
- **Helper functions**: Extract repetitive setup or assertions into helper functions in test files or a `testutils` package.

## Avoiding Fragile Tests

- **Avoid repeated assertions across tests**: Don't assert the same condition in multiple test methods. Each assertion should verify a unique aspect of behavior in a single test.
- **Don't test implementation details**: Focus on observable behavior and outcomes, not internal implementation. Tests should break only when behavior changes, not when code is refactored.
- **Use stable test data**: Avoid hardcoded values that might change (timestamps, IDs, etc.). Use deterministic test data or generate it consistently.
- **Isolate tests**: Each test should be independent. Don't rely on state from other tests or external systems that might change.
- **Minimize external dependencies**: Mock or stub external services to avoid tests failing due to network issues, service downtime, or data changes.
- **Clear assertion messages**: Provide descriptive failure messages that explain what was expected and what was received.
- **One assertion per concept**: Group related assertions but avoid checking multiple unrelated concepts in a single assertion.

## Assertion Helpers

Use assertion helper functions to make tests more readable and provide better error messages. Define these helpers in your test files or a shared `testutils` package:

```go
// assertError checks that an error occurred
func assertError(t *testing.T, err error, message string) {
    t.Helper()
    if err == nil {
        t.Fatalf("%s: expected error but got nil", message)
    }
}

// assertNoError checks that no error occurred
func assertNoError(t *testing.T, err error) {
    t.Helper()
    if err != nil {
        t.Fatalf("unexpected error: %v", err)
    }
}

// assertEqual checks that two values are equal
func assertEqual[T comparable](t *testing.T, got, want T, message string) {
    t.Helper()
    if got != want {
        t.Fatalf("%s: got %v, want %v", message, got, want)
    }
}

// assertErrorContains checks that an error contains a specific message
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

## Example Unit Test

```go
// telemetry_processor_test.go
package telemetry

import (
    "context"
    "testing"
)

func Test_given_empty_deviceID_when_process_telemetry_then_error(t *testing.T) {
    // Arrange
    repo := &SaveTelemetryMock{} // manual mock implementing TelemetryRepository
    sut  := NewTelemetryProcessor(repo)

    // Act
    err := sut.Process(context.Background(), Telemetry{DeviceID: ""})

    // Assert
    assertError(t, err, "empty device ID should return error")
}

// SaveTelemetryMock is an example manual mock used only in tests.
type SaveTelemetryMock struct {
    Recorded []Telemetry
    Err      error
}

func (m *SaveTelemetryMock) Save(ctx context.Context, t Telemetry) error {
    m.Recorded = append(m.Recorded, t)
    return m.Err
}

```

## Extended Example: Registering a User

The following example demonstrates how to apply the guidelines to a simple registration use case. It includes a value object with validation, a domain interface, an application service and a manual mock used in tests.

```go
// Example of a application value object with validation
type Email struct {
    value string
}

func NewEmail(val string) (Email, error) {
    if val == "" || !containsAt(val) {
        return Email{}, errors.New("invalid email")
    }
    return Email{value: val}, nil
}

func containsAt(s string) bool {
    for _, r := range s {
        if r == '@' {
            return true
        }
    }
    return false
}

// Example interface in the application layer
type UserRepository interface {
    Save(ctx context.Context, email Email) error
    Exists(ctx context.Context, email Email) (bool, error)
}

// Example use case in the application layer
type UserRegistration struct {
    repo UserRepository
}

func NewUserRegistration(repo UserRepository) *UserRegistration {
    return &UserRegistration{repo: repo}
}

func (u *UserRegistration) Register(ctx context.Context, email Email) error {
    exists, err := u.repo.Exists(ctx, email)
    if err != nil {
        return err
    }
    if exists {
        return errors.New("user already exists")
    }
    return u.repo.Save(ctx, email)
}

// Manual mock implementing UserRepository for tests
type UserRepoMock struct {
    existing map[string]bool
    saved    []Email
    errOnSave error
}

func NewUserRepoMock() *UserRepoMock {
    return &UserRepoMock{existing: make(map[string]bool)}
}

func (m *UserRepoMock) Save(ctx context.Context, email Email) error {
    if m.errOnSave != nil {
        return m.errOnSave
    }
    m.saved = append(m.saved, email)
    return nil
}

func (m *UserRepoMock) Exists(ctx context.Context, email Email) (bool, error) {
    return m.existing[email.value], nil
}

// Example unit test using the mock
func Test_given_existing_email_when_register_then_error(t *testing.T) {
    // Arrange
    repo := NewUserRepoMock()
    repo.existing["test@example.com"] = true
    sut := NewUserRegistration(repo)
    email, _ := NewEmail("test@example.com")

    // Act
    err := sut.Register(context.Background(), email)

    // Assert
    assertErrorContains(t, err, "user already exists")
}

// Example happy path test
func Test_given_new_email_when_register_then_saves_user(t *testing.T) {
    // Arrange
    repo := NewUserRepoMock()
    sut := NewUserRegistration(repo)
    email, _ := NewEmail("new@example.com")

    // Act
    err := sut.Register(context.Background(), email)

    // Assert
    assertNoError(t, err)
    assertEqual(t, len(repo.saved), 1, "should save exactly one email")
    assertEqual(t, repo.saved[0], email, "should save the correct email")
}
```

## Summary

Practising TDD and ATDD in Go means writing precise, expressive tests before production code. Use the `given_when_then` naming scheme, write one assertion per test, organise your tests with clear `Arrange`/`Act`/`Assert` sections, and create manual mocks for outgoing dependencies. Avoid fragile tests by focusing on behavior over implementation, using stable test data, and ensuring test isolation. These practices result in reliable, readable tests that guide your design and withstand refactoring.