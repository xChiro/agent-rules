---
description: Refactor production code following Clean Architecture and Fowler's principles
---

# Production Code Refactoring Workflow

Improve production code maintainability while preserving behavior and Clean Architecture compliance.

## Phase 1: Prerequisites
- **All tests passing**: Ensure safety net before refactoring
- **Clear target identification**: Know what to improve and why
- **Test coverage verified**: Sufficient coverage for behavior preservation
- **Baseline committed**: Save working state before changes

## Phase 2: Code Analysis
- **Identify code smells**: Functions >20 lines, files >150 lines
- **Check architecture violations**: Layer dependencies, SOLID principles
- **Find duplication**: Repeated logic, similar patterns
- **Locate complexity**: Nested conditionals, long parameter lists

## Phase 3: Apply Fowler Refactoring Patterns

### Extract Method (Split Method)
Break down long methods into smaller, focused ones:

#### Before
```go
func (t *Telemetry) ProcessData() error {
    // Validation logic
    if t.DeviceID == "" { return errors.New("device ID required") }
    if t.Speed < 0 { return errors.New("speed cannot be negative") }
    
    // Transformation logic  
    transformed := Data{
        ID: t.ID,
        Speed: t.Speed * 1.60934, // mph to km/h
        Timestamp: time.Now(),
    }
    
    // Persistence logic
    if err := t.repo.Save(transformed); err != nil {
        return fmt.Errorf("save failed: %w", err)
    }
    
    // Event publishing logic
    t.eventBus.Publish("data.processed", transformed)
    return nil
}
```

#### After
```go
func (t *Telemetry) ProcessData() error {
    if err := t.validate(); err != nil { return err }
    transformed := t.transform()
    if err := t.persist(transformed); err != nil { return err }
    t.publishEvent(transformed)
    return nil
}

func (t *Telemetry) validate() error {
    if t.DeviceID == "" { return errors.New("device ID required") }
    if t.Speed < 0 { return errors.New("speed cannot be negative") }
    return nil
}

func (t *Telemetry) transform() Data {
    return Data{
        ID: t.ID,
        Speed: t.Speed * 1.60934,
        Timestamp: time.Now(),
    }
}
```

### Extract Function (Shared Logic)
Move duplicated code to shared functions:

#### Before
```go
func (t *Telemetry) Validate() error {
    if t.DeviceID == "" { return errors.New("device ID required") }
    if t.Speed < 0 { return errors.New("speed cannot be negative") }
    return nil
}

func (s *Sensor) Validate() error {
    if s.DeviceID == "" { return errors.New("device ID required") }
    if s.Reading < 0 { return errors.New("reading cannot be negative") }
    return nil
}
```

#### After
```go
func ValidateDeviceData(deviceID string, value float64, fieldName string) error {
    if deviceID == "" { return errors.New("device ID required") }
    if value < 0 { return fmt.Errorf("%s cannot be negative", fieldName) }
    return nil
}

func (t *Telemetry) Validate() error {
    return ValidateDeviceData(t.DeviceID, t.Speed, "speed")
}

func (s *Sensor) Validate() error {
    return ValidateDeviceData(s.DeviceID, s.Reading, "reading")
}
```

### Replace Conditional with Polymorphism
Eliminate complex conditional logic:

#### Before
```go
func (p *Processor) Process(deviceType string, data Data) error {
    switch deviceType {
    case "GPS":
        return p.processGPS(data)
    case "Accelerometer":
        return p.processAccelerometer(data)
    case "Temperature":
        return p.processTemperature(data)
    default:
        return fmt.Errorf("unsupported device type: %s", deviceType)
    }
}
```

#### After
```go
type DeviceProcessor interface {
    Process(data Data) error
}

type GPSProcessor struct{ validator GPSValidator }
func (g *GPSProcessor) Process(data Data) error {
    if err := g.validator.Validate(data); err != nil { return err }
    return g.saveGPSData(data)
}

func (p *Processor) Process(processor DeviceProcessor, data Data) error {
    return processor.Process(data)
}
```

### Extract Class (Split Large Struct)
Break down large structs into focused ones:

#### Before
```go
type TelemetryService struct {
    repo          TelemetryRepository
    validator     TelemetryValidator
    transformer   DataTransformer
    eventBus      EventBus
    cache         Cache
    logger        Logger
    metrics       MetricsCollector
}
```

#### After
```go
type TelemetryService struct {
    processor *DataProcessor
    publisher *EventPublisher
    cache     *CacheManager
}

type DataProcessor struct {
    repo        TelemetryRepository
    validator   TelemetryValidator
    transformer DataTransformer
}

type EventPublisher struct {
    eventBus EventBus
    logger   Logger
}
```

### Decompose Conditional
Break down complex conditionals:

#### Before
```go
func (c *Customer) CanPurchase(product Product) bool {
    if c.AccountStatus == "active" && c.Balance >= product.Price && 
       c.Age >= 18 && !c.HasPendingPayments() && product.InStock {
        return true
    }
    return false
}
```

#### After
```go
func (c *Customer) CanPurchase(product Product) bool {
    return c.isActive() && c.hasSufficientBalance(product.Price) && 
           c.isAdult() && c.hasNoPendingPayments() && product.isAvailable()
}

func (c *Customer) isActive() bool { return c.AccountStatus == "active" }
func (c *Customer) hasSufficientBalance(price float64) bool { return c.Balance >= price }
func (c *Customer) isAdult() bool { return c.Age >= 18 }
```

## Phase 4: Clean Architecture Compliance

### Domain Layer Purity
```go
// ✅ Pure domain logic
type Money struct {
    amount   int64
    currency string
}

func (m Money) Add(other Money) (Money, error) {
    if m.currency != other.currency {
        return Money{}, errors.New("currency mismatch")
    }
    return Money{amount: m.amount + other.amount, currency: m.currency}, nil
}

// ❌ Infrastructure concerns in domain
type Money struct {
    amount   int64 `json:"amount"`  // No JSON tags in domain
    currency string `db:"currency"` // No DB tags in domain
}
```

### Application Layer Orchestration
```go
// ✅ Pure orchestration
func (uc *ProcessOrder) Execute(ctx context.Context, req ProcessOrderRequest) error {
    order, err := uc.repo.FindByID(ctx, req.OrderID)
    if err != nil { return err }
    
    if err := order.Process(); err != nil { return err }
    
    return uc.repo.Save(ctx, order)
}

// ❌ Business logic in use case
func (uc *ProcessOrder) Execute(ctx context.Context, req ProcessOrderRequest) error {
    // Complex business rules should be in domain
    if order.Total > 1000 && order.Customer.IsPremium {
        // This belongs in domain entity
    }
}
```

## Phase 5: Dependency Injection Improvements

### Interface Extraction
```go
// Define interfaces in application layer
type OrderRepository interface {
    Save(ctx context.Context, order Order) error
    FindByID(ctx context.Context, id string) (*Order, error)
}

// Implement in infrastructure
type SQLOrderRepository struct {
    db *sql.DB
}

func (r *SQLOrderRepository) Save(ctx context.Context, order Order) error {
    // Implementation
}
```

### Constructor Injection
```go
func NewOrderProcessor(
    repo OrderRepository,
    publisher EventPublisher,
    validator OrderValidator,
) *OrderProcessor {
    return &OrderProcessor{
        repo:      repo,
        publisher: publisher,
        validator: validator,
    }
}
```

## Phase 6: Error Handling Enhancement

### Structured Error Handling
```go
// Define domain errors
var (
    ErrOrderNotFound = errors.New("order not found")
    ErrInvalidStatus = errors.New("invalid order status")
)

// Wrap with context
func (r *OrderRepository) Save(ctx context.Context, order Order) error {
    if err := r.db.Save(order); err != nil {
        return fmt.Errorf("failed to save order %s: %w", order.ID, err)
    }
    return nil
}
```

## Phase 7: Testing and Validation

### Behavior Preservation Tests
```go
func Test_given_refactored_code_when_executed_then_same_behavior(t *testing.T) {
    // Characterization test to ensure behavior preservation
    originalResult := originalImplementation(input)
    refactoredResult := refactoredImplementation(input)
    
    assertEqual(t, originalResult, refactoredResult, "behavior should be preserved")
}
```

### Quality Checks
```bash
# Run tests to verify behavior preservation
go test ./...

# Code quality checks
go fmt ./...
go vet ./...

# Check file sizes
find . -name "*.go" -exec wc -l {} \; | awk '$1 > 150'
```

## Phase 8: Performance Considerations

### Algorithm Optimization
```go
// Before: O(n²) nested loop
func findDuplicates(items []string) []string {
    var duplicates []string
    for i, item1 := range items {
        for j, item2 := range items {
            if i != j && item1 == item2 {
                duplicates = append(duplicates, item1)
            }
        }
    }
    return duplicates
}

// After: O(n) with map
func findDuplicates(items []string) []string {
    seen := make(map[string]bool)
    var duplicates []string
    
    for _, item := range items {
        if seen[item] {
            duplicates = append(duplicates, item)
        } else {
            seen[item] = true
        }
    }
    return duplicates
}
```

## Common Refactoring Scenarios

### Long Function Split
- Identify methods >20 lines with multiple responsibilities
- Extract validation, transformation, persistence into separate methods
- Keep each method under 20 lines with descriptive names
- Use composition to maintain original workflow

### Large File Split
- Split files >150 lines by responsibility or feature
- Group related functionality together
- Maintain clear import dependencies
- Update test files accordingly

### Magic Number Elimination
- Replace hardcoded numbers with named constants
- Group related constants in iota blocks
- Use descriptive names revealing business meaning
- Consider configuration for variable values

## Success Criteria
- **All tests pass**: Behavior preserved
- **File size compliance**: ≤150 lines per file
- **Function size compliance**: ≤20 lines per function
- **Architecture compliance**: Clean layer boundaries
- **SOLID principles**: Single responsibility, dependency inversion
- **Performance maintained**: No degradation in execution time

## Stop When
- Code is clean and maintainable
- All quality metrics met
- Tests pass consistently
- Architecture boundaries clear
- No further obvious improvements

Refactoring improves code maintainability while preserving behavior and architectural integrity.
