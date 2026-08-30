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
- `.codex/config.toml` - Codex defaults with approvals disabled (deployed to `~/.codex/config.toml`)

## Makefile Commands

| Command | Description |
|---------|-------------|
| `make install` | Deploy Claude + Codex configs (validates & backs up first) |
| `make validate` | Check YAML syntax |
| `make backup` | Create timestamped backup of current configs |
| `make restore` | Restore from most recent backup |
| `make diff` | Show differences between local and installed configs |
| `make status` | Display configuration status and locations |
| `make test` | Run configuration tests |
| `make clean` | Remove log files |
| `make uninstall` | Remove installed configs (preserves backups) |

## Features

### Automation First
- **Auto mode**: Minimal confirmations, maximum productivity
- **Proactive execution**: Auto-install dependencies, auto-fix errors
- **Parallel operations**: Up to 10 concurrent operations for speed
- **Smart retry logic**: Automatic retry with backoff for network/timeout errors
- **Code formatting**: Auto-format and organize imports
- **Trust local commands**: 200+ CLI tools pre-approved
- **Codex defaults**: No approval prompts, full filesystem and network access

### Codex Behavior
- `approval_policy = "never"` - Codex never stops to ask before running commands or editing files
- `sandbox_mode = "danger-full-access"` - nothing is blocked, so "never" does not turn into silent sandbox failures
- Workspace paths under `~/workspace` are pre-marked `trusted`, skipping the startup trust prompt
- `shell_environment_policy.inherit = "all"` passes the full environment through so tools do not fail on missing credentials
- Web search enabled without prompting
- Fallback profiles when guard rails are wanted:
  - `codex --profile safe` - workspace-write sandbox, prompts only on escalation
  - `codex --profile readonly` - read-only inspection, still no prompts

> **Warning:** the default profile gives Codex unrestricted read/write and network
> access on this machine. Use `--profile safe` for untrusted repos.

### Security
- Write protection for sensitive files (.env, .git, secrets, keys)
- Network access controls with allowlists for package registries and code hosting
- Command execution restrictions (only dangerous operations require confirmation)
- Metadata service blocking (AWS, GCP)
- Rate limiting (60 commands/min, 100 network requests/min)
- Production environment detection with guard rails

### Operations
- Automatic backups before changes
- Structured logging with rotation (10MB max, 5 files)
- Generous timeouts (5min commands, 1min network)
- Large resource limits (50MB files, 1GB memory, 500k char output)
- Continue on error mode for resilience
- Caching enabled for performance

### Development Support
- **200+ CLI tools**: Multi-language tooling (Node.js, Python, Go, Rust, Java, Ruby, C/C++)
- **Package managers**: npm, pip, cargo, maven, gradle, gem, poetry, pnpm, bun, deno
- **Cloud & DevOps**: Docker, Kubernetes, AWS, GCP, Azure, Terraform, Helm
- **Database CLIs**: psql, mysql, sqlite3, redis-cli, mongo
- **Testing**: pytest, jest, mocha, vitest, cargo test, go test
- **Linting & formatting**: eslint, prettier, black, ruff, rustfmt, gofmt
- **File operations**: All standard Unix utilities (ls, cat, grep, sed, awk, find, etc.)

## Customization

Edit `claude/config.yaml`, `claude/policy.yaml`, and `.codex/config.toml` to match your environment:

```bash
# Change Claude config directory
make install CLAUDE_CONFIG_DIR=/custom/path

# Change Codex config directory
make install CODEX_CONFIG_DIR=/custom/codex/path

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
