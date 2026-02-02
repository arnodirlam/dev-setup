/opt/homebrew/bin/brew shellenv | source
# oh-my-posh init fish | source

# scheme set tokyonight

set -g fish_greeting

if status is-interactive
  # Commands to run in interactive sessions can go here
end

direnv hook fish | source
