---
trigger: always_on
description: 
globs: 
---

# Go Clean Code Guidelines

These rules define how to write **idiomatic, maintainable Go code**. They are adapted from Robert C. Martin’s *Clean Code* principles and tailored for Go’s simplicity. Follow them consistently to produce code that is easy for humans and AI coding agents to read, reason about and extend.

## Goals

- **Expressive code**: Names and structures clearly describe their purpose without redundant comments.
- **Small units**: Functions and methods do one thing, are short (preferably <20 lines), and avoid deep nesting.
- **Encapsulation**: Hide data and behavior that should not be exposed; expose only the minimum API needed.
- **Consistency**: Apply the same conventions across the project so that contributors can easily navigate the codebase.

## Naming Conventions

- **Packages**: Use short, lowercase names (e.g., `telemetry`, `order`). Avoid pluralization (`device` rather than `devices`).
- **Types**: Use PascalCase (e.g., `TelemetryProcessor`). For interfaces, name them by the behaviour they represent (e.g., `TelemetryRepository`). Avoid `Manager`/`Processor` unless it conveys the role clearly.
- **Variables**: Use lowerCamelCase (e.g., `deviceID`, `dbPool`, `ctx`). Keep names short but informative; prefer `cfg` over `configuration` and `err` for error values.
- **Constants**: Use PascalCase and group related constants into iota blocks where appropriate.
- **Avoid abbreviations** unless they are ubiquitous (e.g., `ID`, `URL`), and keep them consistent (always `ID` rather than mixing `Id` and `ID`).

## Functions & Methods

- **Do one thing**: Each function should perform a single operation. If you can describe what the function does with “and,” split it.
- **Small size**: Aim for 20 lines or less per function. Break down complex logic into helper functions within the same package.
- **Prefer small, well-named functions**: Choose small, well-defined, and clearly named functions over large monolithic ones. Small functions are easier to understand, test, and reuse.
- **Clear parameters**: Pass only what the function needs. Avoid long parameter lists; use structs when more than three parameters are required.
- **Return errors**: In Go, error handling is explicit. Return `error` as the last return value. Do not use exceptions or panic for expected errors.
- **Handle errors early**: Check and return errors as soon as possible (guard clauses). Avoid deep indentation by returning early.
- **No redundant comments**: Write code that documents itself via names. Only add comments to explain *why* something is done or to warn about surprising behavior; remove “obvious” comments.

## File Structure

- **File size**: Keep each file under **150 lines** (including imports and comments). If a file grows beyond this, extract types or functions into separate files (Mandatory, Not negotiable).
- **One type per file**: When reasonable, define one high-level type or concept per file. Group related small types (e.g., several value objects) together if they are tightly coupled.
- **Top-level declarations**: Order code as follows: package documentation/comment, imports, constants, types, variables, then functions/methods.

## Error Handling

- **Explicit errors**: Always handle errors returned by functions. Do not ignore them (`_ = foo()`); log or propagate them appropriately.
- **Sentinel errors**: Define package-level variables for common error conditions (e.g., `var ErrNotFound = errors.New("entity not found")`). Prefer `errors.Is` to compare them.
- **Wrapping**: Wrap errors using `fmt.Errorf("context: %w", err)` to add context while preserving the original error for inspection.
- **No panics**: Reserve `panic` for unrecoverable programmer errors (e.g., invariant violations). Business logic should return errors instead.

## Data Structures & Types

- **Value Objects**: Represent immutable domain concepts as structs with unexported fields and exported constructor functions that validate input.
- **Entities**: For mutable domain objects with identity, export only methods that maintain invariants. Keep internal state private.
- **Collections**: Do not expose slices or maps directly. Provide methods that copy or encapsulate internal collections (`Items()` returns a copy).
- **Context**: Pass `context.Context` as the first argument when a function performs I/O or has a cancellable lifetime.

## Refactoring

- **Two Hats**: Refactor only when tests are passing. Make one small change at a time and run tests frequently.
- **Eliminate duplication**: Extract common logic into functions or types. Prefer composition over inheritance (embedding in Go).
- **Favor composition**: Use embedding or interfaces to assemble behaviours instead of inheritance hierarchies.

## Formatting & Style

- **go fmt**: Always run `go fmt` on your code. Let automated tools handle spacing and alignment.
- **imports**: Group standard library imports separately from external packages. Avoid unnecessary imports.
- **Comments**: Use full sentences and proper punctuation. Place package-level comments above the package declaration. Exported identifiers should have comments describing their behavior.

## Summary

Adhering to these clean‑code guidelines helps keep your Go codebase expressive, modular and easy to maintain. Names are descriptive, functions are small, files are limited to 150 lines, and errors are handled explicitly. This foundation supports layered architectures, testability and readability.