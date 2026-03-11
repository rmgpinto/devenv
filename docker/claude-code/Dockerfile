FROM debian:bookworm-slim

RUN apt-get update && \
    apt-get install -y \
    git \
    curl \
    jq \
    && curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | tee /etc/apt/sources.list.d/github-cli.list > /dev/null \
    && apt-get update \
    && apt-get install -y gh \
    && rm -rf /var/lib/apt/lists/*

RUN useradd -m claude
USER claude

RUN curl -fsSL https://claude.ai/install.sh | bash
ENV PATH="/home/claude/.local/bin:${PATH}"

RUN curl https://mise.run | sh

WORKDIR /workspace

ENV DISABLE_AUTOUPDATER=1
ENTRYPOINT ["claude", "--dangerously-skip-permissions"]
