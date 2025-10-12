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
    if [ "$actual" = "$expected" ]; then
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

# .envrc with paths
assert_permission "deny" "cat /path/to/.envrc" "cat with path"
assert_permission "deny" "less ~/project/.envrc" "less with home path"
assert_permission "deny" "cat ./some/dir/.envrc" "cat with relative path"

# .envrc with trailing semicolons
assert_permission "deny" "cat .envrc;"
assert_permission "deny" "cat .envrc; echo done"
assert_permission "deny" "cat /path/.envrc; ls"

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

# ------------------------------------------------------------------------------
# TIER 2: ASK Tests (Commands requiring user approval)
# ------------------------------------------------------------------------------

# .envrc with pipes/transformations
assert_permission "ask" "cat .envrc | grep API"
assert_permission "ask" "cat .envrc | head -n 5"
assert_permission "ask" "less .envrc | wc -l"

# .envrc references in other contexts
assert_permission "ask" "find . -name .envrc"
assert_permission "ask" "grep -r .envrc ."
assert_permission "ask" "ls -la .envrc"
assert_permission "ask" "file .envrc"
assert_permission "ask" "stat .envrc"

# Sensitive variables with transformations
assert_permission "ask" "echo \$API_KEY | base64"
assert_permission "ask" "echo \$SECRET | md5"
assert_permission "ask" "echo \$PASSWORD | grep foo"

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

# Similar but safe patterns
assert_permission "allow" "cat .env.example"
assert_permission "allow" "cat .envrc.template"
assert_permission "allow" "echo \$PUBLIC_KEY"
assert_permission "allow" "echo \$ENVIRONMENT"
assert_permission "allow" "echo \$ENV_NAME"
assert_permission "allow" "grep 'pattern' file.txt"

# Commands with KEY/TOKEN/etc in non-variable context
assert_permission "allow" "echo 'My API key is safe'"
assert_permission "allow" "echo 'token validation'"
assert_permission "allow" "grep KEY file.txt"

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

