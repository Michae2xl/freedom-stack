# FASE 1 — Máquina Local: OS + Hardening

## Passo-a-passo para iniciantes absolutos

### 1.1 — Escolher o Sistema Operacional

**Nunca usou Linux? Comece aqui:**

| OS | Nível | Por quê? |
|----|-------|----------|
| **Linux Mint** | Iniciante | Parece Windows, tudo funciona, loja de apps fácil |
| **Ubuntu** | Iniciante | Mais popular, mais tutoriais online |
| **Fedora** | Intermediário | Mais atualizado, patrocinado pela Red Hat |
| **Debian** | Intermediário/Avançado | Ultra estável, base de tudo |
| **QubesOS** | Avançado | Máxima segurança, compartimentalização por VMs |

**Recomendação padrão:** Linux Mint para quem vem do Windows. Fedora para quem quer algo mais moderno.

### 1.2 — Criar o USB de Instalação

**O que você precisa:**
- Um pendrive de 8GB ou mais (vai ser formatado!)
- O arquivo ISO do Linux escolhido
- Um programa para gravar (Ventoy, Balena Etcher, ou Rufus no Windows)

**Tutorial:**
```
1. Baixe o ISO:
   - Linux Mint: https://linuxmint.com/download.php
   - Ubuntu: https://ubuntu.com/download/desktop
   - Fedora: https://fedoraproject.org/workstation/download

2. Baixe o Ventoy (recomendado — permite múltiplos ISOs no mesmo USB):
   https://www.ventoy.net/en/download.html

3. Instale Ventoy no pendrive:
   - Abra Ventoy → Selecione o pendrive → "Install"
   - ATENÇÃO: isso APAGA tudo do pendrive

4. Copie o arquivo .iso para dentro do pendrive (arraste e solte)

5. Reinicie o computador e dê boot pelo USB:
   - Geralmente: F12, F2, DEL, ou ESC durante a inicialização
   - No menu de boot, selecione o pendrive
```

### 1.3 — Instalar o Linux

**IMPORTANTE: Ative criptografia de disco!**

```
Durante a instalação, quando chegar na parte de particionamento:

✅ Marque "Encrypt the new installation for security" (ou similar)
✅ Escolha uma senha FORTE (mínimo 20 caracteres, misture letras/números/símbolos)
✅ ANOTE essa senha — sem ela você NUNCA mais acessa seus dados

Isso ativa LUKS (Linux Unified Key Setup) — criptografia completa do disco.
Mesmo se roubarem seu laptop, os dados são inacessíveis.
```

**Outras opções durante a instalação:**
- Usuário: escolha um nome sem espaços
- Hostname: algo genérico (ex: "laptop", não "joao-laptop")
- Timezone: pode ser UTC se quiser esconder localização

### 1.4 — Pós-instalação: Hardening

Depois de instalar, abra o Terminal (Ctrl+Alt+T) e rode o script:

```bash
# Baixar e rodar o script de hardening:
curl -fsSL https://raw.githubusercontent.com/Michae2xl/freedom-stack/main/scripts/local-setup.sh | bash
```

Ou, se preferir rodar manualmente, o script faz o seguinte:

**Atualizar tudo:**
```bash
sudo apt update && sudo apt upgrade -y    # Debian/Ubuntu/Mint
# ou
sudo dnf upgrade -y                        # Fedora
```

**Instalar firewall:**
```bash
sudo apt install ufw -y
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw enable
```

**Atualizações automáticas de segurança:**
```bash
sudo apt install unattended-upgrades -y
sudo dpkg-reconfigure -plow unattended-upgrades
```

**Desabilitar telemetria (Ubuntu):**
```bash
sudo apt remove -y ubuntu-report popularity-contest apport whoopsie
sudo systemctl disable --now whoopsie
```

**Bloquear rastreamento por USB:**
```bash
echo 'blacklist usb-storage' | sudo tee /etc/modprobe.d/block-usb-storage.conf
# (remover depois se precisar de USB)
```

**Configurar DNS privado:**
```bash
# Quad9 como DNS padrão (funciona ANTES de ter VPS):
echo "nameserver 9.9.9.9" | sudo tee /etc/resolv.conf
echo "nameserver 149.112.112.112" | sudo tee -a /etc/resolv.conf
sudo chattr +i /etc/resolv.conf  # previne mudanças automáticas

# NOTA: Depois de completar a Fase 4 (VPS) e conectar WireGuard,
# o DNS automaticamente passa pelo AdGuard Home no SEU servidor.
# Quad9 fica como fallback quando a VPN desconecta.
```

**Kernel hardening:**
```bash
sudo tee -a /etc/sysctl.d/99-hardened.conf << 'EOF'
kernel.dmesg_restrict = 1
kernel.kptr_restrict = 2
kernel.randomize_va_space = 2
net.ipv4.conf.all.accept_redirects = 0
net.ipv6.conf.all.accept_redirects = 0
net.ipv4.conf.all.accept_source_route = 0
net.ipv4.tcp_syncookies = 1
net.ipv4.conf.all.log_martians = 1
kernel.yama.ptrace_scope = 2
EOF
sudo sysctl --system
```

### 1.5 — Criptografia Extra

**Pasta pessoal criptografada (além do LUKS):**
```bash
# Instalar VeraCrypt para containers criptografados:
# Útil para arquivos ultra-sensíveis dentro do disco já criptografado
sudo add-apt-repository ppa:unit193/encryption -y
sudo apt install veracrypt -y
```

**Limpeza segura de arquivos:**
```bash
sudo apt install secure-delete -y
# Uso: srm -vz arquivo_sensivel.txt (apaga irrecuperável)
```

### 1.6 — Verificação Final

Depois de tudo configurado, verifique:

```bash
echo "=== Checklist de Segurança ==="
echo -n "Disco criptografado (LUKS): "
lsblk -f | grep -q crypto && echo "✓ SIM" || echo "✗ NÃO"
echo -n "Firewall ativo: "
sudo ufw status | grep -q "Status: active" && echo "✓ SIM" || echo "✗ NÃO"
echo -n "Atualizações automáticas: "
systemctl is-active unattended-upgrades &>/dev/null && echo "✓ SIM" || echo "✗ NÃO"
echo -n "DNS privado: "
grep -q "9.9.9.9" /etc/resolv.conf && echo "✓ SIM" || echo "✗ NÃO"
```

---

## Problemas Comuns

**"Não consigo dar boot pelo USB"**
→ Desabilite Secure Boot na BIOS (F2/DEL na inicialização → Security → Secure Boot → Disabled)

**"WiFi não funciona no Linux"**
→ Conecte via cabo Ethernet primeiro, depois: `sudo apt install firmware-linux-nonfree` (Debian) ou `sudo ubuntu-drivers autoinstall` (Ubuntu)

**"Esqueci a senha do LUKS"**
→ Não tem como recuperar. Seus dados estão seguros... de você também. Por isso: ANOTE a senha em papel, guarde em local seguro.

**"O computador ficou lento"**
→ Se tem menos de 4GB RAM: `sudo apt install zram-tools` (usa compressão de memória)
