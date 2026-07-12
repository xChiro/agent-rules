---
artifact_id: ART-<FEAT>-RED-GREEN-REFACTOR
feature_id: FEAT-<NNNN>
spec_id: SPEC-<NNNN>
status: draft
report_version: 1
---

# Red → Green → Refactor Evidence

Append one cycle entry per behavior partition. Do not combine unrelated partitions or replace an earlier cycle; each entry must be reproducible from its commands and stable IDs.

## Change Classification

- `change_type`: feature | bug-fix | refactor | pipeline | documentation
- `risk_level`: L0 | L1 | L2 | L3
- `story_id`:
- `requirement_id`:
- `scenario_id` or `regression_id`:
- `task_id`:
- `cycle_id`: CYCLE-<FEAT>-<NNN>
- `behavior_partition_id`:

## RED

- `test_id`:
- Test file:
- Behavior partition:
- Given:
- When:
- Then:
- Assertion placement: all assertion APIs are in `Then/Assert`; setup, actions, and helpers do not assert.
- Command:
- Expected failure:
- Actual failure:
- Why the failure proves the intended missing behavior:
- Production files unchanged: yes | no

## GREEN

- Production files changed:
- Smallest implementation change:
- Command:
- Result:
- Tests passing:

## REFACTOR

- Structural changes:
- Behavior preserved evidence:
- Tests rerun:
- Architecture/ownership changes:
- Remaining risk:

## Handoff Evidence

- From role:
- To role:
- Handoff ID:
- Decision or artifact link:
