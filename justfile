# Justfile for dev-setup dotfiles management
#
# This justfile provides commands for linking dotfiles from the dotfiles/ directory
# to the home directory, maintaining symlinks for easy version control.

dotfiles_dir := justfile_directory() / "dotfiles"
home_dir := env_var('HOME')
dotfiles_dir_short := replace_regex(dotfiles_dir, "^" + home_dir, "~")

# Default recipe - show available commands
[default]
_default:
    @just --list

# Private command to show dry-run message
_show-dry-run-message $doit:
    #!/usr/bin/env bash
    set -euo pipefail

    # Only show dry-run message if we're in dry-run mode
    if [[ "$doit" != "true" ]]; then
        echo
        echo -e "{{ BLUE }}💡 This was a dry run. No files were actually modified.{{ NORMAL }}"
        echo -e "{{ BLUE }}   Run with doit=true to perform the actual operation.{{ NORMAL }}"
    fi

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
        echo -e "{{ RED }}❌ Error: Failed to process dotfiles directory{{ NORMAL }}"
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

# Install Fish shell and configure it
setup-fish $doit="false" $make_default="false": && (_show-dry-run-message doit)
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

    # Set Fish as default shell
    current_shell=$(dscl . -read /Users/$(whoami) UserShell | awk '{print $2}')
    if [[ "$current_shell" == "/opt/homebrew/bin/fish" ]]; then
        echo -e "{{ GREEN }}${log_prefix}✅ Fish already set as default shell{{ NORMAL }}"
    elif [[ "$make_default" == "true" ]]; then
        echo -e "{{ BLUE }}${log_prefix}🔄 Changing default shell to fish{{ NORMAL }}"
        [[ "$doit" == "true" ]] && chsh -s /opt/homebrew/bin/fish
    else
        echo -e "{{ BLUE }}${log_prefix}⏭️ Skipping default shell change (make_default=false){{ NORMAL }}"
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
