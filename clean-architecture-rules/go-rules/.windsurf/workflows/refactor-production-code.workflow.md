---
description: Refactor production code following Clean Architecture, SOLID, and YAGNI
---

# Production Code Refactoring Workflow

Improve maintainability while preserving behavior (see `go-clean-code-standards.md`, `go-solid-principles.md`).

## Requirements

**Critical Guardrails**:
- Files target ≤150 lines unless a cohesive exception is clearer
- Functions target ≤20 lines unless a cohesive exception is clearer
- Each method must have one cohesive reason to change
- No unused code (YAGNI)
- Follow CQRS (one interface per file)
- Follow Screaming Architecture
- Follow `go-idiomatic-advanced-practices.md` for context, errors, interfaces, concurrency, generics, performance, and observability

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
- Semantic duplication: repeated business rules, validation, mapping, permissions, error decisions, or setup
- Superficial similarity that should stay explicit
- Complexity (nested conditionals, long params)
- Standards violations (naming, error handling, DI)
- Decorative interfaces, generic helpers, factories, options, or worker pools without current evidence
- Goroutines without ownership/cancellation/error handling
- Error wrapping/logging repeated across layers

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

**Extract Function** (eliminate semantic duplication):
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

**Do Not Abstract Incidental Similarity**:
```go
// These functions look similar but represent different business rules.
// Keep them separate unless the domain confirms they must change together.
func ValidateOrderLimit(limit int) error { /* order-specific rule */ }
func ValidateTransferLimit(limit int) error { /* transfer-specific rule */ }
```

**Prefer Domain Ownership Over Generic Helpers**:
```go
// ❌ Vague helper with unclear ownership
func ValidateString(value string, min int, max int) error { /* ... */ }

// ✅ Rule lives where the concept belongs
func NewOrderCode(value string) (OrderCode, error) { /* ... */ }
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

Use this only when there are multiple current implementations or a real policy variation. Keep a direct conditional when the branch is small, local, and unlikely to vary independently.

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

**DTO Pattern (DIP Compliance)**:
```go
// ✅ Application layer - pure domain DTO (no infrastructure tags)
type CategoryDTO struct {
	CategoryID string
	Path       string
}

// ✅ Interface layer - transport DTO with translation methods
type CategoryDTO struct {
	CategoryID string `json:"categoryID"`
	Path       string `json:"path"`
}

func CategoryDTOFromDomain(categoryID string, path string) CategoryDTO {
	return CategoryDTO{CategoryID: categoryID, Path: path}
}

// ✅ Handler uses translation method
appResponse, err := h.catalogRetriever.Execute(ctx, request)
categories := make([]CategoryDTO, len(appResponse.Categories))
for i, cat := range appResponse.Categories {
	categories[i] = CategoryDTOFromDomain(cat.CategoryID, cat.Path)
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

Optimize after evidence from benchmarks, profiles, production metrics, or an obvious algorithmic issue. Do not introduce pools, caches, concurrency, or generics solely to appear optimized.

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
**Duplication**: Extract semantic duplication to named functions, value objects, mappers, or builders
**Complex Conditionals**: Extract to methods or strategies only when behavior varies independently
**Decorative Interface**: Remove if it has no boundary, substitution, or test isolation value
**Unsafe Goroutine**: Add ownership/cancellation/error collection or keep synchronous code

## Success Criteria

- ✅ All tests pass (behavior preserved)
- ✅ File/function size targets respected or cohesive exceptions are clear
- ✅ Each method has one cohesive reason to change
- ✅ Clean Architecture boundaries respected
- ✅ SOLID principles followed (see `go-solid-principles.md`)
- ✅ CQRS compliance (one interface per file)
- ✅ No unused code (YAGNI)
- ✅ Advanced patterns have current evidence and tests
- ✅ Context, errors, logging, and goroutine lifetimes are handled at the right boundaries
- ✅ Performance maintained

**Stop when**: Code clean, standards met, tests pass, no obvious improvements
