---
artifact_id: ART-<FEAT>-RED-GREEN-REFACTOR
artifact_title: RED Green Refactor evidence for <feature title>
feature_id: FEAT-<NNNN>
feature_title: <human-readable feature title>
spec_id: SPEC-<NNNN>
spec_title: <human-readable spec title>
status: draft
report_version: 1
---

# Red → Green → Refactor Evidence

Append one cycle entry per behavior partition. Do not combine unrelated partitions or replace an earlier cycle; each entry must be reproducible from its commands and stable IDs.

## Change Classification

- `change_type`: feature | bug-fix | refactor | pipeline | documentation
- `risk_level`: L0 | L1 | L2 | L3
- `story_id`:
- `story_title`:
- `requirement_id`:
- `requirement_title`:
- `scenario_id` or `regression_id`:
- `scenario_title` or `regression_title`:
- `task_id`:
- `task_title`:
- `development_layer`: domain | application | boundary | infrastructure | interface | composition
- `gate_3_scope`: domain | application | boundary
- `prior_layer_gate`:
- `resulting_layer_gate`:
- `cycle_id`: CYCLE-<FEAT>-<NNN>
- `cycle_title`:
- `behavior_partition_id`:
- `behavior_partition_title`:
- `test_layer`: domain | application | boundary | infrastructure | interface | composition
- `standalone_test_command`:
- `depends_on_test_layer`: none
- `isolation_scope`:
- `owned_mutable_state`: none | <resources>
- `setup_and_cleanup`:

## RED

- `test_id`:
- `test_title`:
- Test file:
- Behavior partition:
- Given:
- When:
- Then:
- Assertion placement: all assertion APIs are in `// Assert` (Then); setup, actions, and helpers do not assert. `// Act` has exactly one executable statement on one physical line that invokes the layer-appropriate SUT/use case/public boundary.
- Test doubles: none | hand-written stub | hand-written fake | hand-written spy | hand-written mock
- Doubled outgoing ports and reason:
- Command:
- Standalone-from-clean-state result:
- Order/repeat/shuffle evidence:
- Expected failure:
- Actual failure:
- Why the failure proves the intended missing behavior:
- Production files unchanged: yes | no
- Scoped Gate 3 decision/history reference:

## GREEN

- Production files changed:
- Smallest implementation change:
- Command:
- Result:
- Tests passing:
- Combined-suite result:
- Resulting layer-gate status: passed | not_affected | blocked

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
- Handoff title:
- Decision or artifact link:
