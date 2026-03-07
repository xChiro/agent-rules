---
trigger: model_decision
description: Use TDD/ATDD methodology for Go testing with Given/When/Then narrative and AAA structure
globs: 
---

# Go TDD / ATDD Rules

Testing Philosophy:
- Tests drive design.
- Write tests before implementation.
- Focus on behavior, not implementation.

Test Style:
- ATDD narrative: Given / When / Then.
- Internal structure: AAA.

Structure:

// Arrange
// Act
// Assert

Rules:
- One System Under Test per test.
- One action in Act section.
- No logic inside Assert.

Test Order:
1. Edge cases
2. Invalid inputs
3. Boundary conditions
4. Happy paths

Naming:

Test<Method>_<Condition>_<ExpectedResult>

Example:
TestConfirmOrder_WithNoItems_ShouldReturnError

Assertions:
- Assert a single behavior per test.
- Prefer explicit checks.

Isolation:
- Use fakes or mocks for external dependencies.
- Never test infrastructure in unit tests.

Coverage Target:
- Domain layer ~100%
- Application layer high coverage
- Infrastructure minimal unit tests

Test Size:
- Small tests.
- Fast execution.
- Deterministic outcomes.

## Test Code Example
```go
package rules

import "testing"

func TestConfirmOrder_WithNoItems_ShouldReturnError(t *testing.T) {

	// Arrange
	order := NewOrder("order-1")

	// Act
	err := order.Confirm()

	// Assert
	if err == nil {
		t.Fatal("expected error when confirming empty order")
	}
}

func TestConfirmOrder_WithItems_ShouldConfirmOrder(t *testing.T) {

	// Arrange
	order := NewOrder("order-1")
	order.AddItem("product-1", 1)

	// Act
	err := order.Confirm()

	// Assert
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	if order.Status() != "confirmed" {
		t.Fatal("order should be confirmed")
	}
}
```
