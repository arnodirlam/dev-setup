 # Homebrew, mise, and direnv initialization
 # Ensure PATH order: mise shims > Homebrew > macOS defaults
 eval "$(/opt/homebrew/bin/brew shellenv)"
 eval "$(/opt/homebrew/bin/mise activate zsh)"
 eval "$(/opt/homebrew/bin/direnv hook zsh)"

# # Added by OrbStack: command-line tools and integration
# # This won't be added again if you remove it.
# source ~/.orbstack/shell/init.zsh 2>/dev/null || :
