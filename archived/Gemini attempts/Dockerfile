FROM ubuntu:22.04

# Prevent interactive prompts
ENV DEBIAN_FRONTEND=noninteractive

# 1. Install System Dependencies
RUN apt-get update && apt-get install -y \
    curl wget git nano graphviz sudo ca-certificates \
    build-essential xz-utils default-jre python3-pip \
    gnupg software-properties-common \
    && rm -rf /var/lib/apt/lists/*

# 2. Install GitHub CLI
RUN curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg \
    && chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | tee /etc/apt/sources.list.d/github-cli.list > /dev/null \
    && apt-get update && apt-get install gh -y

# 3. Install Quarto
RUN curl -LO https://github.com/quarto-dev/quarto-cli/releases/download/v1.4.550/quarto-1.4.550-linux-amd64.deb \
    && dpkg -i quarto-1.4.550-linux-amd64.deb && rm quarto-1.4.550-linux-amd64.deb

# 5. Install VS Code (code-server)
RUN curl -fsSL https://code-server.dev/install.sh | sh

# 6. Install uv
COPY --from=ghcr.io/astral-sh/uv:latest /uv /uvx /bin/

# 3. Setup User 'engineering'
RUN useradd -m -s /bin/bash engineering \
    && echo "engineering ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers
WORKDIR /home/engineering

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Expose Caddy's default port
EXPOSE 80 443

ENTRYPOINT ["/entrypoint.sh"]