#!/usr/bin/env bash

set -euo pipefail

SCRIPT_NAME="$(basename "$0")"
AUR_HELPER=""

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

check_user() {
    if [[ $EUID -eq 0 ]]; then
        die "Do not run $SCRIPT_NAME as root."
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

    log "Detected: ${PRETTY_NAME:-Arch-based system}"
}

check_pacman() {
    command -v pacman >/dev/null 2>&1 ||
        die "pacman was not found."
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
    log "No AUR helper found. Installing paru..."

    local build_dir
    build_dir="$(mktemp -d)"

    git clone https://aur.archlinux.org/paru.git "$build_dir/paru"

    (
        cd "$build_dir/paru"
        makepkg -si --noconfirm
    )

    rm -rf "$build_dir"

    command -v paru >/dev/null 2>&1 ||
        die "Failed to install paru."

    AUR_HELPER="paru"
}

install_repo_packages() {
    local packages=(
        # Core
        git
        base-devel
        curl
        jq

        # Hyprland / Wayland
        hyprland
        xdg-desktop-portal
        xdg-desktop-portal-hyprland
        xdg-desktop-portal-gtk
        uwsm

        # PipeWire / audio
        pipewire
        pipewire-pulse
        wireplumber
        cava

        # Shell
        fish
        starship
        eza
        ugrep

        # Caelestia CLI supporting tools
        swappy
        libnotify
        slurp
        wl-clipboard
        cliphist
        xdg-utils
        dart-sass
        grim
        fuzzel
        gpu-screen-recorder
        dconf
        killall

        # Terminal / utilities from restored config
        foot
        fastfetch

        # Fonts
        ttf-jetbrains-mono-nerd
        ttf-material-symbols-variable

        # Themes / icons
        adwaita-icon-theme
        papirus-icon-theme
    )

    log "Installing official repository packages..."

    sudo pacman -S --needed "${packages[@]}"
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
        uwsm

        pipewire
        pipewire-pulse
        wireplumber
        cava

        fish
        starship
        eza
        ugrep

        foot
        fastfetch

        caelestia-cli
        caelestia-shell
        quickshell-git
    )

    log "Validating installed packages..."

    local package
    local failed=0

    for package in "${packages[@]}"; do
        if pacman -Q "$package" >/dev/null 2>&1; then
            printf '  ✓ %s\n' "$package"
        else
            printf '  ✗ %s\n' "$package"
            failed=1
        fi
    done

    if (( failed )); then
        die "One or more required packages are missing."
    fi
}

validate_commands() {
    local commands=(
        hyprland
        hyprctl
        fish
        starship
        eza
        ugrep
        foot
        fastfetch
        caelestia
        quickshell
        cava
    )

    log "Validating required commands..."

    local command
    local failed=0

    for command in "${commands[@]}"; do
        if command -v "$command" >/dev/null 2>&1; then
            printf '  ✓ %s\n' "$command"
        else
            printf '  ✗ %s\n' "$command"
            failed=1
        fi
    done

    if (( failed )); then
        die "One or more required commands are unavailable."
    fi
}

main() {
    log "Starting Dotforge dependency installation."

    check_user
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
    validate_commands

    log "Dependency installation completed successfully."
}

main "$@"