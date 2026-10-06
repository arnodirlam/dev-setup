# dev-setup

A comprehensive development environment setup repository with reusable configuration files (dotfiles) and automated setup scripts. Files in [dotfiles/](dotfiles) are designed to be symlinked to your home directory for easy management and version control.

## Quick Start

### Bootstrap Everything

Set up your entire development environment in one command:

```bash
# Dry-run (preview what will happen)
just bootstrap

# Actually perform the setup
just bootstrap true
```

This will:
1. Link all dotfiles from [dotfiles/](dotfiles) to `~/` recursively
2. Install/update Homebrew packages from [Brewfile](Brewfile)
3. Prompt you to choose and configure a default shell (zsh or fish)

### Manual Setup

If you prefer more control, you can set up components individually:

```bash
# Link all dotfiles
just link-all true

# Apply Brewfile
just brew-apply true

# Setup and configure zsh with Oh My Zsh
just setup-zsh true
just set-default-shell zsh true

# Or setup fish shell
just setup-fish true
just set-default-shell fish true
```

## Available Commands

### Dotfiles Management

The [dotfiles/](dotfiles) directory contains configuration files that should live in your home directory. Instead of copying them, this repository creates symlinks:

```bash
# Link all dotfiles
just link-all true

# Link a specific file
just link .zshrc true
just link .config/fish/config.fish true

# Link a whole marked directory
just link .agents/skills/elixir-development true

# Import an existing file from your home directory
just import .vimrc true
```

Linking backs up existing destinations as `.backup`, then `.backup.1`, `.backup.2`, etc., without replacing earlier backups. Already-correct symlinks are left unchanged.

**Directory structure:**

```text
dotfiles/
├── .agents/
│   └── skills/elixir-development/
│       ├── .link-directory
│       └── SKILL.md
├── .codex/
│   └── AGENTS.md
├── .claude/
│   ├── CLAUDE.md -> ../.codex/AGENTS.md
│   └── skills/elixir-development -> ../../.agents/skills/elixir-development
├── .config/
│   ├── fish/
│   │   └── config.fish
│   ├── mise/
│   │   └── config.toml
│   └── opencode/
│       └── AGENTS.md -> ../../.codex/AGENTS.md
├── .zshrc
├── .zshenv
└── .zprofile
```

Home links point to these repo entries. Relative symlinks provide aliases for shared files and skills. An empty `.link-directory` makes `just link` and `just link-all` link that directory as one unit; ordinary directories are traversed file by file by `just link-all`. Linking a child path selects the outermost marked directory or directory symlink, leaving its contents intact.

### Homebrew Package Management

Sync installed Homebrew packages, casks, and taps from/to the [Brewfile](Brewfile) in this repo:

```bash
# Apply Brewfile, installing/uninstalling packages as needed
just brew-apply true

# Install only new packages from Brewfile (no updates)
just brew-install true

# Remove packages not listed in Brewfile
just brew-purge true

# Generate Brewfile from currently installed packages
just brew-dump true
```

### Shell Configuration

Choose between **zsh** (with Oh My Zsh) or **fish** shell:

**Zsh with Oh My Zsh:**
```bash
just setup-zsh true
just set-default-shell zsh true
```

**Fish shell:**
```bash
just setup-fish true
just set-default-shell fish true
```

**Oh My Zsh plugins** are managed via the [omz_plugins](omz_plugins) file int his repo:
```bash
# Install plugins listed in omz_plugins file
just omz-plugins-install true

# Update plugins
just zsh-plugins-update

# Export currently installed plugins to omz_plugins file
just omz-plugins-dump true
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

Setup commands with a `doit` parameter default to dry-run mode. Pass `true` as the final positional argument to apply changes; omit it to preview them.

```bash
# Preview changes (dry-run)
just link-all

# Actually perform the operation
just link-all true
```

You'll see output like:
```
[DRY RUN] 🔗 Linking: ~/.zshrc -> ~/dev/dev-setup/dotfiles/.zshrc

💡 This was a dry run. No files were actually modified.
   Pass true as the final argument to apply changes.
```

## Requirements

- **macOS** (tested on darwin 24.6.0)
- **[just](https://github.com/casey/just)** - Command runner (install via `brew install just`)
- **[Homebrew](https://brew.sh/)** - Package manager for macOS

## Tips

1. **Use tab completion**: Run `just` without arguments to see all available commands
2. **Always dry-run first**: Preview changes before applying them
3. **Keep Brewfile updated**: Run `just brew-dump true` after installing new packages
4. **Version control your changes**: This repository is meant to be kept in git
5. **Customize dotfiles**: Edit files in [dotfiles/](dotfiles) and changes appear in `~/` immediately (via symlinks)

## License

See [LICENSE](LICENSE) file.
