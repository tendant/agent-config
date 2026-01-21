# Claude Agent Configuration

Production-ready configuration files for Claude AI agents with comprehensive security policies and operational settings.

## Quick Start

```bash
# Install configuration files
make install

# Check status
make status

# View all available commands
make help
```

## Configuration Files

- `claude/config.yaml` - Agent behavior, logging, timeouts, and resource limits
- `claude/policy.yaml` - Security permissions for filesystem, execution, and network access

## Makefile Commands

| Command | Description |
|---------|-------------|
| `make install` | Deploy configs to `~/.config/claude` (validates & backs up first) |
| `make validate` | Check YAML syntax |
| `make backup` | Create timestamped backup of current configs |
| `make restore` | Restore from most recent backup |
| `make diff` | Show differences between local and installed configs |
| `make status` | Display configuration status and locations |
| `make test` | Run configuration tests |
| `make clean` | Remove log files |
| `make uninstall` | Remove installed configs (preserves backups) |

## Features

### Security
- Write protection for sensitive files (.env, .git, secrets, keys)
- Network access controls with allowlists
- Command execution restrictions
- Metadata service blocking
- Rate limiting

### Operations
- Automatic backups before changes
- Structured logging with rotation
- Configurable timeouts and retries
- Resource limits (file size, memory, concurrent ops)
- Production guard for safety

### Development Support
- Multi-language tooling (Node.js, Python, Go, Rust)
- Package manager integration (npm, pip, cargo)
- Docker and Kubernetes support
- Testing framework compatibility

## Customization

Edit `claude/config.yaml` and `claude/policy.yaml` to match your environment:

```bash
# Change default config directory
make install CLAUDE_CONFIG_DIR=/custom/path

# Change backup location
make backup BACKUP_DIR=/backup/path
```

## Requirements

- Make
- Optional: `yamllint` or `python3` for validation

Check dependencies:
```bash
make check-deps
```

## License

MIT