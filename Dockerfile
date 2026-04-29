FROM ubuntu:24.04

# ─── Build-time arguments ──────────────────────────────────────────────────────
ARG ENGINEERING_UID=1001
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
        unzip \
        sudo \
        ca-certificates \
        build-essential \
        xz-utils \
        gnupg \
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

# ─── Java 11 (required for Tabula web app compatibility) ─────────────────────
RUN apt-get update && apt-get install -y --no-install-recommends \
        openjdk-11-jre \
        && rm -rf /var/lib/apt/lists/*

# ─── Tabula (web app) ─────────────────────────────────────────────────────────
# tabula-java is the CLI extraction tool; the web UI comes from tabulapdf/tabula
RUN curl -fsSLo /tmp/tabula.zip \
        "https://github.com/tabulapdf/tabula/releases/download/v1.2.1/tabula-jar-1.2.1.zip" \
    && unzip -q /tmp/tabula.zip -d /usr/local/bin/tabula-web \
    && rm /tmp/tabula.zip
 
# Also install tabula-java CLI for command-line use
RUN TABULA_VERSION=$(curl -fsSL https://api.github.com/repos/tabulapdf/tabula-java/releases/latest \
        | grep '"tag_name"' | sed 's/.*"v\([^"]*\)".*/\1/') \
    && curl -fsSLo /usr/local/bin/tabula.jar \
        "https://github.com/tabulapdf/tabula-java/releases/latest/download/tabula-${TABULA_VERSION}-jar-with-dependencies.jar" \
    && printf '#!/bin/sh\nexec java -jar /usr/local/bin/tabula.jar "$@"\n' \
        > /usr/local/bin/tabula \
    && chmod +x /usr/local/bin/tabula

# ─── uv ───────────────────────────────────────────────────────────────────────
RUN curl -LsSf https://astral.sh/uv/install.sh \
        | env UV_INSTALL_DIR=/usr/local/bin sh

# ─── code-server (VS Code) ────────────────────────────────────────────────────
RUN curl -fsSL https://code-server.dev/install.sh | sh

# ─── ttyd (web terminal) ──────────────────────────────────────────────────────
RUN curl -fsSLo /usr/local/bin/ttyd \
        "https://github.com/tsl0922/ttyd/releases/latest/download/ttyd.x86_64" \
    && chmod +x /usr/local/bin/ttyd

# ─── engineering user ─────────────────────────────────────────────────────────
RUN groupadd -g ${ENGINEERING_UID} engineering \
    && useradd -u ${ENGINEERING_UID} -g engineering -m -d /home/engineering \
        -s /bin/bash engineering \
    && echo "engineering ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/engineering \
    && chmod 0440 /etc/sudoers.d/engineering

# ─── Oh My Bash ───────────────────────────────────────────────────────────────
RUN export HOME=/home/engineering \
    && bash -c "$(curl -fsSL https://raw.githubusercontent.com/ohmybash/oh-my-bash/master/tools/install.sh)" \
        --unattended \
    && sed -i 's/OSH_THEME="font"/OSH_THEME="half-life"/' /home/engineering/.bashrc \
    && echo 'export VIRTUAL_ENV_DISABLE_PROMPT=1' >> /home/engineering/.bashrc \
    && chown -R engineering:engineering \
        /home/engineering/.bashrc \
        /home/engineering/.oh-my-bash

# # ─── Bash venv prompt enhancement ────────────────────────────────────────────
# RUN echo '\n# Show active venv name in prompt\nexport VIRTUAL_ENV_DISABLE_PROMPT=1' \
#         >> /home/engineering/.bashrc

# # Configure Oh My Bash for the engineering user
# RUN cp /root/.bashrc /home/engineering/.bashrc \
#     && cp -r /root/.oh-my-bash /home/engineering/.oh-my-bash \
#     && sed -i 's|/root/.oh-my-bash|/home/engineering/.oh-my-bash|g' \
#         /home/engineering/.bashrc \
#     && chown -R engineering:engineering \
#         /home/engineering/.bashrc \
#         /home/engineering/.oh-my-bash


# ─── supervisord ──────────────────────────────────────────────────────────────
RUN apt-get update \
    && apt-get install -y --no-install-recommends supervisor \
    && rm -rf /var/lib/apt/lists/*

# ─── Copy entrypoint & config ─────────────────────────────────────────────────
COPY scripts/entrypoint.sh /entrypoint.sh
COPY scripts/setup-python.sh /setup-python.sh
COPY config/Caddyfile.template /etc/caddy/Caddyfile.template
COPY config/index.html /etc/caddy/index.html
COPY config/supervisord.conf /etc/supervisord.conf
COPY content/ /etc/skel-engineering/

RUN chmod +x /entrypoint.sh /setup-python.sh

EXPOSE 8080

ENTRYPOINT ["/entrypoint.sh"]