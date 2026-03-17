#!/usr/bin/env bash
# ============================================================================
# Freedom Stack v2.0 — Health Check & Troubleshooter
# ============================================================================
set -uo pipefail

GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; NC='\033[0m'
BASE_DIR="/opt/freedom-stack"
PASS=0; FAIL=0; WARN=0

ok()   { echo -e "  ${GREEN}✓${NC} $1"; ((PASS++)); }
fail() { echo -e "  ${RED}✗${NC} $1"; ((FAIL++)); }
skip() { echo -e "  ${YELLOW}!${NC} $1"; ((WARN++)); }

check() {
    local name="$1"; shift
    if eval "$@" &>/dev/null; then ok "$name"; else fail "$name"; fi
}
soft() {
    local name="$1"; shift
    if eval "$@" &>/dev/null; then ok "$name"; else skip "$name"; fi
}

echo -e "${CYAN}━━━ Freedom Stack v2.0 Health Check ━━━${NC}\n"

# --- Docker ---
echo -e "${CYAN}Docker:${NC}"
check "Docker running" "systemctl is-active docker"
check "Compose available" "docker compose version"
check "Log rotation configured" "grep -q max-size /etc/docker/daemon.json"

# --- Unified Compose ---
echo -e "\n${CYAN}Compose (unified):${NC}"
check "docker-compose.yml exists" "test -f ${BASE_DIR}/docker-compose.yml"
soft "All containers up" "cd ${BASE_DIR} && docker compose ps --status running | grep -c running | grep -qE '^[5-9]|^[1-9][0-9]'"

# --- Container Health ---
echo -e "\n${CYAN}Container health:${NC}"
for c in $(docker ps --format '{{.Names}}' 2>/dev/null | grep "^freedom-"); do
    local health
    health=$(docker inspect --format='{{.State.Health.Status}}' "$c" 2>/dev/null || echo "none")
    case "$health" in
        healthy)   ok "${c}: healthy" ;;
        unhealthy) fail "${c}: UNHEALTHY" ;;
        starting)  skip "${c}: starting..." ;;
        *)         skip "${c}: no healthcheck" ;;
    esac
done

# --- Networks (isolation check) ---
echo -e "\n${CYAN}Network isolation:${NC}"
soft "net-proxy exists" "docker network inspect freedom-proxy"
soft "net-data exists" "docker network inspect freedom-data"
soft "net-monitor exists" "docker network inspect freedom-monitor"

# --- Ports (only public ones should be 0.0.0.0) ---
echo -e "\n${CYAN}Port security:${NC}"
check "Port 80 (Caddy)" "ss -tlnp | grep -q ':80 '"
check "Port 443 (Caddy)" "ss -tlnp | grep -q ':443 '"
# These should NOT be on 0.0.0.0
for port in 8080 8008 8088 8222 8443 8888 3000 3001; do
    if ss -tlnp | grep -q "0.0.0.0:${port}"; then
        fail "Port ${port} exposed on 0.0.0.0 (should be 127.0.0.1)"
    else
        ok "Port ${port} properly restricted"
    fi
done

# --- Monitoring ---
echo -e "\n${CYAN}Monitoring:${NC}"
soft "Watchtower running" "docker ps --format '{{.Names}}' | grep -q watchtower"
soft "Uptime Kuma running" "docker ps --format '{{.Names}}' | grep -q uptime-kuma"

# --- Security ---
echo -e "\n${CYAN}Security:${NC}"
check "UFW active" "ufw status | grep -q 'Status: active'"
check "fail2ban running" "systemctl is-active fail2ban"
soft "CrowdSec running" "systemctl is-active crowdsec"
soft "SSH key-only" "grep -q 'PasswordAuthentication no' /etc/ssh/sshd_config"

local ssh_port
ssh_port=$(grep "^Port " /etc/ssh/sshd_config 2>/dev/null | awk '{print $2}')
if [[ "$ssh_port" != "22" && -n "$ssh_port" ]]; then
    ok "SSH port: ${ssh_port} (non-standard)"
else
    skip "SSH port: 22 (default — consider changing)"
fi

soft "fail2ban nextcloud jail" "fail2ban-client status nextcloud"
soft "fail2ban vaultwarden jail" "fail2ban-client status vaultwarden"

# --- Swap / Memory ---
echo -e "\n${CYAN}Resources:${NC}"
local ram_used
ram_used=$(free -m | awk '/^Mem:/{printf "%.0f", $3/$2*100}')
local swap_total
swap_total=$(free -m | awk '/^Swap:/{print $2}')
echo -e "  ${GREEN}i${NC} RAM usage: ${ram_used}%"
echo -e "  ${GREEN}i${NC} Swap: ${swap_total}MB"
[[ "$swap_total" -gt 0 ]] && ok "Swap configured" || skip "No swap (risky with 14 containers)"

local disk_pct
disk_pct=$(df / | tail -1 | awk '{print $5}' | tr -d '%')
if [[ $disk_pct -lt 80 ]]; then ok "Disk: ${disk_pct}%"
elif [[ $disk_pct -lt 90 ]]; then skip "Disk: ${disk_pct}% (getting full)"
else fail "Disk: ${disk_pct}% CRITICAL"; fi

# --- Backup ---
echo -e "\n${CYAN}Backup:${NC}"
soft "Rclone installed" "command -v rclone"
soft "Backup cron active" "crontab -l | grep -q freedom-stack/backup.sh"
if [[ -f /var/log/freedom-backup.log ]]; then
    local last_backup
    last_backup=$(grep "Backup complete" /var/log/freedom-backup.log | tail -1)
    local last_integrity
    last_integrity=$(grep "INTEGRITY CHECK" /var/log/freedom-backup.log | tail -1)
    [[ -n "$last_backup" ]] && ok "Last backup: $last_backup" || skip "No backup completed yet"
    [[ "$last_integrity" == *"PASSED"* ]] && ok "Last integrity: PASSED" || skip "Integrity: not verified yet"
fi

# --- Tor ---
echo -e "\n${CYAN}Tor:${NC}"
soft "Tor container running" "docker ps --format '{{.Names}}' | grep -q freedom-tor"

# --- Summary ---
echo -e "\n${CYAN}━━━ Summary ━━━${NC}"
echo -e "  ${GREEN}Passed: ${PASS}${NC}  ${RED}Failed: ${FAIL}${NC}  ${YELLOW}Warnings: ${WARN}${NC}"
if [[ $FAIL -eq 0 ]]; then
    echo -e "\n  ${GREEN}All critical checks passed! ✊${NC}"
else
    echo -e "\n  ${RED}${FAIL} check(s) failed. Review above.${NC}"
    echo "  Logs: docker compose -f ${BASE_DIR}/docker-compose.yml logs"
fi
