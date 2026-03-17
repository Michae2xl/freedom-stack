# Security Policy

## Reporting Vulnerabilities

If you discover a security vulnerability in Freedom Stack, **do NOT open a public issue.**

Instead, report it privately:

1. Email: [create a proton/tutanota address for this]
2. Or: open a [private security advisory](../../security/advisories/new) on GitHub

Include:
- Description of the vulnerability
- Steps to reproduce
- Potential impact
- Suggested fix (if any)

We will respond within 48 hours and issue a patch as quickly as possible.

## Scope

The following are in scope:
- Docker container escape / privilege escalation
- Network isolation bypass between `net-proxy`, `net-data`, `net-monitor`
- Credential exposure (plaintext leaks, insecure defaults)
- Tor circuit correlation / deanonymization via Freedom Stack configs
- Authentication bypass on any service
- Default configurations that weaken security

## Security Design Principles

Freedom Stack follows these principles:

1. **Ports behind Caddy** — Only Caddy (80/443), WireGuard, AdGuard DNS, and Jitsi JVB expose public ports. Everything else is `127.0.0.1`.
2. **Network isolation** — 3 Docker networks prevent lateral movement between services.
3. **Least privilege** — Containers run with `cap_drop: ALL` where possible.
4. **No default passwords** — All credentials are randomly generated at install time.
5. **Closed registration** — Matrix registration is disabled by default.
6. **Encrypted backups** — Rclone crypt with AES-256, integrity-verified via SHA-256 checksums.
7. **Defense in depth** — UFW + fail2ban + CrowdSec + AppArmor layered together.
