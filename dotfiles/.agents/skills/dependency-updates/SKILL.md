---
name: dependency-updates
description: Plan or perform dependency upgrades one reviewed batch at a time, with release research and separate migration groups. Includes Elixir guidance.
---

# Dependency Updates

## Research

- Follow project rules and the requested scope: planning, implementation, or publishing tickets/PRs.
- Inspect manifests, lockfiles, runtime pins, affected callers, and existing checks before editing. Establish baseline failures so new regressions can be distinguished.
- Read upstream changelogs or release notes for every release after the installed version through the target version, plus relevant migration guides. Use Context7 for documentation matching the target version.
- Assess breaking changes, deprecations, runtime requirements, behavior changes, fixes, and new capabilities against project usage. Distinguish irrelevant changes from unverified ones; record missing sources as uncertainty.
- For Elixir projects, read [elixir.md](references/elixir.md).

## Batch decisions

- Start with one straightforward batch requiring no substantial application, configuration, or runtime changes. Judge by research and validation, not version numbers alone. Move updates requiring substantive adaptation into separate groups.
- Follow with one batch per non-straightforward group: dependencies that must move together belong together; unrelated migrations stay separate. Order by actual prerequisites.
- Each batch references every other batch as depends on, blocks, or independent. Use stable batch names until links exist, and keep references current. Execution order alone creates no dependency.
- If starting with Linear tickets, establish native blocking/blocked-by relationships there and link subsequent PRs to their tickets. Reuse existing tickets/PRs when continuing work.

## Interactive handoff

- Keep a concise todo list. Research may span batches; implement and validate only the current batch.
- When ready, provide its description and stop for review. The user commits and pushes; do not stage, commit, or push unless explicitly asked.
- Address feedback within that batch. Start the next only when the user indicates the current batch is committed and pushed and they are ready. A bare "please continue" does not bypass this handoff.
- On resumption, inspect Git state and remaining work; preserve review edits and distinguish pushed prerequisites from merged ones.

## Adopt useful functionality

- Identify new capabilities that simplify or improve existing functionality, with concrete benefits grounded in project usage.
- Include small, directly related improvements with the update. Put broader refactors or behavior changes in a non-straightforward batch or linked follow-up issue/PR; explain the benefit, reason for separation, and dependency on the enabling update.

## Validate

- Update only the intended dependency group and necessary transitive dependencies. Inspect resolved versions and unexpected lockfile changes; preserve constraints unless changing them is required for the selected update.
- Validate each batch independently using project checks and targeted verification of affected behavior. Existing passing tests alone do not resolve compatibility questions raised by release notes.
- Include meaningful transitive changes in the batch's release summary.

## Describe

- Use [templates.md](references/templates.md) for one description per batch; no overall report. Describe planned work as planned, then update to actual outcomes.
- Include each library's old and new versions, relevant release changes, project impact, and source links. Group intervening releases when useful; use short attributed excerpts when clearer, respecting quotation limits.
- When an update spans only one release, prefer linking that release directly over the general changelog. If no release page exists, link its specific changelog entry when available.
- Omit routine passing-check reports and a Validation section. Use optional Open questions for unresolved decisions, compatibility uncertainty, failing checks, or verification gaps. Omit all empty sections.
