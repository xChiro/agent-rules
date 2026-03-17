---
trigger: always_on
description: 
globs: 
---

# SOLID Principles for Go

SOLID principles applied to Go following Clean Architecture definitions.

## Single Responsibility Principle (SRP)

**Definition (Uncle Bob, Clean Architecture)**: A module should be responsible to one, and only one, actor.

### Method-Level SRP (CRITICAL REQUIREMENT)
**STRICT RULE**: Each method must perform exactly ONE operation/responsibility.

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
- **Method Focus**: Each method has exactly one reason to exist

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

### Guidelines
- Use interfaces and abstractions to allow behavior extension without changing existing code
- Prefer composition over inheritance for extending functionality
- Design for extension points without modifying core logic

### Example
```go
// ✅ Open for extension via interface
type PaymentProcessor interface {
    Process(amount float64) error
}

type CreditCardProcessor struct{}
func (c *CreditCardProcessor) Process(amount float64) error { /* ... */ }

type PayPalProcessor struct{}
func (p *PayPalProcessor) Process(amount float64) error { /* ... */ }

// Add new processors without modifying existing code
```

## Liskov Substitution Principle (LSP)

Subtypes must be substitutable for their base types without altering correctness.

### Guidelines
- Interface contracts must be honored by all implementations
- Avoid breaking expected behavior when using polymorphism
- Implementations should not weaken preconditions or strengthen postconditions

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

### Guidelines
- Keep interfaces small and focused on specific needs
- Prefer multiple specific interfaces over one large interface
- One interface per file (CQRS pattern)

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

### Guidelines
- Depend on interfaces, not concrete types
- Define interfaces in the application layer (near consumers)
- Implement interfaces in the infrastructure layer
- Abstractions should not depend on details; details depend on abstractions

### Example
```go
// ✅ High-level use case depends on abstraction
type EnrollMemberUseCase struct {
    createCmd commands.CreateMemberCommand  // Interface
    validator validation.ValidateUniqueness // Interface
}

// ❌ High-level use case depends on concrete implementation
type EnrollMemberUseCase struct {
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

**Benefits**:
- Maintainable and testable code
- Flexible architecture that adapts to change
- Clear separation of concerns
- Reduced coupling between modules