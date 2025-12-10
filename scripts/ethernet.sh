#!/bin/bash

INSTALL_URL="https://cloud.securew2.com/public/58491/Norwich_University/php/deploy.php"
INSTALL_FILE="SecureW2_JoinNow.run"
NM_DIR="/etc/NetworkManager/system-connections"

# UI helpers
GREEN="\e[32m"; RED="\e[31m"; YELLOW="\e[33m"; BLUE="\e[36m"; NC="\e[0m"
log(){ echo -e "${GREEN}[✔]${NC} $1"; }
info(){ echo -e "${BLUE}[-]${NC} $1"; }
warn(){ echo -e "${YELLOW}[!]${NC} $1"; }
error(){ echo -e "${RED}[✗]${NC} $1"; exit 1; }

command -v expect >/dev/null || error "expect is required → sudo apt install expect"

#==================== 1) Download installer ====================#

info "Requesting SecureW2 installer..."
curl -s -X POST "$INSTALL_URL" \
     -H "Content-Type: application/x-www-form-urlencoded" \
     --data "request=deployLinux" \
     --output "$INSTALL_FILE" || error "download failed"

chmod +x "$INSTALL_FILE"
log "Installer downloaded → $INSTALL_FILE"

#==================== 2) Run installer in PTY ==================#


echo
echo ">>> Installer running — waiting for SSO login..."
echo ">>> Script will pause here until it sees 'Joined...'"
echo

expect << EOF
log_user 1
set timeout -1

spawn ./$INSTALL_FILE

expect {
    "Next/Cancel?" {
        send "Next\r"
        exp_continue
    }
    "Joined..." {
        send_user "\n\[✔]\ Enrollment Completed Successfully!\n"
        exit 0
    }
    eof {
        send_user "\n\[✗]\ Installer exited before Joined... appeared\n"
        exit 1
    }
}
EOF

if [ $? -ne 0 ]; then
    error "Login likely unfinished — no Joined... detected"
fi

#==================== 3) Locate WiFi profile ===================#

info "Searching for Norwich WiFi profile..."

sleep 2
WIFI_PROFILE=$(sudo find "$NM_DIR" -maxdepth 1 -type f -name "Norwich*.nmconnection" | head -n 1)

[[ -z "$WIFI_PROFILE" ]] && error "WiFi profile not found after success — unexpected."

log "WiFi profile found → $WIFI_PROFILE"

#==================== 4) Create Ethernet profile ===============#

UUID=$(uuidgen)
ETH_IFACE=$(nmcli device | awk '$2=="ethernet"{print $1; exit}')
[[ -z "$ETH_IFACE" ]] && ETH_IFACE="eth0" && warn "No ethernet detected — using eth0"

ETH_FILE="$NM_DIR/Norwich-Ethernet.nmconnection"

info "Generating Ethernet configuration..."

sudo awk '
BEGIN { keep=1 }
/^\[wifi\]/ { keep=0 }
/^\[wifi-security\]/ { keep=0 }
/^\[802-1x\]/ { keep=1 }
keep { print }
' "$WIFI_PROFILE" \
| sed -E \
    -e 's/type=wifi/type=ethernet/' \
    -e 's/id=.*/id=Norwich-Ethernet/' \
    -e "s/uuid=.*/uuid=${UUID}/" \
    -e "s/interface-name=.*/interface-name=$ETH_IFACE/" \
| sudo tee "$ETH_FILE" >/dev/null

sudo chmod 600 "$ETH_FILE"
sudo nmcli connection reload
#==================== Done ====================#

echo -e "${BLUE}────────────────────────────────────────────${NC}"
log "Setup Complete!"
echo -e "${GREEN}Connect later using:${NC}"
echo "  sudo nmcli connection up Norwich-Ethernet"
echo -e "${BLUE}────────────────────────────────────────────${NC}"
