---
description: HBK Inventory workflow for publishing domain events through shared SNS infrastructure
---

# HBK Inventory Domain Event Publishing Workflow

Use this workflow only for HBK Inventory or projects intentionally sharing the same SNS envelope, topic, IAM, and cross-stack conventions.

## Steps

- Identify the domain fact to publish
- Reuse the shared inventory SNS topic ARN from cross-stack imports
- Add `sns:Publish` IAM permission
- Inject topic ARN via environment variables
- Publish the standard envelope and attributes
- Keep consumers out of the producer design
