---
rule_id: RULE-GO_SOLID_DESIGN
trigger: model_decision
description: "Go SOLID principles for Clean Architecture projects"
globs: "**/*.go"
---

# Go SOLID Design

## SDD Integration

Apply `RULE-COMMON_SDD_AGENTIC_DISCIPLINE` before this design specialization. SOLID informs each opened layer but never replaces common test-first gates, YAGNI, or convergence.


SOLID principles applied to Go following Clean Architecture definitions.

Apply SOLID through idiomatic Go: small packages, explicit dependencies, composition, focused interfaces, and YAGNI. Do not add abstractions only to look object-oriented.

## Single Responsibility Principle (SRP)

**Definition (Uncle Bob, Clean Architecture)**: A module should be responsible to one, and only one, actor.

### Method-Level Cohesion
Methods should be cohesive and should not mix unrelated actors, policies, layer concerns, or side effects. Do not interpret SRP as a rule that every method must contain only one operation or that every multi-step workflow must be split into artificial helpers.

**Violations**:
- ❌ `validateAndExtractData()` - Validates AND extracts (2 responsibilities)
- ❌ `createAndSaveEntity()` - Creates AND persists (2 responsibilities)
- ❌ `processAndNotify()` - Processes AND notifies (2 responsibilities)

**Correct Examples**:
- ✅ `validateData()` - Only validates (1 responsibility)
- ✅ `extractData()` - Only extracts (1 responsibility)
- ✅ `createEntity()` - Only creates (1 responsibility)
- ✅ `saveEntity()` - Only persists (1 responsibility)
- ✅ `processData()` - Only processes (1 responsibility)
- ✅ `sendNotification()` - Only notifies (1 responsibility)

**Senior Interpretation**:
- Do not split a cohesive function only because it validates, transforms local data, and returns a value.
- Split when different actors, policies, layer concerns, side effects, or reusable domain concepts are mixed; the SRP decision belongs primarily at the module/type boundary.
- Prefer a clear 25-line cohesive function over five vague helpers that hide the workflow.

### Actor Definition
Any entity that needs the system to change:
- **People**: Users, administrators, customers, stakeholders
- **Systems**: External APIs, databases, message queues, third-party services
- **Standards**: Compliance requirements, security standards, protocols
- **Processes**: Business workflows, automated tasks, scheduled jobs
- **Hardware**: Devices, sensors, infrastructure components

### Key Concepts
- **Module**: Any cohesive unit of code (function, class, package, microservice)
- **One Actor**: Each module serves needs of only one stakeholder entity
- **Change Reasons**: Module has only one reason to change, driven by one actor
- **Method Focus**: Each method is cohesive and supports the responsibility of its owning module; SRP is evaluated by actor and reason to change, not by method length or statement count.

### Examples

**Violation**: `Member` class with `calculatePay()` (accounting system) and `reportHours()` (reporting system)
**Correct**: Separate `PayCalculator` (accounting) and `HoursReporter` (reporting)

**Violation**: `OrderProcessor` with `saveToDatabase()` (database) and `sendEmailNotification()` (email system)
**Correct**: Separate `OrderRepository` (database) and `OrderNotificationService` (email)

**Violation**: `UserValidator` with `validateEmailFormat()` (email standard) and `checkCompliance()` (GDPR standard)
**Correct**: Separate `EmailFormatValidator` (email) and `GDPRComplianceChecker` (GDPR)

**Violation**: `DataProcessor` with `encryptForStorage()` (security) and `logForAudit()` (audit system)
**Correct**: Separate `EncryptionService` (security) and `AuditLogger` (audit)

## Open/Closed Principle (OCP)

Software entities should be open for extension but closed for modification.

### Rules
- Use interfaces and abstractions only where current variation exists or a boundary must be protected
- Prefer composition over inheritance-style embedding
- Add extension points when a second real implementation, plugin boundary, transport, persistence adapter, or domain strategy exists
- Do not create speculative interfaces for hypothetical future processors

### Example
```go
// ✅ Open for extension via interface when there are real implementations
type PaymentProcessor interface {
    Process(amount float64) error
}

type CreditCardProcessor struct{}
func (c *CreditCardProcessor) Process(amount float64) error { /* ... */ }

type PayPalProcessor struct{}
func (p *PayPalProcessor) Process(amount float64) error { /* ... */ }

// Add new processors without modifying existing orchestration
```

```go
// ✅ Simpler when pure policy has no current variation or external boundary
type FeeCalculator struct{}

func (FeeCalculator) Calculate(subtotal int64) int64 {
    return subtotal / 100
}
```

## Liskov Substitution Principle (LSP)

Subtypes must be substitutable for their base types without altering correctness.

### Rules
- Interface contracts must be honored by all implementations
- Avoid breaking expected behavior when using polymorphism
- Implementations should not weaken preconditions or strengthen postconditions
- Use shared unit-test examples for substitutable port behavior; verify real adapter wiring through HTTP integration rather than a separate contract suite

### Example
```go
// ✅ All implementations honor the contract
type Repository interface {
    Save(ctx context.Context, entity Entity) error
}

// Both implementations can substitute each other
type SQLRepository struct{}
func (r *SQLRepository) Save(ctx context.Context, entity Entity) error { /* ... */ }

type MongoRepository struct{}
func (r *MongoRepository) Save(ctx context.Context, entity Entity) error { /* ... */ }
```

## Interface Segregation Principle (ISP)

Clients should not depend on interfaces they don't use.

### Rules
- Keep interfaces small and focused on specific needs
- Prefer multiple specific interfaces over one large interface
- One interface per file (CQRS pattern)
- Define interfaces near the consumer, not next to the provider by default
- Do not introduce an interface only to wrap a single private helper

### Example
```go
// ❌ Fat interface - clients forced to depend on unused methods
type Repository interface {
    Save(ctx context.Context, entity Entity) error
    FindByID(ctx context.Context, id string) (*Entity, error)
    Delete(ctx context.Context, id string) error
    Update(ctx context.Context, entity Entity) error
    List(ctx context.Context) ([]*Entity, error)
}

// ✅ Segregated interfaces - clients depend only on what they use
type SaveCommand interface {
    Execute(ctx context.Context, entity Entity) error
}

type FindByIDQuery interface {
    Execute(ctx context.Context, id string) (*Entity, error)
}

type DeleteCommand interface {
    Execute(ctx context.Context, id string) error
}
```

## Dependency Inversion Principle (DIP)

High-level modules should not depend on low-level modules. Both should depend on abstractions.

### Rules
- Depend on interfaces at real boundaries: persistence, messaging, external APIs, clocks, sessions, and transport adapters
- Use concrete types inside a package when no substitution or boundary exists
- Define interfaces in the application layer or near consumers
- Implement interfaces in the infrastructure layer
- Abstractions should not depend on details; details depend on abstractions

### Example
```go
// ✅ High-level use case depends on abstraction
type MemberEnroller struct {
    createCmd commands.CreateMemberCommand  // Interface
    validator validation.ValidateUniqueness // Interface
}

// ❌ High-level use case depends on concrete implementation
type MemberEnrollerWithConcreteDependency struct {
    repo *SQLMemberRepository  // Concrete type - violates DIP
}
```

## SOLID in Clean Architecture

### Layer Dependencies
```
Infrastructure → Application → Domain
```

**Domain**: Pure business logic, no dependencies on outer layers
**Application**: Depends on domain interfaces, defines ports
**Infrastructure**: Implements application/domain interfaces

### SOLID Application
- **SRP**: Each layer serves one actor (domain=business, application=use cases, infrastructure=technical)
- **OCP**: Extend via new implementations without modifying existing code
- **LSP**: All repository implementations are substitutable
- **ISP**: Small CQRS interfaces (commands/queries/validation)
- **DIP**: Application depends on interfaces, infrastructure implements them

## Best Practices

**Apply SOLID when**:
- Designing new modules or refactoring existing ones
- Creating interfaces and abstractions
- Organizing code into layers
- Implementing CQRS patterns

**Avoid SOLID theater**:
- Interfaces with one implementation and no boundary
- Generic repositories created before multiple real use cases need them
- Factories/builders for simple constructors
- Layers that only pass calls through without owning behavior
- Splitting files or functions until the workflow becomes harder to read

**Benefits**:
- Maintainable and testable code
- Flexible architecture that adapts to change
- Clear separation of concerns
- Reduced coupling between modules
