# Contributing to Freedom Stack

Thank you for your interest in contributing to the first Agent Privacy Cloud.

## How to Contribute

### Reporting Issues

- Use [GitHub Issues](../../issues) for bugs and feature requests
- Include your OS, VPS provider, RAM, and which `--flags` you used
- Paste relevant logs: `docker compose logs <service> --tail 50`

### Pull Requests

1. Fork the repo
2. Create a branch: `git checkout -b feature/my-feature`
3. Test on a fresh Ubuntu 24.04 VPS (Hetzner CX22 is cheap for testing)
4. Submit PR with a clear description of what changed and why

### Areas We Need Help

| Area | Difficulty | Impact |
|---|---|---|
| Testing on different VPS providers | Easy | High |
| n8n workflow templates (OSINT, trading, research) | Medium | Very High |
| macOS auto-detection in install.sh | Medium | High |
| Documentation translations (PT-BR, ZH-CN, ES) | Easy | High |
| Security audit of Docker configs | Hard | Critical |
| GPU passthrough for Ollama (NVIDIA) | Hard | High |
| Helm chart for Kubernetes deployment | Hard | Medium |

### Code Style

- Shell scripts: `shellcheck` clean, `set -euo pipefail`
- Follow existing patterns in `install.sh` (add_service, setup_X functions)
- Every new container needs: health check, resource limits, `127.0.0.1` port binding, network assignment

### Testing

Before submitting:

```bash
# Syntax check
bash -n scripts/install.sh

# Count containers and health checks
grep -c 'container_name:' scripts/install.sh
grep -c 'healthcheck:' scripts/install.sh

# Full test on fresh VPS
bash install.sh --all --domain test.example.com
bash scripts/troubleshoot.sh
```

## Code of Conduct

Be respectful. We're building tools for digital freedom — that starts with how we treat each other.
