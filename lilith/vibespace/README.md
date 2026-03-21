# Vibespace

Containerized development environment for AI-assisted coding. Tool-agnostic — supports Claude Code, Gemini CLI, Codex CLI, or any other tool.

## Naming

| Name | What | Why |
|---|---|---|
| `vibespace` | Host directory | The space where vibes are configured |
| `vibe:latest` | Docker image | The frozen state — ready to vibe |
| `ts-vibecode` | Compose service | Tailscale sidecar — the tailnet node |
| `vibecode` | Compose service | The act of vibe-coding |
| `vibration` | Container name | The running vibration |
| `viber` | Hostname | The vibrator — how it presents on the network |
| `${DEVICE}-viber` | Tailscale hostname | How it presents on the tailnet |
| `vibecoder` | User inside container | The one who vibe-codes |
| `vibestorage` | Named volume | Where vibes persist |

## Architecture

```
~/                              # /home/vibecoder (named volume: vibestorage)
├── entrypoint.sh               # mapped from repo, runs init.d/*.sh
├── init.d/                     # init scripts (mapped from repo, read-write)
│   ├── 05-uv.sh                # uv/uvx (Python package manager)
│   ├── 10-ssh.sh               # sshd, host keys, deploy key
│   └── 20-claude.sh            # Claude Code CLI
├── projects/                   # bind mount from host (PROJECT_PATH)
├── skills/                     # global skills (mapped from repo)
├── .bashrc                     # minimal, sources .bashrc.d/
├── .bashrc.d/                  # modular shell config (mapped from repo)
│   ├── 00-history.sh
│   ├── 01-path.sh              # ~/.local/bin, ~/.npm-global/bin
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
# Edit .env: set PROJECT_PATH, DEVICE, and TS_AUTHKEY

# 2. Build
docker compose build

# 3. Create authorized_keys for SSH access
mkdir -p .data/ssh
cp ~/.ssh/id_ed25519.pub .data/ssh/authorized_keys

# 4. Start
docker compose up -d

# 5. Enter
docker exec -it vibration su - vibecoder

# 6. First-time setup: login to tools
claude login
```

## Access

### Direct

```bash
docker exec -it vibration su - vibecoder
```

### SSH via Tailscale

The container is a Tailscale node (`${DEVICE}-viber`). No ports exposed on the host.

```bash
ssh vibecoder@lilith-viber
```

### SSH config (recommended)

```
# ~/.ssh/config
Host vibe-lilith
    HostName lilith-viber
    User vibecoder

Host vibe-asmodeus
    HostName asmodeus-viber
    User vibecoder
```

Then: `ssh vibe-lilith` or `ssh vibe-asmodeus`.

### Network isolation

The viber node has **no outbound SSH access** — it has no SSH keys to connect to other devices. Other devices can SSH into it using their keys via `authorized_keys`. Password authentication is disabled.

## Environment Variables

| Variable | Default | Description |
|---|---|---|
| `DEVICE` | `lilith` | Device name — Tailscale hostname becomes `${DEVICE}-viber` |
| `VIBE_USER` | `vibecoder` | Container username (build arg + runtime) |
| `PUID` | `1000` | User ID — match host for file permissions (build arg) |
| `PGID` | `1000` | Group ID (build arg) |
| `ARCANE` | — | Path to arcane/lilith directory |
| `PROJECT_PATH` | — | Host directory for projects (mounted at ~/projects) |
| `TS_AUTHKEY` | — | Tailscale auth key (tag:viber required in ACL) |
| `TS_EXTRA_ARGS` | — | Tailscale extra args (`--advertise-tags=tag:viber`) |

Changing `VIBE_USER`, `PUID`, or `PGID` requires a rebuild (`docker compose build`).

## Entrypoint

The container runs `entrypoint.sh` as `vibecoder` (non-root) on startup. It executes all `init.d/*.sh` scripts in alphabetical order, then sleeps.

To skip init (debug/quick start):

```bash
docker compose run --entrypoint "sleep infinity" vibecode
```

The entrypoint is volume-mapped from the repo, so changes take effect on next restart without rebuilding.

## Init Scripts

Init scripts run as `vibecoder` (non-root) in alphabetical order on every container start. They live in `init.d/` and are mapped read-write into the container.

Numbering follows the nginx convention — **gaps of 10** between groups, leaving room for future scripts without renumbering:

| Range | Group | Scripts |
|---|---|---|
| `00–09` | Base tools | `05-uv.sh` — uv/uvx (installs to `~/.local/bin`) |
| `10–19` | Infrastructure | `10-ssh.sh` — sshd, host keys, deploy key |
| `20–29` | Agent runtimes | `20-claude.sh` — Claude Code CLI (installs to `~/.npm-global/`) |
| `30–99` | Project-specific | _(add as needed)_ |

### Privilege model

Scripts run as `vibecoder`. Use `sudo` only for operations that genuinely require root, and only for the specific command:

| Needs `sudo` | Doesn't need `sudo` |
|---|---|
| Writing to `/etc/ssh/sshd_config.d/` | `npm install -g` (uses `NPM_CONFIG_PREFIX`) |
| Starting `sshd` on port 22 (privileged) | `curl \| sh` installers (uv → `~/.local/bin`) |
| | `ssh-keygen`, `chmod`, `mkdir` on own files |
| | Anything in `$HOME` |

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

Init scripts can also be generated at runtime by tools operating inside the container — they persist because `init.d/` is mapped read-write from the repo.

## Persistence

| What | Where | Mechanism |
|---|---|---|
| Projects | `~/projects/` | Host bind mount |
| Dotfiles | `~/.bashrc`, `~/.bashrc.d/`, `~/.gitconfig` | Mapped from `dotfiles/` in repo |
| SSH keys (host + deploy) | `~/.ssh/` | `.data/ssh/` (gitignored) |
| Tool configs | `~/.agents/` | `.data/agents/` (gitignored) |
| Tailscale state | `/var/lib/tailscale` | `.data/tailscale/` (gitignored) |
| Everything else | `~/` | Named volume `vibestorage` |

If the named volume is deleted, dotfiles and init scripts come from the repo. SSH keys and tool configs survive in `.data/`.

## GPU

This image does **not** include CUDA, cuDNN, or any GPU runtime. There's a reason for that.

NVIDIA/CUDA images exist because the GPU stack is massive (~5-15GB), tightly version-coupled (driver ↔ toolkit ↔ cuDNN ↔ framework), and changes independently from the application layer. Mixing `node:20-bookworm` with CUDA packages is fragile and produces bloated images.

The intended architecture for GPU workloads is a **separate service** in this same compose file:

```yaml
services:
  vibecode:
    # ... (this service, the coding environment)

  vibecore:
    image: nvidia/cuda:12.x-devel-ubuntu22.04  # or pytorch/pytorch
    container_name: vibration-gpu
    hostname: vibecore
    deploy:
      resources:
        reservations:
          devices:
            - driver: nvidia
              count: all
              capabilities: [gpu]
    networks:
      - lilith_default
    # ... volumes, SSH, etc.
```

The `vibecoder` user accesses `vibecore` via SSH — it's the only other host the agents can reach. Training, inference, and GPU-heavy tasks run there. The coding environment stays lean.

This keeps concerns separated: **vibecode** is for thinking and writing code, **vibecore** is for running it on hardware.

## Git Rules (non-negotiable)

These rules apply to all tools operating inside this container:

- **NEVER** commit, push, merge, or rebase to `main`. No exceptions, even if explicitly instructed.
- Create a feature branch for each task.
- When done: merge to `dev`, push to remote.
- PRs from `dev` to `main` are reviewed and merged manually by the maintainer via GitHub.
- The `main` branch is sacred. Only the maintainer touches it.

## Skills

Skills live in `skills/`. A skill is a reusable set of instructions that any tool can use. Skills define capabilities — "what it knows how to do."

The tools themselves (Claude Code, Gemini CLI, etc.) are the runtimes. When you spawn a session, the prompt you give defines the mission. The CLAUDE.md (or equivalent) plus skills define the capabilities. There are no agent definition files or schemas — you describe what you want conversationally and the tool builds it.

Skills are created and managed via the Claude Web skill creator, not from inside the container. They are versioned with the Arcane repo so all hosts share the same skill set.
