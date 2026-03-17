#!/usr/bin/env bash
# ============================================================================
# Freedom Stack — Dashboard Generator
# Creates a visual control panel at your-domain.com (or VPS_IP:80)
# Shows live status of all services with clickable links
# ============================================================================
set -uo pipefail

DOMAIN="${1:-}"
BASE_DIR="/opt/freedom-stack"
CREDS_FILE="/root/freedom-stack-credentials.txt"
DASH_FILE="${BASE_DIR}/caddy/dashboard.html"

IP=$(curl -s4 ifconfig.me 2>/dev/null || echo "localhost")
SSH_PORT=$(grep "^Port " /etc/ssh/sshd_config 2>/dev/null | awk '{print $2}')
SSH_PORT="${SSH_PORT:-2222}"

# Collect .onion addresses
declare -A ONIONS
for svc in nextcloud matrix element vaultwarden jitsi searxng forgejo mail; do
    for base in "${BASE_DIR}/tor/data" "$(docker volume inspect freedom-stack_tor_data --format '{{.Mountpoint}}' 2>/dev/null || echo '')"; do
        f="${base}/${svc}_hs/hostname"
        [[ -f "$f" ]] && ONIONS[$svc]=$(cat "$f") && break
    done
done

# Check which containers are running
running_containers=$(docker ps --format '{{.Names}}' 2>/dev/null)

is_running() {
    echo "$running_containers" | grep -q "freedom-${1}" && echo "true" || echo "false"
}

# Generate service cards JSON
services_json="["
add_svc() {
    local name="$1" icon="$2" url="$3" desc="$4" status="$5" onion="${6:-}" cat="${7:-app}"
    [[ "$services_json" != "[" ]] && services_json+=","
    services_json+="{\"name\":\"${name}\",\"icon\":\"${icon}\",\"url\":\"${url}\",\"desc\":\"${desc}\",\"status\":${status},\"onion\":\"${onion}\",\"cat\":\"${cat}\"}"
}

# Apps
docker ps --format '{{.Names}}' | grep -q freedom-nextcloud && \
    add_svc "Nextcloud" "☁️" "${DOMAIN:+https://cloud.${DOMAIN}}" "Seu cloud privado — arquivos, docs, calendário" "$(is_running nextcloud)" "${ONIONS[nextcloud]:-}"
docker ps --format '{{.Names}}' | grep -q freedom-element && \
    add_svc "Element" "💬" "${DOMAIN:+https://element.${DOMAIN}}" "Chat criptografado (Matrix)" "$(is_running element)" "${ONIONS[element]:-}"
docker ps --format '{{.Names}}' | grep -q freedom-vaultwarden && \
    add_svc "Vaultwarden" "🔑" "${DOMAIN:+https://vault.${DOMAIN}}" "Gerenciador de senhas (Bitwarden)" "$(is_running vaultwarden)" "${ONIONS[vaultwarden]:-}"
docker ps --format '{{.Names}}' | grep -q freedom-jitsi-web && \
    add_svc "Jitsi Meet" "📹" "${DOMAIN:+https://meet.${DOMAIN}}" "Videochamadas sem conta" "$(is_running jitsi-web)" "${ONIONS[jitsi]:-}"
docker ps --format '{{.Names}}' | grep -q freedom-searxng && \
    add_svc "SearXNG" "🔍" "${DOMAIN:+https://search.${DOMAIN}}" "Buscador privado" "$(is_running searxng)" "${ONIONS[searxng]:-}"
docker ps --format '{{.Names}}' | grep -q freedom-forgejo && \
    add_svc "Forgejo" "🐙" "${DOMAIN:+https://git.${DOMAIN}}" "Git self-hosted" "$(is_running forgejo)" "${ONIONS[forgejo]:-}"
docker ps --format '{{.Names}}' | grep -q freedom-stalwart && \
    add_svc "Stalwart Mail" "📧" "${DOMAIN:+https://mail.${DOMAIN}}" "Email server" "$(is_running stalwart)" "${ONIONS[mail]:-}"

# Protection
docker ps --format '{{.Names}}' | grep -q freedom-adguard && \
    add_svc "AdGuard Home" "🛡️" "${DOMAIN:+https://dns.${DOMAIN}}" "DNS privado + bloqueio de ads" "$(is_running adguard)" "" "protect"
add_svc "WireGuard VPN" "🔒" "" "VPN pessoal — configurar no app" "$(is_running wireguard)" "" "protect"
docker ps --format '{{.Names}}' | grep -q freedom-tor && \
    add_svc "Tor" "🧅" "" "Serviços .onion ativos" "$(is_running tor)" "" "protect"

# Monitoring
docker ps --format '{{.Names}}' | grep -q freedom-grafana && \
    add_svc "Grafana" "📊" "${DOMAIN:+https://dash.${DOMAIN}}" "Métricas e dashboards" "$(is_running grafana)" "" "monitor"
docker ps --format '{{.Names}}' | grep -q freedom-netdata && \
    add_svc "Netdata" "📈" "${DOMAIN:+https://monitor.${DOMAIN}}" "Monitoramento real-time" "$(is_running netdata)" "" "monitor"
docker ps --format '{{.Names}}' | grep -q freedom-uptime-kuma && \
    add_svc "Uptime Kuma" "🟢" "${DOMAIN:+https://status.${DOMAIN}}" "Status e alertas" "$(is_running uptime-kuma)" "" "monitor"
docker ps --format '{{.Names}}' | grep -q freedom-portainer && \
    add_svc "Portainer" "🐳" "${DOMAIN:+https://portainer.${DOMAIN}}" "Gerenciar Docker pelo browser" "$(is_running portainer)" "" "monitor"

services_json+="]"

# Container count
total=$(docker ps --format '{{.Names}}' | grep -c "freedom-" || echo 0)
healthy=$(docker ps --format '{{.Names}} {{.Status}}' | grep "freedom-" | grep -c "healthy" || echo 0)

cat > "$DASH_FILE" << 'HTMLEOF'
<!DOCTYPE html>
<html lang="pt-BR">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>Freedom Stack — Painel de Controle</title>
<style>
@import url('https://fonts.googleapis.com/css2?family=DM+Sans:wght@400;500;600;700&display=swap');
:root{--bg:#0a0f14;--bg2:#131920;--bg3:#1c2430;--text:#e8ecf1;--text2:#7d8a99;--text3:#4a5568;--border:#222d3a;--green:#22c088;--green-bg:#22c08815;--blue:#4799ff;--red:#ff5555;--amber:#f0b429;--radius:12px}
*{box-sizing:border-box;margin:0;padding:0}
body{font-family:'DM Sans',system-ui,sans-serif;background:var(--bg);color:var(--text);min-height:100vh}
.wrap{max-width:780px;margin:0 auto;padding:20px 16px 60px}
.hero{text-align:center;padding:32px 0 24px}
.hero-icon{font-size:48px;margin-bottom:8px}
.hero h1{font-size:28px;font-weight:700;letter-spacing:-1px}
.hero p{color:var(--text2);font-size:14px;margin-top:4px}
.stats{display:flex;gap:8px;margin:20px 0;flex-wrap:wrap}
.stat{flex:1;min-width:80px;background:var(--bg2);border:1px solid var(--border);border-radius:var(--radius);padding:14px 10px;text-align:center}
.stat-n{font-size:28px;font-weight:700}
.stat-n.green{color:var(--green)}
.stat-n.amber{color:var(--amber)}
.stat-l{font-size:11px;color:var(--text2);margin-top:2px}
.section{margin:24px 0 12px;font-size:13px;font-weight:600;color:var(--text2);text-transform:uppercase;letter-spacing:1px}
.grid{display:grid;grid-template-columns:repeat(auto-fill,minmax(220px,1fr));gap:10px}
.svc{background:var(--bg2);border:1px solid var(--border);border-radius:var(--radius);padding:16px;transition:.2s;position:relative;overflow:hidden}
.svc:hover{border-color:var(--green);transform:translateY(-2px)}
.svc-head{display:flex;align-items:center;gap:10px;margin-bottom:8px}
.svc-icon{font-size:24px}
.svc-name{font-size:15px;font-weight:600;flex:1}
.svc-status{width:10px;height:10px;border-radius:50%;flex-shrink:0}
.svc-status.up{background:var(--green);box-shadow:0 0 8px var(--green)}
.svc-status.down{background:var(--red);box-shadow:0 0 8px var(--red)}
.svc-desc{font-size:12px;color:var(--text2);line-height:1.5;margin-bottom:10px}
.svc-links{display:flex;gap:6px;flex-wrap:wrap}
.svc-link{display:inline-block;padding:4px 10px;border-radius:6px;font-size:11px;font-weight:500;text-decoration:none;transition:.15s}
.svc-link.web{background:var(--green-bg);color:var(--green);border:1px solid #22c08830}
.svc-link.web:hover{background:#22c08825}
.svc-link.onion{background:#9333ea15;color:#a855f7;border:1px solid #9333ea30}
.svc-link.onion:hover{background:#9333ea25}
.info-box{background:var(--bg2);border:1px solid var(--border);border-radius:var(--radius);padding:16px;margin-top:20px}
.info-title{font-size:14px;font-weight:600;margin-bottom:8px}
.info-row{display:flex;justify-content:space-between;padding:4px 0;font-size:13px;color:var(--text2);border-bottom:1px solid var(--border)}
.info-row:last-child{border:none}
.info-row span:last-child{color:var(--text);font-family:'DM Mono',monospace;font-size:12px}
.refresh{text-align:center;margin-top:20px}
.refresh-btn{background:var(--bg3);border:1px solid var(--border);color:var(--text2);padding:8px 20px;border-radius:8px;cursor:pointer;font-family:'DM Sans',sans-serif;font-size:13px}
.footer{text-align:center;margin-top:32px;font-size:12px;color:var(--text3)}
@media(max-width:500px){.grid{grid-template-columns:1fr}.hero h1{font-size:22px}}
</style>
</head>
<body>
<div class="wrap">
  <div class="hero">
    <div class="hero-icon">🛡️</div>
    <h1>Freedom Stack</h1>
    <p>Painel de controle — clique em qualquer serviço para abrir</p>
  </div>

  <div class="stats">
    <div class="stat"><div class="stat-n green" id="st-up">—</div><div class="stat-l">Serviços ativos</div></div>
    <div class="stat"><div class="stat-n" id="st-total">—</div><div class="stat-l">Containers</div></div>
    <div class="stat"><div class="stat-n green" id="st-healthy">—</div><div class="stat-l">Healthy</div></div>
    <div class="stat"><div class="stat-n" id="st-onion">—</div><div class="stat-l">.onion ativos</div></div>
  </div>

  <div class="section">Seus serviços — clique para abrir</div>
  <div class="grid" id="grid-app"></div>

  <div class="section">Proteção</div>
  <div class="grid" id="grid-protect"></div>

  <div class="section">Monitoramento & gestão</div>
  <div class="grid" id="grid-monitor"></div>

  <div class="info-box">
    <div class="info-title">Informações do servidor</div>
    <div class="info-row"><span>IP</span><span id="info-ip">—</span></div>
    <div class="info-row"><span>SSH</span><span id="info-ssh">—</span></div>
    <div class="info-row"><span>Domínio</span><span id="info-domain">—</span></div>
    <div class="info-row"><span>Backup</span><span>Diário 3AM (criptografado)</span></div>
    <div class="info-row"><span>Auto-update</span><span>Watchtower — segunda 4AM</span></div>
  </div>

  <div class="refresh">
    <button class="refresh-btn" onclick="location.reload()">🔄 Atualizar status</button>
  </div>
  <div class="footer">Freedom Stack v3.0 — Soberania digital</div>
</div>

<script>
HTMLEOF

# Inject dynamic data
cat >> "$DASH_FILE" << EOF
const SERVICES=${services_json};
const SERVER={ip:"${IP}",domain:"${DOMAIN}",sshPort:"${SSH_PORT}",total:${total},healthy:${healthy}};
EOF

cat >> "$DASH_FILE" << 'HTMLEOF2'
function renderCards(containerId, services) {
  const grid = document.getElementById(containerId);
  if (!grid) return;
  grid.innerHTML = services.map(s => {
    const links = [];
    if (s.url) links.push(`<a href="${s.url}" target="_blank" class="svc-link web">Abrir →</a>`);
    if (s.onion) links.push(`<a href="http://${s.onion}" target="_blank" class="svc-link onion">🧅 .onion</a>`);
    return `<div class="svc">
      <div class="svc-head">
        <span class="svc-icon">${s.icon}</span>
        <span class="svc-name">${s.name}</span>
        <span class="svc-status ${s.status ? 'up' : 'down'}"></span>
      </div>
      <div class="svc-desc">${s.desc}</div>
      <div class="svc-links">${links.join('')}</div>
    </div>`;
  }).join('');
}

const apps = SERVICES.filter(s => s.cat === 'app');
const protect = SERVICES.filter(s => s.cat === 'protect');
const monitor = SERVICES.filter(s => s.cat === 'monitor');

renderCards('grid-app', apps);
renderCards('grid-protect', protect);
renderCards('grid-monitor', monitor);

const up = SERVICES.filter(s => s.status).length;
const onions = SERVICES.filter(s => s.onion).length;
document.getElementById('st-up').textContent = up;
document.getElementById('st-total').textContent = SERVER.total;
document.getElementById('st-healthy').textContent = SERVER.healthy;
document.getElementById('st-onion').textContent = onions;
document.getElementById('info-ip').textContent = SERVER.ip;
document.getElementById('info-ssh').textContent = `ssh -p ${SERVER.sshPort} root@${SERVER.ip}`;
document.getElementById('info-domain').textContent = SERVER.domain || '(sem domínio — use .onion)';
</script>
</body>
</html>
HTMLEOF2

echo "Dashboard generated: ${DASH_FILE}"

# Add dashboard route to Caddyfile if domain exists
if [[ -n "$DOMAIN" ]]; then
    if ! grep -q "${DOMAIN} {" "${BASE_DIR}/caddy/Caddyfile" 2>/dev/null; then
        echo "${DOMAIN} { root * /srv file_server }" >> "${BASE_DIR}/caddy/Caddyfile"
    fi
    # Copy dashboard to Caddy serve directory
    mkdir -p "${BASE_DIR}/caddy/srv"
    cp "$DASH_FILE" "${BASE_DIR}/caddy/srv/index.html"
fi

echo "✓ Dashboard ready"
echo "  Access: ${DOMAIN:+https://${DOMAIN}} or open ${DASH_FILE} in browser"
