---
name: agent-shielded
description: "Agent Shielded — Agent Privacy Cloud. Infraestrutura privada para AI agents em 1 comando: Ollama, n8n, Qdrant, Agent Sandbox, Tor Rotator, Privoxy, Gotify, Agent Dashboard + Prometheus, Grafana, Portainer. Zero dados vazam. Triggers: 'agent shielded', 'agent privacy', 'AI agent infrastructure', 'private LLM', 'Ollama setup', 'n8n workflows', 'vector database', 'agent sandbox', 'open source AI', 'agente privado', 'infraestrutura de agente', 'freedom stack agents'."
---

# Skill Agent Shielded — Freedom Stack Agent Privacy Cloud

> **1 comando. Zero dados vazam.** Infraestrutura privada completa para AI agents.

**Repo:** https://github.com/Michae2xl/freedom-stack

---

## O Que Esta Skill Faz

Instala o **Agent Privacy Cloud** completo de uma vez:

```bash
ssh root@SEU_VPS_IP
curl -fsSL https://raw.githubusercontent.com/Michae2xl/freedom-stack/main/scripts/install.sh -o install.sh
bash install.sh --agents --searxng --tor --security --domain seudominio.com

# Sem domínio (funciona via IP + Tor .onion):
bash install.sh --agents --searxng --tor --security
```

---

## Serviços Instalados

### Agent Privacy Cloud (8 componentes)

| Serviço | Porta | O que faz |
|---------|-------|-----------|
| **Ollama + Open WebUI** | :11434 / :8181 | LLM local — zero dados para OpenAI/Anthropic |
| **n8n** | :5678 | Orquestração visual de workflows AI |
| **Qdrant** | :6333 | Vector DB — memória semântica de longo prazo |
| **Agent Sandbox** | — | Python 3.12 + Node 20 isolado |
| **Tor Rotator** | :9060 | Novo circuit a cada 30s para scraping sem ban |
| **Privoxy** | :8118 | HTTP proxy via Tor — requests anônimos |
| **Gotify** | :8070 | Notificações push privadas pro celular |
| **Agent Dashboard** | :3333 | Status real-time de toda infra |

### Infraestrutura

| Serviço | Porta | Função |
|---------|-------|--------|
| **Prometheus** | :9090 | Métricas |
| **Grafana** | :3100 | Dashboards |
| **Portainer** | :9000 | Docker GUI |
| **SearXNG** | :8888 | Busca anônima (JSON API habilitada) |

---

## Fluxo do Agent

```
Agent (sandbox)
    ├──→ SearXNG      :8888  busca anônima — GET /search?q=QUERY&format=json
    ├──→ Ollama       :11434 LLM local — POST /api/generate
    ├──→ Qdrant       :6333  memória vetorial — PUT /collections/memory/points
    ├──→ Tor/Privoxy  :9060/:8118  rede anônima para requests externos
    ├──→ Gotify       :8070  notificações push pro dono
    └──→ n8n          :5678  orquestração de workflows complexos
```

### Exemplo de código (dentro do sandbox):

```python
import requests

# 1. Busca anônima (Google/Bing/DDG sem saber quem é)
results = requests.get(
    "http://searxng:8080/search",
    params={"q": "bitcoin price", "format": "json"}
).json()

# 2. Analisa com LLM local (zero dados pra cloud)
analysis = requests.post("http://ollama:11434/api/generate", json={
    "model": "llama3.2:3b",
    "prompt": f"Analyze: {results['results'][0]['content']}",
    "stream": False
}).json()["response"]

# 3. Salva memória vetorial (persistente)
requests.put("http://qdrant:6333/collections/memory/points", json={
    "points": [{"id": 1, "vector": [0.1]*384, "payload": {"analysis": analysis}}]
})

# 4. Request externo anônimo via Tor
data = requests.get(
    "https://api.example.com/data",
    proxies={"https": "socks5h://tor-rotator:9050"}
).json()

# 5. Notifica dono no celular
requests.post("http://gotify:80/message", json={
    "title": "Agent Alert", "message": analysis[:100], "priority": 5
})
```

---

## Use Cases

### 1. Trading / Betting Agents
Agent pesquisa odds via SearXNG → analisa com Ollama → executa via Tor (anônimo) → armazena em Qdrant → notifica via Gotify.

### 2. OSINT / Pesquisa
Scraping via Tor Rotator (novo circuit a cada 30s, sem ban) → findings em Qdrant como embeddings → cross-reference semântico.

### 3. Swarm de Agents
50+ agents em sandbox → comunicação via Matrix E2E → memória compartilhada em Qdrant → orquestração via n8n visual.

### 4. Enterprise Private AI
LLM local (Ollama, zero cloud) → storage GDPR-compliant → LGPD/HIPAA sem vendor cloud.

### 5. Jornalismo Investigativo AI
Agent monitora fontes via Tor → cruza dados → armazena evidências criptografadas → comunica via Matrix E2E + .onion.

---

## Como Usar Esta Skill

### Quando o usuário chegar, pergunte:

1. **Objetivo?** (que tipo de agent quer rodar?)
2. **Tem VPS?** (specs: 16GB+ RAM recomendado pra Ollama)
3. **Tem domínio?** (opcional — funciona via IP/Tor .onion)
4. **Quer serviços humanos também?** (se sim, use skill soberana junto)

### Baseado nas respostas:

| Situação | Comando |
|----------|---------|
| Agent Cloud completo | `--agents --searxng --tor --security` |
| Agent Cloud + domínio | `--agents --searxng --tor --security --domain X` |
| Agent Cloud + humano | `--all --domain X` (instala tudo) |
| Só Ollama + n8n (mínimo) | `--agents` |

---

## Requisitos

| | Mínimo | Recomendado |
|---|--------|-------------|
| **RAM** | 8GB (sem Ollama) | 16GB+ (com Ollama) |
| **CPU** | 2 vCPUs | 4+ vCPUs |
| **Disco** | 40GB | 100GB+ (modelos LLM: 2-7GB cada) |
| **OS** | Ubuntu 22.04 | Ubuntu 24.04 |
| **Custo** | ~€8/mês | ~€18/mês (Hetzner CX32) |

### Modelos Ollama recomendados
```bash
# Leve (2GB RAM, rápido)
docker exec freedom-ollama ollama pull llama3.2:3b

# Balanceado (5GB RAM)
docker exec freedom-ollama ollama pull llama3.1:8b

# Poderoso (12GB RAM)
docker exec freedom-ollama ollama pull llama3.1:70b
```

### VPS Providers Privacy-Friendly
| Provider | Privacidade | Preço (16GB) |
|----------|-------------|--------------|
| Hetzner | ★★★★☆ GDPR | €18/mês |
| Njalla | ★★★★★ Zero KYC | ~€30/mês |
| 1984.is | ★★★★★ Islândia | ~€25/mês |

---

## Troubleshooting

```bash
# Ver status
docker compose ps

# Logs de um serviço
docker compose logs freedom-ollama --tail 50

# Testar Tor
curl --socks5-hostname 127.0.0.1:9060 https://check.torproject.org/api/ip

# Testar SearXNG JSON
curl "http://localhost:8888/search?q=test&format=json"

# Testar Ollama
curl http://localhost:11434/api/generate -d '{"model":"llama3.2:3b","prompt":"hello","stream":false}'

# Liberar memória para Ollama
echo 3 > /proc/sys/vm/drop_caches

# Script de diagnóstico
bash scripts/troubleshoot.sh
```

### Bugs conhecidos e fixes (v4.0)
- **Stalwart Mail:** imagem correta é `stalwartlabs/stalwart:latest`
- **Agent Dashboard:** pacote npm correto é `dockerode` (não `docker-dockerode`)
- **Privoxy:** não depende do Tor — funciona independente
- **SearXNG JSON:** `formats: [html, json]` obrigatório no settings.yml
- **Ollama sem memória:** rodar `echo 3 > /proc/sys/vm/drop_caches` antes

---

## Posição de Mercado

```
                    PRIVACIDADE
                         ↑
                         │   ★ AGENT SHIELDED (Freedom Stack)
                         │     (privacy-native + agents)
                         │
            Njalla/1984  │
            (só VPS)     │    n8n AI Kit, Dify, LangChain
                         │    (self-hosted, sem privacidade real)
          ───────────────┼──────────────────────→ AI AGENTS
                         │
                         │    OpenAI / AWS / Google Cloud
                         │    (cloud, loga tudo)
```

**Único produto no quadrante alta privacidade + infraestrutura AI agents.**

---

## Relação com Sovereign Stack

| Projeto | Público | Foco |
|---------|---------|------|
| **Agent Shielded / Freedom Stack** (esta skill) | Devs/Agents AI | Agent Privacy Cloud |
| **Sovereign Stack** (skill soberana) | Humanos | Privacidade pessoal, degoogle |

Podem rodar **juntos no mesmo VPS** — são complementares.
