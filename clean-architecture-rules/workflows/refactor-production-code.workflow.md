---
description: Refactor production code following Clean Architecture, SOLID, and YAGNI
---

# Production Code Refactoring Workflow

Improve maintainability while preserving behavior (see `go-clean-code-standards.md`, `go-solid-principles.md`).

## Requirements

**Critical Limits** (NON-NEGOTIABLE):
- Files ≤150 lines
- Functions ≤20 lines
- Each method must have exactly ONE responsibility (SRP strict)
- No unused code (YAGNI)
- Follow CQRS (one interface per file)
- Follow Screaming Architecture

## Phase 1: Prerequisites

- ✅ All tests passing
- ✅ Clear target identified
- ✅ Test coverage verified
- ✅ Baseline committed

## Phase 2: Analysis

**Identify**:
- Code smells (functions >20 lines, files >150 lines)
- Architecture violations (layer dependencies, SOLID)
- **SRP violations**: Methods with multiple responsibilities
- Duplication (repeated logic)
- Complexity (nested conditionals, long params)
- Standards violations (naming, error handling, DI)

## Phase 3: Refactoring Patterns

**Extract Method** (split long functions AND ensure single responsibility):
```go
// Before: Long function with mixed responsibilities (>20 lines)
func ProcessData() error {
    // validations, transformation, persistence, events...
}

// After: Split into focused methods (≤20 lines each, ONE responsibility each)
func ProcessData() error {
    if err := validateData(); err != nil { return err }
    data := transformData()
    if err := persistData(data); err != nil { return err }
    publishEvent(data)
    return nil
}

// ❌ WRONG: Still has mixed responsibilities
func validateAndTransform() error {
    // validation AND transformation (2 responsibilities)
}

// ✅ CORRECT: One responsibility each
func validateData() error {
    // Only validation (1 responsibility)
}
func transformData() error {
    // Only transformation (1 responsibility)
}
```
```

**Extract Function** (eliminate duplication):
```go
// Before: Duplicated validations
func (t *Type1) Validate() error { /* duplicate logic */ }
func (s *Type2) Validate() error { /* duplicate logic */ }

// After: Shared function
func ValidateCommon(id string, value float64, field string) error {
    if id == "" { return errors.New("ID required") }
    if value < 0 { return fmt.Errorf("%s cannot be negative", field) }
    return nil
}
```

**Replace Conditional with Polymorphism**:
```go
// Before: Complex switch
func Process(deviceType string, data Data) error {
    switch deviceType { /* many cases */ }
}

// After: Interface + implementations
type DeviceProcessor interface { Process(data Data) error }
type GPSProcessor struct{}
func (g *GPSProcessor) Process(data Data) error { /* ... */ }
```

**Extract Class** (split large structs):
```go
// Before: Large struct with many dependencies
type Service struct { repo, validator, transformer, eventBus, cache, logger, metrics ... }

// After: Focused structs
type Service struct { processor *Processor; publisher *Publisher; cache *Cache }
type Processor struct { repo, validator, transformer }
type Publisher struct { eventBus, logger }
```

**Decompose Conditional**:
```go
// Before: Complex condition
func CanPurchase(product Product) bool {
    if status == "active" && balance >= price && age >= 18 && !pending && inStock { return true }
}

// After: Extracted methods
func CanPurchase(p Product) bool {
    return isActive() && hasSufficientBalance(p.Price) && isAdult() && hasNoPending() && p.isAvailable()
}
```

## Phase 4: Clean Architecture

**Domain Purity**:
```go
// ✅ Pure domain (no infrastructure tags)
type Money struct { amount int64; currency string }

// ❌ Infrastructure in domain
type Money struct { amount int64 `json:"amount" db:"amount"` }
```

**Application Orchestration**:
```go
// ✅ Pure orchestration
func Execute(ctx context.Context, req Request) error {
    entity, err := repo.FindByID(ctx, req.ID)
    if err != nil { return err }
    if err := entity.Process(); err != nil { return err }
    return repo.Save(ctx, entity)
}
```

## Phase 5: Dependency Injection

**CQRS Interfaces** (see `go-dependency-injection.md`):
```go
// Define in application (one per file)
type CreateOrderCommand interface { Execute(ctx context.Context, order Order) error }
type GetOrderByID interface { Execute(ctx context.Context, id string) (*Order, error) }

// Implement in infrastructure
type SQLOrderRepository struct { db *sql.DB }
```

**Constructor Injection**:
```go
func NewOrderProcessor(createCmd CreateOrderCommand, getQuery GetOrderByID) *OrderProcessor {
    return &OrderProcessor{createCmd: createCmd, getQuery: getQuery}
}
```

## Phase 6: Error Handling

```go
// Domain errors (in errors.go)
var ErrNotFound = errors.New("not found")
var ErrInvalidStatus = errors.New("invalid status")

// Wrap with context
func Save(ctx context.Context, entity Entity) error {
    if err := db.Save(entity); err != nil {
        return fmt.Errorf("failed to save %s: %w", entity.ID, err)
    }
    return nil
}
```

## Phase 7: Validation

**Tests** (behavior preservation):
```go
func Test_refactored_behavior_preserved(t *testing.T) {
    original := originalImpl(input)
    refactored := refactoredImpl(input)
    assert.Equal(t, original, refactored)
}
```

**Quality Checks**:
```bash
go test ./...                                           # All tests pass
go fmt ./... && go vet ./...                           # Code quality
find . -name "*.go" -exec wc -l {} \; | awk '$1 > 150' # File sizes
```

## Phase 8: Performance

**Algorithm Optimization**:
```go
// Before: O(n²)
func findDuplicates(items []string) []string {
    for i, item1 := range items {
        for j, item2 := range items { /* nested loop */ }
    }
}

// After: O(n) with map
func findDuplicates(items []string) []string {
    seen := make(map[string]bool)
    for _, item := range items {
        if seen[item] { /* ... */ } else { seen[item] = true }
    }
}
```

## Common Scenarios

**Long Function**: Split >20 lines into focused methods
**Large File**: Split >150 lines by responsibility/feature
**Magic Numbers**: Replace with named constants
**Duplication**: Extract to shared functions
**Complex Conditionals**: Extract to methods

## Success Criteria

- ✅ All tests pass (behavior preserved)
- ✅ Files ≤150 lines (MANDATORY)
- ✅ Functions ≤20 lines
- ✅ Each method has exactly ONE responsibility (SRP strict)
- ✅ Clean Architecture boundaries respected
- ✅ SOLID principles followed (see `go-solid-principles.md`)
- ✅ CQRS compliance (one interface per file)
- ✅ No unused code (YAGNI)
- ✅ Performance maintained

**Stop when**: Code clean, standards met, tests pass, no obvious improvements
