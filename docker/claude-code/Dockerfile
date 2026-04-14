FROM debian:bookworm-slim

RUN apt-get update && \
    apt-get install -y --no-install-recommends sudo ca-certificates build-essential curl git gnupg && \
    install -m 0755 -d /etc/apt/keyrings && \
    curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian bookworm stable" > /etc/apt/sources.list.d/docker.list && \
    apt-get update && \
    apt-get install -y --no-install-recommends docker-ce-cli docker-compose-plugin && \
    rm -rf /var/lib/apt/lists/*

RUN useradd -m claude && echo "claude ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/claude
USER claude

RUN curl -fsSL https://claude.ai/install.sh | bash
ENV PATH="/home/claude/.local/bin:${PATH}"

RUN curl https://mise.run | sh
ENV PATH="/home/claude/.local/share/mise/bin:${PATH}"
RUN mise install gh jq sqlite node python

WORKDIR /workspace

ENV DISABLE_AUTOUPDATER=1
ENTRYPOINT ["claude", "--dangerously-skip-permissions", "--continue"]
