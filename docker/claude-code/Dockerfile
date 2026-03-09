FROM node:22-slim

RUN apt-get update && \
    apt-get install -y \
    git \
    curl \
    jq \
    && rm -rf /var/lib/apt/lists/*

RUN npm install -g @anthropic-ai/claude-code@latest

RUN useradd -m claude
USER claude

RUN curl https://mise.run | sh
ENV PATH="/home/claude/.local/bin:${PATH}"

WORKDIR /workspace

ENV DISABLE_AUTOUPDATER=1
ENTRYPOINT ["claude", "--dangerously-skip-permissions"]
