---
description: 
---

# Workflow: /create-tdd-add-test

Use this workflow to generate the initial failing test for a new use case. When the user issues `/create-tdd-add-test <use_case>`, follow these steps:

## Description

Generate a **failing ATDD test** for the specified `<use_case>` following the TDD‑first strategy. The test should describe the desired behaviour using the `given_when_then` pattern in snake_case. It should cover the smallest edge case first and use manual mocks for outgoing dependencies.

## Steps

1. **Identify the actor and responsibility** of the use case. Document who is initiating the action and what outcome they expect.
2. **Create a new test file** in the appropriate package under `internal/<module>/` or `cmd/<service>/` (e.g., `<use_case>_test.go`).
3. Define the test function with a name matching `Test_given_<condition>_when_<action>_then_<expected>()`. Use `t *testing.T` as the parameter.
4. In the **Arrange** section:
   - Instantiate manual mocks for outgoing interfaces (repositories, message buses) as defined in your `mocks` package.
   - Construct the System Under Test (`sut`) using the appropriate constructor and injected mocks.
   - Prepare input data representing the edge condition (e.g., invalid ID, empty list).
5. In the **Act** section, call exactly **one method** or function on the `sut` with the prepared inputs.
6. In the **Assert** section, verify the expected outcome (error returned, no side effects, etc.). Use `t.Fatalf` or `t.Errorf` to fail the test with meaningful messages.
7. Ensure the test file remains under **150 lines** and functions under **20 lines**.
8. Do not implement production code yet. Commit the failing test and proceed to the `/create-use-case` or `/create-domain-entity` workflow for implementation.

## Guidelines

- Follow the **ATDD naming** conventions and structure described in `go-tdd-atdd.rules.md`.
- Use manual mocks as described in `go-di.rules.md` and the extended example for reference.
- Keep tests deterministic: avoid time‑based flakiness or external dependencies.
- Use an assertions library instead of if statements to handle assertions.
