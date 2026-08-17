#!/usr/bin/env bash

set -euo pipefail

# DotForge - Installation

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
DOTFORGE_DIR="$(cd -- "$SCRIPT_DIR/.." && pwd)"

log() {
    printf '\n\033[1;34m[DotForge]\033[0m %s\n' "$1"
}

error() {
    printf '\n\033[1;31m[ERROR]\033[0m %s\n' "$1" >&2
    exit 1
}

# Requirements

if [[ $EUID -eq 0 ]]; then
    error "Do not run this script as root."
fi

if ! command -v pacman >/dev/null 2>&1; then
    error "pacman was not found. DotForge currently requires Arch Linux."
fi

# Update system

log "Updating package database..."
sudo pacman -Syu --noconfirm

# Install paru

if command -v paru >/dev/null 2>&1; then
    log "paru is already installed."
else
    log "Installing prerequisites for paru..."

    sudo pacman -S --needed --noconfirm \
        base-devel \
        git

    log "Building paru..."

    PARU_BUILD_DIR="$(mktemp -d)"

    trap 'rm -rf "$PARU_BUILD_DIR"' EXIT

    git clone https://aur.archlinux.org/paru.git "$PARU_BUILD_DIR/paru"

    cd "$PARU_BUILD_DIR/paru"

    makepkg -si --noconfirm

    cd "$DOTFORGE_DIR"

    log "paru installed successfully."
fi

# Hyprland dependencies / supporting packages

log "Installing Hyprland and supporting packages..."

sudo pacman -S --needed --noconfirm \
    hyprland \
    xdg-desktop-portal-hyprland \
    xdg-desktop-portal-gtk \
    ttf-jetbrains-mono-nerd \
    noto-fonts \
    noto-fonts-emoji \
    papirus-icon-theme \
    ugrep

# Caelestia

if command -v caelestia >/dev/null 2>&1; then
    log "Caelestia CLI is already installed."
else
    log "Installing Caelestia CLI..."

    paru -S --needed --noconfirm caelestia-cli
fi

log "Running Caelestia installer..."

caelestia install

# Restore personal configuration

log "Restoring personal configuration..."

"$SCRIPT_DIR/restore.sh"

log "Installation complete! :))"