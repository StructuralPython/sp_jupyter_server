FROM ubuntu:24.04

# ─── Build-time arguments (configurable via docker-compose / bunny.net vars) ───
ARG ENGINEERING_UID=1000
ARG PYTHON_PACKAGES="structural_starterkit"

# ─── Environment ──────────────────────────────────────────────────────────────
ENV DEBIAN_FRONTEND=noninteractive \
    TZ=UTC \
    HOME=/home/engineering \
    USER=engineering \
    PYTHON_PACKAGES="${PYTHON_PACKAGES}" \
    UV_PROJECT_ENVIRONMENT=/home/engineering/.venv \
    PATH="/home/engineering/.venv/bin:/home/engineering/.local/bin:/usr/local/bin:${PATH}"

# ─── System packages ──────────────────────────────────────────────────────────
RUN apt-get update && apt-get install -y --no-install-recommends \
        curl \
        wget \
        git \
        nano \
        graphviz \
        sudo \
        ca-certificates \
        build-essential \
        xz-utils \
        default-jre \
        && rm -rf /var/lib/apt/lists/*

# ─── Caddy ────────────────────────────────────────────────────────────────────
RUN curl -fsSL "https://dl.cloudsmith.io/public/caddy/stable/gpg.key" \
        | gpg --dearmor -o /usr/share/keyrings/caddy-stable-archive-keyring.gpg \
    && curl -fsSL "https://dl.cloudsmith.io/public/caddy/stable/debian.deb.txt" \
        | tee /etc/apt/sources.list.d/caddy-stable.list \
    && apt-get update \
    && apt-get install -y --no-install-recommends caddy \
    && rm -rf /var/lib/apt/lists/*

# ─── GitHub CLI ───────────────────────────────────────────────────────────────
RUN curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
        | dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg \
    && chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] \
        https://cli.github.com/packages stable main" \
        | tee /etc/apt/sources.list.d/github-cli.list \
    && apt-get update \
    && apt-get install -y --no-install-recommends gh \
    && rm -rf /var/lib/apt/lists/*

# ─── Quarto ───────────────────────────────────────────────────────────────────
RUN QUARTO_VERSION=$(curl -fsSL https://api.github.com/repos/quarto-dev/quarto-cli/releases/latest \
        | grep '"tag_name"' | sed 's/.*"v\([^"]*\)".*/\1/') \
    && curl -fsSLo /tmp/quarto.deb \
        "https://github.com/quarto-dev/quarto-cli/releases/latest/download/quarto-${QUARTO_VERSION}-linux-amd64.deb" \
    && dpkg -i /tmp/quarto.deb \
    && rm /tmp/quarto.deb

# ─── Tabula ───────────────────────────────────────────────────────────────────
RUN curl -fsSLo /usr/local/bin/tabula.jar \
        https://github.com/tabulapdf/tabula-java/releases/latest/download/tabula-jar-with-dependencies.jar \
    && printf '#!/bin/sh\nexec java -jar /usr/local/bin/tabula.jar "$@"\n' \
        > /usr/local/bin/tabula \
    && chmod +x /usr/local/bin/tabula

# ─── uv ───────────────────────────────────────────────────────────────────────
RUN curl -LsSf https://astral.sh/uv/install.sh | sh \
    && cp /root/.local/bin/uv /usr/local/bin/uv \
    && cp /root/.local/bin/uvx /usr/local/bin/uvx

# ─── code-server (VS Code) ────────────────────────────────────────────────────
RUN curl -fsSL https://code-server.dev/install.sh | sh

# ─── engineering user ─────────────────────────────────────────────────────────
RUN groupadd -g ${ENGINEERING_UID} engineering \
    && useradd -u ${ENGINEERING_UID} -g engineering -m -d /home/engineering \
        -s /bin/bash engineering \
    && echo "engineering ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/engineering \
    && chmod 0440 /etc/sudoers.d/engineering

# ─── Copy entrypoint & config templates ───────────────────────────────────────
COPY scripts/entrypoint.sh /entrypoint.sh
COPY scripts/setup-python.sh /setup-python.sh
COPY config/Caddyfile.template /etc/caddy/Caddyfile.template
COPY config/authelia/ /etc/authelia-template/
COPY config/supervisord.conf /etc/supervisord.conf

RUN chmod +x /entrypoint.sh /setup-python.sh

# ─── supervisord ──────────────────────────────────────────────────────────────
RUN apt-get update \
    && apt-get install -y --no-install-recommends supervisor \
    && rm -rf /var/lib/apt/lists/*

# Expose only the Caddy port; all internal services are behind it
EXPOSE 8080

ENTRYPOINT ["/entrypoint.sh"]