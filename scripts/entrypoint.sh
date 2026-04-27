#!/bin/bash
# ─────────────────────────────────────────────────────────────────────────────
# entrypoint.sh  –  Bootstrap the container on every start
# ─────────────────────────────────────────────────────────────────────────────
set -euo pipefail

PYTHON_PACKAGES="${PYTHON_PACKAGES:-structural_starterkit}"

HOME_DIR="/home/engineering"
CONFIG_DIR="/config"
VENV_DIR="${HOME_DIR}/.venv"
CADDY_CONFIG_DIR="${CONFIG_DIR}/caddy"
VSCODE_CONFIG_DIR="${CONFIG_DIR}/code-server"

# ─────────────────────────────────────────────────────────────────────────────
# 1. Directory structure
# ─────────────────────────────────────────────────────────────────────────────
mkdir -p \
    "${CADDY_CONFIG_DIR}" \
    "${VSCODE_CONFIG_DIR}/extensions" \
    "${VSCODE_CONFIG_DIR}/user-data" \
    "${HOME_DIR}/.jupyter" \
    "${HOME_DIR}/.local/share/jupyter/kernels"

chown -R engineering:engineering "${HOME_DIR}"
chown -R engineering:engineering /config

# ─────────────────────────────────────────────────────────────────────────────
# 2. Caddy config — always overwrite from template so changes take effect
# ─────────────────────────────────────────────────────────────────────────────
cp /etc/caddy/Caddyfile.template "${CADDY_CONFIG_DIR}/Caddyfile"

# ─────────────────────────────────────────────────────────────────────────────
# 3. code-server config
# ─────────────────────────────────────────────────────────────────────────────
VSCODE_HOME="${HOME_DIR}/.config/code-server"
mkdir -p "${VSCODE_HOME}"
if [ ! -f "${VSCODE_HOME}/config.yaml" ]; then
    cat > "${VSCODE_HOME}/config.yaml" << 'VSCONF'
bind-addr: 127.0.0.1:8081
auth: none
disable-telemetry: true
VSCONF
fi
ln -sfn "${VSCODE_CONFIG_DIR}/extensions" \
    "${HOME_DIR}/.local/share/code-server/extensions" 2>/dev/null || true
chown -R engineering:engineering "${HOME_DIR}/.config" 2>/dev/null || true

# ─────────────────────────────────────────────────────────────────────────────
# 4. Python virtual environment + kernel
# ─────────────────────────────────────────────────────────────────────────────
/setup-python.sh "${VENV_DIR}" "${PYTHON_PACKAGES}"

# ─────────────────────────────────────────────────────────────────────────────
# 5. JupyterLab config
# ─────────────────────────────────────────────────────────────────────────────
JUPYTER_CONFIG="${HOME_DIR}/.jupyter/jupyter_lab_config.py"
if [ ! -f "${JUPYTER_CONFIG}" ]; then
    cat > "${JUPYTER_CONFIG}" << 'JCONF'
c.ServerApp.ip = '127.0.0.1'
c.ServerApp.port = 8888
c.ServerApp.open_browser = False
c.ServerApp.token = ''
c.ServerApp.password = ''
c.ServerApp.base_url = '/lab'
c.ServerApp.allow_origin = '*'
c.ServerApp.root_dir = '/home/engineering'
JCONF
    chown engineering:engineering "${JUPYTER_CONFIG}"
fi

# Copy files
# ── Copy default content into home dir (skip existing files) ──────────────────
if [ -d /etc/skel-engineering ]; then
    cp -rn /etc/skel-engineering/. "${HOME_DIR}/"
    chown -R engineering:engineering "${HOME_DIR}"
fi

# ─────────────────────────────────────────────────────────────────────────────
# 6. Hand off to supervisord
# ─────────────────────────────────────────────────────────────────────────────
exec /usr/bin/supervisord -c /etc/supervisord.conf