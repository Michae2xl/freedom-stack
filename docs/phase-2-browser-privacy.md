# FASE 2 — Browser & Navegação Privada

## Estratégia: 3 Browsers, 3 Usos

| Browser | Quando Usar | Privacidade |
|---------|-------------|-------------|
| **Tor Browser** | Pesquisas sensíveis, anonimato total | ★★★★★ |
| **Firefox Hardened** | Navegação diária, trabalho | ★★★★☆ |
| **Brave** | Sites que quebram no Firefox, alternativa rápida | ★★★☆☆ |

---

## 2.1 — Tor Browser

**O que é:** Firefox modificado que roteia TUDO pela rede Tor. Seu IP real é invisível.

**Instalar:**
```bash
# Linux — via Flatpak (mais fácil):
flatpak install flathub com.github.nickvergessen.TorBrowser -y

# Ou download direto:
# https://www.torproject.org/download/
# Extrair e rodar: ./start-tor-browser.desktop
```

**Quando usar:**
- Pesquisas que você não quer ligadas a você
- Acessar serviços .onion
- Quando privacidade > velocidade
- Em WiFi público

**NÃO faça no Tor:**
- Login em contas pessoais (Gmail, Facebook) — liga sua identidade
- Torrents — sobrecarrega a rede e vaza IP
- Maximizar a janela — o tamanho da tela pode identificar você

---

## 2.2 — Firefox Hardened (Uso Diário)

**Instalar Firefox:**
```bash
sudo apt install firefox -y    # Debian/Ubuntu
sudo dnf install firefox -y    # Fedora
```

**Configurar privacidade (about:config):**

Abra Firefox → digite `about:config` na barra → aceite o risco → mude:

```
// Bloquear telemetria
toolkit.telemetry.enabled → false
toolkit.telemetry.unified → false
browser.newtabpage.activity-stream.feeds.telemetry → false
browser.ping-centre.telemetry → false

// Bloquear rastreamento
privacy.trackingprotection.enabled → true
privacy.trackingprotection.socialtracking.enabled → true
privacy.firstparty.isolate → true
network.cookie.cookieBehavior → 5 (bloqueia cross-site cookies)

// Desabilitar WebRTC (vaza IP real mesmo com VPN!)
media.peerconnection.enabled → false

// DNS-over-HTTPS
network.trr.mode → 3 (forçar DoH)
network.trr.uri → https://dns.quad9.net/dns-query

// Desabilitar APIs de rastreamento
dom.battery.enabled → false
geo.enabled → false
media.navigator.enabled → false
webgl.disabled → true

// Resistir a fingerprinting
privacy.resistFingerprinting → true
```

**Extensões essenciais (instale todas):**

| Extensão | O que faz | Link |
|----------|----------|------|
| **uBlock Origin** | Bloqueia ads e trackers | addons.mozilla.org |
| **NoScript** | Bloqueia JavaScript por padrão | addons.mozilla.org |
| **HTTPS Everywhere** | Força HTTPS em todo site | addons.mozilla.org |
| **Cookie AutoDelete** | Apaga cookies ao fechar aba | addons.mozilla.org |
| **Decentraleyes** | Bloqueia CDNs de rastreamento | addons.mozilla.org |
| **CanvasBlocker** | Impede fingerprinting | addons.mozilla.org |
| **ClearURLs** | Remove trackers de URLs | addons.mozilla.org |

**Instalar todas via terminal:**
```bash
# Abra Firefox e acesse cada link, ou use a loja de extensões
# Busque por nome em: addons.mozilla.org
```

---

## 2.3 — Brave (Alternativa Rápida)

**Quando usar:** sites que quebram no Firefox hardened (bancos, streaming).

**Instalar:**
```bash
sudo curl -fsSLo /usr/share/keyrings/brave-browser-archive-keyring.gpg \
  https://brave-browser-apt-release.s3.brave.com/brave-browser-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/brave-browser-archive-keyring.gpg] \
  https://brave-browser-apt-release.s3.brave.com/ stable main" | \
  sudo tee /etc/apt/sources.list.d/brave-browser-release.list
sudo apt update && sudo apt install brave-browser -y
```

**Configurar:**
- Settings → Shields → Aggressive (bloqueia tudo)
- Settings → Search engine → DuckDuckGo ou SearXNG
- Settings → Privacy → "Send Do Not Track" → ON
- Settings → Privacy → Desabilitar "Phone home" features

---

## 2.4 — Motor de Busca Privado

**Substituir Google por:**

| Buscador | Privacidade | Nota |
|----------|-------------|------|
| **SearXNG** | ★★★★★ | Metabuscador, pode hospedar próprio no VPS |
| **DuckDuckGo** | ★★★★☆ | Fácil, bons resultados, baseado nos EUA |
| **Startpage** | ★★★★☆ | Resultados do Google sem rastreamento |
| **Brave Search** | ★★★☆☆ | Index próprio, independente do Google |

**SearXNG self-hosted** (no seu VPS da Fase 4):
```bash
# Adicionar ao Freedom Stack — container Docker
docker run -d --name searxng \
  -p 8888:8080 \
  -v /opt/freedom-stack/searxng:/etc/searxng \
  --restart unless-stopped \
  searxng/searxng:latest
```

---

## 2.5 — DNS Privado

**Por que importa:** seu provedor de internet vê TODOS os sites que você acessa via DNS. Mesmo com HTTPS.

**Opções:**

| DNS | Privacidade | Extra |
|-----|-------------|-------|
| **Quad9** (9.9.9.9) | ★★★★★ | Bloqueia malware, Suíça |
| **Mullvad DNS** | ★★★★★ | Sem logs, Suécia |
| **Cloudflare** (1.1.1.1) | ★★★☆☆ | Rápido, mas empresa dos EUA |
| **AdGuard Home** (seu VPS) | ★★★★★ | Você controla TUDO |

**Melhor setup:** WireGuard VPN (Fase 4) + AdGuard Home no VPS = todo DNS passa pelo SEU servidor.

---

## 2.6 — Comportamento de Navegação

Tecnologia não resolve tudo. Hábitos importam:

```
✅ FAÇA:
- Use senhas únicas por site (KeePassXC ou Vaultwarden)
- Ative 2FA em tudo (preferencialmente com app, não SMS)
- Feche abas que não está usando
- Limpe cookies regularmente
- Use containers no Firefox (Multi-Account Containers)
- Verifique URLs antes de clicar

❌ NÃO FAÇA:
- Login em conta pessoal no Tor Browser
- Mesmo browser pra vida pessoal e trabalho
- Clicar em links de email sem verificar
- Salvar senhas no browser (use gerenciador dedicado)
- Aceitar todos os cookies automaticamente
- Usar a mesma senha em múltiplos sites
```
