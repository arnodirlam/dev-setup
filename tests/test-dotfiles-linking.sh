#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)
test_root=$(mktemp -d /tmp/dotfiles-linking.XXXXXX)
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

fixture() {
    source_root="$test_root/$1/source"
    target_root="$test_root/$1/home"
    mkdir -p "$source_root" "$target_root"
}

run_just() {
    just --justfile "$repo_root/justfile" \
        --set dotfiles_dir "$source_root" --set home_dir "$target_root" "$@" \
        > "$test_root/output" 2>&1 || {
            cat "$test_root/output" >&2
            return 1
        }
}

assert_link() {
    [[ -L "$1" && $(readlink "$1") == "$2" ]] || fail "Wrong link: $1"
}

printf 'Testing dotfiles linking '

fixture 'mixed paths'
mkdir -p "$source_root/ordinary/nested" "$source_root/bundle with spaces/nested"
touch "$source_root/ordinary/nested/config" "$source_root/bundle with spaces/.link-directory"
touch "$source_root/bundle with spaces/nested/.link-directory" "$source_root/bundle with spaces/nested/config"
touch "$source_root/.hidden" "$source_root/line"$'\n'"break"
run_just link-all
[[ -z $(find "$target_root" -mindepth 1 -print) ]] || fail 'Dry run changed the destination'
pass

run_just link-all true
assert_link "$target_root/ordinary/nested/config" "$source_root/ordinary/nested/config"
assert_link "$target_root/bundle with spaces" "$source_root/bundle with spaces"
assert_link "$target_root/.hidden" "$source_root/.hidden"
assert_link "$target_root/line"$'\n'"break" "$source_root/line"$'\n'"break"
[[ ! -L "$target_root/ordinary" && ! -L "$target_root/bundle with spaces/nested/config" ]] || fail 'Wrong link granularity'
[[ ! -e "$source_root/bundle with spaces/nested/config.backup" ]] || fail 'Linked children through the directory symlink'
pass

run_just link-all true
run_just link 'bundle with spaces/nested/config' true
run_just link 'bundle with spaces/nested/.link-directory' true
[[ ! -e "$target_root/bundle with spaces.backup" ]] || fail 'Repeat linking created a backup'
[[ ! -L "$source_root/bundle with spaces/nested/config" ]] || fail 'Child request modified source'
pass

fixture migration
mkdir -p "$source_root/bundle" "$target_root/bundle" "$target_root/bundle.backup"
touch "$source_root/bundle/.link-directory" "$source_root/bundle/config"
touch "$target_root/bundle/local-only" "$target_root/bundle.backup/older"
ln -s "$source_root/bundle/config" "$target_root/bundle/config"
run_just link bundle
[[ -d "$target_root/bundle" && ! -L "$target_root/bundle" && ! -e "$target_root/bundle.backup.1" ]] || fail 'Migration dry run changed destination'
run_just link bundle true
assert_link "$target_root/bundle" "$source_root/bundle"
assert_link "$target_root/bundle.backup.1/config" "$source_root/bundle/config"
[[ -f "$target_root/bundle.backup.1/local-only" && -f "$target_root/bundle.backup/older" ]] || fail 'Migration lost existing data'
pass

fixture 'existing files'
touch "$source_root/config" "$target_root/config" "$target_root/config.backup"
ln -s "$test_root/missing" "$target_root/config.backup.1"
run_just link config true
assert_link "$target_root/config" "$source_root/config"
[[ -f "$target_root/config.backup.2" && -f "$target_root/config.backup" && -L "$target_root/config.backup.1" ]] || fail 'Backup collision lost data'
ln -s "$test_root/missing" "$target_root/other"
touch "$source_root/other"
run_just link other true
assert_link "$target_root/other" "$source_root/other"
assert_link "$target_root/other.backup" "$test_root/missing"
pass

fixture 'path forms'
touch "$source_root/config"
for path in config dotfiles/config '~/config' "$source_root/config" "$target_root/config"; do
    run_just link "$path" true
    assert_link "$target_root/config" "$source_root/config"
done
mkdir -p "$source_root/bundle"
touch "$source_root/bundle/.link-directory"
run_just link bundle/ true
assert_link "$target_root/bundle" "$source_root/bundle"
pass

fixture rejected
mkdir -p "$source_root/unmarked"
for path in '' . .. ../outside /etc/passwd unmarked; do
    if run_just link "$path" true 2>/dev/null; then
        fail "Accepted invalid target: $path"
    fi
done
[[ -z $(find "$target_root" -mindepth 1 -print) ]] || fail 'Invalid target changed destination'
pass

fixture 'link failure'
mkdir -p "$source_root/blocked"
touch "$source_root/blocked/config" "$target_root/blocked"
if run_just link-all true 2>/dev/null; then
    fail 'link-all hid a link failure'
fi
[[ -f "$target_root/blocked" ]] || fail 'Failure damaged parent file'
pass

fixture 'scan failure'
source_root="$source_root/missing"
if run_just link-all true 2>/dev/null; then
    fail 'link-all hid a traversal failure'
fi
pass

printf '\n%s linking cases passed.\n' "$tests_passed"
