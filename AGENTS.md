# dev-setup Agent Notes

## Project Shape

This repo manages development environment setup files.

- `dotfiles/` contains files intended to be linked into `$HOME`.
- `Justfile` owns repeatable repo commands.
- Run `just --list` before changing scripts or dotfiles so available checks are known.
- Do not mutate the git index unless the user explicitly asks.

## Secret Safety

Never print raw secret-bearing files or environment.

- Do not read or dump `.env*`, `.envrc*`, or `*.key` files, except `public.key`.
- Treat env vars containing names like `TOKEN`, `SECRET`, `PASSWORD`, `API_KEY`, `PRIVATE_KEY`, `CREDENTIAL`, `AUTH`, `DATABASE_URL`, `AWS_`, `SSH_`, and `TF_VAR_` as sensitive.
- Prefer redacted checks, existence checks, or structural summaries.

## Testing `dotfiles/.zshrc`

Always run syntax validation after editing `.zshrc`:

```sh
zsh -n dotfiles/.zshrc
```

For interactive behavior, run zsh as an interactive shell and force pagers to `cat` so output can be asserted:

```sh
MANPAGER=cat PAGER=cat LESS= zsh -ic 'source dotfiles/.zshrc >/dev/null 2>&1; h mise install'
```

When testing `h`, prefer capturing command output before searching it. Piping `man` output directly into tools like `rg -m 1` can close the pipe early, make `man` fail, and trigger false fallback behavior.

Good pattern:

```sh
MANPAGER=cat PAGER=cat LESS= zsh -ic 'source dotfiles/.zshrc >/dev/null 2>&1; out=$(h git 2>&1); rc=$?; print -- "rc=$rc"; print -r -- "$out" | sed -n "1p"'
```

Regression cases for `h`:

```sh
MANPAGER=cat PAGER=cat LESS= zsh -ic 'source dotfiles/.zshrc >/dev/null 2>&1; out=$(h git 2>&1); rc=$?; print -- "git_rc=$rc"; print -r -- "$out" | sed -n "1p"'
MANPAGER=cat PAGER=cat LESS= zsh -ic 'source dotfiles/.zshrc >/dev/null 2>&1; out=$(h g 2>&1); rc=$?; print -- "g_rc=$rc"; print -r -- "$out" | sed -n "1p"'
MANPAGER=cat PAGER=cat LESS= zsh -ic 'source dotfiles/.zshrc >/dev/null 2>&1; out=$(h mise install 2>&1); rc=$?; print -- "mise_install_rc=$rc"; print -r -- "$out" | rg -m 1 "Usage: mise install"'
MANPAGER=cat PAGER=cat LESS= zsh -ic 'source dotfiles/.zshrc >/dev/null 2>&1; out=$(h h 2>&1); rc=$?; print -- "h_rc=$rc"; print -r -- "$out" | sed -n "1p"'
MANPAGER=cat PAGER=cat LESS= zsh -ic 'source dotfiles/.zshrc >/dev/null 2>&1; out=$(h up 2>&1); rc=$?; print -- "up_rc=$rc"; print -r -- "$out" | tail -n 1'
```

If `terraform` is unavailable, simulate the no-help command and alias cases without installing it:

```sh
MANPAGER=cat PAGER=cat LESS= zsh -ic 'source dotfiles/.zshrc >/dev/null 2>&1; terraform(){ :; }; alias tf=terraform; out=$(h terraform 2>&1); rc=$?; print -- "terraform_rc=$rc"; print -r -- "$out" | tail -n 1; out=$(h tf 2>&1); rc=$?; print -- "tf_rc=$rc"; print -r -- "$out" | tail -n 1'
```

Expected behavior:

- `h git` shows the `git` man page.
- `h g` expands alias `g` and shows the `git` man page.
- `h mise install` shows subcommand help containing `Usage: mise install`.
- `h h` shows `Usage: h <command> [args...]`.
- `h up` returns `h: no help found for up`.
- Missing commands return `h: command not found: ...`.
- Existing commands without help return `h: no help found for ...`.

When using Codex sandboxed command execution, non-PTY interactive zsh startup can emit unrelated Oh My Zsh or ZLE noise, such as:

```text
(eval):1: can't change option: zle
```

`zle` is the Zsh Line Editor. That warning was observed only in non-PTY test runs. Re-run with a real PTY or outside sandbox before treating it as a `.zshrc` regression.
