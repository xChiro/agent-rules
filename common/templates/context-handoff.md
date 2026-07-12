---
handoff_id: HANDOFF-<FEAT>-CONTEXT-<NNN>
feature_id: FEAT-<NNNN>
spec_id: SPEC-<NNNN>
artifact_id: ART-<FEAT>-CONTEXT-HANDOFF
checkpoint_id: CHECKPOINT-<YYYYMMDD>-<HHMMSS>
context_used_percent: <PERCENT>
current_task_id: CURRENT-TASK-ID
next_task_id: NEXT-TASK-ID
status: ready_for_next_context
---

# Context Handoff

This file is an interim, append-only continuation record. The next AI must read it before starting work.

## Current Task

- Objective:
- Done when:
- Current step:
- Risk level:
- Owner/track:

## Completed In This Context

- Tasks completed:
- Files changed:
- Spec artifacts updated:
- Decisions finalized:

## Evidence

- Commands run and results:
- RED/GREEN/REFACTOR status:
- Gates passed:
- Gates still required:
- Test IDs and artifact links:

## Continuation

- Exact first action for the next AI:
- Next task:
- Dependencies:
- Files/modules owned:
- Files/modules that must not be touched:
- User decision requested:

## Risks And Blockers

- Open questions:
- Blockers:
- Residual risk:
- Known failures or flaky checks:

## Resume Checklist

- [ ] Read this checkpoint and the active spec.
- [ ] Confirm `git status` and the current task.
- [ ] Rerun the smallest recorded verification command.
- [ ] Continue only the stated next task.
- [ ] Update `tasks.md`, `verification.md`, and `change-summary.md` after the next microtask.
