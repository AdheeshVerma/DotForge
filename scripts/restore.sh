#!/usr/bin/env bash
script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
timestamp="$(date '+%Y-%m-%d-%H%M%S')"
backup_root="$HOME/.local/share/dotforge/backups/$timestamp"
configs=(
    "starship.toml"
    "fish"
    "hypr"
    "fastfetch"
    "uwsm"
    "foot"
    "caelestia"
)

prepare_home() {
    mkdir -p "$HOME/.config"
    mkdir -p "$HOME/.local/share"
    mkdir -p "$HOME/.local/state"
}

backup_config() {
    local target="$1"
    local name="$(basename "$target")"
    local backup="$backup_root/$name"

    echo "Backing up $target -> $backup"

    if [ -e "$backup" ]; then
        echo "ERROR: Backup already exists: $backup"
        return 1
    fi

    if cp -aL "$target" "$backup"; then
        echo "Backup complete: $backup"
    else
        echo "ERROR: Backup failed!"
        return 1
    fi
}

restore_config() {
    local source="$1"
    local target="$2"

    echo "Restoring $source -> $target"

    if [ -e "$target" ]; then
        rm -rf "$target"
    fi

    if cp -a "$source" "$target"; then
        echo "Restore complete: $target"
    else
        echo "ERROR: Restore failed!"
        return 1
    fi
}

prepare_home

# Validating All the dirs in my backup
for config in "${configs[@]}"; do
    source="$script_dir/../backup/$config"

    if [ -e "$source" ]; then
        echo "$source found"
    else
        echo "ERROR: $source not found"
        exit 1
    fi
done

# Creating Backup dir
mkdir -p "$backup_root"

echo "Backup Root: $backup_root"

# Backing up all user configs 
for config in "${configs[@]}"; do
    source="$script_dir/../backup/$config"
    target="$HOME/.config/$config"

    echo "Config: $config"
    echo "Source: $source"
    echo "Target: $target"

    if [ -e "$target" ]; then
        echo "Target exists: $target"

        if ! backup_config "$target"; then
            echo "ERROR: Backup failed. Aborting."
            exit 1
        fi
    else
        echo "Target does not exist: $target"
    fi
    echo
done

# Restore my configs from the repo
for config in "${configs[@]}"; do
    source="$script_dir/../backup/$config"
    target="$HOME/.config/$config"

    restore_config "$source" "$target" || exit 1
done

echo "Dotforge restore completed successfully."