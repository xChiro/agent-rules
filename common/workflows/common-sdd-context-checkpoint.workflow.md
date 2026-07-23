---
workflow_id: WORKFLOW-COMMON_SDD_CONTEXT_CHECKPOINT_WORKFLOW
trigger: automatic
description: "Pause work at the context budget threshold and create a resumable spec-folder handoff for the next AI agent."
---

# Common SDD Context Checkpoint Workflow

Invoke this workflow when consumed context reaches 60%, when the host warns about compaction, or when the agent can no longer retain the full active-spec state with confidence. The checkpoint is an operational pause and does not change the lifecycle status.

## Threshold Policy

- At 50%, finish only the current microtask and synchronize its evidence.
- At 60%, stop starting new tasks, create the checkpoint, and ask the user to change context.
- At 70% or higher, do not start production edits; only finish a safe atomic operation and write the handoff.
- At 80% or a host compaction warning, stop all non-essential work and produce the handoff immediately.

If the host exposes a context meter, pass it to `tools/create-sdd-context-checkpoint.sh`. If it does not, use a conservative manual checkpoint and say that the percentage is an estimate rather than an observed measurement.

## Preconditions

- An active spec folder exists under `specs/features/<number>-<slug>-active/`.
- The current task has a stable `T-*` ID, an action-oriented human title, and a single concrete outcome.
- The agent knows the exact next task ID and title or can record a blocker title and the user decision required.
- No new production scope is started after the threshold is reached.

## Phase 1 — Finish Only The Safe Atomic Step

1. Complete the current small step only if stopping in the middle would leave the repository invalid.
2. Run the narrowest relevant check.
3. Do not begin another task, broad refactor, exploratory search, or unrelated cleanup.

## Phase 2 — Synchronize The Spec Folder

Update the active spec before asking for the context change:

- `tasks.md`: mark done/in-progress/blocked work and identify the exact next task;
- `change-summary.md`: record actual files, decisions, deviations, and remaining work;
- `verification.md`: record commands, results, failures, exceptions, and checkpoint ID;
- `traceability.yaml`: keep task, test, artifact, and workflow links current;
- `workflow-routing.md`: record the current phase and next workflow;
- `parallel-tracks.md`: record ownership and merge state when parallel work exists;
- `handoffs/context-checkpoints/CHECKPOINT-*.md`: create the resumable handoff from `common/templates/context-handoff.md`.

Use the automation when the host provides context usage:

```bash
tools/create-sdd-context-checkpoint.sh \
  --spec specs/features/<number>-<slug> \
  --context-used "$CONTEXT_USED_PERCENT" \
  --current-task T-<NNNN>-<NNN> \
  --current-task-title "<action and current outcome>" \
  --next-task T-<NNNN>-<NNN> \
  --next-task-title "<action and next outcome>" \
  --state-file /path/to/context-state.md
```

The state file must be concise and factual. It must contain completed work, evidence, decisions, blockers, residual risk, and the exact next action. The automation validates required artifacts and appends continuity records; it must not invent semantic task status or test results.

## Phase 3 — User Pause

Tell the user:

```text
El contexto consumido alcanzó aproximadamente el 60%. Detengo nuevas tareas y dejé la continuidad en:
<spec>/handoffs/context-checkpoints/<checkpoint>.md

Por favor cambia a un contexto nuevo y continúa leyendo primero ese archivo, luego el spec activo.
Estado: <current task> | Siguiente acción: <next task/action> | Bloqueos: <none/list>
```

Do not continue implementation in the same context after this request unless the user explicitly chooses to continue and the context budget still permits a safe atomic action.

## Phase 4 — Resume

The next AI reads the latest checkpoint, verifies `git status`, reruns the recorded narrow check, and continues only the stated next task. It must update `tasks.md`, `verification.md`, and `change-summary.md` after that microtask. If the threshold is reached again, create a new append-only checkpoint rather than editing history.

## Done

- The active spec is internally consistent enough for another AI to resume.
- The current and next task IDs and human-readable titles, plus the exact first action, are explicit.
- Commands, evidence, gates, blockers, ownership, and must-not-touch boundaries are recorded.
- The user received a clear request to change context and the checkpoint path.
- No lifecycle status is changed solely because of a context checkpoint; the checkpoint is an operational handoff, not spec evidence.
