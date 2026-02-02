#!/bin/bash

# Test suite for prevent-secret-exposure.sh hook
# Tests the hook's ability to detect and block sensitive data access

set -uo pipefail

# ==============================================================================
# SETUP AND CONFIGURATION
# ==============================================================================

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOOK_SCRIPT="$SCRIPT_DIR/prevent-secret-exposure.sh"

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Test counters
TESTS_PASSED=0
TESTS_FAILED=0
TESTS_TOTAL=0

# Error collection
ERRORS_OUTPUT=""

# ==============================================================================
# TEST FRAMEWORK FUNCTIONS
# ==============================================================================

# Run the hook script with a command and capture output
# Args: $1 = command string
# Sets global variables: HOOK_OUTPUT, HOOK_EXIT_CODE, HOOK_STDERR
run_hook() {
    local command="$1"

    # Create JSON input
    local json_input
    json_input=$(jq -n --arg cmd "$command" '{command: $cmd}')

    # Run hook and capture output, stderr, and exit code
    set +e
    HOOK_STDERR=$(mktemp)
    HOOK_OUTPUT=$(echo "$json_input" | "$HOOK_SCRIPT" 2>"$HOOK_STDERR")
    HOOK_EXIT_CODE=$?
    HOOK_STDERR_CONTENT=$(cat "$HOOK_STDERR")
    rm "$HOOK_STDERR"
    set -e
}

# Handle a passing test
handle_pass() {
    TESTS_PASSED=$((TESTS_PASSED + 1))
    echo -ne "${GREEN}.${NC}"
}

# Handle a failing test
# Args: $1 = heading (without color), $2+ = detail lines (one per argument)
handle_fail() {
    local heading="$1"
    shift

    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo -ne "${RED}✗${NC}"

    # Join all details with newlines
    local details
    details=$(printf "%s\n" "$@")

    # Indent before all newlines
    details="${details//$'\n'/$'\n'  }"

    # Collect error details
    ERRORS_OUTPUT+="${RED}✗ ${heading}${NC}\n  ${details}\n\n"
}

# Assert that the permission matches expected value
# Args: $1 = expected permission (deny/ask/allow), $2 = command, $3 = test name (optional, defaults to command)
assert_permission() {
    local expected="$1"
    local command="$2"
    local test_name="${3:-$command}"

    TESTS_TOTAL=$((TESTS_TOTAL + 1))

    # Run the hook
    run_hook "$command"

    # Check for crash
    if [ $HOOK_EXIT_CODE -ne 0 ]; then
        handle_fail "CRASH: $test_name" \
            "Command: $command" \
            "Exit code: $HOOK_EXIT_CODE" \
            "Stderr: $HOOK_STDERR_CONTENT"
        return 0
    fi

    # Parse JSON output
    local actual
    actual=$(echo "$HOOK_OUTPUT" | jq -r '.permission' 2>/dev/null)
    local jq_exit=$?

    if [ $jq_exit -ne 0 ] || [ -z "$actual" ] || [ "$actual" = "null" ]; then
        handle_fail "INVALID JSON: $test_name" \
            "Command: $command" \
            "Output: $HOOK_OUTPUT" \
            "Stderr: $HOOK_STDERR_CONTENT"
        return 0
    fi

    # Compare permission
    # Workaround: Cursor 2.4.21+ ignores "ask" - when expected is "ask", accept "deny" as pass
    if [ "$actual" = "$expected" ]; then
        handle_pass
    elif [ "$expected" = "ask" ] && [ "$actual" = "deny" ]; then
        handle_pass
    else
        local user_msg
        user_msg=$(echo "$HOOK_OUTPUT" | jq -r '.userMessage' 2>/dev/null)

        if [ -n "$user_msg" ] && [ "$user_msg" != "null" ]; then
            handle_fail "FAILED: $test_name" \
                "Command: $command" \
                "Expected permission: $expected" \
                "Actual permission: $actual" \
                "User message: $user_msg"
        else
            handle_fail "FAILED: $test_name" \
                "Command: $command" \
                "Expected permission: $expected" \
                "Actual permission: $actual"
        fi
    fi

    return 0
}

# ==============================================================================
# TEST SUITE
# ==============================================================================

echo -e "${CYAN}Starting test suite for prevent-secret-exposure.sh${NC}"
echo -e "Hook script: $HOOK_SCRIPT"
echo ""

# ------------------------------------------------------------------------------
# TIER 1: DENY Tests (Commands that should be blocked outright)
# ------------------------------------------------------------------------------
# DENY only for direct content access to exact .env or .envrc
# (Not .env.*, not .envrc.* - those are ASK)
# ------------------------------------------------------------------------------

# Direct .envrc reading
assert_permission "deny" "cat .envrc"
assert_permission "deny" "less .envrc"
assert_permission "deny" "more .envrc"
assert_permission "deny" "head .envrc"
assert_permission "deny" "tail .envrc"
assert_permission "deny" "view .envrc"
assert_permission "deny" "bat .envrc"
assert_permission "deny" "vim .envrc"
assert_permission "deny" "vi .envrc"
assert_permission "deny" "nano .envrc"
assert_permission "deny" "emacs .envrc"
assert_permission "deny" "code .envrc"
assert_permission "deny" "open .envrc"

# Direct .env reading
assert_permission "deny" "cat .env"
assert_permission "deny" "less .env"
assert_permission "deny" "vim .env"
assert_permission "deny" "code .env"

# .envrc with paths
assert_permission "deny" "cat /path/to/.envrc"
assert_permission "deny" "less ~/project/.envrc"
assert_permission "deny" "cat ./some/dir/.envrc"

# .env with paths
assert_permission "deny" "cat /path/to/.env"
assert_permission "deny" "less ~/project/.env"
assert_permission "deny" "cat ./some/dir/.env"

# .envrc with trailing semicolons
assert_permission "deny" "cat .envrc;"
assert_permission "deny" "cat .envrc; echo done"
assert_permission "deny" "cat /path/.envrc; ls"

# .envrc with cd to .envrc
assert_permission "deny" "cd path && cat .envrc"
assert_permission "deny" "cd path/project && cat .envrc"
assert_permission "deny" "cd /usr/project && cat .envrc"
assert_permission "deny" "cd \"my path/project\" && cat .envrc"

# .env with trailing semicolons
assert_permission "deny" "cat .env;"
assert_permission "deny" "cat .env; echo done"

# nl command (line numbering tool) - DENY for exact .env/.envrc
assert_permission "deny" "nl .env"
assert_permission "deny" "nl .envrc"

# Multiple files - DENY if any is exact .env or .envrc
assert_permission "deny" "cat .env .env.local"

# Command chaining - DENY for exact .env/.envrc
assert_permission "deny" "cat README.md && cat .env"

# Path edge cases - DENY for exact .env/.envrc
assert_permission "deny" "cat ./.env"

# Quoted filenames - should still DENY for exact .env/.envrc
assert_permission "deny" "cat \".env\""
assert_permission "deny" "cat '.env'"
assert_permission "deny" "vim \".envrc\""
assert_permission "deny" "less '.envrc'"

# Quoted variables - should still DENY for sensitive variables
assert_permission "deny" "echo \"\$SECRET\""
assert_permission "deny" "echo '\$API_KEY'"
assert_permission "deny" "printenv \"PASSWORD\""

# Quoted braced variables - should still DENY
assert_permission "deny" "echo \"\${SECRET}\""
assert_permission "deny" "echo \"\${API_KEY}\""
assert_permission "deny" "echo '\${PASSWORD}'"

# Direct printing of sensitive environment variables
assert_permission "deny" "echo \$API_KEY"
assert_permission "deny" "echo \$SECRET"
assert_permission "deny" "echo \$PASSWORD"
assert_permission "deny" "echo \$TOKEN"
assert_permission "deny" "echo \$AWS_SECRET_KEY"
assert_permission "deny" "echo \$DATABASE_PASSWORD"
assert_permission "deny" "echo \$STRIPE_SECRET_KEY"
assert_permission "deny" "echo \$SSH_PRIVATE_KEY"
assert_permission "deny" "echo \$GITHUB_TOKEN"
assert_permission "deny" "echo \$AUTH_TOKEN"
assert_permission "deny" "echo \$BEARER_TOKEN"
assert_permission "deny" "echo \$CREDENTIALS"
assert_permission "deny" "echo \$DATABASE_URL"
assert_permission "deny" "echo \${SECRET_KEY}"
assert_permission "deny" "echo 'literal \$SECRET'"
assert_permission "deny" "printenv AWS_ACCESS_KEY"
assert_permission "deny" "printenv SECRET"

# Sensitive variable patterns
assert_permission "deny" "echo \$MY_API_KEY"
assert_permission "deny" "echo \$REDIS_PASSWORD"
assert_permission "deny" "echo \$JWT_TOKEN"
assert_permission "deny" "echo \$DB_USER"
assert_permission "deny" "echo \$API_SECRET"
assert_permission "deny" "echo \$TF_VAR_password"
assert_permission "deny" "echo \$SECRET_SAUCE"

# Braced variable syntax - should also be DENIED
assert_permission "deny" "echo \${API_KEY}"
assert_permission "deny" "echo \${SECRET}"
assert_permission "deny" "echo \${PASSWORD}"
assert_permission "deny" "echo \${TOKEN}"
assert_permission "deny" "echo \${AWS_SECRET_KEY}"
assert_permission "deny" "echo \${DATABASE_PASSWORD}"
assert_permission "deny" "echo \${SSH_PRIVATE_KEY}"
assert_permission "deny" "echo \${CREDENTIALS}"
assert_permission "deny" "echo \${MY_API_KEY}"
assert_permission "deny" "echo \${DB_USER}"

# Braced variable with expansions - should also be DENIED
assert_permission "deny" "echo \${SECRET:-default}"
assert_permission "deny" "echo \${API_KEY:0:5}"
assert_permission "deny" "echo \${PASSWORD:?error}"
assert_permission "deny" "echo \${TOKEN#prefix}"
assert_permission "deny" "echo \${AWS_SECRET_KEY%suffix}"

# printf with sensitive variables
assert_permission "deny" "printf \"%s\" \$SECRET" "printf with sensitive var"
assert_permission "deny" "printf \"%s\\n\" \$API_KEY" "printf with format and sensitive var"
assert_permission "deny" "printf \$PASSWORD" "printf with just sensitive var"
assert_permission "deny" "printf \"\${TOKEN}\"" "printf with braced sensitive var"

# ------------------------------------------------------------------------------
# TIER 2: ASK Tests (Commands requiring user approval)
# ------------------------------------------------------------------------------
# ASK for:
# 1. Any .env.* or .envrc.* variants (including .example, .sample, .template, etc)
# 2. Any *.key files (treated same as .env.* variants)
# 3. Commands with pipes/transformations on .env or .envrc
# 4. Metadata commands on .env or .envrc files
# 5. Sensitive variable references
# ------------------------------------------------------------------------------

# .envrc with pipes/transformations
assert_permission "ask" "cat .envrc | grep API"
assert_permission "ask" "cat .envrc | head -n 5"
assert_permission "ask" "less .envrc | wc -l"

# .env with pipes/transformations
assert_permission "ask" "cat .env | grep API"
assert_permission "ask" "cat .env | head -n 5"
assert_permission "ask" "less .env | wc -l"

# .env.* variants with pipes
assert_permission "ask" "cat .env.local | grep KEY"

# .envrc references in other contexts
assert_permission "ask" "find . -name .envrc"
assert_permission "ask" "grep -r .envrc ."
assert_permission "ask" "ls -la .envrc"
assert_permission "ask" "file .envrc"
assert_permission "ask" "stat .envrc"

# .env references in other contexts
assert_permission "ask" "find . -name .env"
assert_permission "ask" "find . -name '.env.*'"
assert_permission "ask" "grep -r .env ."
assert_permission "ask" "ls -la .env"
assert_permission "ask" "stat .env.local"

# Sensitive variables with transformations
assert_permission "ask" "echo \$API_KEY | base64"
assert_permission "ask" "echo \$SECRET | md5"
assert_permission "ask" "echo \$PASSWORD | grep foo"

# Braced sensitive variables with transformations
assert_permission "ask" "echo \${API_KEY} | base64"
assert_permission "ask" "echo \${SECRET} | md5"
assert_permission "ask" "echo \${PASSWORD} | grep foo"

# Printing all environment variables - ASK (could expose sensitive data)
assert_permission "ask" "printenv"
assert_permission "ask" "env"
assert_permission "ask" "export"

# Environment dump commands with paths/flags
assert_permission "ask" "/usr/bin/printenv" "printenv with full path"
assert_permission "ask" "/usr/bin/env" "env with full path"
assert_permission "ask" "/bin/env" "env with /bin path"
assert_permission "ask" "export -p" "export with -p flag"
assert_permission "ask" "export --" "export with -- flag"
assert_permission "ask" "env | cat" "env piped to cat"
assert_permission "ask" "printenv | less" "printenv piped to less"

# Process substitution
assert_permission "ask" "cat <(env)" "process substitution with env"
assert_permission "ask" "cat <(printenv)" "process substitution with printenv"
assert_permission "ask" "cat <( env )" "process substitution with spaces"
assert_permission "ask" "less <(export -p)" "process substitution with export -p"

# eval commands
assert_permission "ask" "eval \"echo hello\"" "eval with simple command"
assert_permission "ask" "eval \"echo \\\$SECRET\"" "eval with escaped sensitive var"
assert_permission "ask" "eval 'printenv'" "eval with printenv"

# Grepping for sensitive patterns
assert_permission "ask" "env | grep KEY"
assert_permission "ask" "env | grep TOKEN"
assert_permission "ask" "env | grep PASSWORD"
assert_permission "ask" "env | grep SECRET"
assert_permission "ask" "env | grep AWS"
assert_permission "ask" "env | grep SSH"
assert_permission "ask" "export | grep KEY"
assert_permission "ask" "printenv | grep TOKEN"
assert_permission "ask" "env | grep -i bearer"
assert_permission "ask" "env | grep 'CREDENTIAL'"

# Many variables test (50+ variables)
many_vars_cmd="echo \$VAR1 \$VAR2 \$VAR3 \$VAR4 \$VAR5 \$VAR6 \$VAR7 \$VAR8 \$VAR9 \$VAR10 \$VAR11 \$VAR12 \$VAR13 \$VAR14 \$VAR15 \$VAR16 \$VAR17 \$VAR18 \$VAR19 \$VAR20 \$VAR21 \$VAR22 \$VAR23 \$VAR24 \$VAR25 \$VAR26 \$VAR27 \$VAR28 \$VAR29 \$VAR30 \$VAR31 \$VAR32 \$VAR33 \$VAR34 \$VAR35 \$VAR36 \$VAR37 \$VAR38 \$VAR39 \$VAR40 \$VAR41 \$VAR42 \$VAR43 \$VAR44 \$VAR45 \$VAR46 \$VAR47 \$VAR48 \$VAR49 \$VAR50 \$VAR51"
assert_permission "ask" "$many_vars_cmd" "command with 50+ variables"

# .envrc.* and .env.* variants - ASK the user
assert_permission "ask" "cat .envrc.local"
assert_permission "ask" "cat .env.local"
assert_permission "ask" "cat .env.example"
assert_permission "ask" "cat /path/to/.env.local"

# Quoted .env.* and .envrc.* variants - should still ASK
assert_permission "ask" "cat \".env.local\""
assert_permission "ask" "cat '.envrc.example'"
assert_permission "ask" "vim \"/path/to/.env.local\""

# *.key files - ASK the user (treated same as .env.* variants)
assert_permission "ask" "cat private.key"
assert_permission "ask" "less server.key"
assert_permission "ask" "vim id_rsa.key"
assert_permission "ask" "cat /path/to/certificate.key"
assert_permission "ask" "cat \"private.key\""
assert_permission "ask" "open ~/.ssh/server.key"

# nl command on .env.* or .envrc.* variants - ASK
assert_permission "ask" "nl .env.local"

# Multiple .env.* or .envrc.* files (no exact .env/.envrc) - ASK
assert_permission "ask" "cat .env.local .env.staging"

# Multiple *.key files - ASK
assert_permission "ask" "cat private.key public.key"

# *.key files with pipes - ASK
assert_permission "ask" "cat server.key | grep BEGIN"

# *.key files in find/grep commands - ASK
assert_permission "ask" "find . -name '*.key'"
assert_permission "ask" "ls -la private.key"

# Other transformation commands (sed, awk, wc) - ASK for any .env/.envrc references
assert_permission "ask" "sed -n '1,5p' .env"
assert_permission "ask" "awk '{print}' .envrc"
assert_permission "ask" "wc .env.local"
assert_permission "ask" "wc private.key"

# Command chaining with .env.* or .envrc.* variants - ASK
assert_permission "ask" "cat README.md && cat .env.local"
assert_permission "ask" "test -f private.key && cat private.key"

# Files with trailing dot (edge case) - ASK because these are unusual/suspicious filenames
assert_permission "ask" "cat .env." "file named exactly .env. (trailing dot)"
assert_permission "ask" "cat .envrc." "file named exactly .envrc. (trailing dot)"

# Command substitution with .env/.envrc references - ASK
assert_permission "ask" "cat \$(echo .env)" "command substitution with .env reference"
assert_permission "ask" "cat \"\$(echo .env)\"" "quoted command substitution with .env"
assert_permission "ask" "cat \$(echo .env.local)" "command substitution with .env.local"
assert_permission "ask" "cat \$(echo private.key)" "command substitution with .key file"

# Command substitution with sensitive variables - ASK
assert_permission "ask" "echo \$(printenv SECRET)" "command substitution with sensitive variable"
assert_permission "ask" "printenv \"\${SECRET}\""

# Backslash escaping with .env/.envrc - ASK
assert_permission "ask" "cat .env\\ " ".env with trailing space"

# Mixed quoting with .env/.envrc - ASK
assert_permission "ask" "cat .env\"file\"" ".env with partial quoting"

# ------------------------------------------------------------------------------
# TIER 3: ALLOW Tests (Safe commands)
# ------------------------------------------------------------------------------

# Regular safe commands
assert_permission "allow" "ls -la"
assert_permission "allow" "echo 'hello world'"
assert_permission "allow" "pwd"
assert_permission "allow" "date"
assert_permission "allow" "whoami"
assert_permission "allow" "git status"
assert_permission "allow" "npm install"
assert_permission "allow" "cat README.md"

# Non-sensitive environment variables
assert_permission "allow" "echo \$HOME"
assert_permission "allow" "echo \$PATH"
assert_permission "allow" "echo \$USER"
assert_permission "allow" "echo \$SHELL"
assert_permission "allow" "echo \$PWD"
assert_permission "allow" "printenv PATH"
assert_permission "allow" "printenv HOME"

# Non-sensitive environment variables and safe patterns
assert_permission "allow" "echo \$PUBLIC_KEY"
assert_permission "allow" "echo \$ENVIRONMENT"
assert_permission "allow" "echo \$ENV_NAME"
assert_permission "allow" "grep 'pattern' file.txt"

# Commands with KEY/TOKEN/etc in non-variable context
assert_permission "allow" "echo 'My API key is safe'"
assert_permission "allow" "echo 'token validation'"
assert_permission "allow" "grep KEY file.txt"

# Filenames that CONTAIN but don't START with .env/.envrc - should be ALLOWED
assert_permission "allow" "cat backup.env"
assert_permission "allow" "less config.envrc"

# Filenames that CONTAIN but don't END with .key - should be ALLOWED
assert_permission "allow" "cat .keyboard.txt"
assert_permission "allow" "less mykey_config.json"

# Allow public.key as an exception
assert_permission "allow" "cat public.key"
assert_permission "allow" "less public.key"
assert_permission "allow" "vim public.key"
assert_permission "allow" "cat /path/to/public.key"
assert_permission "allow" "cat \"public.key\""
assert_permission "allow" "open ~/.ssh/public.key"

# Grep searching FOR ".env" as a pattern in other files - should be ALLOWED
assert_permission "allow" "grep '.env' README.md"

# Commands containing 'env' as substring - should NOT trigger env-dump check
assert_permission "allow" "cat environment.txt" "file containing env substring"
assert_permission "allow" "echo \$ENVIRONMENT" "ENVIRONMENT variable (not sensitive)"
assert_permission "allow" "ls /etc/environment" "path containing environment"

# Safe command substitution and backticks
assert_permission "allow" "echo \$(pwd)"
assert_permission "allow" "cat \$(echo README.md)"

# Safe backslash escaping
assert_permission "allow" "cat file\\.txt"

# Safe mixed quoting
assert_permission "allow" "cat \"safe\"file"

# ------------------------------------------------------------------------------
# ERROR HANDLING Tests
# ------------------------------------------------------------------------------

# Empty command
assert_permission "allow" "" "empty command"

# Commands with special characters
assert_permission "allow" "echo \$HOME && ls"
assert_permission "allow" "echo 'test' || echo 'fallback'"
assert_permission "allow" "cat file.txt; ls"

# Complex commands
assert_permission "allow" "for i in {1..10}; do echo \$i; done"
assert_permission "allow" "if [ -f file ]; then cat file; fi"

# Variables in different formats
assert_permission "allow" "echo \${HOME}"
assert_permission "allow" "echo \${HOME}/path"
assert_permission "allow" "echo \$HOME/\$USER"

# Safe braced variables with expansions
assert_permission "allow" "echo \${HOME:-/default}"
assert_permission "allow" "echo \${PATH:0:10}"
assert_permission "allow" "echo \${USER:?not set}"
assert_permission "allow" "echo \${SHELL#/bin/}"

# Quoting and escaping edge cases
assert_permission "allow" "echo \"Hello \$HOME\""
assert_permission "allow" "cat \"README.md\""
assert_permission "allow" "cat 'file.txt'"

# ==============================================================================
# TEST SUMMARY
# ==============================================================================

echo -e "\n"

# Print all collected errors
echo -e "$ERRORS_OUTPUT"

# Print summary
echo -en "${GREEN}✓ $TESTS_PASSED passed "
if [ $TESTS_FAILED -gt 0 ]; then
    echo -en "${RED}✗ $TESTS_FAILED failed "
fi
echo -e "${NC}($TESTS_TOTAL total)"

if [ $TESTS_FAILED -eq 0 ]; then
    exit 0
else
    exit 1
fi

