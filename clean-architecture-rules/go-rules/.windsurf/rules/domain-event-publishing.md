---
trigger: always_on
description: Domain event publishing standards for HBK inventory service
globs: 
---

# Domain Event Publishing

- Publish only domain facts, never consumer-specific commands
- Use the shared SNS topic from `hbk-shared-infrastructure`
- Use the standard event envelope with `event_id`, `event_type`, `event_version`, `source`, `occurred_at`, `correlation_id`, and `payload`
- Add SNS message attributes: `event_type`, `event_version`, `source`, `priority`
- Keep publish logic in infrastructure adapters, not handlers
- Prefer outbox pattern when reliability matters
