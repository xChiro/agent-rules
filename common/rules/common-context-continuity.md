---
rule_id: RULE-COMMON_CONTEXT_CONTINUITY
trigger: always_on
description: Small-task execution, context-budget checkpoints, and resumable handoffs between AI agents.
---

# AI Task Size And Context Continuity

Use this rule for every task performed by an AI agent. Optimize for a clean handoff and a reproducible next step, not for maximizing the amount of code changed in one context.

## Small Tasks, One Step At A Time

- Start each work unit with exactly one `T-*` task, one concrete outcome, one owner, and one done condition.
- Prefer a task that changes one behavior partition, one boundary, one adapter, one test, one documentation surface, or one behavior-preserving refactor.
- Keep the implementation slice small enough to inspect and verify in one short cycle. If a task requires unrelated files, decisions, gates, or more than one behavior partition, split it before editing.
- Execute in this order: inspect → state assumption → make the smallest authorized change → run the narrowest relevant check → update the spec → report the result.
- Do not start the next task in the same turn until the current task has a recorded status, evidence, and next dependency in `tasks.md`.
- Default to sequential execution. Parallel work requires disjoint ownership in `parallel-tracks.md`; it must not be used to avoid context limits.
- Every task must state `current_step`, `done_when`, `depends_on`, `owned_files`, `verification_command`, and `next_step`.
- If a task grows during execution, stop and split it into a completed task plus a new proposed task. Do not hide scope expansion inside the original task.

## Context Budget Policy

Use the host's context/token meter when one is available. Treat the percentage as an estimate of consumed context, not as a measure of software progress.

- At **50%**, finish only the current microtask, update its evidence, and avoid starting a broad new investigation.
- At **60%**, trigger `common-sdd-context-checkpoint.workflow.md`. Stop starting new implementation tasks and request that the user move to a new context.
- At **70%**, do not begin production edits. Only complete a safe atomic operation, write the checkpoint, and request the context change immediately.
- At **80%** or when the host warns about compaction, stop non-essential work. The continuation handoff is the only remaining deliverable.
- Never wait until the context is nearly exhausted to write the handoff. A partial but accurate checkpoint is better than an apparently complete summary that omits decisions or failures.

The 60% request is an explicit user-facing pause, not a hidden internal state. The agent must say that the context should change and identify the exact handoff file the next agent must read first.

## Automatic Checkpoint

When the host exposes context usage, invoke:

```bash
tools/create-sdd-context-checkpoint.sh \
  --spec specs/features/<number>-<slug> \
  --context-used "$CONTEXT_USED_PERCENT" \
  --current-task T-<NNNN>-<NNN> \
  --next-task T-<NNNN>-<NNN> \
  --state-file /path/to/context-state.md
```

The command is a safe automation aid. It validates the active spec structure, creates an append-only checkpoint under `handoffs/context-checkpoints/`, updates the verification/change-summary continuity records, and writes a latest-handoff pointer. It must not invent task status, test results, architecture decisions, or user approvals; the agent supplies those in `context-state.md`.

If the host does not expose a meter, invoke the same workflow conservatively at the end of a major phase, after several microtasks, or whenever the agent cannot retain the full active-spec state with confidence. Do not claim a precise percentage that was not observed.

## Required Spec State Before Context Change

Before asking the user to change context, the active spec folder must contain current, internally consistent versions of:

- `spec.md` and `change-summary.md` with approved intent and actual progress;
- `tasks.md` with completed, in-progress, blocked, and next tasks;
- `workflow-routing.md` and `traceability.yaml` with the current task/test/workflow links;
- `verification.md` with commands, results, failures, exceptions, and remaining checks;
- `parallel-tracks.md` with ownership and merge state when parallel work exists;
- the generated context handoff under `handoffs/context-checkpoints/`.

The context handoff must include the exact first action for the next agent, files not to touch, decisions that must not be reopened, tests already run, tests still required, gates reached, blockers, residual risk, and the requested user decision. Never put secrets, tokens, credentials, private endpoints, or raw unbounded logs in the handoff.

## Resume Contract

The next agent must:

1. Read the latest context checkpoint before reading unrelated repository files.
2. Confirm the active spec path, current task, risk level, and requested next action.
3. Verify the repository status and rerun the smallest recorded check before changing code.
4. Continue only the stated next task unless a new decision is recorded through the appropriate gate.
5. Update the same spec folder and append a new checkpoint if the 60% threshold is reached again.

An AI snapshot is created only at feature completion. Context checkpoints are interim operational handoffs and never replace the approved spec, traceability, verification, or append-only history.
