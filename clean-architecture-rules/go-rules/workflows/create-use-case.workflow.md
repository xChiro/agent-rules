---
description: Create use case following Clean Architecture and DDD principles
---

# Use Case Creation Workflow

Create application use cases following Clean Architecture, DDD, and TDD principles with proper orchestration.

## Phase 1: Requirements Analysis
- Identify **Actor**: Who initiates the use case
- Define **Responsibility**: What the use case accomplishes
- Specify **Dependencies**: Required ports and services
- Confirm **File Size**: ≤150 lines limit

## Phase 2: Failing ATDD Test (Red)
Create failing test following `given_when_then` pattern:

```go
func Test_given_valid_request_when_[use_case]_then_success(t *testing.T) {
    // Arrange: Setup manual mocks and test data
    // Act: Execute use case
    // Assert: Verify expected behavior
}
```

## Phase 3: Port Definition
Define interfaces in application layer:

```go
// internal/application/[module]/ports/[repository].go
package ports

import "context"

type [Repository] interface {
    Save(ctx context.Context, entity [Entity]) error
    FindByID(ctx context.Context, id string) (*[Entity], error)
}

type [Service] interface {
    Execute(ctx context.Context, request [Request]) (*[Response], error)
}
```

## Phase 4: Request/Response DTOs
Define data transfer objects:

```go
// internal/application/[module]/requests.go
package application

type [UseCase]Request struct {
    Field1 string
    Field2 int
}

type [UseCase]Response struct {
    Result  string
    Success bool
    Events  []DomainEvent
}
```

## Phase 5: Use Case Implementation (Green)
Create use case with dependency injection:

```go
// internal/application/[module]/usecases/[use_case].go
package usecases

import (
    "context"
    "errors"
)

type [UseCase] struct {
    repo    ports.[Repository]
    service ports.[Service]
}

func New[UseCase](repo ports.[Repository], service ports.[Service]) *[UseCase] {
    return &[UseCase]{
        repo:    repo,
        service: service,
    }
}

func (uc *[UseCase]) Execute(ctx context.Context, req requests.[UseCase]Request) (requests.[UseCase]Response, error) {
    // 1. Validate request
    if err := uc.validateRequest(req); err != nil {
        return requests.[UseCase]Response{}, err
    }
    
    // 2. Fetch existing data if needed
    existing, err := uc.repo.FindByID(ctx, req.Field1)
    if err != nil && !errors.Is(err, domain.ErrNotFound) {
        return requests.[UseCase]Response{}, err
    }
    
    // 3. Create domain entity
    entity := domain.New[Entity](req.Field1, req.Field2)
    
    // 4. Execute business logic (delegate to domain)
    if err := entity.[BusinessMethod](); err != nil {
        return requests.[UseCase]Response{}, err
    }
    
    // 5. Persist entity
    if err := uc.repo.Save(ctx, entity); err != nil {
        return requests.[UseCase]Response{}, err
    }
    
    // 6. Return response
    return requests.[UseCase]Response{
        Result:  entity.GetResult(),
        Success: true,
        Events:  entity.GetEvents(),
    }, nil
}

func (uc *[UseCase]) validateRequest(req requests.[UseCase]Request) error {
    if req.Field1 == "" {
        return errors.New("field1 is required")
    }
    if req.Field2 <= 0 {
        return errors.New("field2 must be positive")
    }
    return nil
}
```

## Phase 6: Manual Mock Implementation
Create mocks for testing:

```go
// tests/application/mocks/[repository]_mock.go
package mocks

import "context"

type [Repository]Mock struct {
    SavedEntities []domain.[Entity]
    FindByIDResult *domain.[Entity]
    FindByIDError  error
    SaveError     error
}

func (m *[Repository]Mock) Save(ctx context.Context, entity domain.[Entity]) error {
    m.SavedEntities = append(m.SavedEntities, entity)
    return m.SaveError
}

func (m *[Repository]Mock) FindByID(ctx context.Context, id string) (*domain.[Entity], error) {
    if m.FindByIDError != nil {
        return nil, m.FindByIDError
    }
    return m.FindByIDResult, nil
}
```

## Phase 7: Test Implementation
Complete the failing test:

```go
func Test_given_valid_request_when_[use_case]_then_success(t *testing.T) {
    // Arrange: Setup mocks and test data
    mockRepo := &mocks.[Repository]Mock{}
    mockService := &mocks.[Service]Mock{}
    
    sut := usecases.New[UseCase](mockRepo, mockService)
    
    request := requests.[UseCase]Request{
        Field1: "test-value",
        Field2: 42,
    }
    
    // Act: Execute use case
    result, err := sut.Execute(context.Background(), request)
    
    // Assert: Verify expected behavior
    assertNoError(t, err, "use case execution should succeed")
    assertEqual(t, result.Success, true, "should indicate success")
    assertEqual(t, len(mockRepo.SavedEntities), 1, "should save exactly one entity")
    assertEqual(t, mockRepo.SavedEntities[0].GetField1(), "test-value", "should save correct field1")
}
```

## Phase 8: Refactoring (Blue)
- Verify file ≤150 lines, functions ≤20 lines
- Ensure business logic in domain, not use case
- Check proper dependency injection
- Validate all tests pass

## File Organization
```
internal/application/[module]/
├── ports/
│   └── [repository].go
├── usecases/
│   └── [use_case].go
└── requests.go

tests/application/[module]/
├── [use_case]_test.go
└── mocks/
    └── [repository]_mock.go
```

## Complete Example

### User Registration Use Case
```go
// internal/application/users/usecases/register_user.go
package usecases

type RegisterUser struct {
    userRepo ports.UserRepository
    emailSvc ports.EmailService
}

func NewRegisterUser(userRepo ports.UserRepository, emailSvc ports.EmailService) *RegisterUser {
    return &RegisterUser{
        userRepo: userRepo,
        emailSvc: emailSvc,
    }
}

func (ru *RegisterUser) Execute(ctx context.Context, req requests.RegisterUserRequest) (requests.RegisterUserResponse, error) {
    // Validate request
    if req.Email == "" {
        return requests.RegisterUserResponse{}, errors.New("email required")
    }
    
    // Check if user exists
    existing, err := ru.userRepo.FindByEmail(ctx, req.Email)
    if err != nil && !errors.Is(err, domain.ErrNotFound) {
        return requests.RegisterUserResponse{}, err
    }
    if existing != nil {
        return requests.RegisterUserResponse{}, errors.New("user already exists")
    }
    
    // Create domain entity
    email, err := domain.NewEmail(req.Email)
    if err != nil {
        return requests.RegisterUserResponse{}, err
    }
    
    user := domain.NewUser(email, req.Name)
    
    // Persist user
    if err := ru.userRepo.Save(ctx, user); err != nil {
        return requests.RegisterUserResponse{}, err
    }
    
    // Send welcome email
    if err := ru.emailSvc.SendWelcomeEmail(ctx, user.Email()); err != nil {
        // Log error but don't fail registration
        log.Printf("failed to send welcome email: %v", err)
    }
    
    return requests.RegisterUserResponse{
        UserID: user.ID(),
        Success: true,
    }, nil
}
```

## Key Principles

### Use Case Responsibilities
- **Orchestration only**: Coordinate domain objects and services
- **No business logic**: Delegate to domain entities
- **Transaction management**: Ensure data consistency
- **Error handling**: Wrap and contextually enrich errors

### Clean Architecture Compliance
- **Depends on ports**: Interfaces defined in application layer
- **No infrastructure concerns**: No database, HTTP, or external APIs
- **Request/response pattern**: Clear input/output contracts
- **Dependency injection**: All dependencies passed via constructor

### TDD Integration
- **Test first**: Write failing test before implementation
- **Manual mocks**: Simple, explicit test doubles
- **Edge cases first**: Test validation before happy path
- **Behavior verification**: Focus on outcomes, not implementation

## Success Criteria
- All tests pass
- File size ≤150 lines
- Business logic in domain layer
- Proper error handling
- Clean architecture compliance
- Manual mocks for testing

Use cases provide application-level orchestration while maintaining clean separation of concerns and testability.
