---
trigger: always_on
description: HBK Inventory domain event publishing standards
globs: **/*.go,template.yaml
---

# HBK Inventory Domain Event Publishing

Use this profile only for HBK Inventory or projects that intentionally share the same SNS event envelope and infrastructure conventions.

- Publish only domain facts, never consumer-specific commands
- Use the shared SNS topic from `hbk-shared-infrastructure`
- Use the standard event envelope with `event_id`, `event_type`, `event_version`, `source`, `occurred_at`, `correlation_id`, and `payload`
- Add SNS message attributes: `event_type`, `event_version`, `source`, `priority`
- Keep publish logic in infrastructure adapters, not handlers
- Prefer outbox pattern when reliability matters
