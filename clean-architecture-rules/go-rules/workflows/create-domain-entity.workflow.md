---
description: Create domain entity or value object following DDD principles
---

# Domain Entity Creation Workflow

Create domain entities or value objects following Clean Architecture and DDD principles with TDD-first approach.

## Phase 1: Requirements Analysis
- Identify **Domain Concept**: Entity (with identity) or Value Object (immutable)
- Define **Invariants**: Business rules that must always hold
- Specify **Attributes**: Core properties and their validation rules
- Confirm **File Size**: ≤150 lines limit

## Phase 2: Failing TDD Test (Red)
Create failing tests following `given_when_then` pattern:

```go
func Test_given_invalid_[attribute]_when_creating_[entity]_then_return_error(t *testing.T) {
    // Arrange: Prepare invalid input
    // Act: Attempt entity creation
    // Assert: Verify error returned
}

func Test_given_valid_[attributes]_when_creating_[entity]_then_success(t *testing.T) {
    // Arrange: Prepare valid input
    // Act: Create entity
    // Assert: Verify entity created correctly
}
```

## Phase 3: Domain Implementation (Green)

### Value Object Pattern
```go
type [ValueObject] struct {
    field1 type1
    field2 type2
}

func New[ValueObject](field1 type1, field2 type2) ([ValueObject], error) {
    // Validation logic
    if field1 == "" {
        return [ValueObject]{}, errors.New("field1 required")
    }
    return [ValueObject]{field1: field1, field2: field2}, nil
}
```

### Entity Pattern
```go
type [Entity] struct {
    id    [EntityID]
    field1 type1
    field2 type2
}

func New[Entity](id [EntityID], field1 type1, field2 type2) *[Entity] {
    return &[Entity]{
        id:    id,
        field1: field1,
        field2: field2,
    }
}
```

## Phase 4: Behavior Implementation
Add domain methods that maintain invariants:

```go
// For Entities: State-changing methods
func (e *[Entity]) [Action]() error {
    // Business logic with invariant validation
    if e.field1 == "" {
        return errors.New("cannot [action] without field1")
    }
    // Modify state
    return nil
}

// For Value Objects: Computation methods
func (v [ValueObject]) [Method]() [ReturnType] {
    // Pure computation
    return [result]
}
```

## Phase 5: Refactoring (Blue)
- Verify file ≤150 lines, functions ≤20 lines
- Ensure no infrastructure dependencies
- Check naming conventions compliance
- Validate all tests pass

## File Location
```
internal/domain/[bounded_context]/[entity].go
tests/domain/[bounded_context]/[entity]_test.go
```

## Key Rules
- **No infrastructure**: No database tags, HTTP clients, etc.
- **Pure domain logic**: Business rules only
- **Immutable value objects**: Copy semantics
- **Entity identity**: Unique ID with lifecycle
- **Validation in constructors**: Maintain invariants

## Examples

### Email Value Object
```go
type Email struct {
    value string
}

func NewEmail(email string) (Email, error) {
    if email == "" || !strings.Contains(email, "@") {
        return Email{}, errors.New("invalid email format")
    }
    return Email{value: email}, nil
}

func (e Email) String() string { return e.value }
```

### User Entity
```go
type User struct {
    id    UserID
    email Email
    name  string
}

func NewUser(id UserID, email Email, name string) *User {
    return &User{
        id:    id,
        email: email,
        name:  name,
    }
}

func (u *User) ChangeName(newName string) error {
    if newName == "" {
        return errors.New("name cannot be empty")
    }
    u.name = newName
    return nil
}
```

## Success Criteria
- All tests pass
- File size ≤150 lines
- No infrastructure imports
- Clear business intent
- Proper invariant enforcement
