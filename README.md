<div align="center">

# 🛡️ Freedom Stack

### The First Agent Privacy Cloud

**Privacy infrastructure for AI agents AND humans.**
**34 containers. 1 command. Zero big tech.**

[![License: AGPL v3](https://img.shields.io/badge/License-AGPL_v3-blue.svg)](LICENSE)
[![Containers](https://img.shields.io/badge/containers-34-green)]()
[![Health Checks](https://img.shields.io/badge/health_checks-23-green)]()
[![Onion Services](https://img.shields.io/badge/.onion_services-11-purple)]()

[Quick Start](#-quick-start) · [What's Inside](#-whats-inside) · [Agent Privacy Cloud](#-agent-privacy-cloud) · [Why This Matters](WHY.md) · [Docs](docs/)

---

> **🏆 First mover:** No other product combines AI agent infrastructure with privacy-native architecture (Tor, .onion, E2E, VPN, anonymous search + payments). [Full market analysis →](WHY.md)

</div>

---

## The Problem

Every AI agent today leaks data to big tech:

| What your agent does | Who sees it |
|---|---|
| Searches the web | Google knows every query |
| Calls an LLM API | OpenAI/Anthropic log everything |
| Stores results | AWS/Google Cloud sees your data |
| Communicates | Slack/Discord reads messages |
| Makes payments | Stripe/PayPal tracks transactions |
| Runs on a VPS | Provider sees all traffic |

**Freedom Stack fixes all of this.** One command, everything private.

| What your agent does | With Freedom Stack |
|---|---|
| Searches the web | **SearXNG** (your server, zero tracking) |
| Calls an LLM | **Ollama** (local, zero data leaves) |
| Stores results | **Nextcloud** (your server) + **Qdrant** (vector memory) |
| Communicates | **Matrix** (E2E encrypted, your server) |
| Makes payments | **Zcash/ZODL** (shielded transactions) |
| Runs on a VPS | **Tor** + **WireGuard** (invisible traffic) |

---

## 🚀 Quick Start

**Requirements:** Ubuntu 22.04/24.04 VPS with 16GB+ RAM, 4+ vCPUs, 80GB+ disk.

```bash
# SSH into your VPS
ssh root@YOUR_VPS_IP

# Download and run (everything in 1 command)
curl -fsSL https://raw.githubusercontent.com/YOUR_USER/freedom-stack/main/scripts/install.sh -o install.sh
chmod +x install.sh

# Install everything (human + agent stack)
bash install.sh --all --domain yourdomain.com

# Or just the agent privacy cloud
bash install.sh --agents --tor --searxng --domain yourdomain.com

# Or just the human stack (no AI/agent components)
bash install.sh --nextcloud --matrix --vaultwarden --jitsi --searxng --tor --wireguard --security --backup
```

After ~15 minutes, open `https://yourdomain.com` — your visual dashboard shows all services with live status.

> **⚠️ SSH port changes to 2222 after install.** Reconnect: `ssh -p 2222 root@YOUR_VPS_IP`

---

## 📦 What's Inside

### 34 Containers, 3 Isolated Networks, 23 Health Checks

<details>
<summary><b>🤖 Agent Privacy Cloud (8 components)</b></summary>

| Service | What It Does | Internal Endpoint |
|---|---|---|
| **Ollama + Open WebUI** | Local LLM inference — zero data to OpenAI | `http://ollama:11434/api/generate` |
| **n8n** | Visual workflow orchestration for agents | `http://n8n:5678/api/v1` |
| **Qdrant** | Vector DB — agent long-term memory | `http://qdrant:6333` |
| **Agent Sandbox** | Isolated Python 3.12 + Node 20 runtime | `docker exec -it freedom-agent-sandbox bash` |
| **Tor Rotator** | New Tor circuit every 30s for scraping | `socks5h://tor-rotator:9050` |
| **Privoxy** | HTTP proxy via Tor — anonymous API calls | `http://privoxy:8118` |
| **Gotify** | Private push notifications to phone | `http://gotify:80/message` |
| **Agent Dashboard** | Real-time status of all agent infra | `http://agent-dash:3000` |

</details>

<details>
<summary><b>👤 Human Services (10 services)</b></summary>

| Service | Replaces | Subdomain |
|---|---|---|
| **Nextcloud + Redis** | Google Drive, Dropbox, Office 365 | `cloud.` |
| **Matrix/Synapse + PostgreSQL** | WhatsApp, Slack, Discord | `chat.` |
| **Element** | Discord, Teams | `element.` |
| **Vaultwarden** | LastPass, 1Password | `vault.` |
| **Jitsi Meet** | Zoom, Google Meet | `meet.` |
| **SearXNG** | Google Search | `search.` |
| **Forgejo** | GitHub, GitLab | `git.` |
| **Stalwart Mail** | Gmail, Outlook | `mail.` |
| **AdGuard Home** | Google DNS, Pi-hole | `dns.` |
| **WireGuard** | NordVPN, ExpressVPN | — |

</details>

<details>
<summary><b>📊 Monitoring & Infrastructure (8 components)</b></summary>

| Service | Function |
|---|---|
| **Caddy** | Reverse proxy, auto-HTTPS, 17 subdomains |
| **Tor** | 11 .onion hidden services |
| **Prometheus + Grafana** | Metrics + dashboards |
| **Netdata** | Real-time system monitoring |
| **Portainer** | Docker management via browser |
| **Uptime Kuma** | Uptime monitoring + alerts |
| **Watchtower** | Auto-update containers weekly |
| **Rclone Crypt** | Encrypted daily backup to Mega.nz |

</details>

<details>
<summary><b>🔒 Security Hardening</b></summary>

- Unified `docker-compose.yml` (not 34 separate files)
- All ports behind Caddy (`127.0.0.1` only) — no direct exposure
- 3 isolated Docker networks (`net-proxy`, `net-data`, `net-monitor`)
- 23 container health checks
- 34 resource limits (RAM + CPU per container)
- Docker log rotation (prevents disk fill)
- ZRAM + swap for low-RAM VPS
- UFW firewall + fail2ban (SSH + Nextcloud + Vaultwarden jails) + CrowdSec
- SSH on non-standard port (2222, customizable)
- AppArmor + unattended-upgrades
- Matrix registration closed by default
- Credentials encrypted with GPG AES-256
- Backup with SHA-256 integrity verification

</details>

---

## 🤖 Agent Privacy Cloud

The core differentiator. No other platform combines AI agent infrastructure with privacy-native architecture.

### How an agent works inside Freedom Stack

```python
# Inside the sandbox: docker exec -it freedom-agent-sandbox bash

import requests

# Search without Google knowing
results = requests.get("http://searxng:8080/search?q=bitcoin+price&format=json").json()

# Analyze with local LLM (zero data to OpenAI)
analysis = requests.post("http://ollama:11434/api/generate", json={
    "model": "llama3.2:3b",
    "prompt": f"Analyze: {results['results'][0]['content']}"
}).json()

# Store memory as embeddings
requests.put("http://qdrant:6333/collections/memory/points", json={
    "points": [{"id": 1, "vector": [...], "payload": {"analysis": analysis}}]
})

# Make external request via Tor (anonymous)
requests.get("https://api.example.com/data",
    proxies={"https": "socks5h://tor:9050"})

# Notify owner on phone
requests.post("http://gotify:80/message",
    data={"title": "Agent Alert", "message": "Task complete", "priority": 5})

# Save results to private cloud
requests.put("http://nextcloud:80/remote.php/dav/files/admin/agent-results.json",
    data=analysis, auth=("admin", "pass"))
```

### Why this doesn't exist anywhere else

| Feature | n8n AI Kit | Dify | LangChain | **Freedom Stack** |
|---|---|---|---|---|
| Local LLM | ✓ | ✓ | ✓ | ✓ |
| Vector DB | ✓ | ✓ | ✓ | ✓ |
| Visual workflows | ✓ | ✓ | ✗ | ✓ |
| **Tor routing** | ✗ | ✗ | ✗ | **✓ + rotator** |
| **Anonymous search** | ✗ | ✗ | ✗ | **SearXNG** |
| **E2E encrypted chat** | ✗ | ✗ | ✗ | **Matrix** |
| **.onion services** | ✗ | ✗ | ✗ | **11 services** |
| **Integrated VPN** | ✗ | ✗ | ✗ | **WireGuard** |
| **Private DNS** | ✗ | ✗ | ✗ | **AdGuard** |
| **Private payments** | ✗ | ✗ | ✗ | **Zcash/ZODL** |
| **Personal cloud** | ✗ | ✗ | ✗ | **Nextcloud** |
| **Human + Agent stack** | ✗ | ✗ | ✗ | **✓ UNIQUE** |

---

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────┐
│                YOUR VPS (34 containers)                   │
│                                                           │
│  ┌─ HUMAN SERVICES ─────────────────────────────────┐   │
│  │ Nextcloud+Redis │ Matrix+PG │ Vaultwarden │ Jitsi│   │
│  │ Forgejo+PG │ Stalwart Mail │ SearXNG │ Element   │   │
│  └──────────────────────────────────────────────────┘   │
│                                                           │
│  ┌─ AGENT PRIVACY CLOUD ────────────────────────────┐   │
│  │ 🧠 Ollama (LLM)    │ ⚡ n8n (workflows)         │   │
│  │ 🗄️ Qdrant (memory)  │ 📦 Sandbox (Py/JS)        │   │
│  │ 🔄 Tor Rotator      │ 🔔 Gotify (notifications) │   │
│  │ 📊 Agent Dashboard (real-time + endpoints)        │   │
│  └──────────────────────────────────────────────────┘   │
│                                                           │
│  ┌─ PROTECTION ─────────────────────────────────────┐   │
│  │ Caddy │ Tor (11 .onion) │ AdGuard │ WireGuard   │   │
│  │ UFW │ fail2ban │ CrowdSec │ AppArmor            │   │
│  └──────────────────────────────────────────────────┘   │
│                                                           │
│  ┌─ MONITORING ─────────────────────────────────────┐   │
│  │ Grafana │ Prometheus │ Netdata │ Uptime Kuma     │   │
│  │ Portainer (Docker GUI) │ Watchtower (auto-update)│   │
│  └──────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────┘
```

### Network Isolation

```
net-proxy:   Caddy ↔ all web services (reverse proxy)
net-data:    Databases (MariaDB, PostgreSQL, Redis, Qdrant)
net-monitor: Watchtower, Prometheus, Netdata, Portainer
```

---

## 📋 Requirements

| | Minimum | Recommended |
|---|---|---|
| **RAM** | 8GB (without Ollama) | 16GB+ (with Ollama) |
| **CPU** | 2 vCPUs | 4+ vCPUs |
| **Disk** | 40GB | 100GB+ (LLM models = 2-7GB each) |
| **OS** | Ubuntu 22.04 | Ubuntu 24.04 |
| **Cost** | ~€8/month | ~€18/month (Hetzner CX32) |

### Recommended VPS Providers

| Provider | Privacy | Price (16GB) | Notes |
|---|---|---|---|
| **Hetzner** | ★★★★☆ | €18/mo | Best performance/price, GDPR |
| **Njalla** | ★★★★★ | ~€30/mo | Zero KYC, crypto only, founded by Pirate Bay co-founder |
| **1984.is** | ★★★★★ | ~€25/mo | Iceland, strongest free speech laws |
| **Contabo** | ★★★☆☆ | €12/mo | Cheapest 16GB option |

---

## 🖥️ Also Runs on Mac

Docker Desktop + Ollama native (Apple Silicon GPU = 2-5x faster than VPS CPU).

```bash
brew install --cask docker ollama
ollama pull llama3.2:3b
bash install.sh --agents --searxng --adguard --backup  # skips Linux-only hardening
```

---

## 🏆 Market Position

Freedom Stack is the **only** product that combines AI agent infrastructure with privacy-native architecture.

```
                    PRIVACY
                       ↑
                       │
                       │   ★ FREEDOM STACK
                       │     (privacy-native + agents + human stack)
                       │
          Njalla/1984  │
          (VPS only)   │         n8n AI Kit, Dify, Flowise
                       │         (self-hosted, no privacy layer)
                       │
        ───────────────┼──────────────────────→ AI AGENTS
                       │
          Traditional  │   OpenAI / AWS / Google
          self-hosted  │   (cloud, logs everything)
                       │
```

| Metric | Value |
|---|---|
| Closest competitor gap | **3-4 months** of engineering to replicate |
| Target market | **$12B+** (data privacy market) |
| Active community | **3M+** across r/selfhosted, r/privacy, r/degoogle |
| AI agent ecosystem | **500K+** GitHub stars in agent repos (2025) |

**[Full market analysis, use cases, and business model →](WHY.md)**

---

## 🗺️ Roadmap

- [x] v1.0 — Basic self-hosted stack (14 containers)
- [x] v2.0 — Security hardening (unified compose, isolated networks, health checks)
- [x] v3.0 — Production-grade (PostgreSQL, Redis, Grafana, Portainer, Forgejo, Mail)
- [x] v4.0 — Agent Privacy Cloud (Ollama, n8n, Qdrant, sandbox, Tor rotator)
- [ ] v5.0 — coming soon

---

## 🤝 Contributing

Contributions are welcome! See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

Areas where help is needed:
- Testing on different VPS providers
- n8n workflow templates for common agent use cases
- macOS compatibility improvements
- Documentation translations (PT-BR, ZH-CN, ES)
- Security audits

---

## 📄 License

[GNU Affero General Public License v3.0](LICENSE) — Free as in freedom.

You can use, modify, and distribute this software. If you run a modified version as a service, you must release your changes under the same license.

---

## ⚠️ Disclaimer

This software is provided for legitimate privacy and security purposes. Users are responsible for complying with applicable laws in their jurisdiction. The authors do not endorse or encourage any illegal activity.

---

<div align="center">

**Your digital sovereignty starts with one command.**

```bash
bash install.sh --all --domain yourdomain.com
```

[Star this repo](../../stargazers) if you believe privacy is a right, not a feature.

</div>

---

## 💛 Donations

If Freedom Stack saved you time or protects your privacy, consider supporting the project.
All donations are received in privacy-preserving currencies.

**Zcash (Shielded — fully private):**
```
u12rrgyaz7hwyzf0px29ka43tvk7nu92w7mzc99yv9ld3pg96fp4ef0mxe5kd0j5544yc33jqe66fd5s0fjv7uvsxh0uz24c7fuw44wfwcg2g74jgg2ukmpvc0l4a7r56sgjrra35fy4f0k3spjn5uh6kqxx5elmuv3ajd7zjs8s973e0n
```

**Bitcoin:**
```
bc1qus6gvfyepx38apvdxvqh4qj8n3d0jssthzmlnx
```
