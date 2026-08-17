#!/usr/bin/env bash

set -euo pipefail

# DotForge - Restore

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
DOTFORGE_DIR="$(cd -- "$SCRIPT_DIR/.." && pwd)"
BACKUP_DIR="$DOTFORGE_DIR/backup"

log() {
    printf '\033[1;34m[DotForge]\033[0m %s\n' "$1"
}

error() {
    printf '\033[1;31m[ERROR]\033[0m %s\n' "$1" >&2
    exit 1
}

# Fastfetch

if [[ -d "$BACKUP_DIR/fastfetch" ]]; then
    log "Restoring fastfetch..."

    mkdir -p "$HOME/.config/fastfetch"

    cp -a "$BACKUP_DIR/fastfetch/." \
        "$HOME/.config/fastfetch/"
else
    log "No fastfetch backup found. Skipping."
fi

# Starship

if [[ -f "$BACKUP_DIR/starship.toml" ]]; then
    log "Restoring starship.toml..."

    mkdir -p "$HOME/.config"

    cp "$BACKUP_DIR/starship.toml" \
        "$HOME/.config/starship.toml"
else
    log "No starship.toml backup found. Skipping."
fi

log "Restore complete."