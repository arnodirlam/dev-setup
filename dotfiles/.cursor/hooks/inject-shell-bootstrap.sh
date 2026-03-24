#!/usr/bin/env bash
set -euo pipefail

# Cursor preToolUse hook for the Shell tool.
# It rewrites only the Shell tool command to source our bootstrap script.

payload="$(cat)"

tool_name="$(jq -r '.tool_name // empty' <<<"$payload")"
cmd="$(jq -r '.tool_input.command // empty' <<<"$payload")"

if [[ "$tool_name" != "Shell" || -z "$cmd" ]]; then
  jq -n '{ permission: "allow" }'
  exit 0
fi

# Avoid double-injection when multiple hooks/transforms run.
if [[ "$cmd" == *"CURSOR_AGENT_SHELL_BOOTSTRAP_MARKER=1"* ]]; then
  jq -n '{ permission: "allow" }'
  exit 0
fi

BOOTSTRAP_PREFIX='CURSOR_AGENT_SHELL_BOOTSTRAP_MARKER=1; . "$HOME/.cursor/hooks/bootstrap-shell-env.sh" >/dev/null 2>&1 || true; '
new_cmd="${BOOTSTRAP_PREFIX}${cmd}"

jq -n --arg permission "allow" --arg updated_command "$new_cmd" '
  { permission: $permission, updated_input: { command: $updated_command } }
'

