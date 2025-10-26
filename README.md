# dev-setup

A comprehensive development environment setup repository with reusable configuration files (dotfiles) and automated setup scripts. Files in [dotfiles/](dotfiles) are designed to be symlinked to your home directory for easy management and version control.

## Quick Start

### Bootstrap Everything

Set up your entire development environment in one command:

```bash
# Dry-run (preview what will happen)
just bootstrap

# Actually perform the setup
just bootstrap doit=true
```

This will:
1. Link all dotfiles from [dotfiles/](dotfiles) to `~/` recursively
2. Install/update Homebrew packages from [Brewfile](Brewfile)
3. Prompt you to choose and configure a default shell (zsh or fish)

### Manual Setup

If you prefer more control, you can set up components individually:

```bash
# Link all dotfiles
just link-all doit=true

# Apply Brewfile
just brew-apply doit=true

# Setup and configure zsh with Oh My Zsh
just setup-zsh doit=true
just set-default-shell zsh doit=true

# Or setup fish shell
just setup-fish doit=true
just set-default-shell fish doit=true
```

## Available Commands

### Dotfiles Management

The [dotfiles/](dotfiles) directory contains configuration files that should live in your home directory. Instead of copying them, this repository creates symlinks:

```bash
# Link all dotfiles
just link-all doit=true

# Link a specific file
just link .zshrc doit=true
just link .config/fish/config.fish doit=true

# Import an existing file from your home directory
just import .vimrc doit=true
```

All these commands create **backups** of existing files (when not in dry-run).

**Directory structure:**
```
dotfiles/
├── .config/
│   ├── fish/
│   │   └── config.fish
│   └── mise/
│       └── config.toml
├── .zshrc
├── .zshenv
└── .zprofile
```

When linked, these files appear in `~/` as symlinks pointing back to this repository.

### Homebrew Package Management

Sync installed Homebrew packages, casks, and taps from/to the [Brewfile](Brewfile) in this repo:

```bash
# Apply Brewfile, installing/uninstalling packages as needed
just brew-apply [doit=true]

# Generate Brewfile from currently installed packages
just brew-dump [doit=true]
```

### Shell Configuration

Choose between **zsh** (with Oh My Zsh) or **fish** shell:

**Zsh with Oh My Zsh:**
```bash
just setup-zsh doit=true
just set-default-shell zsh doit=true
```

**Fish shell:**
```bash
just setup-fish doit=true
just set-default-shell fish doit=true
```

**Oh My Zsh plugins** are managed via the [omz_plugins](omz_plugins) file int his repo:
```bash
# Install plugins listed in omz_plugins file
just omz-plugins-install doit=true

# Update plugins
just zsh-plugins-update

# Export currently installed plugins to omz_plugins file
just omz-plugins-dump doit=true
```


### Utilities

```bash
# List Elixir dependency package names from projects in ~/dev
just list-elixir-packages [verbose=true]

# Run all tests
just check

# Run test suite
just test
```

## How It Works

### Dry-Run Mode

**All commands that modify files use dry-run mode by default** for safety. Commands will show what they would do without actually doing it.

```bash
# Preview changes (dry-run)
just link-all

# Actually perform the operation
just link-all doit=true
```

You'll see output like:
```
[DRY RUN] 🔗 Creating symlink: ~/.zshrc -> ~/dev/dev-setup/dotfiles/.zshrc

💡 This was a dry run. No files were actually modified.
   Run with doit=true to perform the actual operation.
```

## Requirements

- **macOS** (tested on darwin 24.6.0)
- **[just](https://github.com/casey/just)** - Command runner (install via `brew install just`)
- **[Homebrew](https://brew.sh/)** - Package manager for macOS

## Tips

1. **Use tab completion**: Run `just` without arguments to see all available commands
2. **Always dry-run first**: Preview changes before applying them
3. **Keep Brewfile updated**: Run `just brew-dump doit=true` after installing new packages
4. **Version control your changes**: This repository is meant to be kept in git
5. **Customize dotfiles**: Edit files in [dotfiles/](dotfiles) and changes appear in `~/` immediately (via symlinks)

## Examples

**Set up a new machine:**
```bash
# Clone this repository
git clone https://github.com/arnodirlam/dev-setup.git ~/dev/dev-setup
cd ~/dev/dev-setup

# Preview what will happen
just bootstrap

# Perform the full setup
just bootstrap doit=true
```

**Add a new dotfile:**
```bash
# Import existing file from home directory
just import .config/starship.toml doit=true

# Edit it in the repository
vim dotfiles/.config/starship.toml

# Changes are automatically reflected in ~/ (via symlink)
```

**Update packages:**
```bash
# Add packages to Brewfile manually, then:
just brew-apply doit=true

# Or, install packages normally and export:
brew install ripgrep
just brew-dump doit=true
```

## License

See [LICENSE](LICENSE) file.
