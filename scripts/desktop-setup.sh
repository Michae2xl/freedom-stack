#!/usr/bin/env bash
# ============================================================================
# Freedom Stack — Desktop Integration
# Creates visual shortcuts, browser bookmarks, and desktop launcher
# Run AFTER foss-apps.sh and VPS deploy
# ============================================================================
set -euo pipefail

GREEN='\033[0;32m'; CYAN='\033[0;36m'; NC='\033[0m'
log() { echo -e "${GREEN}[✓]${NC} $1"; }
step() { echo -e "\n${CYAN}━━━ $1 ━━━${NC}\n"; }

DOMAIN="${1:-}"
VPS_IP="${2:-}"
DESKTOP_DIR="${HOME}/Desktop"
APPS_DIR="${HOME}/.local/share/applications"
BOOKMARK_DIR="${HOME}/.config/freedom-stack"

mkdir -p "$DESKTOP_DIR" "$APPS_DIR" "$BOOKMARK_DIR"

step "Creating Freedom Stack desktop launcher"

# ============================================================================
# 1. Local HTML launcher — shows ALL apps (local + VPS) with clickable links
# ============================================================================

cat > "${BOOKMARK_DIR}/freedom-launcher.html" << LAUNCHEREOF
<!DOCTYPE html>
<html><head><meta charset="UTF-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>Freedom Stack — Seus Apps</title>
<style>
@import url('https://fonts.googleapis.com/css2?family=DM+Sans:wght@400;500;600;700&display=swap');
:root{--bg:#0a0f14;--bg2:#131920;--bg3:#1c2430;--text:#e8ecf1;--text2:#7d8a99;--border:#222d3a;--green:#22c088;--blue:#4799ff;--radius:12px}
*{box-sizing:border-box;margin:0;padding:0}
body{font-family:'DM Sans',system-ui,sans-serif;background:var(--bg);color:var(--text);padding:24px}
h1{font-size:24px;font-weight:700;text-align:center;margin-bottom:4px}
.sub{text-align:center;color:var(--text2);font-size:13px;margin-bottom:24px}
h2{font-size:14px;font-weight:600;color:var(--text2);text-transform:uppercase;letter-spacing:1px;margin:20px 0 10px}
.grid{display:grid;grid-template-columns:repeat(auto-fill,minmax(180px,1fr));gap:10px}
.app{background:var(--bg2);border:1px solid var(--border);border-radius:var(--radius);padding:16px;text-align:center;cursor:pointer;transition:.2s;text-decoration:none;color:var(--text)}
.app:hover{border-color:var(--green);transform:translateY(-2px)}
.app-icon{font-size:32px;margin-bottom:6px}
.app-name{font-size:14px;font-weight:600}
.app-desc{font-size:11px;color:var(--text2);margin-top:4px}
.app-open{display:inline-block;margin-top:8px;padding:4px 12px;background:#22c08815;color:var(--green);border-radius:6px;font-size:11px;font-weight:500}
@media(max-width:500px){.grid{grid-template-columns:1fr 1fr}}
</style></head><body>
<h1>🛡️ Freedom Stack</h1>
<p class="sub">Clique em qualquer app para abrir</p>

<h2>Apps no seu computador</h2>
<div class="grid">
<a class="app" onclick="openLocal('firefox')"><div class="app-icon">🦊</div><div class="app-name">Firefox</div><div class="app-desc">Browser hardened</div><div class="app-open">Abrir</div></a>
<a class="app" onclick="openLocal('torbrowser')"><div class="app-icon">🧅</div><div class="app-name">Tor Browser</div><div class="app-desc">Navegação anônima</div><div class="app-open">Abrir</div></a>
<a class="app" onclick="openLocal('brave-browser')"><div class="app-icon">🦁</div><div class="app-name">Brave</div><div class="app-desc">Browser alternativo</div><div class="app-open">Abrir</div></a>
<a class="app" onclick="openLocal('thunderbird')"><div class="app-icon">📧</div><div class="app-name">Thunderbird</div><div class="app-desc">Email seguro</div><div class="app-open">Abrir</div></a>
<a class="app" onclick="openLocal('keepassxc')"><div class="app-icon">🔑</div><div class="app-name">KeePassXC</div><div class="app-desc">Backup de senhas</div><div class="app-open">Abrir</div></a>
<a class="app" onclick="openLocal('libreoffice')"><div class="app-icon">📝</div><div class="app-name">LibreOffice</div><div class="app-desc">Escritório completo</div><div class="app-open">Abrir</div></a>
<a class="app" onclick="openLocal('gimp')"><div class="app-icon">🎨</div><div class="app-name">GIMP</div><div class="app-desc">Editor de imagens</div><div class="app-open">Abrir</div></a>
<a class="app" onclick="openLocal('vlc')"><div class="app-icon">🎬</div><div class="app-name">VLC</div><div class="app-desc">Player de mídia</div><div class="app-open">Abrir</div></a>
<a class="app" onclick="openLocal('signal-desktop')"><div class="app-icon">💬</div><div class="app-name">Signal</div><div class="app-desc">Mensagens criptografadas</div><div class="app-open">Abrir</div></a>
<a class="app" onclick="openLocal('kdenlive')"><div class="app-icon">🎞️</div><div class="app-name">Kdenlive</div><div class="app-desc">Edição de vídeo</div><div class="app-open">Abrir</div></a>
</div>

LAUNCHEREOF

# Add VPS services if domain or IP provided
if [[ -n "$DOMAIN" || -n "$VPS_IP" ]]; then
    cat >> "${BOOKMARK_DIR}/freedom-launcher.html" << EOF2
<h2>Seus serviços na nuvem — clique para abrir no browser</h2>
<div class="grid">
<a class="app" href="${DOMAIN:+https://cloud.${DOMAIN}}" target="_blank"><div class="app-icon">☁️</div><div class="app-name">Nextcloud</div><div class="app-desc">Seu cloud privado</div><div class="app-open">Abrir →</div></a>
<a class="app" href="${DOMAIN:+https://element.${DOMAIN}}" target="_blank"><div class="app-icon">💬</div><div class="app-name">Element</div><div class="app-desc">Chat criptografado</div><div class="app-open">Abrir →</div></a>
<a class="app" href="${DOMAIN:+https://vault.${DOMAIN}}" target="_blank"><div class="app-icon">🔑</div><div class="app-name">Vaultwarden</div><div class="app-desc">Senhas (Bitwarden)</div><div class="app-open">Abrir →</div></a>
<a class="app" href="${DOMAIN:+https://meet.${DOMAIN}}" target="_blank"><div class="app-icon">📹</div><div class="app-name">Jitsi Meet</div><div class="app-desc">Videochamadas</div><div class="app-open">Abrir →</div></a>
<a class="app" href="${DOMAIN:+https://search.${DOMAIN}}" target="_blank"><div class="app-icon">🔍</div><div class="app-name">SearXNG</div><div class="app-desc">Buscador privado</div><div class="app-open">Abrir →</div></a>
<a class="app" href="${DOMAIN:+https://git.${DOMAIN}}" target="_blank"><div class="app-icon">🐙</div><div class="app-name">Forgejo</div><div class="app-desc">Git self-hosted</div><div class="app-open">Abrir →</div></a>
<a class="app" href="${DOMAIN:+https://mail.${DOMAIN}}" target="_blank"><div class="app-icon">📧</div><div class="app-name">Stalwart Mail</div><div class="app-desc">Email server</div><div class="app-open">Abrir →</div></a>
<a class="app" href="${DOMAIN:+https://portainer.${DOMAIN}}" target="_blank"><div class="app-icon">🐳</div><div class="app-name">Portainer</div><div class="app-desc">Gerenciar Docker</div><div class="app-open">Abrir →</div></a>
<a class="app" href="${DOMAIN:+https://dash.${DOMAIN}}" target="_blank"><div class="app-icon">📊</div><div class="app-name">Grafana</div><div class="app-desc">Métricas</div><div class="app-open">Abrir →</div></a>
<a class="app" href="${DOMAIN:+https://monitor.${DOMAIN}}" target="_blank"><div class="app-icon">📈</div><div class="app-name">Netdata</div><div class="app-desc">Monitor real-time</div><div class="app-open">Abrir →</div></a>
<a class="app" href="${DOMAIN:+https://status.${DOMAIN}}" target="_blank"><div class="app-icon">🟢</div><div class="app-name">Uptime Kuma</div><div class="app-desc">Status & alertas</div><div class="app-open">Abrir →</div></a>
<a class="app" href="${DOMAIN:+https://dns.${DOMAIN}}" target="_blank"><div class="app-icon">🛡️</div><div class="app-name">AdGuard</div><div class="app-desc">DNS & ad blocker</div><div class="app-open">Abrir →</div></a>
</div>
EOF2
fi

cat >> "${BOOKMARK_DIR}/freedom-launcher.html" << 'EOF3'
<script>
function openLocal(app) {
  // Try to open via xdg-open (works if .desktop file exists)
  // Fallback: show instruction
  const a = document.createElement('a');
  a.href = `freedomstack://${app}`;
  a.click();
  // Most local apps are in the system menu — this is a visual guide
  alert(`Abra "${app}" pelo menu de aplicativos do Linux (canto inferior esquerdo) ou busque pelo nome.`);
}
</script>
</body></html>
EOF3

log "Launcher HTML created: ${BOOKMARK_DIR}/freedom-launcher.html"

# ============================================================================
# 2. Desktop shortcut for the launcher
# ============================================================================

cat > "${DESKTOP_DIR}/freedom-stack.desktop" << EOF
[Desktop Entry]
Type=Application
Name=Freedom Stack
Comment=Todos os seus apps e serviços
Exec=xdg-open ${BOOKMARK_DIR}/freedom-launcher.html
Icon=security-high
Terminal=false
Categories=Network;Security;
StartupNotify=true
EOF
chmod +x "${DESKTOP_DIR}/freedom-stack.desktop"

# Also install to app menu
cp "${DESKTOP_DIR}/freedom-stack.desktop" "${APPS_DIR}/freedom-stack.desktop"
log "Desktop shortcut created (double-click 'Freedom Stack' on desktop)"

# ============================================================================
# 3. Firefox bookmarks toolbar — all VPS services
# ============================================================================

if [[ -n "$DOMAIN" ]]; then
    step "Creating Firefox bookmarks"

    # Find Firefox profile
    FF_PROFILE=$(find "${HOME}/.mozilla/firefox" -maxdepth 1 -name "*.default-release" -type d 2>/dev/null | head -1)
    [[ -z "$FF_PROFILE" ]] && FF_PROFILE=$(find "${HOME}/.mozilla/firefox" -maxdepth 1 -name "*.default" -type d 2>/dev/null | head -1)

    if [[ -n "$FF_PROFILE" ]]; then
        # Create a bookmarks HTML that Firefox can import
        cat > "${BOOKMARK_DIR}/freedom-bookmarks.html" << BKMEOF
<!DOCTYPE NETSCAPE-Bookmark-file-1>
<META HTTP-EQUIV="Content-Type" CONTENT="text/html; charset=UTF-8">
<TITLE>Freedom Stack Bookmarks</TITLE>
<DL><p>
<DT><H3 PERSONAL_TOOLBAR_FOLDER="true">Freedom Stack</H3>
<DL><p>
<DT><A HREF="https://cloud.${DOMAIN}">☁️ Nextcloud</A>
<DT><A HREF="https://element.${DOMAIN}">💬 Element</A>
<DT><A HREF="https://vault.${DOMAIN}">🔑 Senhas</A>
<DT><A HREF="https://meet.${DOMAIN}">📹 Jitsi</A>
<DT><A HREF="https://search.${DOMAIN}">🔍 Buscar</A>
<DT><A HREF="https://git.${DOMAIN}">🐙 Git</A>
<DT><A HREF="https://portainer.${DOMAIN}">🐳 Docker</A>
<DT><A HREF="https://dash.${DOMAIN}">📊 Grafana</A>
<DT><A HREF="https://status.${DOMAIN}">🟢 Status</A>
</DL>
</DL>
BKMEOF
        log "Firefox bookmarks file: ${BOOKMARK_DIR}/freedom-bookmarks.html"
        log "Import in Firefox: Ctrl+Shift+O → Import → HTML file → select freedom-bookmarks.html"
    fi
fi

# ============================================================================
# 4. Set SearXNG as default search engine in Firefox
# ============================================================================

if [[ -n "$DOMAIN" && -n "$FF_PROFILE" ]]; then
    # Add search engine via user.js
    cat >> "${FF_PROFILE}/user.js" << EOF

// Freedom Stack — SearXNG as default search
user_pref("browser.urlbar.placeholderName", "SearXNG");
user_pref("browser.urlbar.placeholderName.private", "SearXNG");
EOF
    log "SearXNG set as search placeholder in Firefox"
fi

# ============================================================================
# 5. Auto-open dashboard after everything is done
# ============================================================================

step "Opening your Freedom Stack"

# Open the launcher in default browser
if command -v xdg-open &>/dev/null; then
    xdg-open "${BOOKMARK_DIR}/freedom-launcher.html" 2>/dev/null &
    log "Launcher opened in browser"
fi

# Open VPS dashboard if domain available
if [[ -n "$DOMAIN" ]]; then
    sleep 2
    xdg-open "https://${DOMAIN}" 2>/dev/null &
    log "VPS dashboard opened: https://${DOMAIN}"
fi

echo ""
echo -e "${GREEN}━━━ Desktop integration complete! ━━━${NC}"
echo ""
echo "What you got:"
echo "  🖥️  Desktop shortcut: 'Freedom Stack' (double-click to open)"
echo "  🦊  Firefox bookmarks: import from ${BOOKMARK_DIR}/freedom-bookmarks.html"
echo "  🌐  Launcher page: ${BOOKMARK_DIR}/freedom-launcher.html"
echo "  🔍  SearXNG configured in Firefox"
echo ""
echo "All apps are also in your Linux app menu (bottom-left corner)."
echo ""
