# Application configuration

- Use `Application` configuration for application-wide settings, grouped under application or module keys when practical.
- Keep required configuration fail-fast. Prefer required access such as `Application.fetch_env!/2`, `Map.fetch!/2`, or equivalent project helpers over silent defaults.
- Put a sensible global default with its environment-variable override in `runtime.exs`.
- When defaults differ by Mix environment, define them in the relevant `dev.exs`, `test.exs`, or `prod.exs`; let `runtime.exs` override them only when the environment variable is present.
- Parse and validate environment strings at the runtime configuration boundary.
- Reuse a small module-local config helper when several values share a namespace. Call it inline when that remains clear.
