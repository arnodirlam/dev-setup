# Documentation and API Usage

- Always use Context7 MCP when I need library/API documentation, code generation, setup, or configuration steps, without me having to explicitly ask.

# Package Update Policy

- Always keep a project-local `.tool-versions` file with pinned mise-managed versions for every tool used by the project, including local scripts, `just` tasks, CI workflows, and automation.
- Generally do not rely on system-installed tools; only use baseline utilities such as `bash`, `curl`, `jq`, and similar ubiquitous shell tools unless explicitly required.
- In GitHub workflows, generally install pinned tools via `mise` using `jdx/mise-action@v4`:
```yaml
    - name: Setup tools
      uses: jdx/mise-action@v4
```
- Always run `mise install` whenever `.tool-versions` changes.
- When updating a tool, run `mise ls-remote TOOLNAME` first to review available versions.
- Prefer small version steps when updating tools or language-specific packages to keep compatibility and the process predictable.
- If the newest available version ends in `.0`, treat it as potentially unstable and ask the user whether to use that version or the previous version.
- When updating a tool or language-specific package, check other common version pin locations too, including version/lock files and infra/automation files such as `Dockerfile` and `Justfile`.

# Secret Safety (Hard Deny by Default)

- Deny any command that references `.env*`, `.envrc*`, or sensitive variable names/patterns, even if it does not directly read or print values.

## Never Read Secret Env Files

- Never open, read, or print `.env`, `.envrc`, `.env.*`, or `.envrc.*`.
- Never run commands that can reveal their contents directly or indirectly, including through transforms/pipes such as `grep`, `awk`, `sed`, `head`, `tail`, or `wc`.

## Never Print Sensitive Environment Values

- Never run environment dump commands: `env`, `printenv` (without a specific safe variable), `export`, `export -p`, or `export --`.
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
