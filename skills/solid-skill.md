# SOLID Skill

## Purpose

Use this skill when creating, reviewing, or refactoring object-oriented code.

The goal is to keep the design flexible, understandable, testable, and resistant to unnecessary change.

## Core Rules

### Single Responsibility Principle

A module should have one reason to change, based on one actor or stakeholder group.

The agent must identify who requests the change before deciding whether a responsibility belongs in the same module.

### Open/Closed Principle

Software entities should be open for extension and closed for modification.

Prefer adding new behavior through abstractions or composition instead of modifying stable code repeatedly.

### Liskov Substitution Principle

Subtypes must be safely replaceable for their base types.

Do not create inheritance hierarchies where derived classes weaken contracts, throw unexpected exceptions, or change expected behavior.

### Interface Segregation Principle

Clients should not depend on methods they do not use.

Prefer small, role-focused interfaces.

### Dependency Inversion Principle

High-level policies must not depend on low-level details.

Both should depend on abstractions owned by the policy that needs them.

## Review Checklist

- Does each class/module have one clear reason to change?
- Are responsibilities split by actor, not by technical convenience?
- Are abstractions stable and meaningful?
- Are interfaces small and client-focused?
- Is inheritance safe and behaviorally consistent?
- Are high-level rules protected from low-level details?

## Output Expectations

When reviewing code, report:

- The violated principle.
- The reason for change or actor involved.
- The concrete risk created by the violation.
- A minimal refactoring proposal.
