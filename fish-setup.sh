#!/bin/sh
set -exou pipefail

# Install fish shell & fisher
# https://www.joshfinnie.com/blog/moving-from-oh-my-zsh-to-starship-and-fish-shell/

brew install fish fzf bat fd font-fira-code-nerd-font

echo /opt/homebrew/bin/fish | sudo tee -a /etc/shells
chsh -s /opt/homebrew/bin/fish

mkdir -p $HOME/.config/fish
echo "/opt/homebrew/bin/brew shellenv | source" >> $HOME/.config/fish/config.fish
ln fish/fish_plugins ~/.config/fish/fish_plugins

curl -sL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish | fish
fisher update
