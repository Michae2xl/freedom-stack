# Freedom Stack — Launch Posts

## Hacker News (Show HN)

**Title:** `Show HN: Freedom Stack – The First Agent Privacy Cloud (34 containers, 1 command)`

**Text:**

I built an open-source privacy infrastructure stack that gives AI agents (and humans) a complete private environment with one command.

The problem: every AI agent today leaks data — searches go through Google, LLM calls go to OpenAI, storage lives on AWS, communication runs through Slack. Freedom Stack replaces all of that with self-hosted, privacy-native alternatives.

What you get with `bash install.sh --all`:

For AI agents: Ollama (local LLM), n8n (visual workflows), Qdrant (vector memory), isolated Python/Node sandbox, Tor proxy rotator for anonymous scraping, Privoxy, Gotify notifications, agent dashboard.

For humans: Nextcloud, Matrix/Element, Vaultwarden, Jitsi, SearXNG, Forgejo, Stalwart Mail, AdGuard, WireGuard.

Security: 3 isolated Docker networks, 23 health checks, all ports behind Caddy (127.0.0.1 only), 11 Tor .onion services, fail2ban + CrowdSec, AppArmor, encrypted backups with integrity verification.

The key differentiator from n8n's AI starter kit or Dify: none of them route through Tor, none have .onion services, none integrate E2E chat, VPN, private DNS, or anonymous payments. They're self-hosted. Freedom Stack is privacy-native.

34 containers. 1 unified docker-compose.yml. AGPL v3.

GitHub: [link]

---

## r/selfhosted

**Title:** `I built the first "Agent Privacy Cloud" — 34 containers, 1 command, privacy infrastructure for AI agents AND humans`

Hey r/selfhosted,

After months of running AI agents on my VPS and getting frustrated that every tool leaks data somewhere, I built Freedom Stack — a complete self-hosted stack that gives both AI agents and humans a fully private environment.

**What makes it different from the usual self-hosted stacks:**

- Not just Nextcloud + Matrix. Includes full AI agent infra: Ollama (local LLM), n8n (workflows), Qdrant (vector DB), isolated sandbox, Tor rotator
- Everything routes through Tor — 11 .onion services auto-generated
- 3 isolated Docker networks (compromised SearXNG can't touch your Nextcloud DB)
- 23 health checks, resource limits on every container, log rotation, ZRAM
- One unified docker-compose.yml, not 34 separate files
- Matrix registration closed by default
- Credentials GPG-encrypted after install
- Backup with SHA-256 integrity verification

**Full service list:** Nextcloud+Redis, Matrix/Synapse+PostgreSQL, Element, Vaultwarden, Jitsi, SearXNG, Forgejo+PostgreSQL, Stalwart Mail, AdGuard Home, WireGuard, Ollama+OpenWebUI, n8n, Qdrant, Agent Sandbox, Tor+Rotator, Privoxy, Gotify, Caddy, Prometheus, Grafana, Netdata, Portainer, Uptime Kuma, Watchtower, Rclone.

`bash install.sh --all --domain yourdomain.com` → 15 minutes → dashboard at your domain with all services live.

AGPL v3. GitHub: [link]

---

## r/privacy

**Title:** `Open-source "Agent Privacy Cloud" — run AI agents with zero data leaking to big tech (Tor, .onion, E2E, local LLM)`

For everyone here who's tired of AI tools sending your data everywhere:

Freedom Stack is a 1-command installer that gives you a fully private AI + productivity environment on your own VPS. No Google, no OpenAI, no AWS.

**What AI agents get:** Local LLM (Ollama), anonymous search (SearXNG), anonymous web access (Tor rotator), vector memory (Qdrant), visual workflows (n8n), private notifications (Gotify).

**What you get:** Nextcloud (replace Google Drive), Matrix (replace WhatsApp), Vaultwarden (replace LastPass), Jitsi (replace Zoom), SearXNG (replace Google Search), WireGuard VPN, AdGuard DNS ad blocker.

**Privacy architecture:**
- All traffic routable through Tor
- 11 .onion hidden services auto-generated
- WireGuard VPN for always-on encryption
- AdGuard Home blocks trackers at DNS level
- Matrix uses E2E encryption
- Credentials encrypted with GPG AES-256
- Zcash/ZODL for anonymous payments
- 3 isolated Docker networks
- No ports exposed except through Caddy reverse proxy

AGPL v3. One command. 34 containers. GitHub: [link]

---

## r/degoogle

**Title:** `Freedom Stack — replace Google (and everything else) with 1 command. Open source, self-hosted, includes AI agent infra.`

Degoogling checklist that Freedom Stack handles:

- [x] Google Drive → **Nextcloud** (with Redis cache)
- [x] Google Search → **SearXNG** (your server)
- [x] Gmail → **Stalwart Mail** (self-hosted)
- [x] Google Meet → **Jitsi Meet**
- [x] Google Chat → **Matrix/Element** (E2E encrypted)
- [x] Google DNS → **AdGuard Home** (blocks ads too)
- [x] Google Calendar/Contacts → **Nextcloud** (CalDAV/CardDAV)
- [x] Chrome → **Firefox hardened** + **Tor Browser**
- [x] Google Photos → **Nextcloud** auto-upload
- [x] Google Authenticator → **Aegis** (F-Droid)
- [x] Google Passwords → **Vaultwarden** (Bitwarden self-hosted)
- [x] YouTube → **NewPipe** / **FreeTube**
- [x] Play Store → **F-Droid**

BONUS: Also includes AI agent privacy infrastructure (Ollama, n8n, Qdrant, Tor rotator) if you want to run AI agents without big tech seeing anything.

`bash install.sh --all --domain yourdomain.com`

34 containers. 15 minutes. AGPL v3. GitHub: [link]

---

## Twitter/X Thread

**Tweet 1:**
🛡️ I just open-sourced the first "Agent Privacy Cloud"

34 containers. 1 command. Zero big tech.

Privacy infrastructure for AI agents AND humans.

🧵 Thread:

**Tweet 2:**
The problem: every AI agent today leaks your data.

→ Searches: Google sees everything
→ LLM calls: OpenAI logs it all
→ Storage: AWS reads your data
→ Payments: Stripe tracks transactions

Freedom Stack fixes all of this. Self-hosted. Tor-routed. E2E encrypted.

**Tweet 3:**
What you get with 1 command:

🧠 Ollama — local LLM (no OpenAI)
🔍 SearXNG — private search
🗄️ Qdrant — agent memory (vectors)
⚡ n8n — visual agent workflows
🧅 Tor — 11 .onion services
🔒 WireGuard — personal VPN
☁️ Nextcloud — your cloud
💬 Matrix — E2E chat

+22 more services

**Tweet 4:**
What nobody else has:

✅ Tor routing + .onion for agents
✅ Anonymous search (SearXNG)
✅ E2E chat between agents (Matrix)
✅ Private DNS (AdGuard)
✅ Anonymous payments (Zcash)
✅ Human + Agent stack combined

n8n AI Kit, Dify, LangChain = self-hosted
Freedom Stack = privacy-NATIVE

**Tweet 5:**
Try it:

```
bash install.sh --all --domain yourdomain.com
```

15 minutes → visual dashboard → everything live.

34 containers, 3 isolated networks, 23 health checks, auto-updates, encrypted backups.

AGPL v3 → github.com/YOUR_USER/freedom-stack

Star if you believe privacy is a right ⭐
