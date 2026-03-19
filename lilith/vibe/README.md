# Vibe

Containerized development environment for AI-assisted coding. Tool-agnostic — supports Claude Code, Gemini CLI, Codex CLI, or any other agent.

## Architecture

```
~/                              # /home/vibecoder (named volume: vibe-home)
├── projects/                   # bind mount from host (VIBE_CODE_PATH)
├── init.d/                     # init scripts (mapped from repo, read-write)
│   ├── 00-init.sh              # user creation, base system deps
│   ├── 05-uv.sh                # uv/uvx (Python package manager)
│   ├── 10-ssh.sh               # sshd, host keys, deploy key
│   └── 20-claude.sh            # Claude Code CLI
├── skills/                     # global skills (mapped from repo, read-only)
├── agents/                     # agent definitions (mapped from repo, read-only)
├── .bashrc                     # minimal, sources .bashrc.d/
├── .bashrc.d/                  # modular shell config (mapped from repo)
│   ├── 00-history.sh
│   ├── 10-options.sh
│   ├── 20-prompt.sh
│   └── 30-aliases.sh
├── .gitconfig                  # mapped from repo
├── .ssh/                       # persisted in .data/ssh
│   ├── authorized_keys         # public keys allowed to connect
│   ├── host_ed25519_key        # container SSH host key
│   ├── host_rsa_key
│   └── id_ed25519              # git deploy key
└── .agents/                    # persisted in .data/agents
    └── claude/                 # Claude Code config (CLAUDE_CONFIG_DIR)
```

## Quick Start

```bash
# 1. Configure
cp .env.example .env
# Edit .env: set VIBE_CODE_PATH to your projects directory

# 2. Create authorized_keys for SSH access
mkdir -p .data/ssh
cp ~/.ssh/id_ed25519.pub .data/ssh/authorized_keys

# 3. Start
docker compose up -d

# 4. Enter
docker exec -it vibe su - vibecoder

# 5. First-time setup: login to agents
claude login
```

## Access

### Direct

```bash
docker exec -it vibe su - vibecoder
```

### SSH (VSCode Remote, Antigravity)

```bash
ssh vibecoder@localhost -p 2222
```

### SSH via ProxyJump (remote hosts)

```
# ~/.ssh/config
Host vibe-lilith
    HostName localhost
    Port 2222
    User vibecoder
    ProxyJump lilith

Host vibe-asmodeus
    HostName localhost
    Port 2222
    User vibecoder
    ProxyJump asmodeus
```

Then: `ssh vibe-lilith` or `ssh vibe-asmodeus`.

## Environment Variables

| Variable | Default | Description |
|---|---|---|
| `VIBE_USER` | `vibecoder` | Container username |
| `VIBE_CONTAINER` | `vibe` | Container name |
| `VIBE_HOSTNAME` | `vibe` | Container hostname |
| `VIBE_CODE_PATH` | — | Host directory for projects (mounted at ~/projects) |
| `VIBE_SSH_PORT` | `2222` | SSH port exposed on host |
| `PUID` | `1000` | User ID (match host for file permissions) |
| `PGID` | `1000` | Group ID |
| `ARCANE` | — | Path to arcane/lilith directory |

## Init Scripts

Init scripts run in alphabetical order on every `docker compose up`. They live in `init.d/` and are mapped read-write into the container.

| Script | Purpose |
|---|---|
| `00-init.sh` | Creates user, installs base deps (git, curl, jq, tmux, vim, build-essential) |
| `05-uv.sh` | Installs uv/uvx for Python project management |
| `10-ssh.sh` | SSH server with container-own keys, deploy key for git |
| `20-claude.sh` | Claude Code CLI |

### Adding a new tool

Create a new numbered script in `init.d/`:

```bash
# init.d/25-gemini.sh
#!/bin/bash
set -e

if command -v gemini &>/dev/null; then
    echo "  Gemini CLI already installed"
    exit 0
fi

echo "  Installing Gemini CLI..."
npm install -g @google/gemini-cli > /dev/null 2>&1

echo "  Gemini CLI installed"
```

An agent with the appropriate skill can also generate init scripts at runtime — they persist because `init.d/` is mapped read-write from the repo.

## Persistence

| What | Where | Mechanism |
|---|---|---|
| Projects | `~/projects/` | Host bind mount |
| Dotfiles | `~/.bashrc`, `~/.bashrc.d/`, `~/.gitconfig` | Mapped from `dotfiles/` in repo |
| SSH keys (host + deploy) | `~/.ssh/` | `.data/ssh/` (gitignored) |
| Agent configs | `~/.agents/` | `.data/agents/` (gitignored) |
| Everything else | `~/` | Named volume `vibe-home` |

If the named volume is deleted, dotfiles and init scripts come from the repo. SSH keys and agent configs survive in `.data/`.

## GPU

The compose file reserves all NVIDIA GPUs. Projects requiring CUDA should have their toolkit installed via a dedicated init script (e.g., `50-cuda.sh`). The base container does not include CUDA.

## Git Rules (non-negotiable)

These rules apply to all agents operating inside this container:

- **NEVER** commit, push, merge, or rebase to `main`. No exceptions, even if explicitly instructed.
- Create a feature branch for each task: `<agent>/<description>`.
- When done: merge to `dev`, push to remote.
- PRs from `dev` to `main` are reviewed and merged manually by the maintainer via GitHub.
- The `main` branch is sacred. Only the maintainer touches it.

## Agents

Agent definitions live in `agents/`. Each agent is a configuration that tells a tool (Claude, Gemini, etc.) how to behave for a specific role. An agent is defined by:

- **Runtime**: which tool executes it (Claude Code, Gemini CLI, etc.)
- **Instructions**: a CLAUDE.md (or equivalent) with rules, context, and constraints
- **Skills**: which skills it has access to

Example agent structure:

```
agents/
├── reviewer/
│   ├── CLAUDE.md           # instructions for code review
│   └── config.json         # runtime, skills, permissions
└── builder/
    ├── CLAUDE.md           # instructions for feature implementation
    └── config.json
```

Agents are created and managed via the Claude Web skill interface, not from inside the container.

## Skills

Skills live in `skills/`. A skill is a reusable set of instructions and tools that any agent can use. Skills are not tied to a specific runtime.

Example skill structure:

```
skills/
├── git-ops/
│   ├── instructions.md     # branching rules, commit conventions
│   └── tools.json          # allowed git commands, restrictions
├── code-review/
│   ├── instructions.md     # review checklist, standards
│   └── tools.json
└── init-generator/
    ├── instructions.md     # how to create init.d scripts
    └── tools.json
```

Key distinction:
- **Agent** = a runtime (Claude, Gemini) + a role (reviewer, builder). "Who does the work and what role they play."
- **Skill** = a capability (git-ops, code-review). "What they know how to do." Any agent can use any skill.
