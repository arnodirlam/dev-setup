#!/bin/bash

# Cursor Hook Script: Prevent Secret Exposure
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

  # Exclude public/non-sensitive patterns first
  case "$var_name" in
    PUBLIC_KEY|PUBLIC_*|*_PUBLIC|*_PUBLIC_*)
      return 1
      ;;
  esac

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
  local user_msg="🛑 $msg\n\n$command"

  # Use jq to properly encode JSON
  jq -n \
    --arg permission "deny" \
    --arg userMessage "$user_msg" \
    --arg agentMessage "$agent_msg" \
    '{permission: $permission, userMessage: $userMessage, agentMessage: $agentMessage}'
  exit 0
}

respond_ask() {
  local msg="$1"
  local agent_msg="This command may access sensitive data (.envrc files or environment variables ending with _KEY, _TOKEN, _PASSWORD, etc.). User approval required."
  local user_msg="⚠️ $msg"

  # Use jq to properly encode JSON
  jq -n \
    --arg permission "ask" \
    --arg userMessage "$user_msg" \
    --arg agentMessage "$agent_msg" \
    '{permission: $permission, userMessage: $userMessage, agentMessage: $agentMessage}'
  exit 0
}

respond_allow() {
  echo '{"permission":"allow"}'
  exit 0
}

# ==============================================================================
# SECURITY CHECKS - TIER 1: DENY (unambiguous attempts)
# ==============================================================================

# Common patterns for regex reuse
READ_COMMANDS="cat|less|more|head|tail|view|bat|nl|vim|vi|nano|emacs|code|open"
ENV_FILE_PATTERN="\.env(rc)?"
DELIMITER_PATTERN="([[:space:];]|$|\&\&|\|\|)"
WORD_BOUNDARY="(^|[[:space:];/]|\&\&|\|\|)"

# Check 1: Direct .env/.envrc file reading (no pipes/transformations)
# DENY: cat .env, cat .envrc (exact files only)
# ASK: cat .env.local, cat .envrc.production (variants handled by Check 3)
# Note: Skip commands with pipes (|) since they involve transformations
# Allow || and && (command chains without transformations)
if [[ ! "$command" =~ [^|]\|[^|] ]] && [[ "$command" =~ ($READ_COMMANDS)[[:space:]] ]]; then
  # Remove quotes for normalized pattern matching
  cmd_normalized="${command//\'/}"
  cmd_normalized="${cmd_normalized//\"/}"

  # Check for exact .env or .envrc files (DENY)
  # Patterns to match:
  #   - At start or after delimiter: .env, .envrc
  #   - With path: /path/.env, ~/dir/.envrc
  #   - In command chains: && cat .env, || vim .envrc
  # Obfuscation attempts like .envfile will be caught by Check 3 (ASK)
  if [[ "$cmd_normalized" =~ $WORD_BOUNDARY$ENV_FILE_PATTERN$DELIMITER_PATTERN ]] || \
     [[ "$cmd_normalized" =~ /$ENV_FILE_PATTERN$DELIMITER_PATTERN ]]; then
    # Extract the matched filename
    if [[ "$cmd_normalized" =~ (/?$ENV_FILE_PATTERN)$DELIMITER_PATTERN ]]; then
      matched_file="${BASH_REMATCH[1]}"
      respond_deny "Reading $matched_file file (may contain secrets)"
    fi
  fi
fi

# Check 2: Direct printing of sensitive environment variables (no pipes)
# DENY: echo $SENSITIVE_KEY, printenv SENSITIVE_TOKEN
# ASK: echo $VAR | base64 (has transformation)
# Cache the result to avoid re-scanning in Check 4
sensitive_var_cached=""
sensitive_var_checked=false

# Check for commands that dump all environment variables (runs for all commands, including piped)
# Match: env, printenv with no args (or followed by |;&); export with -p/-- or at end
# Use [[:space:]]*([|;&]|$) so printenv VAR / env VAR don't match (they have a word after space)
if [[ "$command" =~ (^|[[:space:];|&/])(printenv|env)[[:space:]]*([|;&]|$) ]] || \
   [[ "$command" =~ (^|[[:space:];|&/])export[[:space:]]+(-p|--) ]] || \
   [[ "$command" =~ (^|[[:space:];|&/])export[[:space:]]*([|;&]|$) ]]; then
  respond_ask "Command may print all environment variables (may include secrets)"
fi

# Check for process substitution that dumps environment
if [[ "$command" =~ \<\([[:space:]]*(env|printenv|export) ]]; then
  respond_ask "Command uses process substitution to read environment (may include secrets)"
fi

# Check for eval - can execute arbitrary code including hidden variable access
if [[ "$command" =~ (^|[[:space:];|&/])eval[[:space:]] ]]; then
  respond_ask "Command uses eval which can execute arbitrary code"
fi

if [[ ! "$command" =~ \| ]]; then
  # For printenv with specific variable, extract the variable name
  # Handle quoted and unquoted variable names: printenv PASSWORD, printenv "PASSWORD"
  if [[ "$command" =~ ^[[:space:]]*printenv[[:space:]]+[\"\']?([A-Z_][A-Z0-9_]*)[\"\']? ]]; then
    var_name="${BASH_REMATCH[1]}"
    if is_sensitive "$var_name"; then
      respond_deny "Printing sensitive variable: $var_name"
    fi
  fi

  # Check for echo or printf with $VAR patterns
  if [[ "$command" =~ ^[[:space:]]*(echo|printf)[[:space:]]+ ]]; then
    sensitive_var_cached=$(find_sensitive_var_in_command "$command" || true)
    sensitive_var_checked=true
    if [ "$sensitive_var_cached" = "<<TOO_MANY_VARS>>" ]; then
      respond_ask "Command has 50+ variables - too many to scan safely"
    elif [ -n "$sensitive_var_cached" ]; then
       respond_deny "Printing sensitive variable: $sensitive_var_cached"
    fi
  fi

  # Check for command substitution with printenv: $(printenv SECRET), `printenv SECRET`
  if [[ "$command" =~ \$\(printenv[[:space:]]+[\"\']?([A-Z_][A-Z0-9_]*) ]] || \
     [[ "$command" =~ \`printenv[[:space:]]+[\"\']?([A-Z_][A-Z0-9_]*) ]]; then
    var_name="${BASH_REMATCH[1]}"
    if is_sensitive "$var_name"; then
      respond_ask "Command substitution may print sensitive variable: $var_name"
    fi
  fi
fi

# ==============================================================================
# SECURITY CHECKS - TIER 2: ASK (ambiguous or potentially legitimate)
# ==============================================================================

# Check 3: Any .env/.envrc reference that wasn't already denied
# ASK: ALL .env.* and .envrc.* files (including .env.local, .env.example, etc.)
# But skip false positives (backup.env, config.envrc, quoted strings)
# Only match if .env/.envrc starts a filename (after space, slash, quote, or at start)
# Skip if .env appears inside a quoted string (like grep 'check .env file')
# Skip if .env is inside a quoted string argument (not a filename)
# Pattern: 'text .env text' or "text .env text" where .env is surrounded by text
if [[ "$command" =~ (^|[[:space:]/\'\"])$ENV_FILE_PATTERN ]] && \
   [[ ! "$command" =~ [\'\"](.* [[:space:]])?$ENV_FILE_PATTERN([[:space:]].*)?[\'\"](.*[[:space:]]|$) ]]; then
    respond_ask "Command references .env/.envrc file - approve if safe"
fi

# Check 3b: Files ending with .key (private keys, certificates, etc.)
# ASK: cat private.key, vim server.key, *.key, $(echo private.key)
# Exclude public.key (public keys are not sensitive)
if [[ "$command" =~ ([^[:space:]]+\.key)($DELIMITER_PATTERN|\)|[\"\']) ]]; then
    filename="${BASH_REMATCH[1]}"
    if [[ ! "$filename" =~ public\.key$ ]]; then
        respond_ask "Command references $filename file - approve if safe"
    fi
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
    # Case-insensitive check for sensitive patterns (use tr for bash 3.2 compatibility)
    pattern_upper=$(echo "$pattern" | tr '[:lower:]' '[:upper:]')
    if [[ "$pattern_upper" =~ (KEY|TOKEN|PASSWORD|PASS|SECRET|AUTH|BEARER|CREDENTIAL|AWS|SSH) ]]; then
       respond_ask "Command might search for sensitive pattern: $pattern"
    fi
  fi
fi

# ==============================================================================
# SECURITY CHECKS - TIER 3: ALLOW (safe commands)
# ==============================================================================

respond_allow
