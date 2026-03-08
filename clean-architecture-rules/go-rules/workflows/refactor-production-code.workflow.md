---
description: Refactor production code following Go Clean Architecture and Fowler's principles
---

# Production Code Refactoring Workflow

## Prerequisites
- All tests passing
- Clear target identification
- Test coverage verified

## Phase 1: Analysis
- Identify code smells (long functions >20 lines, files >150 lines)
- Check Clean Architecture violations
- Find SOLID principle violations

## Phase 2: Safety Net Setup
- Ensure existing tests pass
- Create characterization tests if coverage insufficient
- Commit baseline before refactoring

## Phase 3: Apply Fowler Refactoring Patterns

### Extract Method (Split Method)
Break down long methods into smaller, focused ones:
```go
// Before: Long method with multiple responsibilities
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

// After: Split into focused methods
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

func (t *Telemetry) persist(data Data) error {
    return t.repo.Save(data)
}

func (t *Telemetry) publishEvent(data Data) {
    t.eventBus.Publish("data.processed", data)
}
```

### Extract Function (Shared Logic)
Move duplicated code to shared functions:
```go
// Before: Duplicated validation across multiple structs
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

// After: Extract shared validation function
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
```go
// Before: Complex conditional based on type
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

// After: Polymorphic approach
type DeviceProcessor interface {
    Process(data Data) error
}

type GPSProcessor struct{ validator GPSValidator }
func (g *GPSProcessor) Process(data Data) error {
    if err := g.validator.Validate(data); err != nil { return err }
    return g.saveGPSData(data)
}

type AccelerometerProcessor struct{ validator AccValidator }
func (a *AccelerometerProcessor) Process(data Data) error {
    if err := a.validator.Validate(data); err != nil { return err }
    return a.saveAccData(data)
}

// Processor becomes simple
func (p *Processor) Process(processor DeviceProcessor, data Data) error {
    return processor.Process(data)
}
```

### Extract Class (Split Large Struct)
Break down large structs into focused ones:
```go
// Before: Large struct with multiple responsibilities
type TelemetryService struct {
    repo          TelemetryRepository
    validator     TelemetryValidator
    transformer   DataTransformer
    eventBus      EventBus
    cache         Cache
    logger        Logger
    metrics       MetricsCollector
}

// After: Split into focused structs
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

type CacheManager struct {
    cache   Cache
    metrics MetricsCollector
}
```

### Move Method/Field
Reorganize methods to appropriate classes:
```go
// Before: Method in wrong class
type Order struct {
    ID     string
    Amount float64
}

func (o *Order) CalculateDiscount(customer Customer) float64 {
    if customer.IsPremium() {
        return o.Amount * 0.1
    }
    return 0
}

// After: Move method to appropriate class
type Order struct {
    ID     string
    Amount float64
}

type Customer struct {
    ID      string
    Premium bool
}

func (c *Customer) CalculateDiscount(order Order) float64 {
    if c.Premium {
        return order.Amount * 0.1
    }
    return 0
}
```

### Replace Parameter with Explicit Methods
Replace methods with boolean parameters:
```go
// Before: Boolean parameter obscuring intent
func (u *User) SetPermission(admin bool) {
    if admin {
        u.role = "admin"
        u.permissions = []string{"read", "write", "delete"}
    } else {
        u.role = "user"
        u.permissions = []string{"read"}
    }
}

// After: Explicit methods revealing intent
func (u *User) MakeAdmin() {
    u.role = "admin"
    u.permissions = []string{"read", "write", "delete"}
}

func (u *User) MakeUser() {
    u.role = "user"
    u.permissions = []string{"read"}
}
```

### Decompose Conditional
Break down complex conditionals:
```go
// Before: Complex conditional
func (c *Customer) CanPurchase(product Product) bool {
    if c.AccountStatus == "active" && c.Balance >= product.Price && 
       c.Age >= 18 && !c.HasPendingPayments() && product.InStock {
        return true
    }
    return false
}

// After: Decomposed into meaningful methods
func (c *Customer) CanPurchase(product Product) bool {
    return c.isActive() && c.hasSufficientBalance(product.Price) && 
           c.isAdult() && c.hasNoPendingPayments() && product.isAvailable()
}

func (c *Customer) isActive() bool { return c.AccountStatus == "active" }
func (c *Customer) hasSufficientBalance(price float64) bool { return c.Balance >= price }
func (c *Customer) isAdult() bool { return c.Age >= 18 }
func (c *Customer) hasNoPendingPayments() bool { return !c.HasPendingPayments() }
func (p *Product) isAvailable() bool { return p.InStock }
```

### Replace Magic Number with Symbolic Constant
```go
// Before: Magic numbers
func (t *Telemetry) IsHighSpeed() bool {
    return t.Speed > 120.0 // What does 120 mean?
}

// After: Symbolic constants
const (
    SpeedThresholdHigh = 120.0
    SpeedThresholdLow  = 30.0
)

func (t *Telemetry) IsHighSpeed() bool {
    return t.Speed > SpeedThresholdHigh
}

func (t *Telemetry) IsLowSpeed() bool {
    return t.Speed < SpeedThresholdLow
}
```

## Phase 4: Clean Architecture Compliance
- **Domain**: Technology-agnostic, no infrastructure
- **Application**: Orchestration only, no business logic  
- **Infrastructure**: Implement ports, no domain rules
- **Interface**: HTTP handlers, composition root

## Phase 5: Dependency Injection
```go
// Extract interfaces in application layer
type TelemetryRepository interface { Save(ctx context.Context, t Telemetry) error }

// Inject dependencies via constructors
func NewProcessor(repo TelemetryRepository) *Processor {
    return &Processor{repo: repo}
}
```

## Phase 6: Validation & Testing
```bash
# Run tests to verify behavior preservation
go test ./...

# Code quality checks
go fmt ./...
go vet ./...
```

## Phase 7: Final Verification
- All tests passing
- No behavior changes
- Architecture compliance verified
- Performance maintained

## Safety Checks
- Tests pass before each change
- Small incremental refactors
- Commit after successful changes
- Verify behavior preservation

## Common Scenarios

### Long Function Split (Extract Method)
```go
// Identify methods >20 lines with multiple responsibilities
// Extract validation, transformation, persistence into separate methods
// Keep each method under 20 lines with descriptive names
// Use composition to maintain original workflow
```

### Conditional to Polymorphism  
```go
// Find switch/if-else chains based on type or state
// Create interface defining the behavior
// Implement concrete types for each condition
// Replace conditional with polymorphic calls
// Use DI to inject appropriate implementation
```

### Large Struct Decomposition (Extract Class)
```go
// Identify structs with >7 fields or multiple responsibilities
// Group related fields into focused structs
// Move methods to appropriate new structs
// Use composition to maintain original functionality
```

### Magic Number Elimination
```go
// Replace hardcoded numbers with named constants
// Group related constants in iota blocks when appropriate
// Use descriptive names revealing business meaning
// Consider configuration for values that may change

## Stop When
- Functions ≤20 lines, files ≤150 lines
- SOLID principles followed
- Clean Architecture boundaries respected
- All tests passing, behavior preserved

---

**Note**: For detailed test refactoring techniques, see the separate **Test Code Refactoring Workflow**. This workflow focuses only on production code improvements.
