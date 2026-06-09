---
trigger: always_on
description: Domain event publishing standards
globs: **/*.go,template.yaml
---

# Domain Event Publishing

- Publish only domain facts, never consumer-specific commands.
- Use a shared event bus, message topic, queue, or stream defined by the service architecture.
- Use a standard event envelope with `event_id`, `event_type`, `event_version`, `source`, `occurred_at`, `correlation_id`, and `payload`.
- Add routing metadata such as `event_type`, `event_version`, `source`, and `priority` when the transport supports it.
- Keep publish logic in infrastructure adapters, not handlers.
- Keep domain/application code independent from transport SDKs and wire formats.
- Prefer an outbox pattern when reliability matters.
