#!/usr/bin/env bash

set -euo pipefail

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)
hook="$script_dir/setup-worktree-envrc.sh"
test_root=$(mktemp -d /tmp/setup-worktree-envrc.XXXXXX)
trap 'rm -rf -- "$test_root"' EXIT

tests_passed=0

fail() {
    printf '\nFAIL: %s\n' "$1" >&2
    exit 1
}

pass() {
    tests_passed=$((tests_passed + 1))
    printf '.'
}

create_fixture() {
    local name=$1
    local case_root="$test_root/$name"

    source_root="$case_root/source"
    worktree_root="$case_root/worktree"
    direnv_config_root="$case_root/config/direnv"
    xdg_data_root="$case_root/data"
    xdg_cache_root="$case_root/cache"

    mkdir -p "$direnv_config_root" "$xdg_data_root" "$xdg_cache_root"
    git init --quiet "$source_root"
    printf 'fixture\n' >"$source_root/README.md"
    git -C "$source_root" add README.md
    git -C "$source_root" \
        -c user.name='Codex hook test' \
        -c user.email='codex-hook@example.invalid' \
        commit --quiet --message='Initial fixture'
    printf 'export DIRENV_WORKTREE_FIXTURE=1\n' >"$source_root/.envrc"
    git -C "$source_root" worktree add --quiet --detach "$worktree_root" HEAD

    source_root=$(cd "$source_root" && pwd -P)
    worktree_root=$(cd "$worktree_root" && pwd -P)
}

run_hook_from() {
    local directory=$1

    (
        cd "$directory"
        DIRENV_CONFIG="$direnv_config_root" \
            XDG_DATA_HOME="$xdg_data_root" \
            XDG_CACHE_HOME="$xdg_cache_root" \
            bash "$hook"
    )
}

allow_source() {
    (
        cd "$source_root"
        DIRENV_CONFIG="$direnv_config_root" \
            XDG_DATA_HOME="$xdg_data_root" \
            XDG_CACHE_HOME="$xdg_cache_root" \
            direnv allow . >/dev/null
    )
}

is_allowed() {
    local directory=$1
    local envrc="$directory/.envrc"

    (
        cd "$directory"
        DIRENV_CONFIG="$direnv_config_root" \
            XDG_DATA_HOME="$xdg_data_root" \
            XDG_CACHE_HOME="$xdg_cache_root" \
            direnv status --json |
            jq -e --arg path "$envrc" '
                .state.foundRC.path == $path and
                .state.foundRC.allowed == 0
            '
    ) >/dev/null
}

file_mode() {
    stat -f '%Lp' "$1" 2>/dev/null || stat -c '%a' "$1"
}

printf 'Testing Codex worktree direnv hook '

create_fixture allowed
allow_source
run_hook_from "$worktree_root"
[[ -f "$worktree_root/.envrc" && ! -L "$worktree_root/.envrc" ]] || fail 'allowed source was not copied'
[[ $(file_mode "$worktree_root/.envrc") == 600 ]] || fail 'copied .envrc permissions are not private'
is_allowed "$worktree_root" || fail 'copied worktree .envrc was not allowed'
pass

create_fixture unallowed
run_hook_from "$worktree_root"
[[ ! -e "$worktree_root/.envrc" && ! -L "$worktree_root/.envrc" ]] || fail 'unallowed source was copied'
pass

create_fixture existing
allow_source
touch "$worktree_root/.envrc"
run_hook_from "$worktree_root"
is_allowed "$worktree_root" && fail 'existing worktree .envrc was allowed'
pass

create_fixture primary
allow_source
run_hook_from "$source_root"
is_allowed "$source_root" || fail 'primary checkout trust changed'
pass

mkdir -p "$test_root/not-a-repository"
run_hook_from "$test_root/not-a-repository"
pass

printf ' %d passed\n' "$tests_passed"
