# FASE 5 — Conexão Total: Tudo Integrado

Agora que você tem o computador configurado (Fase 1), browsers seguros (Fase 2), apps FOSS (Fase 3), e VPS rodando (Fase 4), é hora de conectar tudo.

---

## 5.1 — Conectar WireGuard VPN (Computador + Celular)

### No Computador Linux:
```bash
# Instalar WireGuard:
sudo apt install wireguard -y

# Pegar a config do VPS:
scp root@SEU_VPS:/opt/freedom-stack/wireguard/config/peer1/peer.conf ~/wg-freedom.conf

# Ativar:
sudo cp ~/wg-freedom.conf /etc/wireguard/wg0.conf
sudo wg-quick up wg0

# Verificar (deve mostrar endpoint do VPS):
sudo wg show

# Ativar na inicialização:
sudo systemctl enable wg-quick@wg0
```

### No Celular Android:
```
1. Instale WireGuard do F-Droid
2. No VPS, mostre o QR code:
   cat /opt/freedom-stack/wireguard/config/peer2/qr.txt
3. No app WireGuard → "+" → "Escanear QR code"
4. Ative o túnel
5. (Opcional) Configure para conectar automaticamente em redes não confiáveis
```

### No iPhone:
```
1. Instale WireGuard da App Store
2. Mesmo processo do QR code acima
```

**Teste:** Acesse https://whatismyipaddress.com — deve mostrar o IP do VPS, não o seu.

---

## 5.2 — Configurar Nextcloud (Computador + Celular)

### Primeiro acesso (browser):
```
1. Acesse: https://cloud.seudominio.com (ou http://IP_VPS:8080)
2. Login com as credenciais do freedom-stack-credentials.txt
3. Mude a senha de admin imediatamente
4. Crie um usuário pessoal (não use admin no dia a dia)
```

### Sync no Computador Linux:
```bash
# Instalar client Nextcloud:
sudo apt install nextcloud-desktop -y
# Ou: flatpak install flathub com.nextcloud.desktopclient.nextcloud

# Abrir e configurar:
# Server: https://cloud.seudominio.com
# Login com seu usuário
# Escolher pastas para sincronizar
```

### Sync no Celular:
```
1. Instale "Nextcloud" do F-Droid
2. Abra → adicionar conta → URL do servidor
3. Login
4. Ativar:
   - Upload automático de fotos ✓
   - Sync de contatos ✓
   - Sync de calendário ✓
```

### Sync de Contatos (substituir Google Contacts):
```
Android:
1. Instale "DAVx⁵" do F-Droid
2. Abra → adicionar conta → URL do Nextcloud
3. Login → selecionar "Contatos" e "Calendários"
4. Seus contatos/calendários agora sincronizam com SEU servidor

Linux (Thunderbird):
1. Thunderbird → Ferramentas → Livro de Endereços
2. Novo → CardDAV → URL: https://cloud.seudominio.com/remote.php/dav
3. Login
```

### Sync de Calendário:
```
Thunderbird:
1. Agenda → Novo Calendário → Rede
2. CalDAV → URL: https://cloud.seudominio.com/remote.php/dav
3. Login

GNOME Calendar:
1. Settings → Online Accounts → Nextcloud
2. URL do servidor + login
```

---

## 5.3 — Configurar Element/Matrix (Chat Criptografado)

### No Computador:
```bash
# Instalar Element Desktop:
flatpak install flathub im.riot.Riot -y

# Abrir → "Sign in" → Homeserver: https://chat.seudominio.com
# Criar conta ou usar o admin
```

### No Celular:
```
1. Instale "Element" do F-Droid (ou Play Store via Aurora Store)
2. Abra → mudar homeserver → https://chat.seudominio.com
3. Login ou criar conta
4. Verificar dispositivo (cross-signing) para E2E
```

### Convidar pessoas:
```
- Dê a elas o endereço do homeserver
- Elas criam conta (se registration estiver habilitado)
- Ou crie contas para elas pelo admin do Synapse
```

---

## 5.4 — Configurar Vaultwarden (Senhas)

### No Computador:
```
1. Acesse: https://vault.seudominio.com
2. Crie sua conta (email + master password MUITO forte)
3. Instale a extensão Bitwarden no Firefox:
   - addons.mozilla.org → buscar "Bitwarden"
   - Config → Self-hosted → URL: https://vault.seudominio.com
   - Login
```

### No Celular:
```
1. Instale "Bitwarden" do F-Droid (versão FOSS)
2. Config → Self-hosted → URL: https://vault.seudominio.com
3. Login
4. Ativar auto-fill nas configurações do Android
```

### Migrar senhas do Chrome/outro gerenciador:
```
1. Chrome → Configurações → Senhas → Exportar (CSV)
2. Vaultwarden web → Tools → Import → Chrome CSV
3. Depois de verificar que tudo importou: APAGUE o CSV!
4. Desative o gerenciador de senhas do Chrome
```

---

## 5.5 — Configurar AdGuard Home (DNS Privado + Ad Blocking)

### Primeiro acesso:
```
1. Acesse: http://IP_VPS:3000
2. Complete o setup wizard
3. Defina usuário e senha admin
4. O dashboard mostra queries bloqueadas em tempo real
```

### Usar como DNS no Computador:
```bash
# Se já usa WireGuard VPN, configure o DNS do WireGuard para o AdGuard:
# Editar /etc/wireguard/wg0.conf:
# DNS = 10.13.13.1  (IP interno do VPS na rede WireGuard)

# Ou configurar direto:
echo "nameserver IP_DO_VPS" | sudo tee /etc/resolv.conf
sudo chattr +i /etc/resolv.conf
```

### Usar como DNS no Celular:
```
Via WireGuard (recomendado):
- O DNS já está configurado no perfil WireGuard

Direto (Android 9+):
- Settings → Network → Private DNS → dns.seudominio.com
```

### Listas de bloqueio recomendadas:
```
No AdGuard Home → Filters → DNS Blocklists → Add:
- AdGuard DNS filter (padrão)
- OISD Big List: https://big.oisd.nl
- Steven Black hosts: https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts
```

---

## 5.6 — Configurar Jitsi Meet (Videochamadas)

```
1. Acesse: https://meet.seudominio.com
2. Não precisa de conta! Basta abrir e criar uma sala
3. Compartilhe o link da sala com quem quiser
4. Para privacidade extra: defina senha na sala

No celular:
1. Instale "Jitsi Meet" do F-Droid
2. Config → Server URL → https://meet.seudominio.com
3. Criar/entrar em salas
```

---

## 5.7 — Configurar SearXNG (Buscador Privado)

```
1. Acesse: https://search.seudominio.com (ou http://IP_VPS:8888)
2. Já funciona! Faça uma busca pra testar

Configurar como buscador padrão no Firefox:
1. Acesse https://search.seudominio.com
2. Clique na barra de endereço → ícone de lupa com "+" → "Add SearXNG"
3. Settings → Search → Default Search Engine → SearXNG

Configurar no Brave:
1. Settings → Search engine → Manage search engines
2. Add: URL = https://search.seudominio.com/search?q=%s
3. Set as default

Via Tor (.onion):
- Use o endereço .onion do SearXNG no Tor Browser
- Buscas 100% anônimas sem nem o seu VPS saber seu IP
```

---

## 5.8 — Configurar Email Seguro (Thunderbird)

```bash
# Já instalado na Fase 3
# Adicionar conta ProtonMail ou Tutanota:

# ProtonMail:
# 1. Instalar ProtonMail Bridge: https://proton.me/mail/bridge
# 2. Thunderbird → Add Account → IMAP
#    Server: 127.0.0.1, Port: 1143
#    SMTP: 127.0.0.1, Port: 1025

# Tutanota:
# 1. Instalar Tutanota Desktop: https://tutanota.com
# (Tutanota não suporta IMAP — use o client próprio)
```

---

## 5.9 — Checklist Final

Depois de tudo conectado, verifique:

```
COMPUTADOR:
☐ Linux instalado com disco criptografado
☐ Firewall ativo (ufw)
☐ Firefox hardened com extensões
☐ SearXNG como buscador padrão
☐ Tor Browser instalado
☐ KeePassXC ou Bitwarden (→ Vaultwarden)
☐ ZODL wallet configurada (Zcash)
☐ WireGuard VPN conectando ao VPS
☐ Nextcloud sincronizando arquivos
☐ Element conectado ao Matrix
☐ Thunderbird com email seguro
☐ LibreOffice, GIMP, VLC instalados

VPS:
☐ Todos os containers rodando (docker ps)
☐ Tor .onion addresses gerados
☐ HTTPS funcionando (Caddy)
☐ SearXNG respondendo buscas
☐ Backup diário configurado (rclone)
☐ Firewall + fail2ban + CrowdSec ativos

CELULAR:
☐ F-Droid instalado
☐ WireGuard VPN ativo
☐ Nextcloud sincronizando fotos/contatos/calendário
☐ Element conectado
☐ Bitwarden → Vaultwarden
☐ NewPipe (YouTube sem Google)
☐ Mull ou Tor Browser
☐ ZODL (Zcash — pagamentos privados)
```

---

## O Que Você Ganhou

```
ANTES (tudo espionado):                 DEPOIS (você controla):
─────────────────────                   ──────────────────────
Google Drive → dados no Google          Nextcloud → dados NO SEU servidor
WhatsApp → mensagens no Meta            Matrix → mensagens NO SEU servidor
LastPass → senhas em empresa dos EUA    Vaultwarden → senhas NO SEU servidor
Zoom → vídeo no Zoom                    Jitsi → vídeo NO SEU servidor
Google DNS → ISP vê tudo                AdGuard → DNS NO SEU servidor
Chrome → Google sabe tudo               Firefox → ninguém rastreia
Gmail → Google lê seus emails           ProtonMail → E2E criptografado
Google Play → Google sabe seus apps     F-Droid → FOSS, sem rastreamento
Google Search → Google sabe tudo        SearXNG → buscador NO SEU servidor
PayPal/Venmo → rastreamento total       ZODL (Zcash) → pagamentos privados
Sem VPN → IP exposto                    WireGuard → túnel criptografado
Sem backup → dados vulneráveis          Rclone → backup criptografado
Sem Tor → navegação rastreável          Tor → anonimato quando precisa
```

**Sua vida digital agora é SUA. Ninguém mais tem acesso.**
