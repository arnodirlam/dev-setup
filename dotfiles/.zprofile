# Homebrew, mise, and direnv initialization for login shells.
# /etc/zprofile runs `path_helper`, so we re-assert our preferred ordering here.

if [[ -x "/opt/homebrew/bin/brew" ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
elif command -v brew >/dev/null 2>&1; then
  eval "$(brew shellenv)"
fi

if command -v mise >/dev/null 2>&1; then
  eval "$(mise activate zsh)"
fi

if [[ -o interactive ]] && command -v direnv >/dev/null 2>&1; then
  eval "$(direnv hook zsh)"
fi
