---
name: agent-shielded
description: "Agent Shielded — Agent Privacy Cloud. Private infrastructure for AI agents in one command: Ollama, n8n, Qdrant, Agent Sandbox, Tor Rotator, Privoxy, Gotify, Agent Dashboard + Prometheus, Grafana, Portainer. Zero data leaks. Triggers: 'agent shielded', 'agent privacy', 'AI agent infrastructure', 'private LLM', 'Ollama setup', 'n8n workflows', 'vector database', 'agent sandbox', 'open source AI', 'private agent', 'agent infrastructure', 'freedom stack agents'."
---

# Skill Agent Shielded — Freedom Stack Agent Privacy Cloud

> **1 command. Zero data leaks.** Complete private infrastructure for AI agents.

**Repo:** https://github.com/Michae2xl/freedom-stack

---

## What This Skill Does

Installs the full **Agent Privacy Cloud** at once:

```bash
ssh root@YOUR_VPS_IP
curl -fsSL https://raw.githubusercontent.com/Michae2xl/freedom-stack/main/scripts/install.sh -o install.sh
bash install.sh --agents --searxng --tor --security --domain yourdomain.com

# No domain (works via IP + Tor .onion):
bash install.sh --agents --searxng --tor --security
```

---

## Installed Services

### Agent Privacy Cloud (8 components)

| Service | Port | What It Does |
|---------|------|--------------|
| **Ollama + Open WebUI** | :11434 / :8181 | Local LLM — zero data to OpenAI/Anthropic |
| **n8n** | :5678 | Visual AI workflow orchestration |
| **Qdrant** | :6333 | Vector DB — long-term semantic memory |
| **Agent Sandbox** | — | Isolated Python 3.12 + Node 20 |
| **Tor Rotator** | :9060 | New circuit every 30s for scraping without bans |
| **Privoxy** | :8118 | HTTP proxy via Tor — anonymous requests |
| **Gotify** | :8070 | Private push notifications to phone |
| **Agent Dashboard** | :3333 | Real-time status of all infra |

### Infrastructure

| Service | Port | Function |
|---------|------|----------|
| **Prometheus** | :9090 | Metrics |
| **Grafana** | :3100 | Dashboards |
| **Portainer** | :9000 | Docker GUI |
| **SearXNG** | :8888 | Anonymous search (JSON API enabled) |

---

## Agent Flow

```
Agent (sandbox)
    |---> SearXNG      :8888  anonymous search — GET /search?q=QUERY&format=json
    |---> Ollama       :11434 local LLM — POST /api/generate
    |---> Qdrant       :6333  vector memory — PUT /collections/memory/points
    |---> Tor/Privoxy  :9060/:8118  anonymous network for external requests
    |---> Gotify       :8070  push notifications to owner
    |---> n8n          :5678  complex workflow orchestration
```

### Code example (inside the sandbox):

```python
import requests

# 1. Anonymous search (Google/Bing/DDG never know who you are)
results = requests.get(
    "http://searxng:8080/search",
    params={"q": "bitcoin price", "format": "json"}
).json()

# 2. Analyze with local LLM (zero data to cloud)
analysis = requests.post("http://ollama:11434/api/generate", json={
    "model": "llama3.2:3b",
    "prompt": f"Analyze: {results['results'][0]['content']}",
    "stream": False
}).json()["response"]

# 3. Store vector memory (persistent)
requests.put("http://qdrant:6333/collections/memory/points", json={
    "points": [{"id": 1, "vector": [0.1]*384, "payload": {"analysis": analysis}}]
})

# 4. Anonymous external request via Tor
data = requests.get(
    "https://api.example.com/data",
    proxies={"https": "socks5h://tor-rotator:9050"}
).json()

# 5. Notify owner on phone
requests.post("http://gotify:80/message", json={
    "title": "Agent Alert", "message": analysis[:100], "priority": 5
})
```

---

## Use Cases

### 1. Trading / Betting Agents
Agent searches odds via SearXNG → analyzes with Ollama → executes via Tor (anonymous) → stores in Qdrant → notifies via Gotify.

### 2. OSINT / Research
Scraping via Tor Rotator (new circuit every 30s, no IP bans) → findings stored in Qdrant as embeddings → semantic cross-reference.

### 3. Agent Swarms
50+ agents in sandbox → communication via Matrix E2E → shared memory in Qdrant → orchestration via n8n visual workflows.

### 4. Enterprise Private AI
Local LLM (Ollama, zero cloud) → GDPR-compliant storage → HIPAA without cloud vendors.

### 5. Investigative Journalism AI
Agent monitors sources via Tor → cross-references data → stores encrypted evidence → communicates via Matrix E2E + .onion.

---

## How To Use This Skill

### When the user arrives, ask:

1. **Goal?** (what type of agent do you want to run?)
2. **Have a VPS?** (specs: 16GB+ RAM recommended for Ollama)
3. **Have a domain?** (optional — works via IP/Tor .onion)
4. **Want human services too?** (if yes, use the soberana skill alongside)

### Based on answers:

| Situation | Command |
|-----------|---------|
| Full Agent Cloud | `--agents --searxng --tor --security` |
| Agent Cloud + domain | `--agents --searxng --tor --security --domain X` |
| Agent Cloud + human services | `--all --domain X` (installs everything) |
| Ollama + n8n only (minimal) | `--agents` |

---

## Requirements

| | Minimum | Recommended |
|---|---------|-------------|
| **RAM** | 8GB (without Ollama) | 16GB+ (with Ollama) |
| **CPU** | 2 vCPUs | 4+ vCPUs |
| **Disk** | 40GB | 100GB+ (LLM models: 2-7GB each) |
| **OS** | Ubuntu 22.04 | Ubuntu 24.04 |
| **Cost** | ~EUR 8/mo | ~EUR 18/mo (Hetzner CX32) |

### Recommended Ollama Models
```bash
# Light (2GB RAM, fast)
docker exec freedom-ollama ollama pull llama3.2:3b

# Balanced (5GB RAM)
docker exec freedom-ollama ollama pull llama3.1:8b

# Powerful (12GB RAM)
docker exec freedom-ollama ollama pull llama3.1:70b
```

### Privacy-Friendly VPS Providers
| Provider | Privacy | Price (16GB) |
|----------|---------|--------------|
| Hetzner | High, GDPR | EUR 18/mo |
| Njalla | Maximum, Zero KYC | ~EUR 30/mo |
| 1984.is | Maximum, Iceland | ~EUR 25/mo |

---

## Troubleshooting

```bash
# Check status
docker compose ps

# Service logs
docker compose logs freedom-ollama --tail 50

# Test Tor
curl --socks5-hostname 127.0.0.1:9060 https://check.torproject.org/api/ip

# Test SearXNG JSON
curl "http://localhost:8888/search?q=test&format=json"

# Test Ollama
curl http://localhost:11434/api/generate -d '{"model":"llama3.2:3b","prompt":"hello","stream":false}'

# Free memory for Ollama
echo 3 > /proc/sys/vm/drop_caches

# Full diagnostic script
bash scripts/troubleshoot.sh
```

### Known bugs and fixes (v4.0)
- **Stalwart Mail:** correct image is `stalwartlabs/stalwart:latest`
- **Agent Dashboard:** correct npm package is `dockerode` (not `docker-dockerode`)
- **Privoxy:** does not depend on Tor — works independently
- **SearXNG JSON:** `formats: [html, json]` required in settings.yml
- **Ollama out of memory:** run `echo 3 > /proc/sys/vm/drop_caches` first

---

## Market Position

```
                    PRIVACY
                         |
                         |   * AGENT SHIELDED (Freedom Stack)
                         |     (privacy-native + agents)
                         |
            Njalla/1984  |
            (VPS only)   |    n8n AI Kit, Dify, LangChain
                         |    (self-hosted, no real privacy)
          ---------------+------------------------> AI AGENTS
                         |
                         |    OpenAI / AWS / Google Cloud
                         |    (cloud, logs everything)
```

**The only product in the high-privacy + AI agent infrastructure quadrant.**

---

## Relation to Sovereign Stack

| Project | Audience | Focus |
|---------|----------|-------|
| **Agent Shielded / Freedom Stack** (this skill) | Devs/AI Agents | Agent Privacy Cloud |
| **Sovereign Stack** (soberana skill) | Humans | Personal privacy, degoogle |

They can run **together on the same VPS** — fully complementary.
