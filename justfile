# Justfile for dev-setup dotfiles management
#
# This justfile provides commands for linking dotfiles from the dotfiles/ directory
# to the home directory, maintaining symlinks for easy version control.

dotfiles_dir := justfile_directory() / "dotfiles"
home_dir := env_var('HOME')
dotfiles_dir_short := replace_regex(dotfiles_dir, "^" + home_dir, "~")
brewfile_path := justfile_directory() / "Brewfile"
omz_plugins_file := justfile_directory() / "omz_plugins"
omz_plugins_file_short := replace_regex(omz_plugins_file, "^" + home_dir, "~")

# Default recipe - show available commands
[default]
_default:
    @just --list

check: test

test: test-cursor-hooks test-codex-hooks

test-cursor-hooks:
    @{{ dotfiles_dir }}/.cursor/hooks/test-prevent-secret-exposure.sh

test-codex-hooks: (_cmd "direnv") (_cmd "git") (_cmd "jq")
    @bash "{{ dotfiles_dir }}/.codex/hooks/test-setup-worktree-envrc.sh"

# Private command to show dry-run message
_show-dry-run-message $doit:
    #!/usr/bin/env bash
    set -euo pipefail

    # Only show dry-run message if we're in dry-run mode
    if [[ "$doit" != "true" ]]; then
        echo
        echo -e "{{ BLUE }}💡 This was a dry run. No files were actually modified.{{ NORMAL }}"
        echo -e "{{ BLUE }}   Run with doit=true to perform the actual operation.{{ NORMAL }}"
        echo
    fi

_cmd cmd:
    @command -v "{{ cmd }}" >/dev/null || { echo "Missing command: {{ cmd }}" >&2; exit 1; }

# Resolve optional pin, otherwise latest stable GitHub release or default-branch HEAD.
_omz-plugin-target $url $pin="": (_cmd "curl") (_cmd "git") (_cmd "jq")
    #!/usr/bin/env bash
    set -euo pipefail

    temp_dir=$(mktemp -d /tmp/omz-plugin-target.XXXXXX)
    trap 'rm -rf -- "$temp_dir"' EXIT

    target_ref=${pin:-HEAD}
    target_label="$pin"
    target_kind=pin

    if [[ -z "$pin" ]]; then
        target_kind=commit

        github_repo=''
        case "$url" in
            https://github.com/*) github_repo=${url#https://github.com/} ;;
            git@github.com:*) github_repo=${url#git@github.com:} ;;
            ssh://git@github.com/*) github_repo=${url#ssh://git@github.com/} ;;
        esac
        github_repo=${github_repo%.git}
        github_repo=${github_repo%/}

        if [[ -n "$github_repo" ]]; then
            release_file="$temp_dir/release.json"
            if ! http_status=$(curl --silent --show-error --location \
                --header 'Accept: application/vnd.github+json' \
                --output "$release_file" \
                --write-out '%{http_code}' \
                "https://api.github.com/repos/$github_repo/releases/latest"); then
                echo "Unable to query latest release for $url" >&2
                exit 1
            fi

            case "$http_status" in
                200)
                    target_ref=$(jq -er '.tag_name' "$release_file")
                    target_label="$target_ref"
                    target_kind=release
                    ;;
                404) ;;
                *)
                    echo "GitHub release lookup failed for $url (HTTP $http_status)" >&2
                    exit 1
                    ;;
            esac
        fi
    fi

    git -C "$temp_dir" init --bare --quiet
    if ! git -C "$temp_dir" fetch --quiet --depth=1 "$url" "$target_ref"; then
        echo "Unable to fetch $target_ref from $url" >&2
        exit 1
    fi
    target_commit=$(git -C "$temp_dir" rev-parse 'FETCH_HEAD^{commit}')
    target_label=${target_label:-${target_commit:0:7}}
    printf '%s\t%s\t%s\t%s\n' "$target_commit" "$target_label" "$target_kind" "$target_ref"

# Replace hardcoded home paths with actual $HOME
replace-home-paths $doit="false": && (_show-dry-run-message doit)
    #!/usr/bin/env bash
    set -euo pipefail

    [[ "$doit" == "true" ]] && log_prefix="" || log_prefix="[DRY RUN] "

    echo -e "{{ BLUE }}${log_prefix}🏠 Replacing /Users/arno with $HOME in dotfiles...{{ NORMAL }}"

    # Find files containing the old path
    while IFS= read -r file; do
        echo -e "{{ GREEN }}${log_prefix}📝 Updating: $file{{ NORMAL }}"
        [[ "$doit" == "true" ]] && sed -i '' "s|/Users/arno|$HOME|g" "$file" || true
    done < <(grep -rl "/Users/arno" "{{ dotfiles_dir }}" 2>/dev/null || true)

# Create ~/dev directory
create-dev-dir $doit="false": && (_show-dry-run-message doit)
    #!/usr/bin/env bash
    set -euo pipefail

    [[ "$doit" == "true" ]] && log_prefix="" || log_prefix="[DRY RUN] "

    if [[ -d "$HOME/dev" ]]; then
        echo -e "{{ GREEN }}${log_prefix}✅ ~/dev directory already exists{{ NORMAL }}"
    else
        echo -e "{{ BLUE }}${log_prefix}📁 Creating ~/dev directory{{ NORMAL }}"
        [[ "$doit" == "true" ]] && mkdir -p "$HOME/dev" || true
    fi

# Bootstrap the dev environment
bootstrap $doit="false": (replace-home-paths doit) (create-dev-dir doit) (link-all doit) (brew-apply doit) && (_show-dry-run-message doit)
    #!/usr/bin/env bash
    set -euo pipefail

    # Ask user which shell to use
    echo
    echo "Which shell would you like to use by default?"
    while true; do
        select shell_choice in "zsh" "fish" "skip (do not configure shell)"; do
            case "$shell_choice" in
                zsh)
                    just setup-zsh "$doit"
                    just set-default-shell "zsh" "$doit"
                    break 2
                    ;;
                fish)
                    just setup-fish "$doit"
                    just set-default-shell "fish" "$doit"
                    break 2
                    ;;
                "skip (do not configure shell)")
                    echo "Skipped shell setup."
                    break 2
                    ;;
                *)
                    echo "Invalid selection. Please choose 1, 2, or 3."
                    ;;
            esac
        done
    done

# Link a single file from dotfiles/ to ~/
link $relative_path $doit="false": && (_show-dry-run-message doit)
    @just _link "$relative_path" "$doit"

# Private implementation for linking a single file
_link $relative_path $doit="false":
    #!/usr/bin/env bash
    set -euo pipefail

    # Determine mode from boolean argument
    [[ "$doit" == "true" ]] && log_prefix="" || log_prefix="[DRY RUN] "

    # Normalize the relative path by removing common prefixes
    normalized_path="$(echo "$relative_path" \
        | sed "s|^dotfiles/||" \
        | sed "s|^{{ dotfiles_dir }}/||" \
        | sed "s|^~/||" \
        | sed "s|^{{ home_dir }}/||" \
        )"

    # Construct paths
    source_file="{{ dotfiles_dir }}/$normalized_path"
    source_file_short="{{ dotfiles_dir_short }}/$normalized_path"
    target_file="{{ home_dir }}/$normalized_path"
    target_file_short="~/$normalized_path"

    # Check if source file exists
    if [[ ! -f "$source_file" ]]; then
        echo -e "{{ RED }}❌ Error: Source file does not exist: $source_file_short{{ NORMAL }}" >&2
        if [[ -e "$target_file" ]]; then
            echo -e "{{ BLUE }}💡 Did you mean to use 'just import' to import an existing file?{{ NORMAL }}" >&2
        fi
        exit 1
    fi

    # Create parent directories if they don't exist
    parent_dir=$(dirname "$target_file")
    if [[ ! -d "$parent_dir" ]]; then
        echo -e "{{ BLUE }}${log_prefix}📁 Creating directory: $parent_dir{{ NORMAL }}"
        [[ "$doit" == "true" ]] && mkdir -p "$parent_dir"
    fi

    # Handle existing files
    if [[ -e "$target_file" ]] || [[ -L "$target_file" ]]; then
        # Check if it's an identical symlink
        if [[ -L "$target_file" ]]; then
            target_link=$(readlink "$target_file")
            if [[ "$target_link" == "$source_file" ]]; then
                echo -e "{{ GREEN }}${log_prefix}✅ Identical symlink exists: $target_file_short{{ NORMAL }}"
                exit 0
            fi
            echo -e "{{ YELLOW }}${log_prefix}💾 Backing up existing symlink: $target_file_short -> $target_file_short.backup{{ NORMAL }}"
        else
            echo -e "{{ YELLOW }}${log_prefix}💾 Backing up existing file: $target_file_short -> $target_file_short.backup{{ NORMAL }}"
        fi
        [[ "$doit" == "true" ]] && mv "$target_file" "$target_file.backup"
    fi

    # Create the symlink
    echo -e "{{ GREEN }}${log_prefix}🔗 Creating symlink: $target_file_short -> $source_file_short{{ NORMAL }}"
    [[ "$doit" == "true" ]] && ln -s "$source_file" "$target_file" || true

# Link all files in dotfiles/ to ~/
link-all $doit="false": && (_show-dry-run-message doit)
    #!/usr/bin/env bash
    set -euo pipefail

    # Determine mode from boolean argument
    [[ "$doit" == "true" ]] && log_prefix="" || log_prefix="[DRY RUN] "

    echo -e "{{ BLUE }}${log_prefix}🔗 Linking dotfiles from {{ dotfiles_dir_short }} to ~{{ NORMAL }}"
    echo

    # Find all files in dotfiles directory and process them
    if ! find "{{ dotfiles_dir }}" -type f -exec just _link {} "$doit" \; ; then
        echo -e "{{ RED }}❌ Error: Failed to process dotfiles directory{{ NORMAL }}" >&2
        exit 1
    fi

# Import an existing file from ~/ to dotfiles/
import $relative_path $doit="false": && (_show-dry-run-message doit)
    #!/usr/bin/env bash
    set -euo pipefail

    # Determine mode from boolean argument
    [[ "$doit" == "true" ]] && log_prefix="" || log_prefix="[DRY RUN] "

    # Normalize the relative path
    normalized_path="$(echo "$relative_path" \
        | sed "s|^dotfiles/||" \
        | sed "s|^{{ dotfiles_dir }}/||" \
        | sed "s|^~/||" \
        | sed "s|^{{ home_dir }}/||" \
        )"

    # Construct paths
    source_file="{{ dotfiles_dir }}/$normalized_path"
    source_file_short="{{ dotfiles_dir_short }}/$normalized_path"
    target_file="{{ home_dir }}/$normalized_path"
    target_file_short="~/$normalized_path"

    # Check if target file exists
    if [[ ! -e "$target_file" ]]; then
        echo -e "{{ RED }}❌ Error: Target file does not exist: $target_file_short{{ NORMAL }}" >&2
        if [[ -e "$source_file" ]]; then
            echo -e "{{ BLUE }}💡 Did you mean to use 'just link' to link a file?{{ NORMAL }}" >&2
        fi
        exit 1
    fi

    # Create parent directories for source file
    source_parent_dir=$(dirname "$source_file")
    if [[ ! -d "$source_parent_dir" ]]; then
        source_parent_dir_short=$(echo "$source_parent_dir" | sed "s|^{{ home_dir }}|~|")
        echo -e "{{ BLUE }}${log_prefix}📁 Creating directory: $source_parent_dir_short{{ NORMAL }}"
        [[ "$doit" == "true" ]] && mkdir -p "$source_parent_dir"
    fi

    # Backup existing source file if it exists
    if [[ -f "$source_file" ]]; then
        echo -e "{{ YELLOW }}${log_prefix}💾 Backing up source file: $source_file_short -> $source_file_short.backup{{ NORMAL }}"
        [[ "$doit" == "true" ]] && mv "$source_file" "$source_file.backup"
    fi

    # Import the file
    echo -e "{{ BLUE }}${log_prefix}📥 Importing: $target_file_short -> $source_file_short{{ NORMAL }}"

    # If target is a symlink, resolve it and copy the actual file
    if [[ -L "$target_file" ]]; then
        actual_file=$(readlink -f "$target_file")
        actual_file_short=$(echo "$actual_file" | sed "s|^{{ home_dir }}|~|")
        echo -e "{{ BLUE }}${log_prefix}(Resolved symlink: $actual_file_short){{ NORMAL }}"
        [[ "$doit" == "true" ]] && mv "$actual_file" "$source_file"
    else
        # Copy file from target to source (don't move, so we can create symlink)
        [[ "$doit" == "true" ]] && mv "$target_file" "$source_file"
    fi

    # Now create the symlink back
    [[ "$doit" == "true" ]] && ln -s "$source_file" "$target_file" || true

# Set the default shell for the user
set-default-shell $shell $doit="false": && (_show-dry-run-message doit)
    #!/usr/bin/env bash
    set -euo pipefail

    # Determine mode from boolean argument
    [[ "$doit" == "true" ]] && log_prefix="" || log_prefix="[DRY RUN] "

    current_shell=$(dscl . -read /Users/$(whoami) UserShell | awk '{print $2}')
    echo -e "{{ BLUE }}${log_prefix}🔄 Current shell: $current_shell{{ NORMAL }}"

    shell_cmd=$(which "$shell")
    if [[ "$current_shell" == "$shell_cmd" ]]; then
        echo -e "{{ GREEN }}${log_prefix}✅ $shell already set as default shell{{ NORMAL }}"
    else
        echo -e "{{ BLUE }}${log_prefix}🔄 Changing default shell to $shell{{ NORMAL }}"
        [[ "$doit" == "true" ]] && chsh -s "$shell_cmd" || true
    fi

# Install and configure Oh My Zsh
setup-zsh $doit="false": && (_show-dry-run-message doit)
    #!/usr/bin/env bash
    set -euo pipefail

    # Determine mode from boolean argument
    [[ "$doit" == "true" ]] && log_prefix="" || log_prefix="[DRY RUN] "

    # Install oh-my-zsh if not already installed
    if [[ -d "$HOME/.oh-my-zsh" ]]; then
        echo -e "{{ GREEN }}${log_prefix}✅ oh-my-zsh already installed{{ NORMAL }}"
    else
        echo -e "{{ BLUE }}${log_prefix}🐚 Installing oh-my-zsh...{{ NORMAL }}"
        if [[ "$doit" == "true" ]]; then
            RUNZSH=no CHSH=no KEEP_ZSHRC=yes sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
        fi
    fi

    # Install oh-my-zsh custom plugins
    just omz-plugins-install "$doit"

# Install Fish shell and configure it
setup-fish $doit="false": && (_show-dry-run-message doit)
    #!/usr/bin/env bash
    set -euo pipefail

    # Determine mode from boolean argument
    [[ "$doit" == "true" ]] && log_prefix="" || log_prefix="[DRY RUN] "

    echo -e "{{ BLUE }}${log_prefix}🐟 Installing Fish shell and dependencies...{{ NORMAL }}"

    # Install Fish & Friends
    echo -e "{{ BLUE }}${log_prefix}📦 Installing packages: fish, fzf, bat, fd, font-fira-code-nerd-font{{ NORMAL }}"
    [[ "$doit" == "true" ]] && brew install fish fzf bat fd font-fira-code-nerd-font

    # Add Fish to /etc/shells
    if grep -q "/opt/homebrew/bin/fish" /etc/shells 2>/dev/null; then
        echo -e "{{ GREEN }}${log_prefix}✅ Fish already added to /etc/shells{{ NORMAL }}"
    else
        echo -e "{{ BLUE }}${log_prefix}🔧 Adding fish to /etc/shells{{ NORMAL }}"
        [[ "$doit" == "true" ]] && echo /opt/homebrew/bin/fish | sudo tee -a /etc/shells
    fi

    # Install Fisher
    if [[ -f ~/.config/fish/functions/fisher.fish ]]; then
        echo -e "{{ GREEN }}${log_prefix}✅ Fisher plugin manager already installed{{ NORMAL }}"
    else
        echo -e "{{ BLUE }}${log_prefix}🎣 Installing Fisher plugin manager{{ NORMAL }}"
        [[ "$doit" == "true" ]] && curl -sL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish | fish
    fi

    # Update Fisher
    echo -e "{{ BLUE }}${log_prefix}🔄 Updating Fisher{{ NORMAL }}"
    [[ "$doit" == "true" ]] && echo "fisher update" | fish

    # Configure Tide prompt theme
    if [[ ! -f ~/.config/fish/fish_plugins ]]; then
        echo -e "{{ BLUE }}${log_prefix}⏭️ Skipping Tide configuration (fish_plugins not found){{ NORMAL }}"
    elif ! grep -q "tide" ~/.config/fish/fish_plugins; then
        echo -e "{{ BLUE }}${log_prefix}⏭️ Skipping Tide configuration (not in fish_plugins){{ NORMAL }}"
    elif fish -c "functions -q tide" 2>/dev/null; then
        echo -e "{{ GREEN }}${log_prefix}✅ Tide prompt already configured{{ NORMAL }}"
    else
        echo -e "{{ BLUE }}${log_prefix}🎨 Configuring Tide prompt theme{{ NORMAL }}"
        tide_config="tide configure --auto --style=Rainbow --prompt_colors='True color' --show_time=No --rainbow_prompt_separators=Angled --powerline_prompt_heads=Sharp --powerline_prompt_tails=Flat --powerline_prompt_style='Two lines, character' --prompt_connection=Dotted --powerline_right_prompt_frame=No --prompt_connection_andor_frame_color=Light --prompt_spacing=Sparse --icons='Few icons' --transient=Yes"
        [[ "$doit" == "true" ]] && echo "$tide_config" | fish
    fi

    echo -e "{{ GREEN }}${log_prefix}✅ Fish shell setup complete!{{ NORMAL }}"
    echo -e "{{ BLUE }}${log_prefix}💡 You may need to restart your terminal or run 'exec fish' to start using Fish{{ NORMAL }}"

# Export oh-my-zsh custom plugins to file
omz-plugins-dump $doit="false": && (_show-dry-run-message doit)
    #!/usr/bin/env bash
    set -euo pipefail

    # Determine mode from boolean argument
    [[ "$doit" == "true" ]] && log_prefix="" || log_prefix="[DRY RUN] "

    plugins_dir="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins"

    # Check if plugins directory exists
    if [[ ! -d "$plugins_dir" ]]; then
        echo -e "{{ RED }}❌ Oh-my-zsh custom plugins directory not found: $plugins_dir{{ NORMAL }}" >&2
        echo -e "{{ BLUE }}💡 Install oh-my-zsh first with 'just setup-zsh true'{{ NORMAL }}" >&2
        exit 1
    fi

    echo -e "{{ BLUE }}${log_prefix}📦 Exporting custom plugins from $plugins_dir...{{ NORMAL }}"

    # Collect git remote URLs
    temp_file=$(mktemp /tmp/omz-plugins.XXXXXX)

    # Find plugin checkouts, including worktrees whose .git is a file.
    while IFS= read -r plugin_dir; do
        [[ -z "$plugin_dir" ]] && continue
        [[ -e "$plugin_dir/.git" ]] || continue
        git -C "$plugin_dir" rev-parse --git-dir >/dev/null 2>&1 || continue
        plugin_name=$(basename "$plugin_dir")

        # Get git remote URL
        remote_url=$(git -C "$plugin_dir" remote get-url origin 2>/dev/null)
        if [[ -n "$remote_url" ]]; then
            pin=$(awk -F '\t' -v plugin_name="$plugin_name" '$1 == plugin_name { print $3; exit }' "{{ omz_plugins_file }}")
            if [[ -n "$pin" ]]; then
                printf "%s\t%s\t%s\n" "$plugin_name" "$remote_url" "$pin" >> "$temp_file"
                echo -e "{{ GREEN }}${log_prefix}✅ Found: $plugin_name -> $remote_url at $pin{{ NORMAL }}"
            else
                printf "%s\t%s\n" "$plugin_name" "$remote_url" >> "$temp_file"
                echo -e "{{ GREEN }}${log_prefix}✅ Found: $plugin_name -> $remote_url{{ NORMAL }}"
            fi
        else
            echo -e "{{ YELLOW }}${log_prefix}⚠️  Skipping $plugin_name (no remote configured){{ NORMAL }}"
        fi
    done < <(find "$plugins_dir" -mindepth 1 -maxdepth 1 -print | sort)

    # Write to output file (sorted alphabetically)
    echo -e "{{ BLUE }}${log_prefix}📝 Writing plugins to {{ omz_plugins_file }}...{{ NORMAL }}"
    [[ "$doit" == "true" ]] && sort "$temp_file" > "{{ omz_plugins_file }}" || true
    rm -f "$temp_file"

# Install oh-my-zsh custom plugins from file
omz-plugins-install $doit="false": && (_show-dry-run-message doit)
    #!/usr/bin/env bash
    set -euo pipefail

    # Determine mode from boolean argument
    [[ "$doit" == "true" ]] && log_prefix="" || log_prefix="[DRY RUN] "

    # Check if plugins file exists
    if [[ ! -f "{{ omz_plugins_file }}" ]]; then
        echo -e "{{ RED }}❌ Plugins file not found: {{ omz_plugins_file }}{{ NORMAL }}" >&2
        echo -e "{{ BLUE }}💡 Run 'just omz-plugins-dump' to export plugins first{{ NORMAL }}" >&2
        exit 1
    fi

    plugins_dir="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins"

    # Check if plugins directory exists
    if [[ ! -d "$plugins_dir" ]]; then
        echo -e "{{ RED }}❌ Oh-my-zsh custom plugins directory not found: $plugins_dir{{ NORMAL }}" >&2
        echo -e "{{ BLUE }}💡 Install oh-my-zsh first with 'just setup-zsh true'{{ NORMAL }}" >&2
        exit 1
    fi

    echo -e "{{ BLUE }}${log_prefix}📦 Installing plugins to $plugins_dir...{{ NORMAL }}"

    # Read plugin sources from file (format: plugin_name<TAB>url[<TAB>pin])
    while IFS=$'\t' read -r plugin_name url pin || [[ -n "$plugin_name" ]]; do
        # Skip empty lines
        if [[ -z "$plugin_name" ]] || [[ -z "$url" ]]; then
            continue
        fi

        target_dir="$plugins_dir/$plugin_name"

        # Check if plugin already exists
        if [[ -d "$target_dir" ]]; then
            if [[ -e "$target_dir/.git" ]] && git -C "$target_dir" rev-parse --git-dir >/dev/null 2>&1; then
                installed=$(git -C "$target_dir" describe --tags --exact-match 2>/dev/null || git -C "$target_dir" rev-parse --short=7 HEAD)
                if ! git -C "$target_dir" diff --quiet || ! git -C "$target_dir" diff --cached --quiet || [[ -n "$(git -C "$target_dir" ls-files --others --exclude-standard)" ]]; then
                    installed+="-dirty"
                fi
                echo -e "{{ GREEN }}${log_prefix}✅ Already installed: $plugin_name at $installed{{ NORMAL }}"
                continue
            elif [[ -n "$(find "$target_dir" -mindepth 1 -print -quit)" ]]; then
                echo -e "{{ YELLOW }}${log_prefix}⚠️  Skipping $plugin_name (existing directory is not a Git checkout){{ NORMAL }}"
                continue
            fi
        fi

        if ! target=$(just _omz-plugin-target "$url" "$pin"); then
            echo -e "{{ YELLOW }}${log_prefix}⚠️ $plugin_name: unable to resolve latest version{{ NORMAL }}"
            continue
        fi
        IFS=$'\t' read -r target_commit target_label target_kind target_ref <<< "$target"

        echo -e "{{ BLUE }}${log_prefix}📥 Installing: $plugin_name at $target_label from $url{{ NORMAL }}"
        if [[ "$doit" == "true" ]]; then
            if ! git init --quiet "$target_dir" ||
                ! git -C "$target_dir" remote add origin "$url" ||
                ! git -C "$target_dir" fetch --quiet origin "$target_ref"; then
                echo -e "{{ RED }}❌ Failed to install: $plugin_name{{ NORMAL }}"
            elif git -C "$target_dir" checkout --quiet --detach FETCH_HEAD; then
                echo -e "{{ GREEN }}✅ Installed: $plugin_name at $target_label{{ NORMAL }}"
            else
                echo -e "{{ RED }}❌ Installed repository but failed to check out: $plugin_name at $target_label{{ NORMAL }}"
            fi
        fi
    done < "{{ omz_plugins_file }}"

# Update oh-my-zsh custom plugins
omz-plugins-update $doit="false": && (_show-dry-run-message doit)
    #!/usr/bin/env bash
    set -euo pipefail

    # Determine mode from boolean argument
    [[ "$doit" == "true" ]] && log_prefix="" || log_prefix="[DRY RUN] "

    plugins_dir="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins"

    # Check if plugins directory exists
    if [[ ! -d "$plugins_dir" ]]; then
        echo -e "{{ RED }}❌ Oh-my-zsh custom plugins directory not found: $plugins_dir{{ NORMAL }}" >&2
        echo -e "{{ BLUE }}💡 Install oh-my-zsh first with 'just setup-zsh true'{{ NORMAL }}" >&2
        exit 1
    fi

    echo -e "{{ BLUE }}${log_prefix}🔄 Checking plugin updates from {{ omz_plugins_file_short }}...{{ NORMAL }}"

    while IFS=$'\t' read -r plugin_name url pin || [[ -n "$plugin_name" ]]; do
        [[ -z "$plugin_name" ]] || [[ -z "$url" ]] && continue

        plugin_dir="$plugins_dir/$plugin_name"
        if [[ ! -e "$plugin_dir/.git" ]] || ! git -C "$plugin_dir" rev-parse --git-dir >/dev/null 2>&1; then
            echo -e "{{ YELLOW }}${log_prefix}⚠️ $plugin_name: not installed{{ NORMAL }}"
            continue
        fi

        installed_commit=$(git -C "$plugin_dir" rev-parse HEAD)
        installed_label=$(git -C "$plugin_dir" describe --tags --exact-match 2>/dev/null || git -C "$plugin_dir" rev-parse --short=7 HEAD)
        if ! git -C "$plugin_dir" diff --quiet || ! git -C "$plugin_dir" diff --cached --quiet || [[ -n "$(git -C "$plugin_dir" ls-files --others --exclude-standard)" ]]; then
            echo -e "{{ YELLOW }}${log_prefix}⚠️ $plugin_name: skipping dirty checkout{{ NORMAL }}"
            continue
        fi

        if ! target=$(just _omz-plugin-target "$url" "$pin"); then
            echo -e "{{ YELLOW }}${log_prefix}⚠️ $plugin_name: unable to resolve latest version{{ NORMAL }}"
            continue
        fi
        IFS=$'\t' read -r target_commit target_label target_kind target_ref <<< "$target"

        details_url=''
        if [[ "$target_kind" == "release" ]] && [[ "$url" == https://github.com/* ]]; then
            repository_url=${url%.git}
            details_url="$repository_url/releases/tag/$target_label"
        fi

        if [[ "$installed_commit" == "$target_commit" ]]; then
            echo -e "{{ GREEN }}${log_prefix}✅ $plugin_name: $target_label{{ NORMAL }}"
            continue
        fi

        echo -e "{{ BLUE }}${log_prefix}🔄 $plugin_name: $installed_label -> $target_label{{ NORMAL }}"
        [[ -n "$details_url" ]] && echo -e "{{ BLUE }}${log_prefix}   details: $details_url{{ NORMAL }}"

        if [[ "$doit" == "true" ]]; then
            if ! git -C "$plugin_dir" fetch --quiet "$url" "$target_ref"; then
                echo -e "{{ RED }}❌ Failed to fetch: $plugin_name{{ NORMAL }}"
            elif git -C "$plugin_dir" checkout --quiet --detach FETCH_HEAD; then
                echo -e "{{ GREEN }}✅ Updated: $plugin_name at $target_label{{ NORMAL }}"
            else
                echo -e "{{ RED }}❌ Failed to check out: $plugin_name at $target_label{{ NORMAL }}"
            fi
        fi
    done < "{{ omz_plugins_file }}"

# Generate Brewfile from currently installed packages
brew-dump $doit="false": && (_show-dry-run-message doit)
    #!/usr/bin/env bash
    set -euo pipefail

    # Determine mode from boolean argument
    [[ "$doit" == "true" ]] && log_prefix="" || log_prefix="[DRY RUN] "

    echo -e "{{ BLUE }}${log_prefix}🍺 Generating Brewfile from installed packages...{{ NORMAL }}"

    # Brew Bundle treats an empty npm/cargo/uv section as "do not manage this type",
    # not "remove all packages of this type"; exclude them from generated Brewfiles.
    if [[ "$doit" == "true" ]]; then
        brew bundle dump --force --file=- --no-vscode --no-cargo --no-uv --no-npm | \
        awk '
            /^# / { comment = $0; next }
            comment && NF {
                printf "%-28s %s\n", $0, comment
                comment = ""
                next
            }
            comment { print comment; comment = "" }
            { print }
            END { if (comment) print comment }
        ' > "{{ brewfile_path }}"
    fi
    echo -e "{{ GREEN }}${log_prefix}✅ Brewfile generated from installed packages!{{ NORMAL }}"

# Apply Brewfile, (un)installing packages, casks and taps as needed
brew-apply $doit="false": && (_show-dry-run-message doit)
    #!/usr/bin/env bash
    set -euo pipefail

    # Check if Brewfile exists
    if [[ ! -f "{{ brewfile_path }}" ]]; then
        echo -e "{{ RED }}❌ Brewfile not found at {{ brewfile_path }}{{ NORMAL }}" >&2
        echo -e "{{ BLUE }}💡 Run 'just brew-dump true' to generate a Brewfile from installed packages{{ NORMAL }}" >&2
        exit 1
    fi

    # Determine mode from boolean argument
    [[ "$doit" == "true" ]] && log_prefix="" || log_prefix="[DRY RUN] "

    echo -e "{{ BLUE }}${log_prefix}🍺 Applying changes from Brewfile...{{ NORMAL }}"

    # Uninstall first, then install from Brewfile
    if [[ "$doit" == "true" ]]; then
        brew bundle cleanup --force --file="{{ brewfile_path }}"
        echo
        brew bundle --no-upgrade --file="{{ brewfile_path }}" | grep -v '^Using '
        echo
        brew cleanup
    else
        printf 'n' | brew bundle cleanup --file="{{ brewfile_path }}" && echo "No packages to uninstall."
        echo
        brew bundle check --no-upgrade --verbose --file="{{ brewfile_path }}" 2>&1 | grep -v -i 'satisfy.*dependencies' && echo "No packages to install." || true
        echo
    fi

# Install packages from Brewfile
brew-install $doit="false": && (_show-dry-run-message doit)
    #!/usr/bin/env bash
    set -euo pipefail

    # Check if Brewfile exists
    if [[ ! -f "{{ brewfile_path }}" ]]; then
        echo -e "{{ RED }}❌ Brewfile not found at {{ brewfile_path }}{{ NORMAL }}" >&2
        echo -e "{{ BLUE }}💡 Run 'just brew-dump true' to generate a Brewfile from installed packages{{ NORMAL }}" >&2
        exit 1
    fi

    # Determine mode from boolean argument
    [[ "$doit" == "true" ]] && log_prefix="" || log_prefix="[DRY RUN] "

    echo -e "{{ BLUE }}${log_prefix}🍺 Installing packages from Brewfile...{{ NORMAL }}"

    # Install from Brewfile (without cleanup)
    if [[ "$doit" == "true" ]]; then
        brew bundle --no-upgrade --file="{{ brewfile_path }}" | grep -v '^Using '
    else
        brew bundle check --no-upgrade --verbose --file="{{ brewfile_path }}" 2>&1 | grep -v -i 'satisfy.*dependencies' && echo "No packages to install." || true
    fi

# Remove packages not in Brewfile
brew-purge $doit="false": && (_show-dry-run-message doit)
    #!/usr/bin/env bash
    set -euo pipefail

    # Check if Brewfile exists
    if [[ ! -f "{{ brewfile_path }}" ]]; then
        echo -e "{{ RED }}❌ Brewfile not found at {{ brewfile_path }}{{ NORMAL }}" >&2
        echo -e "{{ BLUE }}💡 Run 'just brew-dump true' to generate a Brewfile from installed packages{{ NORMAL }}" >&2
        exit 1
    fi

    # Determine mode from boolean argument
    [[ "$doit" == "true" ]] && log_prefix="" || log_prefix="[DRY RUN] "

    echo -e "{{ BLUE }}${log_prefix}🍺 Removing packages not in Brewfile...{{ NORMAL }}"

    # Clean up packages not in Brewfile
    if [[ "$doit" == "true" ]]; then
        brew bundle cleanup --force --file="{{ brewfile_path }}"
    else
        printf 'n' | brew bundle cleanup --file="{{ brewfile_path }}" && echo "No packages to uninstall." || true
    fi

# List Elixir dependency package names used across stale projects in ~/dev
list-elixir-packages $verbose="false":
    #!/usr/bin/env bash
    set -euo pipefail

    root_dir="${HOME}/dev"

    if [[ ! -d "$root_dir" ]]; then
        echo "❌ Directory not found: $root_dir" >&2
        exit 1
    fi

    # Two years in seconds (365 days * 2)
    two_years_secs=$((365 * 2 * 24 * 60 * 60))
    now_epoch=$(date +%s)

    # Cross-platform stat mtime helper (macOS vs GNU)
    get_mtime() {
        local path="$1"
        if stat -f %m "$path" >/dev/null 2>&1; then
            stat -f %m "$path"    # macOS / BSD
        else
            stat -c %Y "$path"    # GNU
        fi
    }

    # Determine if a directory is stale (not modified in the last two years)
    is_stale_dir() {
        local dir="$1"
        local mtime
        mtime=$(get_mtime "$dir") || return 1
        local age=$((now_epoch - mtime))
        [[ "$age" -ge "$two_years_secs" ]]
    }

    # Extract dependency atoms from a mix.exs file
    extract_deps() {
        local mix_file="$1"
        # Pull text between 'defp deps do' and the matching 'end', then
        # find tuples starting with an atom like {:ecto, ...}
        awk 'BEGIN{inblock=0} /defp[[:space:]]+deps[[:space:]]*do/{inblock=1} inblock{print} /^[[:space:]]*end[[:space:]]*$/&&inblock{exit}' "$mix_file" \
        | sed 's/#.*$//' \
        | grep -Eo "\{:[a-zA-Z0-9_]+[[:space:],}]" || true
    }

    # Accumulate package names and track stats
    tmp_packages=$(mktemp)
    tmp_nonstale=$(mktemp)
    trap 'rm -f "$tmp_packages" "$tmp_nonstale"' EXIT

    total_mix_files=0
    stale_mix_files=0
    dep_tuple_count=0

    # Find all mix.exs files and process those in stale directories
    while IFS= read -r -d '' mix_file; do
        total_mix_files=$((total_mix_files + 1))
        dir="$(dirname "$mix_file")"
        if is_stale_dir "$dir"; then
            stale_mix_files=$((stale_mix_files + 1))
            # Extract deps and write package atoms to temp file
            while IFS= read -r tuple; do
                # tuple looks like '{:ecto,' or '{:ecto }' -> strip to atom name
                pkg=$(echo "$tuple" | sed -E 's/^\{:([a-zA-Z0-9_]+).*/\1/')
                if [[ -n "$pkg" ]]; then
                    dep_tuple_count=$((dep_tuple_count + 1))
                    echo "$pkg" >> "$tmp_packages"
                fi
            done < <(extract_deps "$mix_file")
        else
            echo "$mix_file" >> "$tmp_nonstale"
        fi
    done < <(find "$root_dir" -type d -name deps -prune -o -type f -name mix.exs -print0)

    if [[ ! -s "$tmp_packages" ]]; then
        echo "No dependencies found in stale projects under $root_dir" >&2
        exit 0
    fi

    # Rank by occurrences and output: count package
    total_occurrences=$(wc -l < "$tmp_packages" | awk '{print $1}')
    unique_packages=$(sort "$tmp_packages" | uniq | wc -l | awk '{print $1}')

    non_stale_count=$((total_mix_files - stale_mix_files))
    echo "Stats:"
    echo "  mix.exs found:        $total_mix_files"
    echo "  stale mix.exs:        $stale_mix_files"
    echo "  non-stale mix.exs:    $non_stale_count"
    echo "  dependency tuples:    $dep_tuple_count"
    echo "  total occurrences:    $total_occurrences"
    echo "  unique packages:      $unique_packages"
    echo

    if [[ "$verbose" == "true" ]]; then
        if [[ -s "$tmp_nonstale" ]]; then
            echo "Non-stale mix.exs files:"
            sort "$tmp_nonstale"
            echo
        else
            echo "Non-stale mix.exs files: (none)"
            echo
        fi
    fi
    sort "$tmp_packages" | uniq -c | sort -nr | awk '{printf "%6d %s\n", $1, $2}'
