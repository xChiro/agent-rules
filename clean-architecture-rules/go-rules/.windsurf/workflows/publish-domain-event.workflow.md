---
description: Publish a new inventory domain event using HBK shared SNS infrastructure
---

# Publish Domain Event Workflow

## Steps

- Identify the domain fact to publish
- Reuse the shared inventory SNS topic ARN from cross-stack imports
- Add `sns:Publish` IAM permission
- Inject topic ARN via environment variables
- Publish the standard envelope and attributes
- Keep consumers out of the producer design
