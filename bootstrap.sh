#!/bin/sh
set -euo pipefail

xcode-select --install || true

if ! command -v brew >/dev/null 2>&1; then
  echo "🍺 Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
else
  echo "✅ Homebrew is already installed, skipping installation."
fi

brew install just

just bootstrap "$@"
