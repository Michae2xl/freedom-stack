# FASE 4 — VPS: Sua Nuvem Privada

## 4.1 — Escolher um VPS

### Providers Privacy-Friendly (ordenados por privacidade)

| Provider | País | Aceita Crypto | RAM/Preço | Nota |
|----------|------|---------------|-----------|------|
| **Njalla** | Suécia | ✓ BTC/XMR | 15€/mês 1.5GB | Registro anônimo, owned by Peter Sunde (Pirate Bay) |
| **1984.is** | Islândia | ✓ BTC | 8€/mês 1GB | Foco em liberdade de expressão, leis de privacidade fortes |
| **Bahnhof** | Suécia | Não | 15€/mês 2GB | Datacenter em bunker nuclear, proteção legal |
| **Hetzner** | Alemanha | Não | 4€/mês 4GB | GDPR, excelente custo-benefício |
| **Contabo** | Alemanha | Não | 6€/mês 8GB | Muito barato, bom pra começar |
| **Hostinger** | Lituânia | Não | 4€/mês 2GB | Popular, fácil de usar |

**Recomendação:**
- **Privacidade máxima:** Njalla (pague com Monero)
- **Melhor custo-benefício:** Hetzner
- **Começar rápido:** Contabo ou Hostinger

### Como Contratar (Passo-a-passo)

```
1. Acesse o site do provider (preferencialmente via Tor Browser)
2. Escolha o plano: mínimo 2GB RAM, 2 vCPUs, 40GB disco
3. Selecione Ubuntu 22.04 ou 24.04 como sistema operacional
4. Crie uma senha forte para root
5. Anote o IP do servidor e a senha
6. (Opcional) Adicione uma chave SSH durante a criação
```

## 4.2 — Primeiro Acesso ao VPS

```bash
# No seu computador (Terminal):
ssh root@SEU_IP_DO_VPS

# Se pedir para confirmar fingerprint: digite "yes"
# Digite a senha do root
```

**Configurar acesso por chave SSH (mais seguro):**
```bash
# No SEU computador (não no VPS):
ssh-keygen -t ed25519 -C "freedom-stack"
# Aperte Enter 3x (ou defina uma passphrase)

# Copiar chave para o VPS:
ssh-copy-id root@SEU_IP_DO_VPS
# Digite a senha uma última vez

# Agora pode conectar sem senha:
ssh root@SEU_IP_DO_VPS
```

## 4.3 — Domínio (Opcional mas Recomendado)

**Com domínio:** HTTPS automático, subdomínios bonitos (cloud.meusite.com)
**Sem domínio:** Acesso via .onion (Tor) ou IP direto

**Providers de domínio privacy-friendly:**
- **Njalla** — registro anônimo
- **Namecheap** — aceita BTC, WhoisGuard grátis
- **Porkbun** — barato, WHOIS privacy grátis

**Configurar DNS:**
```
Aponte esses subdomínios para o IP do VPS:

cloud.seudominio.com  → IP_DO_VPS  (Nextcloud)
chat.seudominio.com   → IP_DO_VPS  (Matrix)
element.seudominio.com → IP_DO_VPS (Element Web)
vault.seudominio.com  → IP_DO_VPS  (Vaultwarden)
meet.seudominio.com   → IP_DO_VPS  (Jitsi)
dns.seudominio.com    → IP_DO_VPS  (AdGuard Home)
search.seudominio.com → IP_DO_VPS  (SearXNG)
```

## 4.4 — Instalar o Freedom Stack

```bash
# Conectar no VPS:
ssh root@SEU_IP_DO_VPS

# Baixar o script:
curl -fsSL -o /root/install.sh https://raw.githubusercontent.com/Michae2xl/freedom-stack/main/scripts/install.sh
chmod +x /root/install.sh

# Instalar TUDO (humanos + agents):
bash /root/install.sh --all --domain seudominio.com

# Sem domínio (acesso via Tor .onion ou IP direto):
bash /root/install.sh --all
```

**IMPORTANTE:** O script muda a porta SSH para 2222. Depois da instalação:
```bash
# Reconectar com nova porta:
ssh -p 2222 root@SEU_IP_DO_VPS
```

**O que acontece:** script roda 10-15 min. Gera 1 docker-compose.yml unificado com redes isoladas, health checks, resource limits. Instala Watchtower (auto-update) + Uptime Kuma (monitoramento). Credenciais criptografadas com GPG.

## 4.5 — Pós-instalação

Depois que o script terminar, ele mostra todas as credenciais. Também ficam salvas em:
```bash
cat /root/freedom-stack-credentials.txt
```

**SALVE ESSAS CREDENCIAIS EM LOCAL SEGURO!**
- Copie para o KeePassXC (Fase 3)
- Ou anote em papel e guarde fisicamente
- Especialmente as chaves de criptografia do backup (rclone)

## 4.6 — Configurar Backup (Mega.nz)

```bash
# Se não configurou durante a instalação:

# 1. Criar conta Mega.nz (https://mega.nz — 20GB grátis)
# 2. Editar a config do rclone:
nano /root/.config/rclone/rclone.conf

# 3. Substituir MEGA_EMAIL_HERE e MEGA_PASSWORD_HERE

# 4. Testar:
rclone ls mega:
# Se listar seus arquivos do Mega, funcionou!

# 5. Testar backup completo:
bash /opt/freedom-stack/backup.sh
```

## 4.7 — Verificar se Tudo Funciona

```bash
bash /opt/freedom-stack/scripts/troubleshoot.sh
```

Isso verifica todos os containers, portas, certificados, Tor, e segurança.

## 4.8 — Manutenção

**Atualizar containers (automático via Watchtower!):**
Watchtower atualiza automaticamente toda segunda 4AM. Pra forçar:
```bash
cd /opt/freedom-stack
docker compose pull && docker compose up -d
```

**Ver status de todos os serviços:**
```bash
docker compose ps
# Coluna STATUS mostra "(healthy)" quando tudo OK
```

**Ver logs:**
```bash
docker compose logs nextcloud --tail 50
docker compose logs synapse --tail 50
```

**Monitoramento (Uptime Kuma):**
```bash
# Acesse: https://status.seudominio.com (ou http://127.0.0.1:3001)
# Configure monitores para cada serviço na interface web
```

**Verificar backups:**
```bash
cat /var/log/freedom-backup.log | tail -20
# Procure por "INTEGRITY CHECK: ✓ PASSED"
```

**Criar usuário Matrix (registration fechado):**
```bash
docker exec -it freedom-synapse register_new_matrix_user \
  -u NOME -p SENHA -c /data/homeserver.yaml http://localhost:8008
```
