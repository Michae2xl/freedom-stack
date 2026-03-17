# FASE 3 — Apps FOSS: Substituir TUDO Proprietário

## A Grande Tabela de Substituição

### 📁 Escritório & Produtividade

| Proprietário | FOSS | Como Instalar | Nota |
|-------------|------|---------------|------|
| Microsoft Office | **LibreOffice** | `sudo apt install libreoffice` | Compatível com .docx/.xlsx/.pptx |
| Google Docs | **Nextcloud Office** | Via Fase 4 (VPS) | Colaborativo, no seu servidor |
| Notion | **Joplin** | `flatpak install flathub net.cozic.joplin_desktop` | Sync via Nextcloud, E2E criptografado |
| Notion | **Logseq** | `flatpak install flathub com.logseq.Logseq` | Baseado em grafos, dados locais |
| Evernote | **Standard Notes** | `flatpak install flathub org.standardnotes.standardnotes` | E2E encrypted |
| OneNote | **Joplin** | mesmo acima | Markdown, tags, notebooks |
| Trello | **Planka** | Docker no VPS | Kanban self-hosted |

### 💬 Comunicação

| Proprietário | FOSS | Como Instalar | Nota |
|-------------|------|---------------|------|
| WhatsApp | **Signal** | `flatpak install flathub org.signal.Signal` | E2E, código aberto, sem metadados |
| WhatsApp | **Element (Matrix)** | Via Fase 4 (VPS) | Federado, seu servidor |
| Slack/Discord | **Element** | mesmo acima | Salas, threads, calls |
| Telegram | **SimpleX Chat** | https://simplex.chat | Sem ID de usuário, máxima privacidade |
| Telegram | **Briar** | F-Droid (mobile) | P2P via Tor, funciona sem internet (Bluetooth) |
| Zoom/Meet | **Jitsi Meet** | Via Fase 4 (VPS) | Sem conta necessária, E2E |
| FaceTime | **Jami** | `sudo apt install jami` | P2P, sem servidor central |

### 📧 Email

| Proprietário | FOSS | Como Instalar | Nota |
|-------------|------|---------------|------|
| Gmail/Outlook (client) | **Thunderbird** | `sudo apt install thunderbird` | Multi-conta, calendário, PGP |
| Gmail (serviço) | **ProtonMail** | https://proton.me | E2E, Suíça (não é 100% FOSS mas o client é) |
| Gmail (serviço) | **Tutanota** | https://tutanota.com | E2E, Alemanha, client FOSS |

### 🎨 Criação & Mídia

| Proprietário | FOSS | Como Instalar | Nota |
|-------------|------|---------------|------|
| Photoshop | **GIMP** | `sudo apt install gimp` | Editor de imagens completo |
| Illustrator | **Inkscape** | `sudo apt install inkscape` | Vetores/SVG |
| Premiere Pro | **Kdenlive** | `sudo apt install kdenlive` | Edição de vídeo profissional |
| After Effects | **Natron** | `flatpak install flathub fr.natron.Natron` | Compositing/VFX |
| Audacity | **Audacity** | `sudo apt install audacity` | Já é FOSS! |
| GarageBand | **LMMS** | `sudo apt install lmms` | Produção musical |
| OBS Studio | **OBS Studio** | `sudo apt install obs-studio` | Já é FOSS! |

### 🎵 Mídia & Entretenimento

| Proprietário | FOSS | Como Instalar | Nota |
|-------------|------|---------------|------|
| iTunes/Spotify player | **VLC** | `sudo apt install vlc` | Toca TUDO |
| Spotify | **Spotube** | `flatpak install flathub com.github.KRTirtho.Spotube` | Client alternativo |
| YouTube | **FreeTube** | `flatpak install flathub io.freetubeapp.FreeTube` | YouTube sem rastreamento |
| YouTube (mobile) | **NewPipe** | F-Droid | YouTube sem Google, download |
| Kindle | **Calibre** | `sudo apt install calibre` | Gerenciador de e-books |
| Apple Podcasts | **AntennaPod** | F-Droid (mobile) | Podcasts FOSS |

### 🔐 Segurança & Senhas

**Estratégia: Vaultwarden (principal) + KeePassXC (backup offline)**

| Uso | Ferramenta | Por quê? |
|-----|-----------|----------|
| **Dia-a-dia (todas as senhas)** | **Vaultwarden** (VPS) | Sync entre PC/celular/browser via Bitwarden apps |
| **Backup offline da master password** | **KeePassXC** (local) | Guarda master password + recovery codes. NUNCA na nuvem |
| **2FA (autenticação 2 fatores)** | **Aegis** (mobile) | TOTP FOSS, backup criptografado |

| Proprietário | FOSS | Como Instalar | Nota |
|-------------|------|---------------|------|
| LastPass/1Password | **Vaultwarden** | Via Fase 4 (VPS) | PRIMARY: Bitwarden self-hosted, sync todos devices |
| — | **KeePassXC** | `sudo apt install keepassxc` | BACKUP ONLY: master passwords + recovery offline |
| Google Authenticator | **Aegis** | F-Droid (mobile) | 2FA FOSS, backup criptografado |

### 💰 Crypto & Pagamentos Privados

| Proprietário | FOSS | Como Instalar | Nota |
|-------------|------|---------------|------|
| PayPal/Venmo | **ZODL (Zcash)** | F-Droid / App Store / https://zodl.com | Pagamentos 100% privados (shielded), criado pelos inventores do Zcash |
| Coinbase/Binance wallet | **ZODL** | mesmo acima | Self-custody, sem KYC, sem rastreamento |
| Metamask | **Cake Wallet** | F-Droid / https://cakewallet.com | Multi-moeda (XMR, BTC, ZEC), shielded |
| Cash App | **Zingo!** | F-Droid | Wallet Zcash alternativa, shielded + memos |
| — | **Monero GUI** | https://getmonero.org/downloads | Privacidade por padrão, fungível |

**Por que ZODL?**
- Criado pelos **desenvolvedores originais do protocolo Zcash** (saíram da ECC e fundaram a ZODL Inc.)
- 100% open source — qualquer um pode auditar o código
- Shielded por padrão — transações privadas no blockchain (zero-knowledge proofs)
- Não coleta, rastreia ou vê sua atividade de carteira
- Suporta swaps privados (cross-chain via NEAR Intents)
- Compatível com hardware wallet Keystone (air-gapped)
- Pague em lojas físicas com privacidade

### ☁️ Cloud & Sync

| Proprietário | FOSS | Como Instalar | Nota |
|-------------|------|---------------|------|
| Google Drive/Dropbox | **Nextcloud** | Via Fase 4 (VPS) | Seu cloud completo |
| Google Photos | **Nextcloud** | mesmo acima | Upload automático do celular |
| iCloud | **Nextcloud + Rclone** | Via Fase 4 (VPS) | Sync + backup criptografado |
| Google Calendar | **Nextcloud Calendar** | mesmo acima | CalDAV, sync com Thunderbird |
| Google Contacts | **Nextcloud Contacts** | mesmo acima | CardDAV, sync com celular |

### 🛠️ Desenvolvimento

| Proprietário | FOSS | Como Instalar | Nota |
|-------------|------|---------------|------|
| VS Code | **VSCodium** | `flatpak install flathub com.vscodium.codium` | VS Code sem telemetria Microsoft |
| GitHub | **Forgejo/Gitea** | Docker no VPS | Git self-hosted |
| Postman | **Bruno** | `flatpak install flathub com.usebruno.Bruno` | API client FOSS |
| Figma | **Penpot** | Docker no VPS | Design tool self-hosted |

### 📱 Sistema (Android)

| Proprietário | FOSS | Como Instalar | Nota |
|-------------|------|---------------|------|
| Google Play Store | **F-Droid** | https://f-droid.org | Loja de apps 100% FOSS |
| Google Play Store | **Aurora Store** | F-Droid | Acessa Play Store sem conta Google |
| Google Keyboard | **OpenBoard** | F-Droid | Teclado sem espionagem |
| Google Maps | **OsmAnd+** | F-Droid | OpenStreetMap offline |
| Chrome (mobile) | **Mull** | F-Droid | Firefox hardened pra Android |
| YouTube | **NewPipe** | F-Droid | Sem ads, download, background play |
| Google Camera | **Open Camera** | F-Droid | Câmera sem envio de dados |
| Google Files | **Material Files** | F-Droid | Gerenciador de arquivos |

---

## Como Instalar Apps FOSS

### Método 1: APT (mais fácil)
```bash
sudo apt install nome-do-app
# Exemplo: sudo apt install gimp inkscape vlc thunderbird
```

### Método 2: Flatpak (mais apps, sandboxed)
```bash
# Instalar Flatpak (se não tiver):
sudo apt install flatpak -y
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

# Instalar app:
flatpak install flathub nome.do.App
# Exemplo: flatpak install flathub org.signal.Signal
```

### Método 3: AppImage (portátil, sem instalar)
```bash
# Baixar o .AppImage do site oficial
chmod +x NomeDoApp.AppImage
./NomeDoApp.AppImage
```

### Método 4: F-Droid (mobile Android)
```
1. No celular Android, acesse: https://f-droid.org
2. Baixe o APK do F-Droid
3. Instale (ative "Fontes desconhecidas" nas configurações)
4. Abra F-Droid e busque os apps
```

---

## Kit Inicial Recomendado (Instalar Tudo de Uma Vez)

```bash
# Desktop Linux — copie e cole no terminal:
sudo apt update && sudo apt install -y \
  firefox thunderbird \
  libreoffice gimp inkscape \
  vlc audacity obs-studio \
  keepassxc \
  kdenlive \
  git curl wget

# Flatpak extras:
flatpak install flathub -y \
  org.signal.Signal \
  net.cozic.joplin_desktop \
  io.freetubeapp.FreeTube \
  com.vscodium.codium

echo "✓ Kit FOSS básico instalado!"
```

## Android — Kit FOSS via F-Droid

Depois de instalar F-Droid, busque e instale:
1. **NewPipe** — YouTube sem Google
2. **Aegis** — 2FA (autenticação 2 fatores)
3. **ZODL** — Carteira Zcash (pagamentos privados)
4. **OpenBoard** — Teclado
5. **OsmAnd+** — Mapas offline
6. **Mull** — Browser (Firefox hardened)
7. **AntennaPod** — Podcasts
8. **Material Files** — Gerenciador de arquivos
9. **Nextcloud** — Sync com seu cloud
10. **Element** — Chat Matrix
11. **WireGuard** — VPN

---

## Dica: Android sem Google (GrapheneOS / LineageOS)

Para privacidade máxima no celular:

**GrapheneOS** (Pixel phones apenas):
- Android sem Google, hardened
- Sandboxed Google Play Services (opcional, compatibilidade)
- https://grapheneos.org

**LineageOS** (muitos aparelhos):
- Android sem Google, código aberto
- Mais aparelhos suportados que GrapheneOS
- https://lineageos.org

Ambos usam F-Droid como loja principal de apps.
