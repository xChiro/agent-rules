# Workflow: /create-use-case

This workflow guides the creation of a new application use case. When the user issues `/create-use-case <operation>`, follow the full sequence described below.

## Description

Implement a new use case named `<operation>` using the Clean Architecture layers. The workflow ensures that you start with requirements analysis, create failing tests, define ports, implement the orchestration, and finalise with refactoring. This mirrors the phased approach from the Onnodo use-case instructions.

## Steps

1. **Phase 1: Requirements Analysis**
   - Identify the **Actor** initiating `<operation>` and the core **Responsibility**. Document these details at the top of the test or in a `README` for future reference.
   - Check the 150‑line file limit; plan to split the work across files if necessary.

2. **Phase 2: Failing ATDD Test**
   - Use the `/create-tdd-add-test` workflow to generate the initial failing test for `<operation>` in the appropriate test package (`internal/<module>/_test.go`).
   - Use manual mocks for ports and follow the Arrange‑Act‑Assert structure.

3. **Phase 3: Port Definition**
   - Define any new interfaces (ports) required by `<operation>` in the application layer under `internal/application/<module>/`. Keep interfaces small and specific.

4. **Phase 4: Use Case Implementation**
   - Create request/response structs if needed.
   - Implement the use case struct or function in the application layer. Inject ports via constructor functions.
   - The use case should orchestrate domain logic but **not contain** business rules itself; delegate to domain entities or domain services.

5. **Phase 5: Manual Mock Implementation**
   - Create or update manual mock structs in your test/mocks directory to implement the new port interfaces.
   - Ensure mocks capture inputs and expose configurable outputs.

6. **Phase 6: Refactoring**
   - Once tests pass, refactor for readability. Respect file and function length limits.
   - Ensure names are clear and align with the guidelines in `go-clean-code.rules.md`.

## Guidelines

- Follow the phased structure outlined in `use-case-instruction.md`.
- Keep the use case free of direct infrastructure dependencies; depend only on interfaces.
- Use the DI setup functions defined in `go-di.rules.md` to wire concrete implementations in `cmd/<binary>/main.go`.