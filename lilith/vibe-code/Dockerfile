FROM node:20-slim
# The image contains 11 high vulnerabilities. Change it


ARG USER_UID=1000
ARG USER_GID=1000

# System deps: python3 for chat-archaeologist scripts, git for claude code
RUN apt-get update && apt-get install -y --no-install-recommends \
    python3 python3-pip python3-venv \
    git curl ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Install Claude Code CLI
RUN npm install -g @anthropic-ai/claude-code

# Create non-root user matching host UID
RUN groupadd -g ${USER_GID} claude && \
    useradd -m -u ${USER_UID} -g ${USER_GID} -s /bin/bash claude

# Python deps for chat-archaeologist (sklearn for TF-IDF fallback)
RUN pip3 install --break-system-packages scikit-learn hdbscan

# Working directory
WORKDIR /projects/ClaudeData

USER claude

ENTRYPOINT ["claude"]
CMD ["--dangerously-skip-permissions"]
