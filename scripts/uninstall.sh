#!/bin/bash
# Uninstall Script - Removes all packages installed by setup.sh
# Workflow by aldenpartridge

set -euo pipefail  # Exit on error, undefined vars, pipe failures

# Color output for better readability
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly RED='\033[0;31m'
readonly NC='\033[0m'

log() { echo -e "${GREEN}[INFO]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1" >&2; exit 1; }

# Check if running on Arch
if [[ ! -f /etc/arch-release ]]; then
    error "This script is optimized for Arch Linux"
fi

log "Starting Arch Linux package removal..."

    # Core pacman packages
    log "Removing core pacman packages..."
    core_packages=(
        "python3"
        "python-pip"
        "rustup"
        "python-pipx"
        "python-setuptools"
        "cmake"
        "docker"
        "docker-compose"
        "flatpak"
        "wget"
        "ripgrep"
        "jq"
        "nmap"
        "btop"
        "fzf"
        "llvm"
        "openbsd-netcat"
        "base-devel"
        "oryx"
        "tickrs"
        "tor"
        "yubikey-personalization"
        "libfido2"
        "yubikey-manager"
        "binwalk"
        "findomain"
        "radare2"
        "hashcat"
        "ghidra"
        "go"
        "stow"
        "cronie"
        "obs-studio"
        "obsidian"
        "signal-desktop"
    )

    failed_removals=()
    for package in "${core_packages[@]}"; do
        if sudo pacman -R --noconfirm "$package" 2>/dev/null; then
            log "✓ Removed $package"
        else
            warn "✗ Failed to remove $package (may not be installed)"
            failed_removals+=("$package")
        fi
    done

    # Remove AUR packages if paru exists
    if command -v paru &> /dev/null; then
        log "Removing AUR packages..."
        aur_packages=(
            "mullvad-vpn"
            "mullvad-vpn-cli"
            "burpsuite"
            "aquatone-bin"
            "paru"
        )

        for package in "${aur_packages[@]}"; do
            if paru -R --noconfirm "$package" 2>/dev/null; then
                log "✓ Removed AUR package $package"
            else
                warn "✗ Failed to remove AUR package $package"
            fi
        done
    fi

    # Remove Flatpak applications
    log "Removing Flatpak applications..."
    flatpak_apps=(
        "com.brave.Browser"
        "com.vscodium.codium"
        "dev.vencord.Vesktop"
        "com.github.KRTirtho.Spotube"
        "org.chromium.Chromium"
    )

    for app in "${flatpak_apps[@]}"; do
        if flatpak uninstall -y "$app" 2>/dev/null; then
            log "✓ Removed Flatpak app $app"
        else
            warn "✗ Failed to remove Flatpak app $app"
        fi
    done

    # Disable services
    log "Disabling services..."
    sudo systemctl disable cronie.service 2>/dev/null || warn "Failed to disable cronie"

    # Remove Go tools
    log "Removing Go tools..."
    go_tools=(
        "katana"
        "waybackurls"
        "oty"
        "gf"
        "nuclei"
        "wpprobe"
        "subfinder"
        "httpx"
        "dnsx"
        "assetfinder"
        "puredns"
        "chaos-dl"
        "amass"
        "ffuf"
        "gobuster"
        "dalfox"
        "anew"
        "mgwls"
        "gau"
        "qsreplace"
        "subzy"
        "bxss"
        "recx"
        "shef"
        "gospider"
        "anti-burl"
    )

    for tool in "${go_tools[@]}"; do
        if [[ -f "$HOME/go/bin/$tool" ]]; then
            rm -f "$HOME/go/bin/$tool"
            sudo rm -f "/usr/bin/$tool" 2>/dev/null || true
            log "✓ Removed Go tool $tool"
        fi
    done

    # Remove Python tools
    log "Removing Python tools..."
    if command -v pipx &> /dev/null; then
        python_tools=(
            "dirsearch"
            "sublist3r"
            "xnlinkfinder"
            "arjun"
            "uro"
            "ghauri"
            "xsrfprobe"
            "bbot"
            "waymore"
        )

        for tool in "${python_tools[@]}"; do
            if pipx uninstall "$tool" 2>/dev/null; then
                log "✓ Removed Python tool $tool"
            else
                warn "✗ Failed to remove Python tool $tool"
            fi
        done
    fi

    # Remove Rust tools
    log "Removing Rust tools..."
    if [[ -d "$HOME/.cargo/bin" ]]; then
        cargo uninstall x8 2>/dev/null || warn "Failed to uninstall x8"
    fi

    # Remove manually installed tools
    log "Removing manually installed tools..."
    manual_tools=(
        "/usr/bin/urldedupe"
        "/usr/bin/massdns"
        "/usr/bin/lostfuzzer"
        "/usr/local/bin/trufflehog"
    )

    for tool in "${manual_tools[@]}"; do
        if [[ -f "$tool" ]]; then
            sudo rm -f "$tool"
            log "✓ Removed $tool"
        fi
    done

    # Remove directories and configurations
    log "Removing directories and configurations..."
    dirs_to_remove=(
        "$HOME/tools"
        "$HOME/scripts"
        "$HOME/wordlists"
        "$HOME/.gf"
        "$HOME/.config/puredns"
        "$HOME/Notes"
        "$HOME/Dev"
        "$HOME/Work"
        "$HOME/Misc"
        "$HOME/sys-scripts"
        "$HOME/nuclei-templates"
        "$HOME/oty-templates"
        "$HOME/.var/app/org.torproject.torbrowser-launcher"
        "$HOME/go"
        "/tmp/yay"
        "/tmp/paru"
        "/tmp/massdns"
        "~/tools/urldedupe"
        "~/tools/lostfuzzer"
        "~/tools/bb"
        "~/tools/rocket-crawl.sh"
    )

    for dir in "${dirs_to_remove[@]}"; do
        if [[ -d "$dir" ]]; then
            rm -rf "$dir"
            log "✓ Removed directory $dir"
        fi
    done

    # Remove PATH additions from .bashrc
    log "Cleaning up .bashrc..."
    if [[ -f "$HOME/.bashrc" ]]; then
        # Create backup
        cp "$HOME/.bashrc" "$HOME/.bashrc.backup"

        # Remove PATH additions
        sed -i '/export PATH="$HOME\/\.cargo\/bin:$PATH"/d' "$HOME/.bashrc"
        sed -i '/export PATH="$PATH:$HOME\/go\/bin"/d' "$HOME/.bashrc"
        log "✓ Removed PATH additions from .bashrc"
    fi

    # Remove cron job
    log "Removing cron jobs..."
    if sudo grep -q "rand-serv.sh" /etc/crontab 2>/dev/null; then
        sudo sed -i '/rand-serv.sh/d' /etc/crontab
        log "✓ Removed cron job"
    fi

    # Remove TruffleHog
    if command -v trufflehog &> /dev/null; then
        sudo rm -f /usr/local/bin/trufflehog
        log "✓ Removed TruffleHog"
    fi

    # Clean up package cache
    log "Cleaning up package cache..."
    sudo pacman -Scc --noconfirm || warn "Failed to clean package cache"

    if [ ${#failed_removals[@]} -gt 0 ]; then
        warn "Some packages failed to remove: ${failed_removals[*]}"
        warn "This is normal if they weren't installed"
    fi

    log "Arch Linux packages removed successfully!"
    warn "Please manually review ~/.bashrc and other config files for any remaining modifications"

log "Uninstall script finished!"