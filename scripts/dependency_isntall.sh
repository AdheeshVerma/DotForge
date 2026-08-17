#!/usr/bin/env bash

set -euo pipefail

SCRIPT_NAME="$(basename "$0")"

log() {
    printf '[Dotforge] %s\n' "$1"
}

warn() {
    printf '[Dotforge] WARNING: %s\n' "$1" >&2
}

die() {
    printf '[Dotforge] ERROR: %s\n' "$1" >&2
    exit 1
}

require_root_or_sudo() {
    if [[ $EUID -eq 0 ]]; then
        die "Do not run dependency_install.sh as root."
    fi

    if ! command -v sudo >/dev/null 2>&1; then
        die "sudo is required."
    fi
}

check_arch() {
    if [[ ! -f /etc/os-release ]]; then
        die "Cannot determine operating system."
    fi

    source /etc/os-release

    if [[ "${ID:-}" != "arch" && "${ID_LIKE:-}" != *"arch"* ]]; then
        die "This version of Dotforge only supports Arch-based systems."
    fi

    log "Detected Arch-based system: ${PRETTY_NAME:-unknown}"
}

check_pacman() {
    if ! command -v pacman >/dev/null 2>&1; then
        die "pacman was not found."
    fi
}

install_repo_packages() {
    local packages=(
        git
        base-devel
        curl
        jq
        eza
        ugrep
        starship

        hyprland
        xdg-desktop-portal
        xdg-desktop-portal-hyprland
        xdg-desktop-portal-gtk

        pipewire
        pipewire-pulse
        wireplumber

        networkmanager
        fish

        brightnessctl
        # ddcutil
        # lm_sensors

        wl-clipboard
        cliphist
        grim
        slurp
        swappy

        ttf-jetbrains-mono-nerd
        ttf-material-symbols-variable
    )

    log "Installing official repository packages..."

    sudo pacman -S --needed "${packages[@]}"
}

detect_aur_helper() {
    if command -v paru >/dev/null 2>&1; then
        AUR_HELPER="paru"
        return
    fi

    if command -v yay >/dev/null 2>&1; then
        AUR_HELPER="yay"
        return
    fi

    AUR_HELPER=""
}

install_paru() {
    log "No AUR helper detected. Installing paru..."

    local build_dir="$(mktemp -d)"

    trap 'rm -rf "$build_dir"' RETURN

    git clone https://aur.archlinux.org/paru.git "$build_dir/paru"

    (
        cd "$build_dir/paru"
        makepkg -si --noconfirm
    )

    if ! command -v paru >/dev/null 2>&1; then
        die "paru installation failed."
    fi

    AUR_HELPER="paru"
}

install_aur_packages() {
    local packages=(
        caelestia-cli
        caelestia-shell
        quickshell-git
    )

    log "Installing AUR packages using ${AUR_HELPER}..."

    "$AUR_HELPER" -S --needed "${packages[@]}"
}

validate_packages() {
    local packages=(
        hyprland
        xdg-desktop-portal
        xdg-desktop-portal-hyprland
        xdg-desktop-portal-gtk

        pipewire
        pipewire-pulse
        wireplumber

        networkmanager
        fish

        caelestia-cli
        caelestia-shell
        quickshell-git
    )

    log "Validating installed packages..."

    local package

    for package in "${packages[@]}"; do
        if pacman -Q "$package" >/dev/null 2>&1; then
            printf '  ✓ %s\n' "$package"
        else
            printf '  ✗ %s\n' "$package"
            die "Package validation failed."
        fi
    done
}

main() {
    log "Starting dependency installation."

    require_root_or_sudo
    check_arch
    check_pacman

    detect_aur_helper

    if [[ -z "$AUR_HELPER" ]]; then
        install_paru
    else
        log "Using AUR helper: $AUR_HELPER"
    fi

    install_repo_packages
    install_aur_packages
    validate_packages

    log "Dependency installation completed successfully."
}

main "$@"