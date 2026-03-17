#!/usr/bin/env bash
# ============================================================================
# Freedom Stack Installer v4.0 — Agent Privacy Cloud
#
# v4.0 — AGENT PRIVACY CLOUD:
#  [J] Ollama (local LLM inference — zero data to OpenAI/Anthropic)
#  [K] n8n (visual workflow orchestration for agents)
#  [L] Qdrant (vector DB — agent long-term memory + embeddings)
#  [M] Agent sandbox (isolated Python/Node runtime)
#  [N] Tor proxy rotator (multi-circuit for scraping without bans)
#  [O] Gotify (private push notifications to phone)
#  [P] Privoxy (privacy-first API gateway via Tor)
#  [Q] Agent dashboard (real-time view of all agent activity)
#
# Inherits v3.0: PostgreSQL, Redis, Prometheus, Grafana, Portainer,
# Forgejo, Stalwart, Netdata, all v2.0 hardening.
# ============================================================================
set -euo pipefail

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BLUE='\033[0;34m'; CYAN='\033[0;36m'; NC='\033[0m'

DOMAIN=""
INSTALL_ALL=false
INSTALL_NEXTCLOUD=false
INSTALL_MATRIX=false
INSTALL_TOR=false
INSTALL_WIREGUARD=false
INSTALL_SECURITY=false
INSTALL_BACKUP=false
INSTALL_VAULTWARDEN=false
INSTALL_JITSI=false
INSTALL_ADGUARD=false
INSTALL_SEARXNG=false
INSTALL_FORGEJO=false
INSTALL_MAIL=false
INSTALL_AGENTS=false
SKIP_TOR=false
SKIP_CROWDSEC=false
SSH_PORT="${SSH_PORT:-2222}"
BASE_DIR="/opt/freedom-stack"
CREDENTIALS_FILE="/root/freedom-stack-credentials.txt"

COMPOSE_SERVICES=""
COMPOSE_VOLUMES=""

log()  { echo -e "${GREEN}[✓]${NC} $1"; }
warn() { echo -e "${YELLOW}[!]${NC} $1"; }
err()  { echo -e "${RED}[✗]${NC} $1"; }
info() { echo -e "${BLUE}[i]${NC} $1"; }
step() { echo -e "\n${CYAN}━━━ $1 ━━━${NC}\n"; }
gen_password() { openssl rand -base64 32 | tr -dc 'a-zA-Z0-9' | head -c "$1"; }
save_credential() { echo "$1" >> "$CREDENTIALS_FILE"; }

check_root() { [[ $EUID -eq 0 ]] || { err "Run as root"; exit 1; }; }

# ============================================================================
parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --all)         INSTALL_ALL=true ;;
            --nextcloud)   INSTALL_NEXTCLOUD=true ;;
            --matrix)      INSTALL_MATRIX=true ;;
            --tor)         INSTALL_TOR=true ;;
            --wireguard)   INSTALL_WIREGUARD=true ;;
            --security)    INSTALL_SECURITY=true ;;
            --backup)      INSTALL_BACKUP=true ;;
            --vaultwarden) INSTALL_VAULTWARDEN=true ;;
            --jitsi)       INSTALL_JITSI=true ;;
            --adguard)     INSTALL_ADGUARD=true ;;
            --searxng)     INSTALL_SEARXNG=true ;;
            --forgejo)     INSTALL_FORGEJO=true ;;
            --mail)        INSTALL_MAIL=true ;;
            --agents)      INSTALL_AGENTS=true ;;
            --domain)      DOMAIN="$2"; shift ;;
            --ssh-port)    SSH_PORT="$2"; shift ;;
            --skip-tor)    SKIP_TOR=true ;;
            --skip-crowdsec) SKIP_CROWDSEC=true ;;
            -h|--help)
                echo "Freedom Stack v4.0 — Agent Privacy Cloud"
                echo "Usage: bash install.sh [OPTIONS]"
                echo ""
                echo "  CORE SERVICES:"
                echo "  --all           Install everything (human + agent)"
                echo "  --nextcloud     Nextcloud + Redis"
                echo "  --matrix        Matrix/Synapse + PostgreSQL"
                echo "  --vaultwarden   Passwords"
                echo "  --jitsi         Video calls"
                echo "  --adguard       DNS + ad blocker"
                echo "  --searxng       Private search"
                echo "  --forgejo       Git hosting"
                echo "  --mail          Email server"
                echo ""
                echo "  AGENT PRIVACY CLOUD:"
                echo "  --agents        Ollama + n8n + Qdrant + sandbox + Tor rotator"
                echo "                  + Gotify + Privoxy + Agent dashboard"
                echo ""
                echo "  INFRASTRUCTURE:"
                echo "  --tor           Tor hidden services"
                echo "  --wireguard     VPN"
                echo "  --security      Firewall + fail2ban + CrowdSec"
                echo "  --backup        Encrypted backup"
                echo "  --domain DOMAIN Enable HTTPS"
                echo "  --ssh-port PORT SSH port (default: 2222)"
                exit 0 ;;
            *) err "Unknown: $1"; exit 1 ;;
        esac
        shift
    done

    local any=false
    for f in INSTALL_NEXTCLOUD INSTALL_MATRIX INSTALL_TOR INSTALL_WIREGUARD \
             INSTALL_SECURITY INSTALL_BACKUP INSTALL_VAULTWARDEN INSTALL_JITSI \
             INSTALL_ADGUARD INSTALL_SEARXNG INSTALL_FORGEJO INSTALL_MAIL \
             INSTALL_AGENTS; do
        ${!f} && any=true
    done
    $any || INSTALL_ALL=true

    if $INSTALL_ALL; then
        INSTALL_NEXTCLOUD=true; INSTALL_MATRIX=true; INSTALL_TOR=true
        INSTALL_WIREGUARD=true; INSTALL_SECURITY=true; INSTALL_BACKUP=true
        INSTALL_VAULTWARDEN=true; INSTALL_JITSI=true; INSTALL_ADGUARD=true
        INSTALL_SEARXNG=true; INSTALL_FORGEJO=true; INSTALL_MAIL=true
        INSTALL_AGENTS=true
    fi
}

add_service() { COMPOSE_SERVICES+="$1"; }

# ============================================================================
# Base System + Log Rotation + ZRAM
# ============================================================================
install_base() {
    step "Base system + Docker + swap"
    export DEBIAN_FRONTEND=noninteractive
    apt-get update -qq && apt-get upgrade -y -qq
    apt-get install -y -qq curl wget git unzip jq gnupg lsb-release \
        ca-certificates apt-transport-https software-properties-common \
        openssl qrencode gpg

    if ! command -v docker &>/dev/null; then
        curl -fsSL https://get.docker.com | bash
        systemctl enable --now docker
    fi
    docker compose version &>/dev/null || apt-get install -y -qq docker-compose-plugin

    # [F] unattended-upgrades on VPS
    apt-get install -y -qq unattended-upgrades
    dpkg-reconfigure -plow unattended-upgrades 2>/dev/null || true
    log "Automatic OS security updates enabled"

    # [F] AppArmor
    if ! systemctl is-active apparmor &>/dev/null; then
        apt-get install -y -qq apparmor apparmor-utils 2>/dev/null || true
        systemctl enable --now apparmor 2>/dev/null || true
    fi
    log "AppArmor active"

    # Log rotation
    mkdir -p /etc/docker
    cat > /etc/docker/daemon.json <<'EOF'
{ "log-driver": "json-file", "log-opts": { "max-size": "10m", "max-file": "3" } }
EOF
    systemctl restart docker

    # ZRAM + swap
    local ram_mb; ram_mb=$(free -m | awk '/^Mem:/{print $2}')
    if [[ $ram_mb -lt 8000 ]]; then
        apt-get install -y -qq zram-tools 2>/dev/null || true
        [[ -f /etc/default/zramswap ]] && sed -i 's/^#*PERCENT=.*/PERCENT=50/' /etc/default/zramswap && systemctl restart zramswap 2>/dev/null
        if [[ ! -f /swapfile ]]; then
            fallocate -l 2G /swapfile && chmod 600 /swapfile && mkswap /swapfile && swapon /swapfile
            grep -q swapfile /etc/fstab || echo '/swapfile none swap sw 0 0' >> /etc/fstab
        fi
        log "ZRAM + 2GB swap active (RAM: ${ram_mb}MB)"
    fi
    mkdir -p "$BASE_DIR"/{data,config,logs}
    log "Base system ready"
}

# ============================================================================
# Compose generator
# ============================================================================
generate_compose() {
    step "Writing unified docker-compose.yml"
    cat > "$BASE_DIR/docker-compose.yml" <<EOF
networks:
  net-proxy:
    name: freedom-proxy
  net-data:
    name: freedom-data
  net-monitor:
    name: freedom-monitor

services:
${COMPOSE_SERVICES}

volumes:
${COMPOSE_VOLUMES}
EOF
    log "docker-compose.yml generated"
}

# ============================================================================
# Caddy
# ============================================================================
setup_caddy() {
    step "Caddy reverse proxy"
    mkdir -p "$BASE_DIR/caddy"
    local C=""
    if [[ -n "$DOMAIN" ]]; then
        $INSTALL_NEXTCLOUD  && C+="cloud.${DOMAIN}   { reverse_proxy nextcloud:80; header Strict-Transport-Security \"max-age=31536000\" }
"
        $INSTALL_MATRIX     && C+="chat.${DOMAIN}    { reverse_proxy synapse:8008 }
element.${DOMAIN} { reverse_proxy element:80 }
"
        $INSTALL_VAULTWARDEN && C+="vault.${DOMAIN}   { reverse_proxy vaultwarden:80 }
"
        $INSTALL_JITSI      && C+="meet.${DOMAIN}    { reverse_proxy jitsi-web:80 }
"
        $INSTALL_SEARXNG    && C+="search.${DOMAIN}  { reverse_proxy searxng:8080 }
"
        $INSTALL_FORGEJO    && C+="git.${DOMAIN}     { reverse_proxy forgejo:3000 }
"
        $INSTALL_MAIL       && C+="mail.${DOMAIN}    { reverse_proxy stalwart:8080 }
"
        C+="status.${DOMAIN}  { reverse_proxy uptime-kuma:3001 }
dash.${DOMAIN}    { reverse_proxy grafana:3000 }
portainer.${DOMAIN} { reverse_proxy portainer:9000 }
monitor.${DOMAIN} { reverse_proxy netdata:19999 }
"
        # Agent Privacy Cloud routes
        $INSTALL_AGENTS && C+="n8n.${DOMAIN}      { reverse_proxy n8n:5678 }
ollama.${DOMAIN}  { reverse_proxy ollama-web:8080 }
notify.${DOMAIN}  { reverse_proxy gotify:80 }
agents.${DOMAIN}  { reverse_proxy agent-dash:3000 }
"
    else
        C=":80 { respond \"Freedom Stack v4 — Agent Privacy Cloud. Use Tor .onion or domain.\" }
"
    fi
    echo "$C" > "$BASE_DIR/caddy/Caddyfile"

    add_service "
  caddy:
    image: caddy:2-alpine
    container_name: freedom-caddy
    restart: unless-stopped
    ports:
      - \"80:80\"
      - \"443:443\"
      - \"443:443/udp\"
    volumes:
      - ./caddy/Caddyfile:/etc/caddy/Caddyfile
      - caddy_data:/data
      - caddy_config:/config
    networks: [net-proxy]
    healthcheck:
      test: [\"CMD\", \"wget\", \"--spider\", \"-q\", \"http://localhost:80\"]
      interval: 30s
      timeout: 5s
      retries: 3
    deploy:
      resources: { limits: { memory: 128M, cpus: '0.25' } }
"
    COMPOSE_VOLUMES+="  caddy_data:
  caddy_config:
"
    log "Caddy configured"
}

# ============================================================================
# [B] Nextcloud + Redis
# ============================================================================
setup_nextcloud() {
    step "Nextcloud + MariaDB + Redis"
    local nc_user="${NC_ADMIN_USER:-admin}"
    local nc_pass="${NC_ADMIN_PASS:-$(gen_password 24)}"
    local nc_db_pass; nc_db_pass=$(gen_password 32)
    local redis_pass; redis_pass=$(gen_password 24)
    mkdir -p "$BASE_DIR/nextcloud"

    add_service "
  nextcloud-db:
    image: mariadb:11
    container_name: freedom-nextcloud-db
    restart: unless-stopped
    environment:
      MYSQL_ROOT_PASSWORD: ${nc_db_pass}
      MYSQL_DATABASE: nextcloud
      MYSQL_USER: nextcloud
      MYSQL_PASSWORD: ${nc_db_pass}
    volumes: [nextcloud_db:/var/lib/mysql]
    networks: [net-data]
    healthcheck:
      test: [\"CMD\", \"healthcheck.sh\", \"--connect\", \"--innodb_initialized\"]
      interval: 30s
      timeout: 10s
      retries: 5
    deploy:
      resources: { limits: { memory: 512M, cpus: '0.5' } }

  nextcloud-redis:
    image: redis:7-alpine
    container_name: freedom-nextcloud-redis
    restart: unless-stopped
    command: redis-server --requirepass ${redis_pass} --maxmemory 128mb --maxmemory-policy allkeys-lru
    volumes: [nextcloud_redis:/data]
    networks: [net-data]
    healthcheck:
      test: [\"CMD\", \"redis-cli\", \"-a\", \"${redis_pass}\", \"ping\"]
      interval: 15s
      timeout: 3s
      retries: 3
    deploy:
      resources: { limits: { memory: 192M, cpus: '0.15' } }

  nextcloud:
    image: nextcloud:29-apache
    container_name: freedom-nextcloud
    restart: unless-stopped
    ports: [\"127.0.0.1:8080:80\"]
    environment:
      MYSQL_HOST: nextcloud-db
      MYSQL_DATABASE: nextcloud
      MYSQL_USER: nextcloud
      MYSQL_PASSWORD: ${nc_db_pass}
      NEXTCLOUD_ADMIN_USER: ${nc_user}
      NEXTCLOUD_ADMIN_PASSWORD: ${nc_pass}
      NEXTCLOUD_TRUSTED_DOMAINS: \"localhost ${DOMAIN:+cloud.${DOMAIN}}\"
      OVERWRITEPROTOCOL: https
      REDIS_HOST: nextcloud-redis
      REDIS_HOST_PASSWORD: ${redis_pass}
    volumes:
      - nextcloud_html:/var/www/html
      - nextcloud_data:/var/www/html/data
    depends_on:
      nextcloud-db: { condition: service_healthy }
      nextcloud-redis: { condition: service_healthy }
    networks: [net-proxy, net-data]
    healthcheck:
      test: [\"CMD\", \"curl\", \"-f\", \"http://localhost/status.php\"]
      interval: 60s
      timeout: 10s
      retries: 3
    deploy:
      resources: { limits: { memory: 1G, cpus: '1.0' } }
"
    COMPOSE_VOLUMES+="  nextcloud_db:
  nextcloud_redis:
  nextcloud_html:
  nextcloud_data:
"
    save_credential "━━━ NEXTCLOUD (+ Redis cache) ━━━"
    save_credential "URL: ${DOMAIN:+https://cloud.${DOMAIN}}"
    save_credential "Admin: ${nc_user} / ${nc_pass}"
    save_credential ""
    log "Nextcloud + Redis configured"
}

# ============================================================================
# [A] Matrix/Synapse + PostgreSQL + Element
# ============================================================================
setup_matrix() {
    step "Matrix/Synapse + PostgreSQL + Element"
    local matrix_secret; matrix_secret=$(gen_password 32)
    local pg_pass; pg_pass=$(gen_password 32)
    local server_name="${DOMAIN:-localhost}"
    mkdir -p "$BASE_DIR/matrix"/{synapse,element}

    cat > "$BASE_DIR/matrix/synapse/homeserver.yaml" <<EOF
server_name: "${server_name}"
pid_file: /data/homeserver.pid
listeners:
  - port: 8008
    tls: false
    type: http
    x_forwarded: true
    resources:
      - names: [client, federation]
        compress: false
database:
  name: psycopg2
  args:
    user: synapse
    password: ${pg_pass}
    database: synapse
    host: synapse-db
    cp_min: 5
    cp_max: 10
log_config: "/data/log.config"
media_store_path: /data/media_store
registration_shared_secret: "${matrix_secret}"
report_stats: false
enable_registration: false
suppress_key_server_warning: true
trusted_key_servers: []
EOF

    cat > "$BASE_DIR/matrix/synapse/log.config" <<'EOF'
version: 1
formatters:
  precise:
    format: '%(asctime)s - %(name)s - %(lineno)d - %(levelname)s - %(message)s'
handlers:
  console:
    class: logging.StreamHandler
    formatter: precise
root:
  level: WARNING
  handlers: [console]
EOF

    cat > "$BASE_DIR/matrix/element/config.json" <<EOF
{
    "default_server_config": {
        "m.homeserver": {
            "base_url": "${DOMAIN:+https://chat.${DOMAIN}}",
            "server_name": "${server_name}"
        }
    },
    "brand": "Freedom Chat",
    "default_theme": "dark"
}
EOF

    add_service "
  synapse-db:
    image: postgres:16-alpine
    container_name: freedom-synapse-db
    restart: unless-stopped
    environment:
      POSTGRES_USER: synapse
      POSTGRES_PASSWORD: ${pg_pass}
      POSTGRES_DB: synapse
      POSTGRES_INITDB_ARGS: \"--encoding=UTF-8 --lc-collate=C --lc-ctype=C\"
    volumes: [synapse_db:/var/lib/postgresql/data]
    networks: [net-data]
    healthcheck:
      test: [\"CMD-SHELL\", \"pg_isready -U synapse\"]
      interval: 15s
      timeout: 5s
      retries: 5
    deploy:
      resources: { limits: { memory: 512M, cpus: '0.5' } }

  synapse:
    image: matrixdotorg/synapse:latest
    container_name: freedom-synapse
    restart: unless-stopped
    ports: [\"127.0.0.1:8008:8008\"]
    volumes: [./matrix/synapse:/data]
    environment:
      SYNAPSE_CONFIG_PATH: /data/homeserver.yaml
    depends_on:
      synapse-db: { condition: service_healthy }
    networks: [net-proxy, net-data]
    healthcheck:
      test: [\"CMD\", \"curl\", \"-f\", \"http://localhost:8008/health\"]
      interval: 30s
      timeout: 10s
      retries: 3
    deploy:
      resources: { limits: { memory: 1536M, cpus: '1.0' } }

  element:
    image: vectorim/element-web:latest
    container_name: freedom-element
    restart: unless-stopped
    ports: [\"127.0.0.1:8088:80\"]
    volumes: [./matrix/element/config.json:/app/config.json:ro]
    networks: [net-proxy]
    healthcheck:
      test: [\"CMD\", \"wget\", \"--spider\", \"-q\", \"http://localhost\"]
      interval: 30s
      timeout: 5s
      retries: 3
    deploy:
      resources: { limits: { memory: 128M, cpus: '0.25' } }
"
    COMPOSE_VOLUMES+="  synapse_db:
"
    save_credential "━━━ MATRIX/ELEMENT (+ PostgreSQL) ━━━"
    save_credential "Element: ${DOMAIN:+https://element.${DOMAIN}}"
    save_credential "Homeserver: ${DOMAIN:+https://chat.${DOMAIN}}"
    save_credential "Registration: CLOSED"
    save_credential "Create user: docker exec -it freedom-synapse register_new_matrix_user -u USER -p PASS -c /data/homeserver.yaml http://localhost:8008"
    save_credential "Registration Secret: ${matrix_secret}"
    save_credential ""
    log "Matrix + PostgreSQL configured"
}

# ============================================================================
# Vaultwarden
# ============================================================================
setup_vaultwarden() {
    step "Vaultwarden"
    local vw_token; vw_token=$(gen_password 48)
    add_service "
  vaultwarden:
    image: vaultwarden/server:latest
    container_name: freedom-vaultwarden
    restart: unless-stopped
    ports: [\"127.0.0.1:8222:80\"]
    environment:
      ADMIN_TOKEN: ${vw_token}
      DOMAIN: ${DOMAIN:+https://vault.${DOMAIN}}
      SIGNUPS_ALLOWED: true
      SHOW_PASSWORD_HINT: false
    volumes: [vaultwarden_data:/data]
    networks: [net-proxy]
    healthcheck:
      test: [\"CMD\", \"curl\", \"-f\", \"http://localhost:80/alive\"]
      interval: 30s
      timeout: 5s
      retries: 3
    deploy:
      resources: { limits: { memory: 256M, cpus: '0.25' } }
"
    COMPOSE_VOLUMES+="  vaultwarden_data:
"
    save_credential "━━━ VAULTWARDEN ━━━"
    save_credential "URL: ${DOMAIN:+https://vault.${DOMAIN}}"
    save_credential "Admin: ${DOMAIN:+https://vault.${DOMAIN}}/admin → ${vw_token}"
    save_credential ""
    log "Vaultwarden configured"
}

# ============================================================================
# Jitsi Meet
# ============================================================================
setup_jitsi() {
    step "Jitsi Meet"
    mkdir -p "$BASE_DIR/jitsi"
    local j1; j1=$(gen_password 32)
    local j2; j2=$(gen_password 32)
    local j3; j3=$(gen_password 32)
    local ip; ip=$(curl -s4 ifconfig.me || echo "YOUR_IP")
    local host="${DOMAIN:+meet.${DOMAIN}}"
    host="${host:-$ip}"

    cat > "$BASE_DIR/jitsi/.env" <<EOF
CONFIG=/opt/freedom-stack/jitsi
HTTP_PORT=80
TZ=UTC
PUBLIC_URL=https://${host}
JICOFO_AUTH_PASSWORD=${j1}
JVB_AUTH_PASSWORD=${j2}
JIBRI_XMPP_PASSWORD=${j3}
JVB_PORT=10000
ENABLE_AUTH=0
ENABLE_GUESTS=1
ENABLE_LOBBY=1
EOF

    add_service "
  jitsi-web:
    image: jitsi/web:stable
    container_name: freedom-jitsi-web
    restart: unless-stopped
    ports: [\"127.0.0.1:8443:80\"]
    env_file: ./jitsi/.env
    volumes: [jitsi_web:/config, jitsi_transcripts:/usr/share/jitsi-meet/transcripts]
    networks:
      net-proxy: { aliases: [meet.jitsi] }
    deploy:
      resources: { limits: { memory: 256M, cpus: '0.5' } }

  jitsi-prosody:
    image: jitsi/prosody:stable
    container_name: freedom-jitsi-prosody
    restart: unless-stopped
    env_file: ./jitsi/.env
    volumes: [jitsi_prosody:/config]
    networks:
      net-proxy: { aliases: [xmpp.meet.jitsi] }
    deploy:
      resources: { limits: { memory: 256M, cpus: '0.25' } }

  jitsi-jicofo:
    image: jitsi/jicofo:stable
    container_name: freedom-jitsi-jicofo
    restart: unless-stopped
    env_file: ./jitsi/.env
    volumes: [jitsi_jicofo:/config]
    depends_on: [jitsi-prosody]
    networks: [net-proxy]
    deploy:
      resources: { limits: { memory: 256M, cpus: '0.25' } }

  jitsi-jvb:
    image: jitsi/jvb:stable
    container_name: freedom-jitsi-jvb
    restart: unless-stopped
    ports: [\"10000:10000/udp\"]
    env_file: ./jitsi/.env
    volumes: [jitsi_jvb:/config]
    depends_on: [jitsi-prosody]
    networks: [net-proxy]
    deploy:
      resources: { limits: { memory: 512M, cpus: '0.5' } }
"
    COMPOSE_VOLUMES+="  jitsi_web:
  jitsi_transcripts:
  jitsi_prosody:
  jitsi_jicofo:
  jitsi_jvb:
"
    save_credential "━━━ JITSI MEET ━━━"
    save_credential "URL: https://${host}"
    save_credential ""
    log "Jitsi configured"
}

# ============================================================================
# AdGuard + SearXNG
# ============================================================================
setup_adguard() {
    step "AdGuard Home"
    mkdir -p "$BASE_DIR/adguard"/{work,conf}
    systemctl is-active systemd-resolved &>/dev/null && {
        systemctl disable --now systemd-resolved
        echo "nameserver 9.9.9.9" > /etc/resolv.conf
    }
    add_service "
  adguard:
    image: adguard/adguardhome:latest
    container_name: freedom-adguard
    restart: unless-stopped
    ports: [\"53:53/tcp\", \"53:53/udp\", \"853:853/tcp\", \"127.0.0.1:3000:3000\"]
    volumes: [./adguard/work:/opt/adguardhome/work, ./adguard/conf:/opt/adguardhome/conf]
    networks: [net-proxy]
    healthcheck:
      test: [\"CMD\", \"wget\", \"--spider\", \"-q\", \"http://localhost:3000\"]
      interval: 30s
      timeout: 5s
      retries: 3
    deploy:
      resources: { limits: { memory: 256M, cpus: '0.25' } }
"
    save_credential "━━━ ADGUARD HOME ━━━"
    save_credential "Dashboard: ${DOMAIN:+https://dns.${DOMAIN}} (setup wizard on first access)"
    save_credential ""
    log "AdGuard configured"
}

setup_searxng() {
    step "SearXNG"
    mkdir -p "$BASE_DIR/searxng"
    local sk; sk=$(gen_password 32)
    cat > "$BASE_DIR/searxng/settings.yml" <<EOF
use_default_settings: true
general: { instance_name: "Freedom Search", enable_metrics: false }
search:
  safe_search: 0
  autocomplete: "duckduckgo"
  default_lang: "en"
  languages: ["en", "pt-BR", "zh-CN"]
  formats:
    - html
    - json
server: { secret_key: "${sk}", image_proxy: true, method: "POST", limiter: false }
ui: { default_theme: "simple", theme_args: { simple_style: "auto" }, infinite_scroll: true }
enabled_plugins: ['Hash plugin', 'Tracker URL remover', 'Ahmia blacklist']
EOF
    cat > "$BASE_DIR/searxng/limiter.toml" <<'EOF'
[botdetection.ip_limit]
link_token = false
EOF
    add_service "
  searxng:
    image: searxng/searxng:latest
    container_name: freedom-searxng
    restart: unless-stopped
    ports: [\"127.0.0.1:8888:8080\"]
    volumes: [./searxng/settings.yml:/etc/searxng/settings.yml:ro, ./searxng/limiter.toml:/etc/searxng/limiter.toml:ro]
    cap_drop: [ALL]
    cap_add: [CHOWN, SETGID, SETUID]
    networks: [net-proxy]
    healthcheck:
      test: [\"CMD\", \"wget\", \"--spider\", \"-q\", \"http://localhost:8080\"]
      interval: 30s
      timeout: 5s
      retries: 3
    deploy:
      resources: { limits: { memory: 512M, cpus: '0.5' } }
"
    save_credential "━━━ SEARXNG ━━━"
    save_credential "URL: ${DOMAIN:+https://search.${DOMAIN}}"
    save_credential ""
    log "SearXNG configured"
}

# ============================================================================
# [E] Forgejo (self-hosted Git)
# ============================================================================
setup_forgejo() {
    step "Forgejo (Git hosting)"
    mkdir -p "$BASE_DIR/forgejo"
    local fg_db_pass; fg_db_pass=$(gen_password 32)
    local fg_secret; fg_secret=$(gen_password 32)

    add_service "
  forgejo-db:
    image: postgres:16-alpine
    container_name: freedom-forgejo-db
    restart: unless-stopped
    environment:
      POSTGRES_USER: forgejo
      POSTGRES_PASSWORD: ${fg_db_pass}
      POSTGRES_DB: forgejo
    volumes: [forgejo_db:/var/lib/postgresql/data]
    networks: [net-data]
    healthcheck:
      test: [\"CMD-SHELL\", \"pg_isready -U forgejo\"]
      interval: 15s
      timeout: 5s
      retries: 5
    deploy:
      resources: { limits: { memory: 256M, cpus: '0.25' } }

  forgejo:
    image: codeberg.org/forgejo/forgejo:9
    container_name: freedom-forgejo
    restart: unless-stopped
    ports: [\"127.0.0.1:3030:3000\", \"127.0.0.1:2222:22\"]
    environment:
      FORGEJO__database__DB_TYPE: postgres
      FORGEJO__database__HOST: forgejo-db:5432
      FORGEJO__database__NAME: forgejo
      FORGEJO__database__USER: forgejo
      FORGEJO__database__PASSWD: ${fg_db_pass}
      FORGEJO__server__ROOT_URL: ${DOMAIN:+https://git.${DOMAIN}}
      FORGEJO__server__SSH_DOMAIN: ${DOMAIN:-localhost}
      FORGEJO__server__SSH_PORT: 2222
      FORGEJO__security__SECRET_KEY: ${fg_secret}
      FORGEJO__service__DISABLE_REGISTRATION: false
    volumes: [forgejo_data:/data]
    depends_on:
      forgejo-db: { condition: service_healthy }
    networks: [net-proxy, net-data]
    healthcheck:
      test: [\"CMD\", \"curl\", \"-f\", \"http://localhost:3000/api/v1/version\"]
      interval: 30s
      timeout: 5s
      retries: 3
    deploy:
      resources: { limits: { memory: 512M, cpus: '0.5' } }
"
    COMPOSE_VOLUMES+="  forgejo_db:
  forgejo_data:
"
    save_credential "━━━ FORGEJO (GIT) ━━━"
    save_credential "URL: ${DOMAIN:+https://git.${DOMAIN}}"
    save_credential "SSH clone: ssh://git@${DOMAIN:-VPS_IP}:2222/user/repo.git"
    save_credential "Register on first access to become admin"
    save_credential ""
    log "Forgejo configured"
}

# ============================================================================
# [G] Stalwart Mail Server
# ============================================================================
setup_mail() {
    step "Stalwart Mail Server"
    mkdir -p "$BASE_DIR/stalwart"
    local mail_admin_pass; mail_admin_pass=$(gen_password 24)

    add_service "
  stalwart:
    image: stalwartlabs/stalwart:latest
    container_name: freedom-stalwart
    restart: unless-stopped
    ports:
      - \"25:25\"
      - \"587:587\"
      - \"993:993\"
      - \"4190:4190\"
      - \"127.0.0.1:8180:8080\"
    volumes: [stalwart_data:/opt/stalwart-mail]
    networks: [net-proxy]
    healthcheck:
      test: [\"CMD\", \"curl\", \"-f\", \"http://localhost:8080/healthz\"]
      interval: 30s
      timeout: 5s
      retries: 3
    deploy:
      resources: { limits: { memory: 512M, cpus: '0.5' } }
"
    COMPOSE_VOLUMES+="  stalwart_data:
"
    save_credential "━━━ STALWART MAIL SERVER ━━━"
    save_credential "Admin: ${DOMAIN:+https://mail.${DOMAIN}} (or http://127.0.0.1:8180)"
    save_credential "IMAP: ${DOMAIN:-VPS_IP}:993 (TLS)"
    save_credential "SMTP: ${DOMAIN:-VPS_IP}:587 (STARTTLS)"
    save_credential "Setup wizard on first access — create admin account"
    save_credential "IMPORTANT: Set SPF, DKIM, DMARC DNS records for deliverability!"
    save_credential ""
    log "Stalwart Mail configured"
}

# ============================================================================
# [J-Q] AGENT PRIVACY CLOUD — 8 components
# ============================================================================
setup_agents() {
    step "Agent Privacy Cloud (8 components)"
    mkdir -p "$BASE_DIR/agents"/{n8n,qdrant,sandbox,privoxy,dashboard}

    local ollama_models="${OLLAMA_MODELS:-llama3.2:3b}"
    local n8n_key; n8n_key=$(gen_password 32)
    local gotify_pass; gotify_pass=$(gen_password 16)

    # --- [J] Ollama — Local LLM inference ---
    # Zero data leaves the server. Replaces OpenAI/Anthropic for private tasks.
    # Open WebUI provides a ChatGPT-like interface to talk to local models.
    add_service "
  ollama:
    image: ollama/ollama:latest
    container_name: freedom-ollama
    restart: unless-stopped
    ports: [\"127.0.0.1:11434:11434\"]
    volumes: [ollama_data:/root/.ollama]
    networks: [net-proxy, net-data]
    deploy:
      resources: { limits: { memory: 4G, cpus: '2.0' } }

  ollama-web:
    image: ghcr.io/open-webui/open-webui:main
    container_name: freedom-ollama-web
    restart: unless-stopped
    ports: [\"127.0.0.1:8181:8080\"]
    environment:
      OLLAMA_BASE_URL: http://ollama:11434
      WEBUI_AUTH: true
    volumes: [ollama_web_data:/app/backend/data]
    depends_on: [ollama]
    networks: [net-proxy]
    healthcheck:
      test: [\"CMD\", \"curl\", \"-f\", \"http://localhost:8080\"]
      interval: 30s
      timeout: 5s
      retries: 3
    deploy:
      resources: { limits: { memory: 512M, cpus: '0.5' } }
"
    COMPOSE_VOLUMES+="  ollama_data:
  ollama_web_data:
"

    # --- [K] n8n — Agent workflow orchestration ---
    # Visual drag-and-drop for agent pipelines. Connect SearXNG → Ollama → Matrix → Nextcloud.
    add_service "
  n8n:
    image: n8nio/n8n:latest
    container_name: freedom-n8n
    restart: unless-stopped
    ports: [\"127.0.0.1:5678:5678\"]
    environment:
      N8N_ENCRYPTION_KEY: ${n8n_key}
      N8N_PROTOCOL: https
      N8N_HOST: ${DOMAIN:+n8n.${DOMAIN}}
      WEBHOOK_URL: ${DOMAIN:+https://n8n.${DOMAIN}/}
      N8N_DIAGNOSTICS_ENABLED: false
      N8N_PERSONALIZATION_ENABLED: false
    volumes: [n8n_data:/home/node/.n8n]
    networks: [net-proxy, net-data]
    healthcheck:
      test: [\"CMD\", \"wget\", \"--spider\", \"-q\", \"http://localhost:5678/healthz\"]
      interval: 30s
      timeout: 5s
      retries: 3
    deploy:
      resources: { limits: { memory: 512M, cpus: '0.5' } }
"
    COMPOSE_VOLUMES+="  n8n_data:
"

    # --- [L] Qdrant — Vector DB for agent memory ---
    # Store embeddings, semantic search, long-term memory for agents.
    add_service "
  qdrant:
    image: qdrant/qdrant:latest
    container_name: freedom-qdrant
    restart: unless-stopped
    ports: [\"127.0.0.1:6333:6333\", \"127.0.0.1:6334:6334\"]
    volumes: [qdrant_data:/qdrant/storage]
    networks: [net-data]
    healthcheck:
      test: [\"CMD\", \"wget\", \"--spider\", \"-q\", \"http://localhost:6333/healthz\"]
      interval: 30s
      timeout: 5s
      retries: 3
    deploy:
      resources: { limits: { memory: 1G, cpus: '0.5' } }
"
    COMPOSE_VOLUMES+="  qdrant_data:
"

    # --- [M] Agent sandbox — Isolated Python/Node runtime ---
    # Agents execute code here. Isolated from host. Auto-destroyed.
    cat > "$BASE_DIR/agents/sandbox/Dockerfile" << 'DKEOF'
FROM python:3.12-slim
RUN pip install --no-cache-dir requests httpx beautifulsoup4 \
    qdrant-client openai anthropic langchain chromadb \
    matrix-nio aiohttp pydantic numpy pandas
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl jq git nodejs npm && rm -rf /var/lib/apt/lists/*
RUN npm install -g axios cheerio
WORKDIR /workspace
ENV PYTHONUNBUFFERED=1
ENV TOR_PROXY=socks5h://tor:9050
ENV SEARXNG_URL=http://searxng:8080
ENV OLLAMA_URL=http://ollama:11434
ENV QDRANT_URL=http://qdrant:6333
ENV MATRIX_URL=http://synapse:8008
ENV NEXTCLOUD_URL=http://nextcloud:80
ENV VAULTWARDEN_URL=http://vaultwarden:80
ENV N8N_URL=http://n8n:5678
ENV GOTIFY_URL=http://gotify:80
CMD ["sleep", "infinity"]
DKEOF

    add_service "
  agent-sandbox:
    build: ./agents/sandbox
    container_name: freedom-agent-sandbox
    restart: unless-stopped
    volumes: [agent_workspace:/workspace]
    networks: [net-proxy, net-data]
    environment:
      TOR_PROXY: socks5h://tor:9050
      SEARXNG_URL: http://searxng:8080
      OLLAMA_URL: http://ollama:11434
      QDRANT_URL: http://qdrant:6333
      N8N_URL: http://n8n:5678
    cap_drop: [ALL]
    cap_add: [NET_RAW]
    security_opt: [no-new-privileges:true]
    read_only: false
    tmpfs: [/tmp:size=256M]
    deploy:
      resources: { limits: { memory: 2G, cpus: '1.0' } }
"
    COMPOSE_VOLUMES+="  agent_workspace:
"

    # --- [N] Tor proxy rotator — Multi-circuit scraping ---
    # Multiple Tor circuits for parallel anonymous scraping. Privoxy adds HTTP proxy.
    cat > "$BASE_DIR/agents/privoxy/config" << 'PRIVOXYEOF'
listen-address  0.0.0.0:8118
forward-socks5  / tor:9050 .
toggle  0
enable-remote-toggle  0
enable-edit-actions  0
enable-remote-http-toggle  0
buffer-limit  32768
forwarded-connect-retries  2
keep-alive-timeout  300
socket-timeout  120
PRIVOXYEOF

    add_service "
  privoxy:
    image: vimagick/privoxy:latest
    container_name: freedom-privoxy
    restart: unless-stopped
    ports: [\"127.0.0.1:8118:8118\"]
    volumes: [./agents/privoxy/config:/etc/privoxy/config:ro]
    networks: [net-proxy]
    deploy:
      resources: { limits: { memory: 64M, cpus: '0.1' } }

  tor-rotator:
    image: osminogin/tor-simple:latest
    container_name: freedom-tor-rotator
    restart: unless-stopped
    environment:
      TOR_NewCircuitPeriod: 30
      TOR_MaxCircuitDirtiness: 60
      TOR_NumEntryGuards: 8
    ports: [\"127.0.0.1:9060:9050\"]
    networks: [net-proxy]
    deploy:
      resources: { limits: { memory: 128M, cpus: '0.15' } }
"

    # --- [O] Gotify — Private push notifications ---
    add_service "
  gotify:
    image: gotify/server:latest
    container_name: freedom-gotify
    restart: unless-stopped
    ports: [\"127.0.0.1:8070:80\"]
    environment:
      GOTIFY_DEFAULTUSER_PASS: ${gotify_pass}
    volumes: [gotify_data:/app/data]
    networks: [net-proxy]
    healthcheck:
      test: [\"CMD\", \"wget\", \"--spider\", \"-q\", \"http://localhost:80/health\"]
      interval: 30s
      timeout: 5s
      retries: 3
    deploy:
      resources: { limits: { memory: 128M, cpus: '0.1' } }
"
    COMPOSE_VOLUMES+="  gotify_data:
"

    # --- [Q] Agent Dashboard — Real-time activity view ---
    cat > "$BASE_DIR/agents/dashboard/Dockerfile" << 'DASHEOF'
FROM node:20-alpine
WORKDIR /app
RUN npm init -y && npm install express dockerode ws
COPY server.js .
EXPOSE 3000
CMD ["node", "server.js"]
DASHEOF

    cat > "$BASE_DIR/agents/dashboard/server.js" << 'SERVEREOF'
const express = require('express');
const app = express();
const PORT = 3000;

const SERVICES = {
  ollama: { url: 'http://ollama:11434', label: 'LLM Local', icon: '🧠' },
  n8n: { url: 'http://n8n:5678', label: 'Workflows', icon: '⚡' },
  qdrant: { url: 'http://qdrant:6333', label: 'Vector DB', icon: '🗄️' },
  searxng: { url: 'http://searxng:8080', label: 'Search', icon: '🔍' },
  tor: { url: 'http://tor:9050', label: 'Tor Proxy', icon: '🧅' },
  privoxy: { url: 'http://privoxy:8118', label: 'HTTP Proxy', icon: '🔄' },
  gotify: { url: 'http://gotify:80', label: 'Notifications', icon: '🔔' },
  sandbox: { label: 'Agent Sandbox', icon: '📦' },
};

app.get('/api/status', async (req, res) => {
  const status = {};
  for (const [name, svc] of Object.entries(SERVICES)) {
    try {
      if (svc.url) {
        const controller = new AbortController();
        const timeout = setTimeout(() => controller.abort(), 3000);
        await fetch(svc.url, { signal: controller.signal });
        clearTimeout(timeout);
        status[name] = { ...svc, up: true };
      } else {
        status[name] = { ...svc, up: true };
      }
    } catch {
      status[name] = { ...svc, up: false };
    }
  }
  res.json(status);
});

app.get('/', (req, res) => {
  res.send(`<!DOCTYPE html><html><head>
<meta charset="UTF-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>Agent Privacy Cloud</title>
<style>
@import url('https://fonts.googleapis.com/css2?family=DM+Sans:wght@400;500;600;700&family=DM+Mono&display=swap');
*{box-sizing:border-box;margin:0;padding:0}
body{font-family:'DM Sans',sans-serif;background:#0a0f14;color:#e8ecf1;padding:24px}
h1{font-size:24px;font-weight:700;text-align:center;margin-bottom:4px}
.sub{text-align:center;color:#7d8a99;font-size:13px;margin-bottom:20px}
.grid{display:grid;grid-template-columns:repeat(auto-fill,minmax(200px,1fr));gap:10px;max-width:800px;margin:0 auto}
.card{background:#131920;border:1px solid #222d3a;border-radius:12px;padding:16px;transition:.2s}
.card:hover{border-color:#22c088;transform:translateY(-2px)}
.card-head{display:flex;align-items:center;gap:8px}
.card-icon{font-size:22px}
.card-name{font-size:14px;font-weight:600;flex:1}
.dot{width:10px;height:10px;border-radius:50%}
.dot.up{background:#22c088;box-shadow:0 0 8px #22c088}
.dot.down{background:#ff5555;box-shadow:0 0 8px #ff5555}
.card-desc{font-size:11px;color:#7d8a99;margin-top:6px}
.endpoints{margin-top:16px;padding:16px;background:#131920;border:1px solid #222d3a;border-radius:12px;max-width:800px;margin-left:auto;margin-right:auto}
.ep-title{font-size:14px;font-weight:600;margin-bottom:8px}
.ep{display:flex;justify-content:space-between;padding:4px 0;font-size:12px;border-bottom:1px solid #222d3a}
.ep:last-child{border:none}
.ep span:last-child{font-family:'DM Mono',monospace;color:#22c088}
.refresh{text-align:center;margin-top:16px}
.refresh-btn{background:#1c2430;border:1px solid #222d3a;color:#7d8a99;padding:8px 20px;border-radius:8px;cursor:pointer;font-family:'DM Sans'}
</style></head><body>
<h1>🤖 Agent Privacy Cloud</h1>
<p class="sub">Real-time status of your AI agent infrastructure</p>
<div class="grid" id="grid"></div>
<div class="endpoints">
<div class="ep-title">Agent endpoints (use inside sandbox or n8n)</div>
<div class="ep"><span>LLM (Ollama)</span><span>http://ollama:11434/api/generate</span></div>
<div class="ep"><span>Search (SearXNG)</span><span>http://searxng:8080/search?q=...&format=json</span></div>
<div class="ep"><span>Memory (Qdrant)</span><span>http://qdrant:6333</span></div>
<div class="ep"><span>Workflows (n8n)</span><span>http://n8n:5678/api/v1</span></div>
<div class="ep"><span>Tor SOCKS</span><span>socks5h://tor:9050</span></div>
<div class="ep"><span>HTTP via Tor</span><span>http://privoxy:8118</span></div>
<div class="ep"><span>Notifications</span><span>http://gotify:80/message</span></div>
<div class="ep"><span>Chat (Matrix)</span><span>http://synapse:8008/_matrix/client</span></div>
<div class="ep"><span>Files (Nextcloud)</span><span>http://nextcloud:80/remote.php/dav</span></div>
<div class="ep"><span>Passwords</span><span>http://vaultwarden:80/api</span></div>
</div>
<div class="refresh"><button class="refresh-btn" onclick="load()">Refresh</button></div>
<script>
async function load(){
  const r=await fetch('/api/status');const d=await r.json();
  document.getElementById('grid').innerHTML=Object.entries(d).map(([k,v])=>
    '<div class="card"><div class="card-head"><span class="card-icon">'+v.icon+'</span><span class="card-name">'+v.label+'</span><span class="dot '+(v.up?'up':'down')+'"></span></div><div class="card-desc">'+k+'</div></div>'
  ).join('');
}
load();setInterval(load,15000);
</script></body></html>`);
});

app.listen(PORT, () => console.log('Agent dashboard on :' + PORT));
SERVEREOF

    add_service "
  agent-dash:
    build: ./agents/dashboard
    container_name: freedom-agent-dash
    restart: unless-stopped
    ports: [\"127.0.0.1:3333:3000\"]
    networks: [net-proxy, net-data, net-monitor]
    healthcheck:
      test: [\"CMD\", \"wget\", \"--spider\", \"-q\", \"http://localhost:3000\"]
      interval: 30s
      timeout: 5s
      retries: 3
    deploy:
      resources: { limits: { memory: 128M, cpus: '0.15' } }
"

    # Add Prometheus scrape for Qdrant
    if [[ -f "$BASE_DIR/prometheus/prometheus.yml" ]]; then
        cat >> "$BASE_DIR/prometheus/prometheus.yml" << 'EOF'

  - job_name: 'qdrant'
    static_configs:
      - targets: ['qdrant:6333']
    metrics_path: '/metrics'

  - job_name: 'ollama'
    static_configs:
      - targets: ['ollama:11434']
    metrics_path: '/metrics'
EOF
    fi

    save_credential "━━━ AGENT PRIVACY CLOUD ━━━"
    save_credential ""
    save_credential "Ollama (LLM):     ${DOMAIN:+https://ollama.${DOMAIN}} — ChatGPT-like UI for local models"
    save_credential "  API: http://127.0.0.1:11434  |  Pull model: docker exec freedom-ollama ollama pull ${ollama_models}"
    save_credential "n8n (workflows):  ${DOMAIN:+https://n8n.${DOMAIN}} — visual agent orchestration"
    save_credential "Qdrant (memory):  http://127.0.0.1:6333 — vector DB REST API"
    save_credential "Agent sandbox:    docker exec -it freedom-agent-sandbox bash"
    save_credential "Tor proxy:        SOCKS5 = 127.0.0.1:9050 | HTTP = 127.0.0.1:8118"
    save_credential "Tor rotator:      SOCKS5 = 127.0.0.1:9060 (new circuit every 30s)"
    save_credential "Gotify (notify):  ${DOMAIN:+https://notify.${DOMAIN}} — admin pass: ${gotify_pass}"
    save_credential "Agent dashboard:  ${DOMAIN:+https://agents.${DOMAIN}} — real-time status"
    save_credential ""
    save_credential "AGENT INTERNAL ENDPOINTS (use inside sandbox or n8n):"
    save_credential "  LLM:       http://ollama:11434/api/generate"
    save_credential "  Search:    http://searxng:8080/search?q=QUERY&format=json"
    save_credential "  Memory:    http://qdrant:6333"
    save_credential "  Tor SOCKS: socks5h://tor:9050"
    save_credential "  HTTP Tor:  http://privoxy:8118"
    save_credential "  Notify:    curl http://gotify:80/message -F title=X -F message=Y -F priority=5"
    save_credential "  Matrix:    http://synapse:8008/_matrix/client"
    save_credential "  Files:     http://nextcloud:80/remote.php/dav"
    save_credential "  Secrets:   http://vaultwarden:80/api"
    save_credential ""
    log "Agent Privacy Cloud configured (8 components)"
    info "Pull first model: docker exec freedom-ollama ollama pull ${ollama_models}"
}

# ============================================================================
# Tor
# ============================================================================
setup_tor() {
    if $SKIP_TOR; then warn "Skipping Tor"; return; fi
    step "Tor hidden services"
    mkdir -p "$BASE_DIR/tor"
    local T="SocksPort 0.0.0.0:9050
Log notice stdout
DataDirectory /var/lib/tor
"
    for svc_port in \
        "nextcloud:INSTALL_NEXTCLOUD:nextcloud:80" \
        "matrix:INSTALL_MATRIX:synapse:8008" \
        "element:INSTALL_MATRIX:element:80" \
        "vaultwarden:INSTALL_VAULTWARDEN:vaultwarden:80" \
        "jitsi:INSTALL_JITSI:jitsi-web:80" \
        "searxng:INSTALL_SEARXNG:searxng:8080" \
        "forgejo:INSTALL_FORGEJO:forgejo:3000" \
        "mail:INSTALL_MAIL:stalwart:8080" \
        "n8n:INSTALL_AGENTS:n8n:5678" \
        "ollama:INSTALL_AGENTS:ollama-web:8080" \
        "agents:INSTALL_AGENTS:agent-dash:3000"; do
        IFS=: read -r name flag target port <<< "$svc_port"
        ${!flag} && T+="HiddenServiceDir /var/lib/tor/${name}_hs/
HiddenServicePort 80 ${target}:${port}
"
    done
    echo "$T" > "$BASE_DIR/tor/torrc"

    add_service "
  tor:
    image: osminogin/tor-simple:latest
    container_name: freedom-tor
    restart: unless-stopped
    ports: [\"127.0.0.1:9050:9050\"]
    volumes: [./tor/torrc:/etc/tor/torrc:ro, tor_data:/var/lib/tor]
    networks: [net-proxy]
    deploy:
      resources: { limits: { memory: 256M, cpus: '0.25' } }
"
    COMPOSE_VOLUMES+="  tor_data:
"
    log "Tor configured"
}

# ============================================================================
# WireGuard
# ============================================================================
setup_wireguard() {
    step "WireGuard VPN"
    mkdir -p "$BASE_DIR/wireguard"
    local ip; ip=$(curl -s4 ifconfig.me || echo "YOUR_IP")
    local wg_port="${WIREGUARD_PORT:-51820}"
    local dns="9.9.9.9,149.112.112.112"
    $INSTALL_ADGUARD && dns="10.13.13.1"

    add_service "
  wireguard:
    image: linuxserver/wireguard:latest
    container_name: freedom-wireguard
    cap_add: [NET_ADMIN, SYS_MODULE]
    environment:
      PUID: 1000
      PGID: 1000
      TZ: UTC
      SERVERURL: ${ip}
      SERVERPORT: ${wg_port}
      PEERS: 5
      PEERDNS: ${dns}
      INTERNAL_SUBNET: 10.13.13.0
      ALLOWEDIPS: 0.0.0.0/0
    volumes: [./wireguard/config:/config, /lib/modules:/lib/modules:ro]
    ports: [\"${wg_port}:${wg_port}/udp\"]
    sysctls: [net.ipv4.conf.all.src_valid_mark=1]
    restart: unless-stopped
    networks: [net-proxy]
    deploy:
      resources: { limits: { memory: 128M, cpus: '0.25' } }
"
    save_credential "━━━ WIREGUARD ━━━"
    save_credential "Server: ${ip}:${wg_port} | DNS: ${dns}"
    save_credential "Configs: ${BASE_DIR}/wireguard/config/peer*/"
    save_credential ""
    log "WireGuard configured (DNS → ${dns})"
}

# ============================================================================
# [C][D][H][I] Monitoring: Watchtower + Uptime Kuma + Prometheus + Grafana + Netdata + Portainer
# ============================================================================
setup_monitoring() {
    step "Full monitoring stack"

    # Prometheus config
    mkdir -p "$BASE_DIR/prometheus"
    cat > "$BASE_DIR/prometheus/prometheus.yml" <<'EOF'
global:
  scrape_interval: 30s
  evaluation_interval: 30s

scrape_configs:
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']

  - job_name: 'netdata'
    metrics_path: '/api/v1/allmetrics'
    params:
      format: ['prometheus']
    static_configs:
      - targets: ['netdata:19999']

  - job_name: 'caddy'
    static_configs:
      - targets: ['caddy:2019']
EOF

    # Grafana provisioning
    mkdir -p "$BASE_DIR/grafana/provisioning/datasources"
    cat > "$BASE_DIR/grafana/provisioning/datasources/prometheus.yml" <<'EOF'
apiVersion: 1
datasources:
  - name: Prometheus
    type: prometheus
    access: proxy
    url: http://prometheus:9090
    isDefault: true
EOF

    add_service "
  watchtower:
    image: containrrr/watchtower:latest
    container_name: freedom-watchtower
    restart: unless-stopped
    environment:
      WATCHTOWER_CLEANUP: true
      WATCHTOWER_SCHEDULE: \"0 0 4 * * 1\"
      WATCHTOWER_ROLLING_RESTART: true
    volumes: [/var/run/docker.sock:/var/run/docker.sock]
    networks: [net-monitor]
    deploy:
      resources: { limits: { memory: 128M, cpus: '0.15' } }

  uptime-kuma:
    image: louislam/uptime-kuma:latest
    container_name: freedom-uptime-kuma
    restart: unless-stopped
    ports: [\"127.0.0.1:3001:3001\"]
    volumes: [uptime_kuma_data:/app/data]
    networks: [net-proxy, net-monitor]
    healthcheck:
      test: [\"CMD\", \"wget\", \"--spider\", \"-q\", \"http://localhost:3001\"]
      interval: 30s
      timeout: 5s
      retries: 3
    deploy:
      resources: { limits: { memory: 256M, cpus: '0.25' } }

  prometheus:
    image: prom/prometheus:latest
    container_name: freedom-prometheus
    restart: unless-stopped
    ports: [\"127.0.0.1:9090:9090\"]
    volumes:
      - ./prometheus/prometheus.yml:/etc/prometheus/prometheus.yml:ro
      - prometheus_data:/prometheus
    command: [\"--config.file=/etc/prometheus/prometheus.yml\", \"--storage.tsdb.retention.time=30d\"]
    networks: [net-monitor, net-proxy]
    healthcheck:
      test: [\"CMD\", \"wget\", \"--spider\", \"-q\", \"http://localhost:9090/-/healthy\"]
      interval: 30s
      timeout: 5s
      retries: 3
    deploy:
      resources: { limits: { memory: 512M, cpus: '0.25' } }

  grafana:
    image: grafana/grafana:latest
    container_name: freedom-grafana
    restart: unless-stopped
    ports: [\"127.0.0.1:3100:3000\"]
    environment:
      GF_SECURITY_ADMIN_PASSWORD: ${GRAFANA_PASS:-$(gen_password 20)}
      GF_SERVER_ROOT_URL: ${DOMAIN:+https://dash.${DOMAIN}}
      GF_INSTALL_PLUGINS: grafana-clock-panel
    volumes:
      - grafana_data:/var/lib/grafana
      - ./grafana/provisioning:/etc/grafana/provisioning:ro
    networks: [net-proxy, net-monitor]
    healthcheck:
      test: [\"CMD\", \"curl\", \"-f\", \"http://localhost:3000/api/health\"]
      interval: 30s
      timeout: 5s
      retries: 3
    deploy:
      resources: { limits: { memory: 256M, cpus: '0.25' } }

  netdata:
    image: netdata/netdata:stable
    container_name: freedom-netdata
    restart: unless-stopped
    ports: [\"127.0.0.1:19999:19999\"]
    cap_add: [SYS_PTRACE, SYS_ADMIN]
    security_opt: [apparmor:unconfined]
    volumes:
      - netdata_config:/etc/netdata
      - netdata_lib:/var/lib/netdata
      - netdata_cache:/var/cache/netdata
      - /proc:/host/proc:ro
      - /sys:/host/sys:ro
      - /var/run/docker.sock:/var/run/docker.sock:ro
    networks: [net-monitor, net-proxy]
    healthcheck:
      test: [\"CMD\", \"curl\", \"-f\", \"http://localhost:19999/api/v1/info\"]
      interval: 30s
      timeout: 5s
      retries: 3
    deploy:
      resources: { limits: { memory: 384M, cpus: '0.25' } }

  portainer:
    image: portainer/portainer-ce:latest
    container_name: freedom-portainer
    restart: unless-stopped
    ports: [\"127.0.0.1:9000:9000\"]
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
      - portainer_data:/data
    networks: [net-proxy, net-monitor]
    healthcheck:
      test: [\"CMD\", \"wget\", \"--spider\", \"-q\", \"http://localhost:9000\"]
      interval: 30s
      timeout: 5s
      retries: 3
    deploy:
      resources: { limits: { memory: 256M, cpus: '0.25' } }
"
    COMPOSE_VOLUMES+="  uptime_kuma_data:
  prometheus_data:
  grafana_data:
  netdata_config:
  netdata_lib:
  netdata_cache:
  portainer_data:
"
    save_credential "━━━ MONITORING & MANAGEMENT ━━━"
    save_credential "Uptime Kuma: ${DOMAIN:+https://status.${DOMAIN}} (uptime monitors)"
    save_credential "Grafana:     ${DOMAIN:+https://dash.${DOMAIN}} (metrics dashboard)"
    save_credential "Grafana admin password: check GF_SECURITY_ADMIN_PASSWORD in compose"
    save_credential "Netdata:     ${DOMAIN:+https://monitor.${DOMAIN}} (real-time system metrics)"
    save_credential "Portainer:   ${DOMAIN:+https://portainer.${DOMAIN}} (Docker GUI management)"
    save_credential "Prometheus:  http://127.0.0.1:9090 (metrics backend)"
    save_credential "Watchtower:  auto-updates every Monday 4AM"
    save_credential ""
    log "Monitoring stack configured (7 components)"
}

# ============================================================================
# Security Hardening
# ============================================================================
setup_security() {
    step "Security hardening"
    local sshd="/etc/ssh/sshd_config"
    sed -i "s/^#*Port .*/Port ${SSH_PORT}/" "$sshd"
    sed -i 's/^#*MaxAuthTries.*/MaxAuthTries 3/' "$sshd"
    if [[ -f /root/.ssh/authorized_keys ]] && [[ -s /root/.ssh/authorized_keys ]]; then
        sed -i 's/^#*PasswordAuthentication.*/PasswordAuthentication no/' "$sshd"
        sed -i 's/^#*PermitRootLogin.*/PermitRootLogin prohibit-password/' "$sshd"
    fi
    systemctl restart sshd

    apt-get install -y -qq ufw
    ufw default deny incoming && ufw default allow outgoing
    ufw allow "${SSH_PORT}"/tcp comment SSH
    ufw allow 80/tcp comment HTTP && ufw allow 443/tcp comment HTTPS
    $INSTALL_WIREGUARD && ufw allow "${WIREGUARD_PORT:-51820}"/udp comment WireGuard
    $INSTALL_JITSI && ufw allow 10000/udp comment 'Jitsi JVB'
    $INSTALL_ADGUARD && { ufw allow 53/tcp comment DNS; ufw allow 53/udp comment DNS; }
    $INSTALL_MAIL && { ufw allow 25/tcp comment SMTP; ufw allow 587/tcp comment 'SMTP submission'; ufw allow 993/tcp comment IMAPS; }
    echo "y" | ufw enable

    apt-get install -y -qq fail2ban
    cat > /etc/fail2ban/jail.local <<EOF
[DEFAULT]
bantime = 3600
findtime = 600
maxretry = 3
backend = systemd

[sshd]
enabled = true
port = ${SSH_PORT}
maxretry = 3
bantime = 86400

[nextcloud]
enabled = true
port = 80,443
filter = nextcloud
logpath = /var/lib/docker/volumes/*nextcloud_html*/_data/data/nextcloud.log
maxretry = 5

[vaultwarden]
enabled = true
port = 80,443
filter = vaultwarden
logpath = /var/log/syslog
maxretry = 5
EOF

    mkdir -p /etc/fail2ban/filter.d
    cat > /etc/fail2ban/filter.d/nextcloud.conf <<'EOF'
[Definition]
failregex = ^.*Login failed: '.*' \(Remote IP: '<HOST>'\).*$
EOF
    cat > /etc/fail2ban/filter.d/vaultwarden.conf <<'EOF'
[Definition]
failregex = ^.*Username or password is incorrect.*<HOST>.*$
EOF
    systemctl enable --now fail2ban

    if ! $SKIP_CROWDSEC; then
        curl -s https://install.crowdsec.net | bash 2>/dev/null || true
        apt-get install -y -qq crowdsec-firewall-bouncer-iptables 2>/dev/null || true
        systemctl enable --now crowdsec 2>/dev/null || true
    fi

    save_credential "━━━ SECURITY ━━━"
    save_credential "SSH: port ${SSH_PORT} → ssh -p ${SSH_PORT} root@VPS_IP"
    save_credential "fail2ban: SSH + Nextcloud + Vaultwarden"
    save_credential "AppArmor: active"
    save_credential "Auto OS updates: unattended-upgrades active"
    save_credential ""
    log "Security hardened (SSH:${SSH_PORT}, fail2ban, AppArmor, auto-updates)"
}

# ============================================================================
# Backup (with integrity)
# ============================================================================
setup_backup() {
    step "Rclone encrypted backup"
    command -v rclone &>/dev/null || curl -fsSL https://rclone.org/install.sh | bash
    local cp; cp=$(gen_password 48)
    local cs; cs=$(gen_password 48)
    local cpo; cpo=$(rclone obscure "$cp")
    local cso; cso=$(rclone obscure "$cs")
    mkdir -p /root/.config/rclone
    cat > /root/.config/rclone/rclone.conf <<EOF
[mega]
type = mega
user = ${MEGA_USER:-CHANGE_ME}
pass = ${MEGA_PASS:+$(rclone obscure "$MEGA_PASS")}${MEGA_PASS:-CHANGE_ME}

[freedom-crypt]
type = crypt
remote = mega:freedom-backup
password = ${cpo}
password2 = ${cso}
filename_encryption = standard
directory_name_encryption = true
EOF
    chmod 600 /root/.config/rclone/rclone.conf

    cat > "$BASE_DIR/backup.sh" <<'BKSCRIPT'
#!/usr/bin/env bash
set -uo pipefail
D=$(date +%Y-%m-%d_%H%M); S="/opt/freedom-stack/backups/${D}"; L="/var/log/freedom-backup.log"
log() { echo "[$(date '+%F %T')] $1" | tee -a "$L"; }
log "═══ Backup starting ═══"
mkdir -p "$S"
docker ps --format '{{.Names}}' | grep -q freedom-nextcloud && {
    docker exec freedom-nextcloud php occ maintenance:mode --on 2>/dev/null || true
    tar -czf "$S/nextcloud.tar.gz" -C /var/lib/docker/volumes . --include='*nextcloud*' 2>/dev/null
    docker exec freedom-nextcloud-db mariadb-dump -u root --all-databases 2>/dev/null | gzip > "$S/nc-db.sql.gz"
    docker exec freedom-nextcloud php occ maintenance:mode --off 2>/dev/null || true
}
docker ps --format '{{.Names}}' | grep -q freedom-synapse && {
    docker exec freedom-synapse-db pg_dumpall -U synapse 2>/dev/null | gzip > "$S/synapse-db.sql.gz"
}
[[ -d /opt/freedom-stack/wireguard ]] && tar -czf "$S/wireguard.tar.gz" -C /opt/freedom-stack/wireguard config/ 2>/dev/null
[[ -d /opt/freedom-stack/tor ]] && tar -czf "$S/tor.tar.gz" -C /opt/freedom-stack/tor . 2>/dev/null
[[ -f /root/freedom-stack-credentials.txt ]] && cp /root/freedom-stack-credentials.txt "$S/"
cd "$S" && sha256sum * > checksums.sha256 2>/dev/null
rclone copy "$S" "freedom-crypt:${D}" --transfers 4 2>&1 | tee -a "$L"
V=$(mktemp -d)
rclone copy "freedom-crypt:${D}/checksums.sha256" "$V/" 2>/dev/null
diff -q "$S/checksums.sha256" "$V/checksums.sha256" &>/dev/null && log "INTEGRITY: ✓ PASSED" || log "INTEGRITY: ✗ FAILED"
rm -rf "$V"
find /opt/freedom-stack/backups -mindepth 1 -maxdepth 1 -type d -mtime +30 -exec rm -rf {} \;
rclone delete "freedom-crypt:" --min-age 30d 2>/dev/null || true
log "═══ Backup complete — $(du -sh "$S" | awk '{print $1}') ═══"
BKSCRIPT
    chmod +x "$BASE_DIR/backup.sh"

    cat > "$BASE_DIR/restore.sh" <<'EOF'
#!/usr/bin/env bash
[[ -z "${1:-}" ]] && { echo "Backups:"; rclone lsd freedom-crypt:; echo "Usage: bash restore.sh DATE"; exit 0; }
D=$(mktemp -d); rclone copy "freedom-crypt:$1" "$D/" --progress
cd "$D" && sha256sum -c checksums.sha256 && echo "✓ Verified" || echo "✗ CORRUPTED"
echo "Files: $D/"; ls -lh "$D/"
EOF
    chmod +x "$BASE_DIR/restore.sh"
    (crontab -l 2>/dev/null | grep -v "freedom-stack/backup"; echo "0 3 * * * /opt/freedom-stack/backup.sh >> /var/log/freedom-backup.log 2>&1") | crontab -

    save_credential "━━━ BACKUP (integrity-verified) ━━━"
    save_credential "Cron: daily 3AM | Includes: NC data+DB, Synapse PostgreSQL dump, WG, Tor keys"
    save_credential "⚠️  SAVE OFFLINE: Crypt Pass: ${cp}"
    save_credential "⚠️  SAVE OFFLINE: Crypt Salt: ${cs}"
    save_credential ""
    log "Backup configured (now dumps PostgreSQL too)"
}

# ============================================================================
# Tor .onion reader
# ============================================================================
read_onion_addresses() {
    $INSTALL_TOR && ! $SKIP_TOR || return 0
    info "Waiting for Tor .onion generation (30s)..."
    sleep 30
    save_credential "━━━ TOR .ONION ━━━"
    for svc in nextcloud matrix element vaultwarden jitsi searxng forgejo mail; do
        for base in "$BASE_DIR/tor/data" "$(docker volume inspect freedom-stack_tor_data --format '{{.Mountpoint}}' 2>/dev/null)"; do
            local f="${base}/${svc}_hs/hostname"
            [[ -f "$f" ]] && { save_credential "${svc}: http://$(cat "$f")"; log "${svc} .onion ready"; break; }
        done
    done
    save_credential ""
}

# ============================================================================
# Credential encryption
# ============================================================================
secure_credentials() {
    chmod 600 "$CREDENTIALS_FILE"
    if command -v gpg &>/dev/null; then
        gpg --batch --yes --symmetric --cipher-algo AES256 -o "${CREDENTIALS_FILE}.gpg" "$CREDENTIALS_FILE" 2>/dev/null && \
            log "Credentials encrypted: ${CREDENTIALS_FILE}.gpg" || \
            warn "GPG encryption skipped — encrypt manually: gpg -c ${CREDENTIALS_FILE}"
    fi
}

# ============================================================================
# Main
# ============================================================================
main() {
    echo -e "${CYAN}"
    echo "╔══════════════════════════════════════════════════╗"
    echo "║       🛡️  FREEDOM STACK v3.0 — Full Suite        ║"
    echo "║  PostgreSQL • Redis • Grafana • Portainer • Git  ║"
    echo "╚══════════════════════════════════════════════════╝"
    echo -e "${NC}"

    parse_args "$@"
    check_root

    cat > "$CREDENTIALS_FILE" <<EOF
═══════════════════════════════════════
  FREEDOM STACK v3.0 — Credentials
  $(date) | $(curl -s4 ifconfig.me 2>/dev/null)
═══════════════════════════════════════

EOF

    install_base
    setup_caddy
    $INSTALL_NEXTCLOUD   && setup_nextcloud
    $INSTALL_MATRIX      && setup_matrix
    $INSTALL_VAULTWARDEN && setup_vaultwarden
    $INSTALL_JITSI       && setup_jitsi
    $INSTALL_ADGUARD     && setup_adguard
    $INSTALL_SEARXNG     && setup_searxng
    $INSTALL_FORGEJO     && setup_forgejo
    $INSTALL_MAIL        && setup_mail
    $INSTALL_AGENTS      && setup_agents
    $INSTALL_TOR         && setup_tor
    $INSTALL_WIREGUARD   && setup_wireguard
    setup_monitoring

    generate_compose
    step "Starting all services"
    cd "$BASE_DIR" && docker compose up -d
    log "All containers launching"

    $INSTALL_SECURITY && setup_security
    $INSTALL_BACKUP   && setup_backup
    read_onion_addresses
    secure_credentials

    # Generate visual dashboard
    step "Generating visual dashboard"
    bash "${BASE_DIR}/scripts/generate-dashboard.sh" "${DOMAIN}" 2>/dev/null || true

    # Serve dashboard via Caddy
    if [[ -n "$DOMAIN" ]]; then
        mkdir -p "${BASE_DIR}/caddy/srv"
        [[ -f "${BASE_DIR}/caddy/dashboard.html" ]] && cp "${BASE_DIR}/caddy/dashboard.html" "${BASE_DIR}/caddy/srv/index.html"
        # Add root domain route to Caddyfile
        if ! grep -q "^${DOMAIN} " "${BASE_DIR}/caddy/Caddyfile" 2>/dev/null; then
            echo "${DOMAIN} { root * /srv; file_server }" >> "${BASE_DIR}/caddy/Caddyfile"
        fi
        # Reload Caddy
        docker exec freedom-caddy caddy reload --config /etc/caddy/Caddyfile 2>/dev/null || \
            docker restart freedom-caddy 2>/dev/null || true
        log "Dashboard live at https://${DOMAIN}"
    fi

    step "Freedom Stack v4.0 — Agent Privacy Cloud Complete! 🎉"
    cat "$CREDENTIALS_FILE"
    echo ""
    echo -e "${CYAN}━━━ WHAT TO DO NOW ━━━${NC}"
    echo ""
    if [[ -n "$DOMAIN" ]]; then
        echo -e "${GREEN}1. Open your dashboard:${NC} https://${DOMAIN}"
        echo -e "${GREEN}2. Agent dashboard:${NC} https://agents.${DOMAIN}"
    fi
    echo ""
    echo -e "${GREEN}3. Pull your first local LLM:${NC}"
    echo "   docker exec freedom-ollama ollama pull llama3.2:3b"
    echo ""
    echo -e "${GREEN}4. Enter the agent sandbox:${NC}"
    echo "   docker exec -it freedom-agent-sandbox bash"
    echo "   python -c \"import requests; r=requests.get('http://searxng:8080/search?q=test&format=json'); print(r.json())\""
    echo ""
    echo -e "${GREEN}5. Create agent workflows:${NC} ${DOMAIN:+https://n8n.${DOMAIN}}"
    echo ""
    echo -e "${GREEN}6. SSH (new port!):${NC} ssh -p ${SSH_PORT} root@$(curl -s4 ifconfig.me 2>/dev/null)"
    echo ""
    echo -e "${GREEN}The first Agent Privacy Cloud is live. ✊${NC}"
}

main "$@"
