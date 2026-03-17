# Building Agents on Freedom Stack

## Internal Endpoints

| Service | Endpoint | Use |
|---------|----------|-----|
| Ollama | `http://ollama:11434/api/generate` | Local LLM inference |
| SearXNG | `http://searxng:8080/search?q=QUERY&format=json` | Anonymous search |
| Qdrant | `http://qdrant:6333` | Vector memory |
| Matrix | `http://synapse:8008/_matrix/client/v3` | E2E agent communication |
| Nextcloud | `http://nextcloud:80/remote.php/dav/files/` | Private storage |
| Gotify | `http://gotify:80/message` | Push notifications |
| Vaultwarden | `http://vaultwarden:80` | API key management |
| Tor SOCKS | `socks5h://tor-rotator:9050` | Anonymous external requests |
| Privoxy HTTP | `http://privoxy:8118` | HTTP proxy via Tor |

## Quick Start (inside the sandbox)

```bash
docker exec -it freedom-agent-sandbox bash
```

```python
import requests

# Anonymous search
results = requests.get(
    "http://searxng:8080/search",
    params={"q": "your query", "format": "json"}
).json()

# Local LLM (zero data to OpenAI)
response = requests.post("http://ollama:11434/api/generate", json={
    "model": "llama3.2:3b",
    "prompt": "Your prompt here",
    "stream": False
}).json()["response"]

# Anonymous external request via Tor
data = requests.get(
    "https://api.example.com",
    proxies={"https": "socks5h://tor-rotator:9050"}
).json()

# Push notification
requests.post("http://gotify:80/message", json={
    "title": "Agent done", "message": response[:200], "priority": 5
})
```

## Use Cases

- **Trading/Betting agents** — SearXNG + Ollama + Tor + Qdrant + Gotify
- **OSINT/Research** — Tor Rotator + Qdrant + Matrix + SearXNG
- **Agent Swarms** — Matrix E2E + Qdrant shared memory + n8n orchestration
- **Enterprise Private AI** — Ollama + Nextcloud + Vaultwarden
- **Investigative Journalism** — Tor + Matrix + Nextcloud + .onion
