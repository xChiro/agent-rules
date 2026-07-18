---
workflow_id: WORKFLOW-COMMON_BDD_SPECIFICATION_WORKFLOW
trigger: manual
description: "Business-first BDD specification using shared language, concrete examples, executable behavior, and living documentation."
---

# Common BDD Specification Workflow

Use this workflow to discover and specify behavior. Keep it independent of delivery mechanics, implementation structure, and execution tools.

## Flow

`Value → Conversation → Examples → Specification → Automation → Living documentation`

1. **Value** — name the actor, business objective, capability, and measurable outcome.
2. **Conversation** — resolve shared meaning with the people who understand the business, rules, risks, and expected outcomes. Record uncertainty instead of guessing.
3. **Examples** — illustrate the capability with concrete successful, boundary, invalid, and counter examples. Prefer a few precise examples over exhaustive prose.
4. **Specification** — express each example as an observable behavior in business language.
5. **Automation** — map each scenario to executable acceptance evidence without changing the scenario into implementation instructions.
6. **Living documentation** — keep scenarios, results, and traceability synchronized with the delivered behavior.

## Language Contract

Use `Feature`, `Scenario`, `Given`, `When`, and `Then` only to organize meaning:

```gherkin
@US-0001-001 @REQ-0001-001 @SCN-0001-001
Scenario: Actor achieves the business outcome
  Given the relevant business context exists
  When the actor performs one meaningful business action
  Then the expected business outcome is observable
```

- `Given` establishes relevant business facts, permissions, state, or policy—not setup mechanics.
- `When` describes one meaningful action, decision, or event—not an interaction mechanism.
- `Then` states an observable result, invariant, decision, or side effect—not internal structure.
- Use business nouns and verbs from the domain glossary. A non-technical stakeholder should understand the scenario without translation.
- Keep one behavior partition per scenario. Split scenarios when the rule, actor, outcome, or reason changes.
- Use examples/tables for meaningful rule partitions, not for implementation data.
- Use `Background` only for context shared by every scenario in the feature.

## Hard Boundaries

Do not put these in a BDD scenario:

- interaction mechanics or delivery details;
- internal structure, execution details, persistence details, or implementation names;
- assertions about how behavior is built instead of what the actor or business can observe.

Those details belong in the technical plan, test implementation, architecture rules, or verification record.

## Test-First Boundary

- The scenario is the business specification; acceptance evidence proves it at the closest stable boundary.
- For backend work, the business model is made explicit before technical layers; TDD then opens domain and application one failing behavior partition at a time. Executable boundary RED follows the core gate only when outer production changes.
- Tests describe behavior and remain independent of internal structure; production code is written only to pass the current failing test.
- Test layers remain execution-independent: Domain, Application, and Boundary each run from clean state with no state or ordering dependency on another test layer.

## Quality Check

Before approval, confirm:

- the feature delivers a stated business value;
- examples came from a collaborative clarification, including uncertainty and counterexamples;
- scenarios are deterministic, concise, independent, and free of implementation language;
- every User Story has at least one scenario and every scenario has stable `US-*`, `REQ-*`, and `SCN-*` links;
- each scenario maps to executable acceptance evidence;
- the scenario remains the source of expected behavior while lower-level tests drive design after RED.

## SDD Integration

- Gate 1 approves the value, stories, examples, scenarios, risks, and scope before spec writes.
- Gate 2 approves the acceptance scenarios and inside-out RED plan.
- Gate 3-DOMAIN and Gate 3-APPLICATION review focused core RED before each core Green.
- Gate 3-BOUNDARY reviews executable acceptance RED before affected outer production. When outer production is `not_affected`, existing boundary evidence remains GREEN verification and the gate is recorded `not_affected` without manufacturing RED.
- GREEN and REFACTOR update the scenario traceability and living documentation.
- A changed business outcome returns to this workflow before implementation resumes.

BDD defines what the business expects. TDD defines the smallest design step that makes the current behavior pass. Neither replaces the other.
