#!/usr/bin/env bash
# ============================================================================
# Freedom Stack — Browser Privacy Setup (Phase 2)
# Installs and configures privacy-focused browsers
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
    case "$PKG" in
        apt) sudo apt install -y "$@" ;;
        dnf) sudo dnf install -y "$@" ;;
        pacman) sudo pacman -S --noconfirm "$@" ;;
        *) warn "Install manually: $*" ;;
    esac
}

echo -e "${CYAN}"
echo "╔══════════════════════════════════════════════════╗"
echo "║   🌐 FREEDOM STACK — Browser Privacy Setup       ║"
echo "║   Phase 2: Secure your browsing                  ║"
echo "╚══════════════════════════════════════════════════╝"
echo -e "${NC}"

detect_distro

# ============================================================================
step "1/4 — Install Tor Browser"
# ============================================================================

if command -v flatpak &>/dev/null; then
    info "Installing Tor Browser via Flatpak..."
    flatpak install -y flathub com.github.nickvergessen.TorBrowser 2>/dev/null || {
        info "Flatpak method failed, trying torbrowser-launcher..."
        pkg_install torbrowser-launcher 2>/dev/null || warn "Install Tor Browser manually: https://www.torproject.org/download/"
    }
else
    pkg_install torbrowser-launcher 2>/dev/null || warn "Install Tor Browser manually: https://www.torproject.org/download/"
fi
log "Tor Browser ready"

# ============================================================================
step "2/4 — Harden Firefox"
# ============================================================================

# Ensure Firefox is installed
command -v firefox &>/dev/null || pkg_install firefox

# Find Firefox profile directory
FF_PROFILE_DIR=""
if [[ -d "$HOME/.mozilla/firefox" ]]; then
    FF_PROFILE_DIR=$(find "$HOME/.mozilla/firefox" -maxdepth 1 -name "*.default-release" -type d 2>/dev/null | head -1)
    [[ -z "$FF_PROFILE_DIR" ]] && FF_PROFILE_DIR=$(find "$HOME/.mozilla/firefox" -maxdepth 1 -name "*.default" -type d 2>/dev/null | head -1)
fi

if [[ -z "$FF_PROFILE_DIR" ]]; then
    info "Firefox profile not found. Creating one..."
    firefox --headless &
    sleep 3
    kill %1 2>/dev/null || true
    FF_PROFILE_DIR=$(find "$HOME/.mozilla/firefox" -maxdepth 1 -name "*.default-release" -type d 2>/dev/null | head -1)
fi

if [[ -n "$FF_PROFILE_DIR" ]]; then
    info "Hardening Firefox profile: $FF_PROFILE_DIR"

    cat > "$FF_PROFILE_DIR/user.js" << 'EOF'
// ================================================================
// Freedom Stack — Firefox Hardened user.js
// ================================================================

// --- Telemetry OFF ---
user_pref("toolkit.telemetry.enabled", false);
user_pref("toolkit.telemetry.unified", false);
user_pref("toolkit.telemetry.archive.enabled", false);
user_pref("browser.newtabpage.activity-stream.feeds.telemetry", false);
user_pref("browser.ping-centre.telemetry", false);
user_pref("datareporting.healthreport.uploadEnabled", false);
user_pref("datareporting.policy.dataSubmissionEnabled", false);
user_pref("app.shield.optoutstudies.enabled", false);
user_pref("breakpadreporter@mozilla.com", false);

// --- Tracking Protection ---
user_pref("privacy.trackingprotection.enabled", true);
user_pref("privacy.trackingprotection.socialtracking.enabled", true);
user_pref("privacy.trackingprotection.cryptomining.enabled", true);
user_pref("privacy.trackingprotection.fingerprinting.enabled", true);
user_pref("network.cookie.cookieBehavior", 5);
user_pref("privacy.firstparty.isolate", true);

// --- Disable WebRTC IP leak ---
user_pref("media.peerconnection.enabled", false);
user_pref("media.peerconnection.ice.default_address_only", true);
user_pref("media.peerconnection.ice.no_host", true);

// --- DNS-over-HTTPS (Quad9) ---
user_pref("network.trr.mode", 3);
user_pref("network.trr.uri", "https://dns.quad9.net/dns-query");

// --- Anti-Fingerprinting ---
user_pref("privacy.resistFingerprinting", true);
user_pref("webgl.disabled", true);
user_pref("dom.battery.enabled", false);
user_pref("geo.enabled", false);
user_pref("media.navigator.enabled", false);
user_pref("dom.webaudio.enabled", false);

// --- Disable dangerous features ---
user_pref("dom.allow_scripts_to_close_windows", false);
user_pref("dom.disable_open_during_load", true);
user_pref("dom.event.clipboardevents.enabled", false);
user_pref("dom.popup_allowed_events", "click dblclick mousedown pointerdown");

// --- Search / New Tab ---
user_pref("browser.newtabpage.enabled", false);
user_pref("browser.startup.homepage", "about:blank");
user_pref("browser.search.suggest.enabled", false);
user_pref("browser.urlbar.suggest.searches", false);
user_pref("browser.urlbar.speculativeConnect.enabled", false);

// --- Downloads ---
user_pref("browser.download.useDownloadDir", false);
user_pref("browser.download.manager.addToRecentDocs", false);

// --- HTTPS-Only Mode ---
user_pref("dom.security.https_only_mode", true);
user_pref("dom.security.https_only_mode_ever_enabled", true);

// --- Misc Privacy ---
user_pref("browser.contentblocking.category", "strict");
user_pref("network.http.sendRefererHeader", 0);
user_pref("network.http.referer.XOriginPolicy", 2);
user_pref("browser.sessionstore.privacy_level", 2);
user_pref("network.IDN_show_punycode", true);
EOF

    log "Firefox hardened (user.js applied)"
    info "Restart Firefox for changes to take effect"
else
    warn "Could not find Firefox profile — harden manually via about:config"
fi

# ============================================================================
step "3/4 — Install Brave Browser"
# ============================================================================

if [[ "$PKG" == "apt" ]]; then
    if ! command -v brave-browser &>/dev/null; then
        sudo curl -fsSLo /usr/share/keyrings/brave-browser-archive-keyring.gpg \
            https://brave-browser-apt-release.s3.brave.com/brave-browser-archive-keyring.gpg
        echo "deb [signed-by=/usr/share/keyrings/brave-browser-archive-keyring.gpg] \
            https://brave-browser-apt-release.s3.brave.com/ stable main" | \
            sudo tee /etc/apt/sources.list.d/brave-browser-release.list
        sudo apt update && sudo apt install -y brave-browser
        log "Brave Browser installed"
    else
        log "Brave Browser already installed"
    fi
elif [[ "$PKG" == "dnf" ]]; then
    sudo dnf install -y dnf-plugins-core
    sudo dnf config-manager --add-repo https://brave-browser-rpm-release.s3.brave.com/brave-browser.repo
    sudo rpm --import https://brave-browser-rpm-release.s3.brave.com/brave-core.asc
    sudo dnf install -y brave-browser
    log "Brave Browser installed"
elif [[ "$PKG" == "pacman" ]]; then
    warn "Brave: install from AUR (yay -S brave-bin)"
else
    warn "Brave: install manually from https://brave.com"
fi

# ============================================================================
step "4/4 — Summary"
# ============================================================================

echo ""
echo -e "${CYAN}━━━ Browsers Ready ━━━${NC}"
echo ""
echo -n "  Tor Browser: "
(command -v torbrowser-launcher &>/dev/null || flatpak list 2>/dev/null | grep -qi tor) && echo -e "${GREEN}✓${NC}" || echo -e "${YELLOW}! install manually${NC}"
echo -n "  Firefox (hardened): "
[[ -f "${FF_PROFILE_DIR:-}/user.js" ]] && echo -e "${GREEN}✓ user.js applied${NC}" || echo -e "${YELLOW}! check manually${NC}"
echo -n "  Brave: "
command -v brave-browser &>/dev/null && echo -e "${GREEN}✓${NC}" || echo -e "${YELLOW}! check manually${NC}"

echo ""
echo "Next: Install extensions manually in Firefox:"
echo "  1. uBlock Origin     — blocks ads & trackers"
echo "  2. NoScript           — blocks JavaScript by default"
echo "  3. Cookie AutoDelete  — auto-cleans cookies"
echo "  4. ClearURLs          — removes tracking from URLs"
echo "  5. CanvasBlocker      — prevents fingerprinting"
echo ""
echo "Change default search engine to DuckDuckGo or SearXNG"
echo ""
echo -e "${GREEN}Phase 2 complete! ✊${NC}"
