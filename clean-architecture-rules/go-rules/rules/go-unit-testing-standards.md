---
trigger: model_decision
description: when working with unit test
globs: 
---

# Go Unit Testing Standards - CQRS Enhanced with YAGNI

**Principles**: TDD-first, Red-Green-Refactor, behavior over implementation, isolation, deterministic, YAGNI testing

## Test Structure

**Naming**: `Test_given_[scenario]_when_[action]_then_[expected]` (snake_case)
**Template**: Arrange → Act → Assert
**Organization**: `tests/{domain}/application/{use_case}/{usecase_test.go, mocks/}`

## Anti-Patterns

**One-Class-One-Test**: Don't create separate test files per domain class. Test through use cases covering complete workflows.

**Domain Entity Testing**: Don't test entities directly. Test implicitly through use case tests.

**Loop-Based Testing**: Don't use loops for multiple scenarios. Write individual test functions per scenario.
- Exceptions: Theory-style tests, character validation, performance benchmarks

## TDD Workflow

1. **Red**: Write failing test
2. **Green**: Minimal code to pass
3. **Refactor**: Clean up

## Quality Standards

**Requirements**: ≤150 lines/file, ≤20 lines/function, use `testify/assert`, single assertion concept
**YAGNI**: Test current functionality only, delete unused tests, focus on critical paths, simple setup

## CQRS Mock Strategy

**Guidelines**: One per interface, exported fields for config/verification, mock only outgoing ports
**Structure**: `tests/{domain}/application/{use_case}/mocks/mock_{interface}.go`

```go
type MockCreateMemberCommand struct {
    Error error
    Calls []CreateMemberCall
}

func (m *MockCreateMemberCommand) Execute(ctx context.Context, member domain.Member) error {
    m.Calls = append(m.Calls, CreateMemberCall{Member: member})
    return m.Error
}
```

## Testing Patterns

```go
// Use Case Test
func Test_given_valid_data_when_enrolling_member_then_success(t *testing.T) {
    createCmd := &MockCreateMemberCommand{}
    validateCmd := &MockValidateMemberUniqueness{Result: true}
    useCase := NewEnrollMemberUseCase(createCmd, validateCmd)
    
    response, err := useCase.Execute(ctx, request)
    
    assert.NoError(t, err)
    assert.NotEmpty(t, response.MemberID)
    assert.Len(t, createCmd.Calls, 1)
}

// Test Data Builder
func NewTestMember() *domain.Member {
    handlerName, _ := domain.NewHandlerName("test-handler")
    externalID := domain.NewExternalIdentifier("test-id", "test-provider")
    return domain.NewMember(handlerName, externalID)
}
```

## Quality Gates

All tests pass, ≥80% coverage, no race conditions, static analysis passes

## Best Practices

**Test Design**: TDD (failing test first), test behavior not implementation, descriptive names (ATDD), simple tests
**CQRS Mocks**: One per interface, mock only external dependencies, simple manual mocks, verify interactions
**Organization**: Group by use case, mirror production structure, test data builders, ≤150 lines
**CQRS Testing**: Commands (write ops), Queries (read ops), Validation (business rules), Integration (real infrastructure)
**YAGNI**: Test current functionality, delete unused tests, critical paths, simple setup

Ensures comprehensive, maintainable, reliable unit test coverage for Go applications following CQRS, Clean Architecture, YAGNI, and Screaming Architecture.
