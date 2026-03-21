FROM node:20-bookworm

ARG VIBE_USER=vibecoder
ARG PUID=1000
ARG PGID=1000

# ── System packages ───────────────────────────────────────────────────────────
RUN apt-get update -qq && apt-get install -y -qq --no-install-recommends \
    sudo openssh-server \
    python3 python3-pip python3-venv \
    git curl wget ca-certificates \
    tmux jq make build-essential vim \
    && rm -rf /var/lib/apt/lists/*

# ── Create user matching host UID/GID ─────────────────────────────────────────
RUN groupadd -g "${PGID}" "${VIBE_USER}" 2>/dev/null || true \
    && useradd -m -u "${PUID}" -g "${PGID}" -s /bin/bash "${VIBE_USER}" \
    && echo "${VIBE_USER} ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/${VIBE_USER} \
    && chmod 0440 /etc/sudoers.d/${VIBE_USER}

# ── SSH run dir ───────────────────────────────────────────────────────────────
RUN mkdir -p /run/sshd

USER ${VIBE_USER}
WORKDIR /home/${VIBE_USER}
