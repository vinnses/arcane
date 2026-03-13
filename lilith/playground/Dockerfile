FROM pytorch/pytorch:2.8.0-cuda12.8-cudnn9-devel AS base

ARG USER=devel
ARG UID=1000
ARG GID=1000

EXPOSE 8888
EXPOSE 8443

ENV TERM=xterm-256color
ENV LANG=en_US.UTF-8
ENV LC_ALL=en_US.UTF-8
ENV TZ=America/Sao_Paulo

# ── System packages ──────────────────────────────────────────────────────────
RUN apt-get update && apt-get install -y --no-install-recommends \
    sudo git vim make curl tree procps ca-certificates locales && \
    rm -rf /var/lib/apt/lists/* && \
    update-ca-certificates && \
    locale-gen en_US.UTF-8 && \
    ln -snf /usr/share/zoneinfo/${TZ} /etc/localtime

# ── Code Server (VS Code in browser) ────────────────────────────────────────
RUN curl -fsSL https://code-server.dev/install.sh | sh

# ── Non-root user ────────────────────────────────────────────────────────────
RUN if ! getent group ${GID} >/dev/null 2>&1; then \
        groupadd --gid ${GID} ${USER}; \
    fi && \
    if id -u ${USER} >/dev/null 2>&1; then \
        usermod --uid ${UID} --gid ${GID} ${USER}; \
    else \
        useradd --uid ${UID} --gid ${GID} -m -s /bin/bash ${USER}; \
    fi && \
    echo "${USER} ALL=(root) NOPASSWD:ALL" > /etc/sudoers.d/${USER} && \
    chmod 0440 /etc/sudoers.d/${USER}

USER ${USER}

# ── UV package manager ───────────────────────────────────────────────────────
# UV_SYSTEM_PYTHON=1: install into conda base env (where torch already lives),
# avoiding duplication of the ~2 GB torch install from the base image.
ENV UV_SYSTEM_PYTHON=1
ENV PATH="/home/${USER}/.local/bin:${PATH}"

RUN curl -LsSf https://astral.sh/uv/install.sh | sh

RUN echo '' >> ~/.bashrc && \
    echo '# ── Injected by Dockerfile ──' >> ~/.bashrc && \
    echo 'eval "$(uv generate-shell-completion bash)"' >> ~/.bashrc && \
    echo 'eval "$(uvx --generate-shell-completion bash)"' >> ~/.bashrc && \
    echo '' >> ~/.bashrc && \
    echo '[ -f /workspace/.scripts/bash_options ] && source /workspace/.scripts/bash_options' >> ~/.bashrc

WORKDIR /workspace

COPY --chown=${UID}:${GID} entrypoint.sh .
RUN chmod +x ./entrypoint.sh

ENTRYPOINT ["./entrypoint.sh"]
