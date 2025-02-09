#!/bin/sh
set -exou pipefail

xcode-select --install

/usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"

brew install 1password act actionlint asdf autoconf automake awscli bat bat-extras cmake coreutils curl direnv ffmpeg gh ghostscript git-lfs gitui glib gnu-sed gnupg gnutls graphite harfbuzz hcloud htop icu4c@76 imagemagick imagemagick@6 imap-backup jnv jpeg-xl jq libarchive libass libbluray libtool libxslt libyaml make mise neovim openjdk@11 openssl@3 pango pdftk-java pinentry-mac pkgconf qpdf readline ripgrep rust tesseract testdisk unixodbc unzip watch watchexec wget wxwidgets yamlfmt zsh-completions

echo "pinentry-program $(brew --prefix)/bin/pinentry-mac" >> ~/.gnupg/gpg-agent.conf
gpgconf --kill gpg-agent
