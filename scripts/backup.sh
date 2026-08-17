#!/usr/bin/env bash

set -euo pipefail

# DotForge - Backup

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

if [[ -d "$HOME/.config/fastfetch" ]]; then
    log "Backing up fastfetch..."

    mkdir -p "$BACKUP_DIR/fastfetch"

    rm -rf "$BACKUP_DIR/fastfetch/"*

    cp -a "$HOME/.config/fastfetch/." \
        "$BACKUP_DIR/fastfetch/"
else
    log "No fastfetch configuration found. Skipping."
fi

# Starship

if [[ -f "$HOME/.config/starship.toml" ]]; then
    log "Backing up starship.toml..."

    cp "$HOME/.config/starship.toml" \
        "$BACKUP_DIR/starship.toml"
else
    log "No starship.toml found. Skipping."
fi

# Git

cd "$DOTFORGE_DIR"

if [[ ! -d ".git" ]]; then
    error "DotForge is not a Git repository."
fi

log "Checking Git status..."

git add backup/fastfetch backup/starship.toml

if git diff --cached --quiet; then
    log "No configuration changes detected."
    exit 0
fi

git status --short

printf '\n'
read -r -p "Commit these changes? [y/N] " answer

if [[ "$answer" =~ ^[Yy]$ ]]; then
    git commit -m "Update personal configs"
    log "Backup committed to Git."
else
    log "Changes staged but not committed."
fi