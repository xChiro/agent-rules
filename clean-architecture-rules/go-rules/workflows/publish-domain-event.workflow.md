---
description: Publish a new domain event through the service's messaging infrastructure
---

# Domain Event Publishing Workflow

## Steps

- Identify the domain fact to publish.
- Define or reuse the standard event envelope.
- Add publish permissions or configuration only when required by the transport.
- Inject topic, queue, stream, or bus configuration via environment/configuration.
- Publish the standard envelope and routing metadata from an infrastructure adapter.
- Keep consumers out of the producer design.
- Add integration coverage for serialization, routing metadata, and publish failures.
