FROM debian:bookworm-slim

RUN apt-get update && \
  apt-get install -y --no-install-recommends sudo ca-certificates build-essential curl git gnupg \
  autoconf patch rustc libssl-dev libyaml-dev libreadline6-dev zlib1g-dev libgmp-dev libncurses5-dev libffi-dev libgdbm6 libgdbm-dev libdb-dev uuid-dev && \
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
ENV PATH="/home/claude/.local/share/mise/shims:/home/claude/.local/share/mise/bin:${PATH}"
ARG CC_GITHUB_TOKEN
ENV GITHUB_TOKEN=${CC_GITHUB_TOKEN}
RUN mise settings ruby.compile=false
RUN mise use -g \
  gh \
  jq \
  sqlite \
  node \
  yarn \
  python \
  ruby@3.4.9

WORKDIR /workspace

ENV MISE_TRUSTED_CONFIG_PATHS="/workspace"
ENV DISABLE_AUTOUPDATER=1
COPY entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/bin/sh", "/entrypoint.sh"]
