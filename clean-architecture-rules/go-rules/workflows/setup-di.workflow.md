---
description: 
---

# Workflow: /setup-di

Use this workflow to create or update dependency injection setup functions for a given layer. When the user issues `/setup-di <layer>`, build the appropriate `Setup` function that wires together dependencies according to clean architecture.

## Description

For the specified `<layer>` (`domain`, `application`, `infrastructure` or `interfaces`), generate or refine a `Setup` function that constructs objects, accepts explicit dependencies, validates configuration, and returns the fully wired component without side effects. This function is critical for managing object lifetimes and enabling testability through manual wiring.

## Steps

1. **Determine the layer**: Identify which layer’s setup is being requested:
   - **Domain**: Provides pure domain services and value objects.
   - **Application**: Orchestrates domain services and ports.
   - **Infrastructure**: Instantiates concrete implementations (database, message bus, external clients).
   - **Interfaces**: Configures servers/handlers that expose the application.
2. **Identify required dependencies**: Inspect the constructors in the layer to determine what dependencies must be provided (repositories, event buses, configuration values, etc.).
3. **Define the Setup function signature**:
   - Use the pattern `func Setup<Layer>(args ...) (<ReturnType>, error)`.
   - Accept dependencies explicitly as parameters or via a config struct. Do not use global variables.
4. **Construct objects**:
   - Instantiate concrete implementations or domain services as needed.
   - Wire interfaces to implementations, passing mocks when testing.
5. **Validate configuration**:
   - Check that required configuration values (e.g., connection strings) are non‑empty.
   - Return descriptive errors for invalid configuration. Do not panic.
6. **Avoid side effects**:
   - Do not start background goroutines or open network listeners in the setup function.
   - Provide a separate `Start()` method on the returned component to begin processing.
7. **Return the result**: Return the fully constructed object or component along with any error encountered. The caller (e.g., `main.go` or tests) will be responsible for invoking `Start()` or similar methods.

## Guidelines

- Respect the naming conventions: `Setup<Layer>` for layers or `Setup<Subsystem>` for specific subsystems.
- Keep each setup file under 150 lines. Extract helper functions when necessary.
- Adhere to the DI principles described in `go-di.rules.md`: explicit dependencies, idempotent registration, and clear lifetimes.
- When using Google Wire optionally, define provider sets and generator files separate from the manual setup to maintain clarity.