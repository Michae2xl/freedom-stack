#!/usr/bin/env bash
# ============================================================================
# Freedom Stack — FOSS Apps Installer (Phase 3)
# Replaces all proprietary software with open source alternatives
# ============================================================================
set -euo pipefail

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

log()  { echo -e "${GREEN}[✓]${NC} $1"; }
warn() { echo -e "${YELLOW}[!]${NC} $1"; }
info() { echo -e "${BLUE}[i]${NC} $1"; }
step() { echo -e "\n${CYAN}━━━ $1 ━━━${NC}\n"; }

INSTALLED=0
FAILED=0

detect_distro() {
    . /etc/os-release 2>/dev/null || true
    case "${ID:-}" in
        ubuntu|linuxmint|pop|elementary|zorin|debian) PKG="apt" ;;
        fedora) PKG="dnf" ;;
        arch|manjaro|endeavouros) PKG="pacman" ;;
        *) PKG="unknown" ;;
    esac
}

pkg_install() {
    local name="$1"
    shift
    case "$PKG" in
        apt) sudo apt install -y "$@" 2>/dev/null ;;
        dnf) sudo dnf install -y "$@" 2>/dev/null ;;
        pacman) sudo pacman -S --noconfirm "$@" 2>/dev/null ;;
        *) return 1 ;;
    esac
    if [[ $? -eq 0 ]]; then
        log "$name"
        ((INSTALLED++))
    else
        warn "$name — failed via package manager, try Flatpak"
        ((FAILED++))
    fi
}

flatpak_install() {
    local name="$1"
    local app_id="$2"
    if command -v flatpak &>/dev/null; then
        flatpak install -y flathub "$app_id" 2>/dev/null && {
            log "$name (Flatpak)"
            ((INSTALLED++))
            return 0
        }
    fi
    warn "$name — Flatpak install failed"
    ((FAILED++))
    return 1
}

# Parse arguments
INSTALL_ALL=false
INSTALL_OFFICE=false
INSTALL_MEDIA=false
INSTALL_COMM=false
INSTALL_DEV=false
INSTALL_SECURITY=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --all) INSTALL_ALL=true ;;
        --office) INSTALL_OFFICE=true ;;
        --media) INSTALL_MEDIA=true ;;
        --comm) INSTALL_COMM=true ;;
        --dev) INSTALL_DEV=true ;;
        --security) INSTALL_SECURITY=true ;;
        -h|--help)
            echo "Usage: bash foss-apps.sh [OPTIONS]"
            echo "  --all       Install everything"
            echo "  --office    Office & productivity (LibreOffice, Joplin)"
            echo "  --media     Media & creative (GIMP, VLC, Kdenlive, OBS)"
            echo "  --comm      Communication (Signal, Element, Thunderbird)"
            echo "  --dev       Development (VSCodium, Git)"
            echo "  --security  Security tools (KeePassXC, VeraCrypt)"
            exit 0
            ;;
        *) warn "Unknown option: $1" ;;
    esac
    shift
done

if ! $INSTALL_OFFICE && ! $INSTALL_MEDIA && ! $INSTALL_COMM && ! $INSTALL_DEV && ! $INSTALL_SECURITY; then
    INSTALL_ALL=true
fi

if $INSTALL_ALL; then
    INSTALL_OFFICE=true
    INSTALL_MEDIA=true
    INSTALL_COMM=true
    INSTALL_DEV=true
    INSTALL_SECURITY=true
fi

echo -e "${CYAN}"
echo "╔══════════════════════════════════════════════════╗"
echo "║   📦 FREEDOM STACK — FOSS Apps Installer         ║"
echo "║   Phase 3: Replace all proprietary software      ║"
echo "╚══════════════════════════════════════════════════╝"
echo -e "${NC}"

detect_distro

# Ensure Flatpak is ready
if ! command -v flatpak &>/dev/null; then
    info "Installing Flatpak..."
    case "$PKG" in
        apt) sudo apt install -y flatpak ;;
        dnf) sudo dnf install -y flatpak ;;
        pacman) sudo pacman -S --noconfirm flatpak ;;
    esac
    flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
fi

# ============================================================================
if $INSTALL_OFFICE; then
step "Office & Productivity (replaces Microsoft Office, Google Docs, Notion)"
# ============================================================================

pkg_install "LibreOffice (replaces MS Office)" libreoffice
flatpak_install "Joplin (replaces Notion/Evernote)" net.cozic.joplin_desktop
flatpak_install "Logseq (knowledge graph)" com.logseq.Logseq
fi

# ============================================================================
if $INSTALL_MEDIA; then
step "Media & Creative (replaces Photoshop, Premiere, Spotify)"
# ============================================================================

pkg_install "GIMP (replaces Photoshop)" gimp
pkg_install "Inkscape (replaces Illustrator)" inkscape
pkg_install "Kdenlive (replaces Premiere Pro)" kdenlive
pkg_install "Audacity (audio editor)" audacity
pkg_install "OBS Studio (screen recording/streaming)" obs-studio
pkg_install "VLC (plays everything)" vlc
pkg_install "Calibre (e-book manager)" calibre
flatpak_install "FreeTube (YouTube without Google)" io.freetubeapp.FreeTube
flatpak_install "Spotube (Spotify alternative)" com.github.KRTirtho.Spotube
fi

# ============================================================================
if $INSTALL_COMM; then
step "Communication (replaces WhatsApp, Zoom, Gmail)"
# ============================================================================

pkg_install "Thunderbird (email client)" thunderbird
flatpak_install "Signal (encrypted messaging)" org.signal.Signal
flatpak_install "Element (Matrix chat client)" im.riot.Riot
flatpak_install "Jami (P2P video calls)" net.jami.Jami
fi

# ============================================================================
if $INSTALL_DEV; then
step "Development (replaces VS Code, Postman)"
# ============================================================================

pkg_install "Git" git
pkg_install "curl" curl
pkg_install "wget" wget
flatpak_install "VSCodium (VS Code without telemetry)" com.vscodium.codium
flatpak_install "Bruno (API client, replaces Postman)" com.usebruno.Bruno
fi

# ============================================================================
if $INSTALL_SECURITY; then
step "Security & Privacy Tools"
# ============================================================================

pkg_install "KeePassXC (password manager)" keepassxc
pkg_install "WireGuard (VPN)" wireguard-tools

# VeraCrypt
if ! command -v veracrypt &>/dev/null; then
    if [[ "$PKG" == "apt" ]]; then
        info "Installing VeraCrypt..."
        sudo add-apt-repository ppa:unit193/encryption -y 2>/dev/null && \
        sudo apt update && sudo apt install -y veracrypt && \
        log "VeraCrypt (encrypted containers)" || warn "VeraCrypt — install manually: https://veracrypt.fr"
    else
        warn "VeraCrypt — install manually: https://veracrypt.fr"
    fi
else
    log "VeraCrypt already installed"
fi
fi

# ============================================================================
step "Summary"
# ============================================================================

echo ""
echo -e "${CYAN}━━━ Installation Results ━━━${NC}"
echo -e "  ${GREEN}Installed: ${INSTALLED}${NC}"
echo -e "  ${YELLOW}Issues: ${FAILED}${NC}"
echo ""

echo -e "${CYAN}What You Replaced:${NC}"
$INSTALL_OFFICE && echo "  Microsoft Office → LibreOffice"
$INSTALL_OFFICE && echo "  Notion/Evernote → Joplin"
$INSTALL_MEDIA && echo "  Photoshop → GIMP"
$INSTALL_MEDIA && echo "  Illustrator → Inkscape"
$INSTALL_MEDIA && echo "  Premiere Pro → Kdenlive"
$INSTALL_MEDIA && echo "  Spotify player → Spotube"
$INSTALL_MEDIA && echo "  YouTube → FreeTube"
$INSTALL_COMM && echo "  WhatsApp → Signal + Element"
$INSTALL_COMM && echo "  Zoom/Meet → Jami"
$INSTALL_COMM && echo "  Gmail client → Thunderbird"
$INSTALL_DEV && echo "  VS Code → VSCodium"
$INSTALL_DEV && echo "  Postman → Bruno"
$INSTALL_SECURITY && echo "  LastPass/1Password → KeePassXC"
echo ""

echo "📱 For your PHONE, install F-Droid: https://f-droid.org"
echo "   Then search for: NewPipe, Aegis, OpenBoard, OsmAnd+, Mull, Element"
echo ""
echo -e "${GREEN}Phase 3 complete! Your software is now libre. ✊${NC}"
