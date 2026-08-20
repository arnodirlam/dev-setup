# Application configuration

- Follow existing project configuration structure before introducing another layer.
- Use `Application` configuration for application-wide settings, grouped under application or module keys when practical.
- Keep required configuration fail-fast. Prefer required access such as `Application.fetch_env!/2`, `Map.fetch!/2`, or equivalent project helpers over silent defaults.
- Put a sensible global default with its environment-variable override in `runtime.exs`.
- When defaults differ by Mix environment, define them in the relevant `dev.exs`, `test.exs`, or `prod.exs`; let `runtime.exs` override them only when the environment variable is present.
- Parse and validate environment strings at the runtime configuration boundary.
- Reuse a small module-local config helper when several values share a namespace. Call it inline when that remains clear.
- Avoid one-use variables and wrapper functions that only rename a config lookup.

```elixir
# runtime.exs: global default with environment override
config :my_app, MyApp.Client,
  http_timeout_ms:
    System.get_env("MY_APP_HTTP_TIMEOUT_MS", "5000")
    |> String.to_integer()
```

```elixir
# Environment-specific default
config :my_app, MyApp.Client, ws_reconnect_ms: 250

# runtime.exs: override without replacing the environment-specific default when unset
if ws_reconnect_ms = System.get_env("MY_APP_WS_RECONNECT_MS") do
  config :my_app, MyApp.Client, ws_reconnect_ms: String.to_integer(ws_reconnect_ms)
end
```

```elixir
defp config(key) do
  :my_app
  |> Application.fetch_env!(__MODULE__)
  |> Keyword.fetch!(key)
end
```
