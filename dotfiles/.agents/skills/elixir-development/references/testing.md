# Testing

- Favor high-level happy-path coverage for workflows and integration boundaries over many narrow implementation-detail tests.
- For end-to-end tests, use the library `phoenix_test_playwright` when JavaScript needs to be tested, and `phoenix_test` otherwise.
- For PhoenixTest suites, centralize setup, shared imports, and reusable user journeys in a `FeatureCase` based on [feature_case.ex](feature_case.ex).
- Add focused unit tests for edge cases, pure logic, error contracts, and regressions that high-level tests would diagnose poorly.
- Use doctests for stable public functions with concise input/output examples that also improve documentation.
- In a test module dedicated to one module or responsibility, use direct `test` blocks unless a `describe` block adds meaningful context or shared setup.
