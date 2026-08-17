#!/usr/bin/env bash

set -u

# ==========================================
# DotForge - System Probe
# ==========================================

json_escape() {
    printf '%s' "$1" |
        sed 's/\\/\\\\/g; s/"/\\"/g'
}

# ==========================================
# OS
# ==========================================

get_distro() {
    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        printf '%s' "${NAME:-Unknown}"
    else
        printf '%s' "Unknown"
    fi
}

get_distro_id() {
    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        printf '%s' "${ID:-unknown}"
    else
        printf '%s' "unknown"
    fi
}

get_distro_version() {
    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        printf '%s' "${VERSION_ID:-rolling}"
    else
        printf '%s' "unknown"
    fi
}

# ==========================================
# CPU
# ==========================================

get_cpu_model() {
    lscpu 2>/dev/null |
        awk -F: '/Model name/ {
            gsub(/^[ \t]+/, "", $2)
            print $2
            exit
        }'
}

get_cpu_cores() {
    lscpu 2>/dev/null |
        awk -F: '/Core\(s\) per socket/ {
            gsub(/^[ \t]+/, "", $2)
            cores=$2
        }

        /Socket\(s\)/ {
            gsub(/^[ \t]+/, "", $2)
            sockets=$2
        }

        END {
            if (cores && sockets)
                print cores * sockets
            else
                print 0
        }'
}

get_cpu_threads() {
    lscpu 2>/dev/null |
        awk -F: '/CPU\(s\)/ {
            gsub(/^[ \t]+/, "", $2)
            print $2
            exit
        }'
}

# ==========================================
# GPU
# ==========================================

get_gpu_info() {
    if ! command -v lspci >/dev/null 2>&1; then
        return
    fi

    lspci -nnk |
        grep -A 3 -Ei \
        'VGA compatible controller|3D controller|Display controller' \
        || true
}

get_gpu_vendor() {
    local gpu="$1"

    case "$gpu" in
        *NVIDIA*)
            printf '%s' "NVIDIA"
            ;;
        *AMD*|*Advanced\ Micro\ Devices*|*ATI*)
            printf '%s' "AMD"
            ;;
        *Intel*)
            printf '%s' "Intel"
            ;;
        *)
            printf '%s' "Unknown"
            ;;
    esac
}

get_gpu_model() {
    local gpu_block="$1"

    printf '%s\n' "$gpu_block" |
        head -n1 |
        sed 's/^[^:]*: //' |
        sed 's/ \[[0-9a-fA-F:]*\]//g'
}

get_gpu_driver() {
    local gpu_block="$1"

    local driver

    driver=$(
        printf '%s\n' "$gpu_block" |
            sed -n 's/.*Kernel driver in use: //p' |
            head -n1
    )

    if [[ -n "$driver" ]]; then
        printf '%s' "$driver"
    else
        printf '%s' "none"
    fi
}

# ==========================================
# Graphics
# ==========================================

has_drm() {
    if [[ -d /dev/dri ]]; then
        echo true
    else
        echo false
    fi
}

has_render_node() {
    if compgen -G "/dev/dri/renderD*" >/dev/null 2>&1; then
        echo true
    else
        echo false
    fi
}

get_opengl_renderer() {
    if command -v glxinfo >/dev/null 2>&1; then

        local renderer

        renderer=$(
            glxinfo -B 2>/dev/null |
                awk -F: '
                    /OpenGL renderer string/ {
                        gsub(/^[ \t]+/, "", $2)
                        print $2
                        exit
                    }
                '
        )

        if [[ -n "$renderer" ]]; then
            printf '%s' "$renderer"
        else
            printf '%s' "unavailable"
        fi

    else
        printf '%s' "unavailable"
    fi
}

get_vulkan_gpu() {
    if command -v vulkaninfo >/dev/null 2>&1; then

        local gpu

        gpu=$(
            vulkaninfo --summary 2>/dev/null |
                awk -F: '
                    /deviceName/ {
                        gsub(/^[ \t]+/, "", $2)
                        print $2
                        exit
                    }
                '
        )

        if [[ -n "$gpu" ]]; then
            printf '%s' "$gpu"
        else
            printf '%s' "unavailable"
        fi

    else
        printf '%s' "unavailable"
    fi
}

# ==========================================
# Session
# ==========================================

get_session_type() {
    printf '%s' "${XDG_SESSION_TYPE:-unknown}"
}

get_desktop() {
    printf '%s' "${XDG_CURRENT_DESKTOP:-unknown}"
}

get_session_desktop() {
    printf '%s' "${XDG_SESSION_DESKTOP:-unknown}"
}

# ==========================================
# Collect values
# ==========================================

ARCH="$(uname -m)"

DISTRO="$(get_distro)"
DISTRO_ID="$(get_distro_id)"
DISTRO_VERSION="$(get_distro_version)"
KERNEL="$(uname -r)"

CPU_MODEL="$(get_cpu_model)"
CPU_CORES="$(get_cpu_cores)"
CPU_THREADS="$(get_cpu_threads)"

MEMORY_MB="$(
    awk '/MemTotal/ {
        printf "%.0f", $2 / 1024
    }' /proc/meminfo
)"

GPU_INFO="$(get_gpu_info)"

GPU_VENDOR="Unknown"
GPU_MODEL="Unknown"
GPU_DRIVER="none"

if [[ -n "$GPU_INFO" ]]; then
    GPU_VENDOR="$(get_gpu_vendor "$GPU_INFO")"
    GPU_MODEL="$(get_gpu_model "$GPU_INFO")"
    GPU_DRIVER="$(get_gpu_driver "$GPU_INFO")"
fi

DRM="$(has_drm)"
RENDER_NODE="$(has_render_node)"

OPENGL="$(get_opengl_renderer)"
VULKAN="$(get_vulkan_gpu)"

SESSION_TYPE="$(get_session_type)"
CURRENT_DESKTOP="$(get_desktop)"
SESSION_DESKTOP="$(get_session_desktop)"

# ==========================================
# Output JSON
# ==========================================

cat <<EOF
{
  "architecture": "$(json_escape "$ARCH")",

  "os": {
    "name": "$(json_escape "$DISTRO")",
    "id": "$(json_escape "$DISTRO_ID")",
    "version": "$(json_escape "$DISTRO_VERSION")",
    "kernel": "$(json_escape "$KERNEL")"
  },

  "cpu": {
    "model": "$(json_escape "$CPU_MODEL")",
    "cores": $CPU_CORES,
    "threads": $CPU_THREADS
  },

  "memory": {
    "total_mb": $MEMORY_MB
  },

  "gpu": {
    "vendor": "$(json_escape "$GPU_VENDOR")",
    "model": "$(json_escape "$GPU_MODEL")",
    "driver": "$(json_escape "$GPU_DRIVER")"
  },

  "graphics": {
    "drm": $DRM,
    "render_node": $RENDER_NODE,
    "opengl_renderer": "$(json_escape "$OPENGL")",
    "vulkan_gpu": "$(json_escape "$VULKAN")"
  },

  "session": {
    "type": "$(json_escape "$SESSION_TYPE")",
    "desktop": "$(json_escape "$CURRENT_DESKTOP")",
    "session_desktop": "$(json_escape "$SESSION_DESKTOP")"
  }
}
EOF