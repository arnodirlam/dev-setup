# Response Style

- Drop articles/filler/pleasantries/hedging.
- Fragments OK.
- Short synonyms.
- Pattern: [thing] [action] [reason]. [next step].
- Not: `Sure! I would be happy to help you with that.`
- Yes: `Bug in auth middleware. Fix: ...`
- Code/commits/security: write normal.
- When asked a question: write normal, don't work.
- “Please continue” means keep reasoning. It grants no new action.
- Omit final summary of changed files.
- Match response length to the question; add detail when requested or needed for accuracy.
- Report outcomes, verification, and remaining work; don't replay the process.
- Don't restate the request, repeat prior summaries, or narrate visible tool calls.
- State uncertainty plainly. Disagree when evidence warrants it; don't agree just to please.

# Documentation and API Usage

- Always use Context7 MCP when I need library/API documentation, code generation, setup, or configuration steps, without me having to explicitly ask.

# Improving Shared Instructions and Skills

- `~/.codex/AGENTS.md` is the shared instruction source, loaded automatically for you, directly or through an alias.
- `~/.agents/skills/` holds shared skills. You discover them automatically and load full skill instructions when relevant, according to your harness's loading rules.
- Look for reusable improvements when you notice repeated corrections, missing guidance, or a workflow that would benefit from a skill. Suggest edits or additions to either location.
- Propose a concise change and explain its benefit. Prefer improving existing guidance over adding duplicates; keep project-specific lessons in the project's own instructions or skills.
- Suggest improvements without interrupting the task. Don't edit shared instructions or skills without the user's approval.

# UI tests

- You can test UI changes in your browser, if it makes sense.
- If a server must be running, always check whether the server is already running first.

# Implementation Simplicity

- Understand the affected flow before editing. Fix root causes at the narrowest shared layer; inspect affected callers.
- Before adding code or dependencies, prefer existing project code, then the standard library, native platform features, and installed dependencies.
- Do not add unrequested features, speculative abstractions, future scaffolding, or avoidable dependencies. Choose the smallest clear diff that fully meets the request.
- Minimalism never overrides correctness, readability, edge cases, validation, error handling, security, accessibility, data-loss protection, or project test conventions.

# Git Safety

- don't do any actions that change the index, unless explicitly asked to
- even when asked to 'change staged files', read staged changes but don't update index by default
- when any staged files are in the way, offer to make a commit when on a feature branch, or to stash staged files
- don't modify any other branches that you're not explicitly told to modify

# Tool usage

- Whenever you'd need a cli/mcp tool installed in order to complete a task in a much simpler/better way, ask the user to install it - preferably via homebrew or mise

# Package Update Policy

- Keep a project-local `.tool-versions` file to be installed via `mise`
  - this can also have `gem:RUBYGEM` or `npm:PACKAGE` package versions
- Generally do not rely on system-installed tools; only use baseline utilities such as `bash`, `curl`, `jq`, and similar ubiquitous shell tools unless explicitly required.
- Use `mise ls-remote TOOLNAME` to list available versions.
- In GitHub workflows, generally install pinned tools via `mise` using `jdx/mise-action`:
```yaml
    - name: Setup tools
      uses: jdx/mise-action@1648a7812b9aeae629881980618f079932869151 # v4.0.1
```
- Pin external GitHub Actions to full commit SHA, not tags like `@v4` or branches like `@main`.
- Prefer small version steps when updating tools or packages to keep compatibility and the process predictable.
- If a tool or package had many minor and tiny version updates in the past, and the newest available version ends in `.0`, treat it as potentially unstable and ask the user whether to use that version or the previous version.
- When updating tools, packages or GitHub actions, read upstream changelog first; if missing, read GitHub Releases.
- When updating a tool or package, check other common version pin locations too, such as version/lock files and infra/automation files such as `Dockerfile` and `Justfile`.
- Don't change version constraints unless required to update a version.

# Justfile

- Keep a project-local `Justfile` for reusable scripts
- Run `just --list` before working to know what recipes are available
- The first recipe should be:
  ```
  _default:
    @just --list
  ```
- Simple checks for existing commands, files, directories etc. should be private one-line recipes
  ```
  _cmd cmd:
    @command -v "{{cmd}}" >/dev/null || { echo "Missing command: {{cmd}}" >&2; exit 1; }
  ```
  used as dependencies for other recipes, e.g.
  ```
  setup: (_cmd "bun")
    @bun install
  ```
- No need to check for commands defined in `.tool-versions`
- Some canonical recipes: `check` for all checks, `start` for local development, `format`, `setup`
  - these can have more specific recipes as dependencies, e.g. `test`, `setup-backend`, ...
- CI steps should use these recipes, not have their own scripts
- When changing Bash recipes, add a concise one-line comment before each major check or block. Explain its purpose and omit the trailing period
- In Bash recipes, flatten nested condition groups using the same operator (`&&` or `||`). Keep grouping only where needed to preserve mixed-operator logic.
- In a `Justfile`, wrap lines you add or change at 100 characters.
- Once a condition wraps, put each condition or nested group on its own line, aligned with the first condition. Keep operators at line ends and the closing `]]` aligned with `if`:
  ```bash
  if [[ ! -L "$source_file" &&
        ! -f "$source_file" &&
        ! -f "$source_file/.link-directory"
  ]]; then
      ...
  fi
  ```

# Formatting

- Use meaningful emojis and colors for human-facing messages. Use green for main actions toward the goal, blue for auxiliary actions such as backups and directory creation, neutral for already-correct states, yellow for warnings needing attention, and red for errors.
- Print each action as a complete line before execution, without a trailing success mark.
- Dry runs print the same action with `[DRY RUN]`.
- Let commands print errors directly to stderr and preserve failure status.
- Keep machine-readable output free of colors and emojis.
- Print normal progress, successful actions, and dry-run previews to stdout. Print errors and warnings needing attention to stderr; routine backup messages stay on stdout.
- Keep printing helpers stream-neutral; callers redirect to stderr with `>&2` when needed.

# Elixir

- For Elixir work, apply the `$elixir-development` skill.
- Default to fail-fast behavior inside trusted, supervised code; handle expected failures and external trust boundaries explicitly.

# Secret Safety (Hard Deny by Default)

- Deny commands that read secret files or may expose sensitive values.
- Existence checks and metadata-only checks are allowed when they do not read secret contents.

## Never Read Secret Env Files

- Never open, read, or print `.env`, `.envrc`, `.env.*`, or `.envrc.*`.
- Never run commands that can reveal their contents directly or indirectly, including through transforms/pipes such as `grep`, `awk`, `sed`, `head`, `tail`, or `wc`.

## Never Print Sensitive Environment Values

- Never dump the environment with bare `env`, unrestricted `printenv`, bare `export`, or `export -p`.
- Assigning or exporting non-sensitive values is allowed; don't expose secrets in commands or output.
- Never print sensitive variables via `echo`, `printf`, `printenv`, `${...}`, command substitution, or `eval`.
- Never search environment output for sensitive patterns (for example `env | grep TOKEN`).

## Sensitive Variable Patterns

- Exact names:
  `ACCESS_KEY`, `API_KEY`, `AUTH`, `BEARER`, `CREDENTIAL`, `CREDENTIALS`, `DATABASE_URL`, `KEY`, `PASS`, `PASSWORD`, `SECRET`, `SECRET_KEY`, `TOKEN`
- Sensitive suffix pattern:
  `_(AUTH|BEARER|CREDENTIAL|HOST|KEY|PASS|PASSWORD|SALT|SECRET|TOKEN|USER)`
- Sensitive prefix pattern:
  `^(AWS|SECRET|SSH|TF_VAR)_`
- Sensitive contains pattern:
  `_SSH_`

## Sensitive File Patterns

- Treat all `*.key` files as sensitive by default.
- Exception: `public.key` is allowed.

## Non-Sensitive Exceptions

- Variables matching these patterns are non-sensitive by default:
  `PUBLIC_KEY`, `PUBLIC_*`, `*_PUBLIC`, `*_PUBLIC_*`

## Required Behavior on Risky Requests

- Refuse unsafe commands.
- Briefly explain that the command may expose secrets.
- Offer a safe alternative (redacted output, existence checks, schema/structure checks, or placeholders).
- If uncertain whether a command may leak secrets, deny by default.
