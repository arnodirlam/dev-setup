#!/bin/bash

# Cursor Hook Script: Block Sensitive Commands
# This hook runs before shell execution to prevent access to sensitive data
# Three-tier security system:
#   1. DENY - Unambiguous attempts to access sensitive data (blocked outright)
#   2. ASK - Ambiguous cases that might be legitimate (prompt for approval)
#   3. ALLOW - Safe commands (no prompt)

# Enable strict error handling
set -euo pipefail
# trap 'respond_deny "Internal error in security hook"' ERR

# ==============================================================================
# INPUT PARSING
# ==============================================================================

# Read JSON input from stdin and extract command
command=$(jq -r '.command')

# ==============================================================================
# HELPER FUNCTIONS
# ==============================================================================

# Check if a variable name matches any sensitive pattern
is_sensitive() {
  local var_name=$1

  # Fast exact match check using case statement
  case "$var_name" in
    ACCESS_KEY|API_KEY|AUTH|BEARER|CREDENTIAL|CREDENTIALS|DATABASE_URL|KEY|PASS|PASSWORD|SECRET_KEY|SECRET|TOKEN)
      return 0
      ;;
  esac

  # Combined suffix patterns (one regex instead of 11 separate checks)
  [[ "$var_name" =~ _(AUTH|BEARER|CREDENTIAL|HOST|KEY|PASS|PASSWORD|SALT|SECRET|TOKEN|USER)$ ]] && return 0

  # Combined prefix patterns (one regex instead of 4 separate checks)
  [[ "$var_name" =~ ^(AWS|SECRET|SSH|TF_VAR)_ ]] && return 0

  # Contains patterns
  [[ "$var_name" =~ _SSH_ ]] && return 0

  return 1
}

# Extract variables from command and find first sensitive one
# Returns: sensitive variable name if found, "<<TOO_MANY_VARS>>" if iteration limit hit, empty string otherwise
# Stops early when sensitive variable is found for efficiency
find_sensitive_var_in_command() {
  local cmd="$1"
  local max_iterations=50
  local iteration_count=0

  # Extract $VAR or ${VAR} patterns and check if sensitive
  while [[ "$cmd" =~ \$\{?([A-Z_][A-Z0-9_]*) ]]; do
    local var_name="${BASH_REMATCH[1]}"
    local match="${BASH_REMATCH[0]}"

    # Check if this variable is sensitive
    if is_sensitive "$var_name"; then
      echo "$var_name"
      return 0
    fi

    # Remove matched part and continue
    cmd="${cmd#*$match}"

    # Safety check to prevent infinite loops
    iteration_count=$((iteration_count + 1))
    if [ $iteration_count -ge $max_iterations ]; then
      # Return special marker (contains invalid chars for env var names)
      echo "<<TOO_MANY_VARS>>"
      return 0
    fi
  done

  return 1
}

# ==============================================================================
# RESPONSE FUNCTIONS
# ==============================================================================

respond_deny() {
  local msg="$1"
  local agent_msg="This command was blocked by security hook because it attempts to directly access sensitive data (.envrc files or environment variables ending with _KEY, _TOKEN, _PASSWORD, etc.)."

  # Manually construct JSON, escaping quotes in messages
  # Include the blocked command in the message
  local cmd_escaped="${command//\"/\\\"}"
  msg="${msg//\"/\\\"}"
  agent_msg="${agent_msg//\"/\\\"}"

  echo "{\"permission\":\"deny\",\"userMessage\":\"🛑 $msg\n\n$cmd_escaped\",\"agentMessage\":\"$agent_msg\"}"
  exit 0
}

respond_ask() {
  local msg="$1"
  local agent_msg="This command may access sensitive data (.envrc files or environment variables ending with _KEY, _TOKEN, _PASSWORD, etc.). User approval required."

  # Manually construct JSON, escaping quotes in messages
  msg="${msg//\"/\\\"}"
  agent_msg="${agent_msg//\"/\\\"}"

  echo "{\"permission\":\"ask\",\"userMessage\":\"⚠️ Security Hook: $msg\",\"agentMessage\":\"$agent_msg\"}"
  exit 0
}

respond_allow() {
  echo '{"permission":"allow"}'
  exit 0
}

# ==============================================================================
# SECURITY CHECKS - TIER 1: DENY (unambiguous attempts)
# ==============================================================================

# Check 1: Direct .envrc file reading (no pipes/transformations)
# DENY: cat .envrc, less .envrc, vim .envrc
# ASK: cat .envrc | grep (has transformation)
if [[ ! "$command" =~ \| ]]; then
  if [[ "$command" =~ ^[[:space:]]*(cat|less|more|head|tail|view|bat|nl|vim|vi|nano|emacs|code|open)[[:space:]]+\.envrc[[:space:]]*$ ]] || \
     [[ "$command" =~ ^[[:space:]]*(cat|less|more|head|tail|view|bat|nl|vim|vi|nano|emacs|code|open)[[:space:]]+.*/\.envrc[[:space:]]*$ ]] || \
     [[ "$command" =~ ^[[:space:]]*(cat|less|more|head|tail|view|bat|nl|vim|vi|nano|emacs|code|open)[[:space:]]+\.envrc[[:space:]]*\;.*$ ]] || \
     [[ "$command" =~ ^[[:space:]]*(cat|less|more|head|tail|view|bat|nl|vim|vi|nano|emacs|code|open)[[:space:]]+.*/\.envrc[[:space:]]*\;.*$ ]]; then
    respond_deny "Reading .envrc file contents (may contain secrets)"
  fi
fi

# Check 2: Direct printing of sensitive environment variables (no pipes)
# DENY: echo $SENSITIVE_KEY, printenv SENSITIVE_TOKEN
# ASK: echo $VAR | base64 (has transformation)
# Cache the result to avoid re-scanning in Check 4
sensitive_var_cached=""
sensitive_var_checked=false

if [[ ! "$command" =~ \| ]]; then
  if [[ "$command" =~ ^[[:space:]]*(echo|printenv)[[:space:]]+ ]]; then
    sensitive_var_cached=$(find_sensitive_var_in_command "$command" || true)
    sensitive_var_checked=true
    if [ "$sensitive_var_cached" = "<<TOO_MANY_VARS>>" ]; then
      respond_ask "Command has 50+ variables - too many to scan safely"
    elif [ -n "$sensitive_var_cached" ]; then
       respond_deny "Printing sensitive variable: $sensitive_var_cached"
    fi
  fi
fi

# ==============================================================================
# SECURITY CHECKS - TIER 2: ASK (ambiguous or potentially legitimate)
# ==============================================================================

# Check 3: Any .envrc reference that wasn't already denied
# ASK: find .envrc, grep .envrc, cat .envrc.example
if [[ "$command" =~ \.envrc ]]; then
    respond_ask "Command references .envrc file - approve if safe"
fi

# Check 4: Commands printing sensitive variables (with transformations)
# ASK: echo $VAR | base64, env | grep sensitive patterns
# Reuse cached result if already scanned in Check 2, otherwise scan now
if [ "$sensitive_var_checked" = false ]; then
  sensitive_var_cached=$(find_sensitive_var_in_command "$command" || true)
fi

if [ "$sensitive_var_cached" = "<<TOO_MANY_VARS>>" ]; then
  respond_ask "Command contains many variables (50+) - manual review recommended"
elif [ -n "$sensitive_var_cached" ]; then
  respond_ask "Command might attempt to print sensitive variable: $sensitive_var_cached"
fi

# Check 5: Grepping for sensitive patterns
# ASK: env | grep TOKEN, export | grep KEY
if [[ "$command" =~ (env|export|printenv)[[:space:]]*\|[[:space:]]*grep ]]; then
  if [[ "$command" =~ grep[[:space:]]+-?[a-z]*[[:space:]]*[\'\"]?([A-Z_a-z0-9]+) ]]; then
    pattern="${BASH_REMATCH[1]}"
    if [[ "$pattern" =~ (KEY|TOKEN|PASSWORD|PASS|SECRET|AUTH|BEARER|CREDENTIAL|AWS|SSH) ]]; then
       respond_ask "Command might search for sensitive pattern: $pattern"
    fi
  fi
fi

# ==============================================================================
# SECURITY CHECKS - TIER 3: ALLOW (safe commands)
# ==============================================================================

respond_allow
