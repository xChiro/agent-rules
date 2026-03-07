---
trigger: always_on
description: 
globs: 
---

# Go Project Structure (Clean Architecture)

/cmd
  api/main.go

/internal
  /domain
    /order
      order.go
      value_objects.go
      repository.go

  /application
    /create_order
      command.go
      handler.go

  /interfaces
    /http
      handlers.go

  /infrastructure
    /persistence
      order_repository.go

Rules:
- Domain must not depend on infrastructure.
- Infrastructure implements domain interfaces.
- Application coordinates use cases.
- Interfaces translate transport -> application.

File Limits:
- <=150 lines per file.
- <=20 lines per function.

Package Guidelines:
- Domain packages represent business concepts.
- Avoid generic packages like utils/helpers.