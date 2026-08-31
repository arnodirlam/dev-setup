#!/usr/bin/env bash

set -euo pipefail

command -v git >/dev/null || exit 0

# Exit outside a Git worktree
worktree_root=$(git rev-parse --show-toplevel 2>/dev/null) || exit 0

# Skip an existing worktree .envrc
[[ ! -e "$worktree_root/.envrc" && ! -L "$worktree_root/.envrc" ]] || exit 0

# Find the primary worktree
source_root=$(git worktree list --porcelain | sed -n '1s/^worktree //p') || exit 0
[[ -n "$source_root" ]] || exit 0

# Require a source .envrc
[[ -f "$source_root/.envrc" ]] || exit 0

# The first worktree is the primary checkout. Only linked worktrees need setup.
[[ "$worktree_root" != "$source_root" ]] || exit 0

# Require direnv, jq, and direnv 2.33.0 or newer
command -v direnv >/dev/null || exit 0
command -v jq >/dev/null || exit 0
direnv version 2.33.0 >/dev/null 2>&1 || exit 0

# Check whether source .envrc is allowed
if ! (
    cd "$source_root"
    direnv status --json |
        jq -e --arg path "$source_root/.envrc" '
            .state.foundRC.path == $path and
            .state.foundRC.allowed == 0
        '
) >/dev/null; then
    exit 0
fi

# Copy and allow the missing worktree .envrc
(
    umask 077
    cp -n "$source_root/.envrc" "$worktree_root/.envrc"
    direnv allow "$worktree_root" >/dev/null
)
