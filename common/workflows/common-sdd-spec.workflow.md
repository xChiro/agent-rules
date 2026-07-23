---
workflow_id: WORKFLOW-COMMON_SDD_SPEC_WORKFLOW
trigger: manual
description: "Create one or more SDD specs or evolve approved existing specs, selecting the correct action after repository discovery and requiring approval before modifying existing specs."
---

# Common SDD Spec Workflow

Use this workflow for any request that needs a feature, behavior, contract, risk, architecture, verification, or documentation spec. It replaces the former create-spec and evolve-spec workflows. For a reported defect, use `common-sdd-fix-bug.workflow.md` first; that workflow classifies the defect and then routes here when a spec must be created or changed.

## Phase 0: Discover and classify spec ownership (read-only)

Before creating or modifying any spec artifact:

1. Inspect the repository's `specs/` layout and read the relevant `spec.md`, `change-summary.md`, `acceptance.feature`, `plan.md`, `tasks.md`, `workflow-routing.md`, `parallel-tracks.md`, `traceability.yaml`, `verification.md`, and recent `history/` entries.
2. Search all feature specs, including completed, superseded, and retired specs, for matching User Stories, requirements, contracts, domain terms, paths, and behavior. Do not assume the first name match is the owner.
3. Produce an ownership matrix with every plausible existing spec, its status, matching evidence, and the requested behavior's overlap or divergence.
4. Classify each requested scope as one of:
   - `create`: no existing spec owns the behavior;
   - `modify`: an active spec is the clear owner;
   - `new-linked-spec`: an existing verified, superseded, or retired spec is relevant evidence, but must remain immutable and the change needs a new linked active spec;
   - `split`: the request contains independent behaviors that should be represented by multiple specs.
5. A request may result in multiple specs. List every proposed spec, its reason, relationship to other specs, and stable feature number. Never merge unrelated behavior merely to avoid creating another spec.

If no repository spec system exists, propose the minimum `specs/features/` structure from `common-sdd-spec-structure.md`.

## Phase 1: Gate 1 — show the write plan and ask for approval

Do not write any spec file during discovery. Present one plan covering all create and modify decisions:

- ownership matrix and the selected action for every candidate;
- each new folder path, or each existing folder and exact sections/files to modify;
- required and optional artifacts, IDs, canonical human-readable titles, User Stories, requirements, and summarized Given/When/Then scenarios;
- proposed history entry for each spec; new specs start with `status: proposed` and active paths use the status suffix contract;
- architecture, contract, data, test, security, coverage, clean-up, documentation, and quality-gate impact;
- tasks, tracks, dependencies, ownership, parallel waves, merge order, and workflow routing;
- links between specs when the request is split or a new spec supersedes/extends prior evidence.

If one or more existing specs are candidates for modification, explicitly identify them and ask for approval to modify those specific specs. Approval to create a new spec does not authorize modifying an existing spec. Approval must name the accepted create/modify mapping; otherwise stop.

Ask explicitly: “¿Apruebas crear estos specs y modificar únicamente los specs existentes indicados?” Do not create folders, history entries, or artifacts until approval is received.

## Phase 2: Establish the approved spec set

After Gate 1 approval:

- create every approved new `specs/features/<number>-<behavior-slug>-proposed/` folder;
- use the approved active owner for each modification;
- never edit a `verified`, `superseded`, or `retired` spec in place; create a linked active evolution or defect spec instead;
- assign stable `FEAT-*`, `SPEC-*`, and `ART-*` IDs, with separate human-readable titles;
- keep history append-only and do not rewrite prior entries;
- do not put specs in `.windsurf`, `.codex`, issue comments, chat history, or temporary notes.

Minimum files for each new spec:

```text
spec.md
change-summary.md
acceptance.feature
plan.md
security-review.md
tasks.md
workflow-routing.md
parallel-tracks.md
traceability.yaml
verification.md
history/YYYY-MM-DD-created.md
```

Add `invariants.md`, `research.md`, `data-model.md`, `contracts/`, or `decisions/` only when they reduce ambiguity or drive verification. For every modified spec, create a dated history entry before production code changes, after the approved plan is confirmed.

## Phase 3: Define and synchronize intent

For each approved spec, create or update the complete living baseline:

1. `spec.md`: metadata, objective, actors, User Stories, requirements, out-of-scope, edge/failure behavior, non-functional requirements, and `[NEEDS CLARIFICATION]` markers.
2. Invoke `WORKFLOW-COMMON_BDD_SPECIFICATION_WORKFLOW` and write business-readable acceptance scenarios.
3. Capture the domain model and business-policy map before technical layers: capability, terms, policy owner, invariants, transitions, events, examples, and counterexamples. Record an evidence-based `domain: not_affected` reason when applicable.
4. Update `plan.md`, `change-summary.md`, tasks, tracks, routing, traceability, verification, and history. Every planned change has a `CHG-*` row and every defined entity keeps one canonical title.
5. Derive inside-out layer scope and gates using `RULE-COMMON_INSIDE_OUT_DEVELOPMENT`; no outer production task may precede the applicable inner gate.

For discovery-driven changes, pause, preserve the last approved baseline, fill `common/templates/spec-adjustment-request.md`, show evidence, impact, alternatives, affected IDs/files, gates to repeat, and the exact resume action. Obtain approval before changing intent or continuing. Append the approved adjustment to history and rebaseline affected artifacts and gates.

## Phase 4: Gate 2 and implementation routing

After the spec set is synchronized, show unresolved questions, RED plan, affected layer gates, and implementation routing. Ask for approval to start RED. Then follow the selected language and boundary workflows, including Domain RED/GREEN, Application RED/GREEN, conditional Boundary RED, infrastructure, interface, and composition/IaC in inside-out order. Use the common documentation, clean-up, security, coverage, context-checkpoint, and verification workflows as required by risk and the spec.

Each task records one primary workflow, supporting workflow IDs, `work_type`, `development_layer`, `layer_gate`, `track_id`, ownership, dependencies, `can_run_with`, standalone test command, done condition, and verification command. Apply `RULE-COMMON_TEST_LAYER_ISOLATION`.

## Phase 5: Converge and verify

Before completion, ensure every spec's code, acceptance scenarios, plan, tasks, tracks, traceability, workflow routing, verification, history, documentation result, clean-up review, security review, and coverage evidence agree. Run `WORKFLOW-COMMON_SDD_UPDATE_DOCUMENTATION_WORKFLOW`; if no project surface is affected, record `no_documentation_change_reason` in `spec.md`, `verification.md`, and `change-summary.md`.

When a spec is fully verified, invoke `WORKFLOW-COMMON_SDD_VERIFY_SPEC_WORKFLOW` and keep its stable folder path. Report each created spec, each modified spec, and any intentionally untouched candidate.

## Non-negotiable rules

- Discovery never writes.
- Existing-spec modification always requires explicit Gate 1 approval naming the target spec(s).
- Multiple new specs are allowed when the request contains independent behaviors.
- A new spec does not silently absorb changes to an existing spec.
- Verified, superseded, and retired specs are audit evidence and are never edited in place.
- No implementation starts before the approved spec set and required human gates are recorded.
