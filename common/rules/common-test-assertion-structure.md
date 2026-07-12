---
rule_id: RULE-COMMON_TEST_ASSERTION_STRUCTURE
trigger: model_decision
description: Cross-language test structure that keeps all assertion APIs in one Then/Assert section.
---

# Common Test Assertion Structure

Apply to unit, HTTP integration, component, and acceptance-support tests.

## Required Shape

Every test follows this order:

```text
Given / Arrange: create data, fixtures, and doubles
When / Act:      perform one behavior call or public request
Then / Assert:   observe results and make every assertion
```

- All assertion APIs belong only in the `Then/Assert` section: `assert`, `require`, `expect`, `Assert.*`, `Should()`, matcher calls, or equivalent.
- `Given/Arrange` prepares; it must not assert.
- `When/Act` executes; it must not assert or start a second behavior.
- `Then/Assert` groups assertions by observable outcome: return value/error, response, state, event, or meaningful side effect.
- A `Then/Assert` read may fetch state needed to observe a side effect; it must not perform another business action.

## Helper Rule

- Builders, fixtures, setup/teardown, constructors, fakes, spies, mocks, and action helpers return data/errors/state; they never assert.
- An assertion helper is allowed only when it represents one stable contract, is named `assert...`/equivalent, lives with test assertions, and is called only from `Then/Assert`.
- Do not use `if`/`switch` as hidden assertions. Use the test framework's assertion API in `Then/Assert`.
- Keep one behavior partition per test and order assertions from primary outcome to relevant side effects. Avoid unrelated or exhaustive field assertions.

## Review Check

The test reviewer must be able to find every assertion by scanning the `Then/Assert` block. An assertion outside it is a test-structure finding and must be moved or explicitly documented as a repository/framework exception before Gate 4.
