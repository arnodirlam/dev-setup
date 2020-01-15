xcode-select --install

/usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"

brew install autoconf gnupg openssl pinentry-mac
brew install ansible cask git-crypt htop jq rsync watch wget

brew cask install 1password battle-net caffeine chromedriver clipmenu deckset diffmerge
brew cask install firefox flash-npapi flux google-chrome iterm2 karabiner-elements keepassx
brew cask install macmediakeyforwarder notion slack spectacle spotify synology-cloud-station-drive
brew cask install the-unarchiver toggldesktop vanilla veracrypt visual-studio-code vlc whatsapp

echo "pinentry-program $(brew --prefix)/bin/pinentry-mac" >> ~/.gnupg/gpg-agent.conf
gpgconf --kill gpg-agent
