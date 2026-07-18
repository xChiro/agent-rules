---
rule_id: RULE-COMMON_TEST_ASSERTION_STRUCTURE
trigger: model_decision
description: "Cross-language test structure that keeps Given/When/Then behavior and all assertion APIs in one Assert section."
---

# Common Test Assertion Structure

Apply `RULE-COMMON_TEST_LAYER_ISOLATION` in addition to this assertion-placement rule. Correct assertion structure does not compensate for a test layer that depends on another layer's execution or mutable state.

Apply to every automated test: unit, `integration/http`, `integration/infrastructure`, component, hook, contract, browser, and acceptance-support tests.

## Required Shape

Every test follows this order. BDD scenarios and behavior names use `Given/When/Then`; executable test code uses the exact section comments `// Arrange`, `// Act`, and `// Assert`:

```text
// Arrange
// Act
// Assert
```

`// Arrange` represents Given, `// Act` represents When, and `// Assert` represents Then.

- `// Arrange` is the Given section and prepares data/dependencies only.
- `// Act` is the When section and contains exactly one executable statement on one physical line: the SUT/use-case/public-boundary call. Build arguments and read setup values in Arrange; do not put helper calls, state reads, a second call, or assertions in Act. If the call does not fit on one line, extract its arguments or a setup helper before Act.
- The single `// Act` statement must execute the system under test: the domain object/policy for a Domain unit test, the Application use case for an Application unit or `integration/infrastructure` test, the real public request/interaction for `integration/http` or UI tests, or the equivalent public contract entry point. It must not be a fixture/helper call, adapter-only call, state read, assertion, or infrastructure bootstrap.
- `// Assert` is the Then section and contains every assertion/failure API: `assert`, `require`, `expect`, `Assert.*`, `Should()`, `t.Error`, `t.Errorf`, `t.Fatal`, `t.Fatalf`, matcher calls, or equivalent.
- `Given/Arrange` prepares; it must not assert.
- `When/Act` executes one behavior; it must not assert or start a second behavior.
- `// Assert` (Then) groups assertions by observable outcome: return value/error, response, state, event, or meaningful side effect.
- An `Assert` read may fetch state needed to observe a side effect; it must not perform another business action.

## Helper Rule

- Builders, fixtures, setup/teardown, constructors, fakes, spies, mocks, and action helpers return data/errors/state; they never assert.
- An assertion helper is allowed only when it represents one stable contract, is named `assert...`/equivalent, lives with test assertions, and is called only from `// Assert`.
- Do not hide assertions in setup or action control flow. Languages such as Go may use an `if`/`switch` in `// Assert` when the branch immediately calls the standard test failure API; third-party assertion libraries are not required.
- Keep one behavior partition per test and order assertions from primary outcome to relevant side effects. Avoid unrelated or exhaustive field assertions.

## Review Check

The test reviewer must be able to find every assertion by scanning the `// Assert` block and verify that `// Act` contains one physical line. An assertion outside `// Assert`, or a second/multiline Act statement, is a test-structure finding and must be fixed or explicitly documented as a repository/framework exception before final validation.
