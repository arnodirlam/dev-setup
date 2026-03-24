#!/usr/bin/env bash
set -euo pipefail

# This script is intended to be *sourced* by Cursor Agent shell commands
# (via the preToolUse injector hook).

if [[ "${CURSOR_AGENT_SHELL_BOOTSTRAP_DONE:-}" == "1" ]]; then
  return 0
fi

export CURSOR_AGENT_SHELL_BOOTSTRAP_DONE=1

# Homebrew: initialize PATH for brew-installed binaries (macOS arm64 default).
if [[ -x "/opt/homebrew/bin/brew" ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
elif command -v brew >/dev/null 2>&1; then
  eval "$(brew shellenv)"
fi

# mise: initialize shims.
# We intentionally activate for `bash` even in zsh because `mise activate zsh`
# can emit zsh-specific code that may fail in non-interactive contexts.
if command -v mise >/dev/null 2>&1; then
  eval "$(mise activate bash)" || true
fi

# direnv: export any `.envrc` for the current working directory (best-effort).
if command -v direnv >/dev/null 2>&1; then
  # `direnv export` prints shell code (typically `export ...`) which we eval.
  # Errors commonly occur when no .envrc is present; don't break the session.
  eval "$(direnv export bash 2>/dev/null)" || true
fi

return 0

