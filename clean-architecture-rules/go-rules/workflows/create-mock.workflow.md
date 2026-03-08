# Workflow: /create-mock

Use this workflow to generate a manual mock for a given interface. When the user issues `/create-mock <interface>`, follow these instructions to create a deterministic mock that adheres to your DI and testing guidelines.

## Description

Generate a mock implementation of the specified `<interface>` for use in unit tests. The mock should live in the `*_test.go` package and implement all methods of the interface with simple fields to record inputs and configurable outputs or errors. It must not rely on any external mocking framework or reflection.

## Steps

1. **Locate the interface**: Identify the fully qualified name and package of `<interface>` within the domain or application layer. The mock will implement this interface.
2. **Create a new test helper file**: Place the mock in a file such as `mock_<interface>.go` under the corresponding test directory (e.g., `internal/<module>/mocks/`). Ensure the file is in the `_test` package so that it is only used in tests.
3. **Define the mock struct**:
   - Name the struct `<interface>NameMock` (e.g., `UserRepositoryMock`).
   - Include fields to capture each method’s input parameters (e.g., slices or simple variables) and fields to hold preconfigured return values or errors.
   - Optionally include counters to track how many times methods were called.
4. **Implement the interface**:
   - For each method in `<interface>`, implement a method on the mock that records the inputs into the corresponding fields and returns the preconfigured result or error.
   - Do not include any business logic or side effects.
5. **Expose configuration methods** (optional): Provide helper methods on the mock to set return values or errors before running tests.
6. **Write tests**: Use the newly created mock in unit tests to verify the behaviour of the system under test. Ensure you follow Arrange–Act–Assert with only one Act per test.

## Guidelines

- Manual mocks should not depend on third‑party mocking frameworks. Keep them plain Go structs implementing the interface.
- Store the mock code outside of the production package to avoid accidental inclusion in builds.
- Follow the naming and file structure conventions defined in your DI and clean‑architecture guidelines.
- Respect the 150‑line file limit: split the mock implementation across files if multiple interfaces are mocked.