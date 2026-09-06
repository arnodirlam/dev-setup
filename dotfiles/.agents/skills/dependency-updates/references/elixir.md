# Elixir updates

- Apply the available `elixir-development` skill when changing Elixir code.
- Inspect `mix.exs`, `mix.lock`, Elixir/Erlang pins, and CI configuration. In umbrellas, include child manifests and shared dependency resolution.
- Use `mix hex.outdated` when an overview is needed; add `--all` for transitive dependencies or a package name to inspect constraints. Exit code 1 can mean outdated dependencies were found.
- Make required Elixir/OTP upgrades explicit prerequisites or part of the coupled migration. Check adapter and transitive constraints; ecosystem membership alone does not require a shared batch.
- Check application configuration, compile-time behavior, database interactions, and generated frontend assets where release notes indicate impact.
