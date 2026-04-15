# # Use the official Jupyter base-notebook
# FROM quay.io/jupyter/base-notebook

# USER root

FROM quay.io/jupyter/base-notebook
RUN pip install --no-cache-dir structural_starterkit

# # Install system dependencies (Quarto, Graphviz, curl)
# RUN apt-get update && apt-get install -y --no-install-recommends \
#     curl \
#     gdebi-core \
#     graphviz \
#     && rm -rf /var/lib/apt/lists/*

# # Install Quarto
# RUN curl -LO https://quarto.org/download/latest/quarto-linux-amd64.deb && \
#     gdebi --non-interactive quarto-linux-amd64.deb && \
#     rm quarto-linux-amd64.deb

# # Install uv (latest version)
# COPY --from=ghcr.io/astral-sh/uv:latest /uv /uvx /bin/

# USER ${NB_USER}

# # Use uv to install Python packages and Quarto extensions
# # We use the --system flag so uv manages the existing environment in the image
# RUN uv pip install --system --no-cache \
#     graphviz \
#     jupyterlab-quarto \
#     structural_starterkit