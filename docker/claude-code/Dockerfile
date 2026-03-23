FROM debian:bookworm-slim

RUN apt-get update && \
    apt-get install -y --no-install-recommends ca-certificates build-essential curl git && \
    rm -rf /var/lib/apt/lists/*

RUN useradd -m claude
USER claude

RUN curl -fsSL https://claude.ai/install.sh | bash
ENV PATH="/home/claude/.local/bin:${PATH}"

RUN curl https://mise.run | sh
ENV PATH="/home/claude/.local/share/mise/bin:${PATH}"
RUN mise install gh jq sqlite3

WORKDIR /workspace

ENV DISABLE_AUTOUPDATER=1
ENTRYPOINT ["claude", "--dangerously-skip-permissions", "--resume"]
