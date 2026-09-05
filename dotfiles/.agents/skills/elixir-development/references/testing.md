# Testing

- Favor high-level happy-path coverage for workflows and integration boundaries over many narrow implementation-detail tests.
- For end-to-end tests, use the library `phoenix_test_playwright` when JavaScript needs to be tested, and `phoenix_test` otherwise.
- Add focused unit tests for edge cases, pure logic, error contracts, and regressions that high-level tests would diagnose poorly.
- Use doctests for stable public functions with concise input/output examples that also improve documentation.
- In a test module dedicated to one module or responsibility, use direct `test` blocks unless a `describe` block adds meaningful context or shared setup.

## FeatureCase

- Centralize feature-test setup and shared helpers in a `FeatureCase` with working `visit` and `sign_in` functions.
- Support `sign_in` with an optional existing connection or session, followed by the arguments required for authentication; create the connection or session when omitted. Return the authenticated connection or session for subsequent steps.
- Choose the simplest working authentication approach supported by the project. Exercise the actual sign-in journey when authentication itself is under test.
- Adapt setup and concurrency to the project's test driver and sandbox arrangement.

Use [feature_case.ex](feature_case.ex) as an illustrative connection-based example when implementing this convention. Its Swoosh, factory, and magic-link choices are application-specific; the contract above takes precedence.
