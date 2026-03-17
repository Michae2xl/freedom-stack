#!/usr/bin/env bash
# ============================================================================
# Freedom Stack — Local Machine Hardening (Phase 1)
# Run this AFTER installing Linux on your computer
# ============================================================================
set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

log()  { echo -e "${GREEN}[✓]${NC} $1"; }
warn() { echo -e "${YELLOW}[!]${NC} $1"; }
err()  { echo -e "${RED}[✗]${NC} $1"; }
info() { echo -e "${BLUE}[i]${NC} $1"; }
step() { echo -e "\n${CYAN}━━━ $1 ━━━${NC}\n"; }

# Detect distro
detect_distro() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        DISTRO="$ID"
        DISTRO_FAMILY=""
        case "$ID" in
            ubuntu|linuxmint|pop|elementary|zorin) DISTRO_FAMILY="debian" ;;
            debian) DISTRO_FAMILY="debian" ;;
            fedora) DISTRO_FAMILY="fedora" ;;
            arch|manjaro|endeavouros) DISTRO_FAMILY="arch" ;;
            *) DISTRO_FAMILY="unknown" ;;
        esac
    else
        DISTRO="unknown"
        DISTRO_FAMILY="unknown"
    fi
    info "Detected: ${PRETTY_NAME:-$DISTRO} (family: $DISTRO_FAMILY)"
}

# Package manager wrapper
pkg_install() {
    case "$DISTRO_FAMILY" in
        debian) sudo apt install -y "$@" ;;
        fedora) sudo dnf install -y "$@" ;;
        arch)   sudo pacman -S --noconfirm "$@" ;;
        *)      err "Unsupported distro. Install manually: $*"; return 1 ;;
    esac
}

pkg_remove() {
    case "$DISTRO_FAMILY" in
        debian) sudo apt purge -y "$@" 2>/dev/null || true ;;
        fedora) sudo dnf remove -y "$@" 2>/dev/null || true ;;
        arch)   sudo pacman -Rns --noconfirm "$@" 2>/dev/null || true ;;
    esac
}

# ============================================================================
echo -e "${CYAN}"
echo "╔══════════════════════════════════════════════════╗"
echo "║   🛡️  FREEDOM STACK — Local Machine Hardening    ║"
echo "║   Phase 1: Secure your computer                  ║"
echo "╚══════════════════════════════════════════════════╝"
echo -e "${NC}"

detect_distro

# ============================================================================
step "1/8 — System Update"
# ============================================================================

case "$DISTRO_FAMILY" in
    debian) sudo apt update && sudo apt upgrade -y ;;
    fedora) sudo dnf upgrade -y ;;
    arch)   sudo pacman -Syu --noconfirm ;;
esac
log "System updated"

# ============================================================================
step "2/8 — Remove Telemetry & Unnecessary Services"
# ============================================================================

if [[ "$DISTRO" == "ubuntu" || "$DISTRO" == "pop" ]]; then
    pkg_remove ubuntu-report popularity-contest apport whoopsie 2>/dev/null
    sudo systemctl disable --now whoopsie 2>/dev/null || true
    sudo systemctl disable --now apport 2>/dev/null || true
    log "Ubuntu telemetry removed"
elif [[ "$DISTRO" == "fedora" ]]; then
    # Fedora has less telemetry, but disable ABRT reporting
    sudo systemctl disable --now abrtd 2>/dev/null || true
    log "Fedora telemetry minimized"
fi

# Disable unnecessary services on all distros
for svc in avahi-daemon cups bluetooth; do
    if systemctl is-active "$svc" &>/dev/null; then
        sudo systemctl disable --now "$svc" 2>/dev/null || true
        info "Disabled: $svc"
    fi
done
log "Unnecessary services disabled"

# ============================================================================
step "3/8 — Firewall (UFW)"
# ============================================================================

pkg_install ufw
sudo ufw default deny incoming
sudo ufw default allow outgoing
# Allow local network for printing/sharing if needed
# sudo ufw allow from 192.168.0.0/16
echo "y" | sudo ufw enable
log "Firewall active — all incoming blocked, outgoing allowed"

# ============================================================================
step "4/8 — Automatic Security Updates"
# ============================================================================

case "$DISTRO_FAMILY" in
    debian)
        pkg_install unattended-upgrades
        sudo dpkg-reconfigure -plow unattended-upgrades
        log "Automatic security updates enabled (unattended-upgrades)"
        ;;
    fedora)
        pkg_install dnf-automatic
        sudo systemctl enable --now dnf-automatic-install.timer
        log "Automatic security updates enabled (dnf-automatic)"
        ;;
    arch)
        warn "Arch: no auto-updates configured (rolling release — update manually)"
        ;;
esac

# ============================================================================
step "5/8 — Kernel Hardening (sysctl)"
# ============================================================================

sudo tee /etc/sysctl.d/99-freedom-hardened.conf > /dev/null << 'EOF'
# Freedom Stack — Kernel Hardening

# Restrict kernel logs and pointers
kernel.dmesg_restrict = 1
kernel.kptr_restrict = 2

# Full ASLR
kernel.randomize_va_space = 2

# Restrict ptrace (prevents process snooping)
kernel.yama.ptrace_scope = 2

# Network hardening
net.ipv4.conf.all.accept_redirects = 0
net.ipv6.conf.all.accept_redirects = 0
net.ipv4.conf.default.accept_redirects = 0
net.ipv6.conf.default.accept_redirects = 0
net.ipv4.conf.all.accept_source_route = 0
net.ipv6.conf.all.accept_source_route = 0
net.ipv4.conf.all.send_redirects = 0
net.ipv4.tcp_syncookies = 1
net.ipv4.conf.all.log_martians = 1
net.ipv4.icmp_echo_ignore_broadcasts = 1

# Disable IPv6 if not needed (uncomment if desired)
# net.ipv6.conf.all.disable_ipv6 = 1
# net.ipv6.conf.default.disable_ipv6 = 1
EOF

sudo sysctl --system > /dev/null
log "Kernel hardened (sysctl)"

# ============================================================================
step "6/8 — Private DNS"
# ============================================================================

info "Setting DNS to Quad9 (9.9.9.9) — Swiss, blocks malware, no logging"

# Handle different DNS config methods
if command -v resolvectl &>/dev/null && systemctl is-active systemd-resolved &>/dev/null; then
    # systemd-resolved based (Ubuntu 22+, Fedora)
    sudo mkdir -p /etc/systemd/resolved.conf.d/
    sudo tee /etc/systemd/resolved.conf.d/freedom-dns.conf > /dev/null << 'EOF'
[Resolve]
DNS=9.9.9.9#dns.quad9.net 149.112.112.112#dns.quad9.net
DNSOverTLS=yes
DNSSEC=yes
Domains=~.
EOF
    sudo systemctl restart systemd-resolved
    log "DNS-over-TLS configured via systemd-resolved → Quad9"
else
    # Direct resolv.conf
    sudo chattr -i /etc/resolv.conf 2>/dev/null || true
    echo -e "nameserver 9.9.9.9\nnameserver 149.112.112.112" | sudo tee /etc/resolv.conf
    sudo chattr +i /etc/resolv.conf
    log "DNS configured → Quad9 (resolv.conf locked)"
fi

# ============================================================================
step "7/8 — Install Essential FOSS Security Tools"
# ============================================================================

# Password manager
pkg_install keepassxc
log "KeePassXC installed (password manager)"

# Secure delete
pkg_install secure-delete 2>/dev/null || pkg_install srm 2>/dev/null || warn "secure-delete not available"

# Disk encryption tools
pkg_install cryptsetup
log "cryptsetup installed (disk encryption management)"

# Install Flatpak for sandboxed apps
if ! command -v flatpak &>/dev/null; then
    pkg_install flatpak
    flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
    log "Flatpak + Flathub configured"
else
    log "Flatpak already available"
fi

# Install WireGuard (for VPN in Phase 4)
pkg_install wireguard-tools 2>/dev/null || pkg_install wireguard 2>/dev/null || warn "WireGuard: install manually"
log "WireGuard tools installed (ready for Phase 4)"

# ============================================================================
step "8/8 — Verification"
# ============================================================================

echo ""
echo -e "${CYAN}━━━ Security Checklist ━━━${NC}"

# Check LUKS
echo -n "  Disk encryption (LUKS): "
if lsblk -f 2>/dev/null | grep -q "crypto_LUKS"; then
    echo -e "${GREEN}✓ ACTIVE${NC}"
else
    echo -e "${YELLOW}! NOT DETECTED — did you encrypt during install?${NC}"
fi

# Check firewall
echo -n "  Firewall (UFW): "
if sudo ufw status 2>/dev/null | grep -q "Status: active"; then
    echo -e "${GREEN}✓ ACTIVE${NC}"
else
    echo -e "${RED}✗ INACTIVE${NC}"
fi

# Check auto-updates
echo -n "  Auto-updates: "
case "$DISTRO_FAMILY" in
    debian)
        if systemctl is-active unattended-upgrades &>/dev/null; then
            echo -e "${GREEN}✓ ACTIVE${NC}"
        else
            echo -e "${YELLOW}! CHECK CONFIG${NC}"
        fi
        ;;
    fedora)
        if systemctl is-active dnf-automatic-install.timer &>/dev/null; then
            echo -e "${GREEN}✓ ACTIVE${NC}"
        else
            echo -e "${YELLOW}! CHECK CONFIG${NC}"
        fi
        ;;
    *) echo -e "${YELLOW}! MANUAL${NC}" ;;
esac

# Check DNS
echo -n "  Private DNS (Quad9): "
if resolvectl status 2>/dev/null | grep -q "9.9.9.9" || grep -q "9.9.9.9" /etc/resolv.conf 2>/dev/null; then
    echo -e "${GREEN}✓ CONFIGURED${NC}"
else
    echo -e "${YELLOW}! CHECK CONFIG${NC}"
fi

# Check sysctl
echo -n "  Kernel hardening: "
if [[ -f /etc/sysctl.d/99-freedom-hardened.conf ]]; then
    echo -e "${GREEN}✓ APPLIED${NC}"
else
    echo -e "${RED}✗ MISSING${NC}"
fi

# Check tools
echo -n "  KeePassXC: "
command -v keepassxc &>/dev/null && echo -e "${GREEN}✓ INSTALLED${NC}" || echo -e "${RED}✗${NC}"

echo -n "  WireGuard: "
command -v wg &>/dev/null && echo -e "${GREEN}✓ INSTALLED${NC}" || echo -e "${YELLOW}! MISSING${NC}"

echo -n "  Flatpak: "
command -v flatpak &>/dev/null && echo -e "${GREEN}✓ INSTALLED${NC}" || echo -e "${RED}✗${NC}"

echo ""
echo -e "${GREEN}━━━ Phase 1 Complete! ━━━${NC}"
echo ""
echo "Next steps:"
echo "  Phase 2: Configure your browsers for privacy"
echo "  Phase 3: Install FOSS apps to replace proprietary software"
echo "  Phase 4: Deploy your VPS (your private cloud)"
echo "  Phase 5: Connect everything together"
echo ""
echo -e "${GREEN}Your machine is now hardened. ✊${NC}"
