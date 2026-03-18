<div align="center">

# Freedom Stack

### The Agent Privacy Cloud

**Privacy infrastructure for AI agents.**
**~18 containers. 1 command. Zero big tech.**

[![License: AGPL v3](https://img.shields.io/badge/License-AGPL_v3-blue.svg)](LICENSE)
[![Health Checks](https://img.shields.io/badge/health_checks-automated-green)]()
[![Onion Services](https://img.shields.io/badge/.onion_services-yes-purple)]()

[Quick Start](#quick-start) · [What's Inside](#whats-inside) · [Agent Privacy Cloud](#agent-privacy-cloud) · [Why This Matters](WHY.md)

**Skill:** [Agent Shielded](skills/agent-shielded/SKILL.md)

---

> **First mover:** No other product combines AI agent infrastructure with privacy-native architecture (Tor, .onion, E2E, anonymous search). [Full market analysis ->](WHY.md)

</div>

---

## The Problem

Every AI agent today leaks data to big tech:

| What your agent does | Who sees it |
|---|---|
| Searches the web | Google knows every query |
| Calls an LLM API | OpenAI/Anthropic log everything |
| Stores results | AWS/Google Cloud sees your data |
| Runs on a VPS | Provider sees all traffic |

**Freedom Stack fixes all of this.** One command, everything private.

| What your agent does | With Freedom Stack |
|---|---|
| Searches the web | **SearXNG** (your server, zero tracking) |
| Calls an LLM | **Ollama** (local, zero data leaves) |
| Stores results | **Qdrant** (vector memory, your server) |
| Runs on a VPS | **Tor** (invisible traffic) |

---

## Quick Start

**Requirements:** Ubuntu 22.04/24.04 VPS with 16GB+ RAM, 4+ vCPUs, 80GB+ disk.

```bash
# SSH into your VPS
ssh root@<YOUR_VPS_IP>

# Download and run (everything in 1 command)
curl -fsSL https://raw.githubusercontent.com/Michae2xl/freedom-stack/main/scripts/install.sh -o install.sh
chmod +x install.sh

# Install the Agent Privacy Cloud
bash install.sh --agents --tor --searxng --domain <yourdomain.com>

# No domain? Works via IP or Tor .onion
bash install.sh --agents --tor --searxng
```

After ~15 minutes your stack is live. With a domain: `https://<yourdomain.com>`. Without: access services directly by port or via Tor .onion addresses printed at the end.

> **SSH port changes to 2222 after install.** Reconnect: `ssh -p 2222 root@<YOUR_VPS_IP>`

---

## What's Inside

### Agent Privacy Cloud + Infrastructure

<details open>
<summary><b>Agent Privacy Cloud (9 containers)</b></summary>

| Service | What It Does | Internal Endpoint |
|---|---|---|
| **Ollama + Open WebUI** | Local LLM inference -- zero data to OpenAI | `http://ollama:11434/api/generate` |
| **n8n** | Visual workflow orchestration for agents | `http://n8n:5678/api/v1` |
| **Qdrant** | Vector DB -- agent long-term memory | `http://qdrant:6333` |
| **Agent Sandbox** | Isolated Python 3.12 + Node 20 runtime | `docker exec -it freedom-agent-sandbox bash` |
| **Tor Rotator** | New Tor circuit every 30s for scraping | `socks5h://tor-rotator:9050` |
| **Privoxy** | HTTP proxy via Tor -- anonymous API calls | `http://privoxy:8118` |
| **Gotify** | Private push notifications to phone | `http://gotify:80/message` |
| **Agent Dashboard** | Real-time status of all agent infra | `http://agent-dash:3000` |

</details>

<details open>
<summary><b>Privacy and Networking (3 containers)</b></summary>

| Service | Function |
|---|---|
| **Caddy** | Reverse proxy, auto-HTTPS |
| **Tor** | .onion hidden services for all agent endpoints |
| **SearXNG** | Private meta-search engine (zero tracking) |

</details>

<details open>
<summary><b>Monitoring (6 containers)</b></summary>

| Service | Function |
|---|---|
| **Prometheus + Grafana** | Metrics + dashboards |
| **Netdata** | Real-time system monitoring |
| **Portainer** | Docker management via browser |
| **Uptime Kuma** | Uptime monitoring + alerts |
| **Watchtower** | Auto-update containers weekly |

</details>

<details open>
<summary><b>Security Hardening</b></summary>

- Unified `docker-compose.yml` (single file, not scattered)
- All ports behind Caddy (`127.0.0.1` only) -- no direct exposure
- Isolated Docker networks (`net-proxy`, `net-data`, `net-monitor`)
- Container health checks on all services
- Resource limits (RAM + CPU per container)
- Docker log rotation (prevents disk fill)
- ZRAM + swap for low-RAM VPS
- UFW firewall + fail2ban + CrowdSec
- SSH on non-standard port (2222, customizable)
- AppArmor + unattended-upgrades
- Credentials encrypted with GPG AES-256

</details>

---

## Agent Privacy Cloud

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
```

### Why this doesn't exist anywhere else

| Feature | n8n AI Kit | Dify | LangChain | **Freedom Stack** |
|---|---|---|---|---|
| Local LLM | Yes | Yes | Yes | Yes |
| Vector DB | Yes | Yes | Yes | Yes |
| Visual workflows | Yes | Yes | No | Yes |
| **Tor routing** | No | No | No | **Yes + rotator** |
| **Anonymous search** | No | No | No | **SearXNG** |
| **.onion services** | No | No | No | **Yes** |
| **Push notifications** | No | No | No | **Gotify** |
| **Isolated sandbox** | No | No | No | **Python + Node** |

---

## Architecture

```
+-----------------------------------------------------------+
|                YOUR VPS (~18 containers)                    |
|                                                             |
|  +- AGENT PRIVACY CLOUD ------------------------------+    |
|  | Ollama + Open WebUI   | n8n (workflows)            |    |
|  | Qdrant (memory)       | Sandbox (Py/JS)            |    |
|  | Tor Rotator           | Gotify (notifications)     |    |
|  | Privoxy (Tor proxy)   | Agent Dashboard            |    |
|  +----------------------------------------------------+    |
|                                                             |
|  +- PRIVACY + NETWORKING -----------------------------+    |
|  | Caddy (reverse proxy, auto-HTTPS)                  |    |
|  | Tor (.onion hidden services)                       |    |
|  | SearXNG (private search)                           |    |
|  +----------------------------------------------------+    |
|                                                             |
|  +- MONITORING ---------------------------------------+    |
|  | Grafana | Prometheus | Netdata | Uptime Kuma       |    |
|  | Portainer (Docker GUI) | Watchtower (auto-update)  |    |
|  +----------------------------------------------------+    |
|                                                             |
|  +- HARDENING ----------------------------------------+    |
|  | UFW | fail2ban | CrowdSec | AppArmor              |    |
|  +----------------------------------------------------+    |
+-----------------------------------------------------------+
```

### Network Isolation

```
net-proxy:   Caddy <-> all web services (reverse proxy)
net-data:    Databases (Qdrant, agent storage)
net-monitor: Watchtower, Prometheus, Netdata, Portainer
```

---

## Requirements

| | Minimum | Recommended |
|---|---|---|
| **RAM** | 8GB (without Ollama) | 16GB+ (with Ollama) |
| **CPU** | 2 vCPUs | 4+ vCPUs |
| **Disk** | 40GB | 100GB+ (LLM models = 2-7GB each) |
| **OS** | Ubuntu 22.04 | Ubuntu 24.04 |
| **Cost** | ~EUR 8/month | ~EUR 18/month (Hetzner CX32) |

### Recommended VPS Providers

| Provider | Privacy | Price (16GB) | Notes |
|---|---|---|---|
| **Hetzner** | High | EUR 18/mo | Best performance/price, GDPR |
| **Njalla** | Maximum | ~EUR 30/mo | Zero KYC, crypto only, founded by Pirate Bay co-founder |
| **1984.is** | Maximum | ~EUR 25/mo | Iceland, strongest free speech laws |
| **Contabo** | Standard | EUR 12/mo | Cheapest 16GB option |

---

## Also Runs on Mac

Docker Desktop + Ollama native (Apple Silicon GPU = 2-5x faster than VPS CPU).

```bash
brew install --cask docker ollama
ollama pull llama3.2:3b
bash install.sh --agents --searxng  # skips Linux-only hardening
```

---

## Market Position

Freedom Stack is the **only** product that combines AI agent infrastructure with privacy-native architecture.

No other platform routes agent traffic through Tor, generates .onion services, integrates anonymous search, and runs local LLMs -- all in a single command.

**[Full market analysis, use cases, and competitive landscape ->](WHY.md)**

---

## Roadmap

- [x] v1.0 -- Core agent infrastructure (Ollama, n8n, Qdrant, sandbox)
- [x] v2.0 -- Security hardening (unified compose, isolated networks, health checks)
- [x] v3.0 -- Production-grade (Grafana, Prometheus, Portainer, monitoring)
- [x] v4.0 -- Agent Privacy Cloud (Tor rotator, Privoxy, Gotify, Agent Dashboard)

---

## License

[GNU Affero General Public License v3.0](LICENSE) -- Free as in freedom.

You can use, modify, and distribute this software. If you run a modified version as a service, you must release your changes under the same license.

---

## Disclaimer

This software is provided for legitimate privacy and security purposes. Users are responsible for complying with applicable laws in their jurisdiction. The authors do not endorse or encourage any illegal activity.

---

<div align="center">

**Your agent sovereignty starts with one command.**

```bash
bash install.sh --agents --tor --searxng --domain yourdomain.com
```

[Star this repo](../../stargazers) if you believe privacy is a right, not a feature.

</div>

---

## Related Projects

- **[Sovereign Stack](https://github.com/Michae2xl/sovereign-stack)** -- From Hero to Sovereign: the complete digital freedom journey for humans. Self-hosted Nextcloud, Matrix, Vaultwarden, Jitsi, Forgejo, Mail, and more. If you want human services alongside your agent cloud, start there.

---

## Donations

If Freedom Stack saved you time or protects your privacy, consider supporting the project.

All donations are received in privacy-preserving currencies.

**Zcash (Shielded -- fully private):** Send from any shielded wallet -- Mobile: [ZODL](https://electriccoin.co/zashi/), [Zingo](https://www.zingolabs.org/), [Ywallet](https://ywallet.app/), [Zkool](https://github.com/hhanh00/zkool2) -- Desktop: [Zingo](https://www.zingolabs.org/), [Ywallet](https://ywallet.app/), [Zkool](https://github.com/hhanh00/zkool2)
```
u12rrgyaz7hwyzf0px29ka43tvk7nu92w7mzc99yv9ld3pg96fp4ef0mxe5kd0j5544yc33jqe66fd5s0fjv7uvsxh0uz24c7fuw44wfwcg2g74jgg2ukmpvc0l4a7r56sgjrra35fy4f0k3spjn5uh6kqxx5elmuv3ajd7zjs8s973e0n
```

**Bitcoin:**
```
bc1qus6gvfyepx38apvdxvqh4qj8n3d0jssthzmlnx
```
