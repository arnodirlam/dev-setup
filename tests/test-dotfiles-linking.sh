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
mkdir -p "$source_root/dir"$'\n'"break"
touch "$source_root/dir"$'\n'"break/config"
run_just link-all
[[ -z $(find "$target_root" -mindepth 1 -print) ]] || fail 'Dry run changed the destination'
pass

run_just link-all true
assert_link "$target_root/ordinary/nested/config" "$source_root/ordinary/nested/config"
assert_link "$target_root/bundle with spaces" "$source_root/bundle with spaces"
assert_link "$target_root/.hidden" "$source_root/.hidden"
assert_link "$target_root/line"$'\n'"break" "$source_root/line"$'\n'"break"
assert_link "$target_root/dir"$'\n'"break/config" "$source_root/dir"$'\n'"break/config"
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

fixture 'shared agent symlinks'
mkdir -p "$source_root/.agents/skills/example" "$source_root/.codex" "$source_root/.claude/skills"
touch "$source_root/.agents/skills/example/.link-directory"
printf 'Shared instructions\n' > "$source_root/.codex/AGENTS.md"
printf 'Shared skill\n' > "$source_root/.agents/skills/example/SKILL.md"
ln -s ../.codex/AGENTS.md "$source_root/.claude/CLAUDE.md"
ln -s ../../.agents/skills/example "$source_root/.claude/skills/example"
mkdir -p "$target_root/.codex" "$target_root/.claude/skills/example"
printf 'Old instructions\n' > "$target_root/.codex/AGENTS.md"
touch "$target_root/.claude/skills/example/local-only" "$target_root/.claude/skills/existing"
run_just link-all
[[ ! -L "$target_root/.codex/AGENTS.md" && ! -L "$target_root/.claude/skills/example" ]] || fail 'Symlink dry run changed destination'
run_just link-all true
for destination in .codex/AGENTS.md .claude/CLAUDE.md .agents/skills/example .claude/skills/example; do
    assert_link "$target_root/$destination" "$source_root/$destination"
done
[[ $(cat "$target_root/.claude/CLAUDE.md") == 'Shared instructions' ]] || fail 'File symlink chain is broken'
[[ $(cat "$target_root/.claude/skills/example/SKILL.md") == 'Shared skill' ]] || fail 'Directory symlink chain is broken'
[[ ! -L "$source_root/.agents/skills/example/SKILL.md" ]] || fail 'Skill contents linked individually'
[[ -f "$target_root/.codex/AGENTS.md.backup" && -f "$target_root/.claude/skills/example.backup/local-only" ]] || fail 'Symlink migration lost existing data'
[[ -f "$target_root/.claude/skills/existing" ]] || fail 'Linking replaced unrelated skills'
run_just link-all true
run_just link .codex/AGENTS.md true
run_just link .claude/skills/example/SKILL.md true
[[ ! -e "$target_root/.codex/AGENTS.md.backup.1" && ! -e "$target_root/.claude/skills/example.backup.1" ]] || fail 'Repeat linking created a backup'
[[ ! -L "$source_root/.agents/skills/example/SKILL.md" ]] || fail 'Alias child request modified source'
pass

fixture 'unmarked directory alias'
mkdir -p "$source_root/ordinary dir"
touch "$source_root/ordinary dir/config file"
ln -s 'ordinary dir' "$source_root/alias dir"
run_just link-all true
assert_link "$target_root/alias dir" "$source_root/alias dir"
run_just link 'alias dir/config file' true
[[ -f "$target_root/alias dir/config file" && ! -L "$source_root/ordinary dir/config file" ]] || fail 'Unmarked alias child request modified source'
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

fixture 'import ordinary file'
mkdir -p "$target_root/dir with spaces"
printf 'New config\n' > "$target_root/dir with spaces/config file"
run_just import 'dir with spaces/config file'
[[ ! -e "$source_root/dir with spaces" && ! -L "$target_root/dir with spaces/config file" ]] || fail 'Import dry run changed files'
[[ $(cat "$test_root/output") != *'Backing up'* ]] || fail 'Ordinary import preview showed a home backup'
run_just import 'dir with spaces/config file' true
assert_link "$target_root/dir with spaces/config file" "$source_root/dir with spaces/config file"
[[ $(cat "$source_root/dir with spaces/config file") == 'New config' ]] || fail 'Import lost file contents'
[[ ! -e "$target_root/dir with spaces/config file.backup" ]] || fail 'Ordinary import made a home backup'
pass

fixture 'import existing source'
printf 'New config\n' > "$target_root/config"
printf 'Old config\n' > "$source_root/config"
touch "$source_root/config.backup"
ln -s "$test_root/missing" "$source_root/config.backup.1"
run_just import dotfiles/config true
assert_link "$target_root/config" "$source_root/config"
[[ $(cat "$source_root/config") == 'New config' && $(cat "$source_root/config.backup.2") == 'Old config' ]] || fail 'Import overwrote a source backup'
pass

fixture 'already imported'
printf 'Config\n' > "$source_root/config"
ln -s "$source_root/config" "$target_root/config"
run_just import '~/config'
run_just import "$target_root/config" true
assert_link "$target_root/config" "$source_root/config"
[[ ! -e "$source_root/config.backup" && ! -e "$target_root/config.backup" ]] || fail 'Already-imported file created backups'
[[ $(cat "$source_root/config") == 'Config' ]] || fail 'Already-imported file was changed'
pass

fixture 'import symlink rejected'
printf 'Original\n' > "$target_root/original"
printf 'Old config\n' > "$source_root/config"
mkdir -p "$target_root/directory"
for stored_target in original missing "$target_root/directory"; do
    ln -s "$stored_target" "$target_root/config"
    for mode in false true; do
        if just --justfile "$repo_root/justfile" \
            --set dotfiles_dir "$source_root" --set home_dir "$target_root" \
            import config "$mode" > "$test_root/stdout" 2> "$test_root/stderr"; then
            fail 'Accepted a home symlink to another location'
        fi
        display_target=${stored_target//"$target_root/"/'~/'}
        [[ $(cat "$test_root/stderr") == *"Cannot import symlink: ~/config -> $display_target"* ]] || fail 'Symlink error omitted stored target'
        [[ ! -s "$test_root/stdout" ]] || fail 'Symlink error was printed to stdout'
        if [[ "$mode" == false ]]; then
            [[ $(cat "$test_root/stderr") == *'[DRY RUN]'* ]] || fail 'Dry-run error omitted prefix'
        fi
    done
    assert_link "$target_root/config" "$stored_target"
    rm "$target_root/config"
done
[[ $(cat "$source_root/config") == 'Old config' && $(cat "$target_root/original") == 'Original' ]] || fail 'Rejected symlink import changed files'
[[ ! -e "$source_root/config.backup" && ! -e "$target_root/config.backup" ]] || fail 'Rejected symlink import made backups'
pass

fixture 'import rejected'
mkdir -p "$target_root/directory" "$source_root/destination-dir"
ln -s missing "$target_root/dangling"
ln -s directory "$target_root/directory-link"
touch "$target_root/destination-dir"
for path in '' . .. ../outside /etc/passwd missing dangling directory directory-link destination-dir; do
    if run_just import "$path" true 2>/dev/null; then
        fail "Accepted invalid import: $path"
    fi
done
[[ ! -e "$source_root/destination-dir.backup" ]] || fail 'Rejected import changed source'
pass

fixture 'import marked directory'
mkdir -p "$source_root/bundle" "$target_root/bundle"
touch "$source_root/bundle/.link-directory"
printf 'Config\n' > "$target_root/bundle/config"
run_just import bundle/config
[[ $(cat "$test_root/output") == *'bundle/config ->'* ]] || fail 'Import preview omitted final file link'
[[ ! -e "$source_root/bundle/config" && ! -e "$target_root/bundle.backup" ]] || fail 'Marked import dry run changed files'
run_just import bundle/config true
assert_link "$target_root/bundle" "$source_root/bundle"
[[ $(cat "$target_root/bundle/config") == 'Config' ]] || fail 'Marked import lost file'
pass

fixture 'import directory alias'
mkdir -p "$test_root/alias original" "$target_root/alias"
ln -s "$test_root/alias original" "$source_root/alias"
printf 'Home config\n' > "$target_root/alias/config"
if run_just import alias/config true 2>/dev/null; then
    fail 'Import wrote through a repository alias'
fi
[[ ! -e "$test_root/alias original/config" && -f "$target_root/alias/config" ]] || fail 'Rejected alias import changed files'
pass

fixture 'import link failure'
printf 'New config\n' > "$target_root/config"
mkdir -p "$test_root/failing commands"
printf '#!/usr/bin/env bash\nexit 1\n' > "$test_root/failing commands/ln"
chmod +x "$test_root/failing commands/ln"
if PATH="$test_root/failing commands:$PATH" run_just import config true 2>/dev/null; then
    fail 'Import hid a link failure'
fi
[[ $(cat "$source_root/config") == 'New config' ]] || fail 'Link failure lost imported file'
pass

printf '\n%s linking/import cases passed.\n' "$tests_passed"
