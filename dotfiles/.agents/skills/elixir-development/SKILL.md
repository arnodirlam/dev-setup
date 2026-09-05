---
name: elixir-development
description: Apply personal fail-fast and style conventions. Use for coding tasks in Elixir, Mix, OTP, Phoenix, LiveView, or Ecto projects.
---

# Elixir Development

- Respect pinned Elixir, Erlang/OTP, and dependency versions; do not use unavailable APIs, even as optional fallbacks.

## Error semantics

- Fail fast inside trusted, supervised code. Let violated invariants and programmer errors raise instead of adding defensive branches, silent defaults, broad `rescue`, or catch-all clauses.
- Handle expected recoverable failures and external trust-boundary input explicitly, normally with `{:ok, value}` / `{:error, reason}`.
- When the next step requires success, use a raising function or exact match. Translate failures only at a boundary that can recover or present them meaningfully.
- For atom-key maps, use `map.key`, pattern matching, or `Map.fetch!/2` for required keys. Use `map[:key]` or `Map.get/3` only when absence is part of the contract.
- Prefer `and`, `or`, and `not` for boolean operands. Use truthy operators only when truthy semantics are intentional.
- When both raising and tagged-result variants are needed, keep the raising variant a thin wrapper around the tagged-result variant; reuse an existing tuple-unpack helper where appropriate.

## Functions and style

- Express contracts and dispatch with function-head matches, but extract deeply nested fields in the body.
- Prefix helpers that intentionally pass through optional input with `maybe_`.
- Return `nil` or `[]` for optional absence when callers need no failure distinction; use tagged results when callers must distinguish expected outcomes.
- Prefer `do ... end` bodies. Use one-line definitions only for short multi-clause mappings, base cases, and tiny accessors that `mix format` keeps readable.
- Keep canonical private helpers such as config accessors and tuple unpackers at the bottom of the module.
- When a shared, application-independent helper is justified, place it under `Util` and an appropriate submodule, e.g. `Util.Map.map_values`.

## References

- Read [configuration.md](references/configuration.md) for application or runtime configuration.
- Read [ecto.md](references/ecto.md) for Ecto associations or queries.
- Read [phoenix-1.8.md](references/phoenix-1.8.md) only for projects using Phoenix 1.8 generated conventions.
- Read [testing.md](references/testing.md) when choosing or changing tests; it defines the `FeatureCase` convention and links an example.
