#!/bin/sh
set -eou pipefail

# Install fish shell & fisher
# https://www.joshfinnie.com/blog/moving-from-oh-my-zsh-to-starship-and-fish-shell/

brew install fish fzf bat exa fd font-fira-code-nerd-font

echo /opt/homebrew/bin/fish | sudo tee -a /etc/shells
chsh -s /opt/homebrew/bin/fish

mkdir -p $HOME/.config/fish
echo "/opt/homebrew/bin/brew shellenv | source" >> $HOME/.config/fish/config.fish

curl -sL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish | source
