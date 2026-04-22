#!/bin/bash
# ─────────────────────────────────────────────────────────────────────────────
# entrypoint.sh  –  Bootstrap the container on every start
# ─────────────────────────────────────────────────────────────────────────────
set -euo pipefail

AUTH_EMAIL="${AUTH_EMAIL:?AUTH_EMAIL must be set}"
AUTH_PASSWORD="${AUTH_PASSWORD:?AUTH_PASSWORD must be set}"
PYTHON_PACKAGES="${PYTHON_PACKAGES:-structural_starterkit}"

# ── Paths ─────────────────────────────────────────────────────────────────────
HOME_DIR="/home/engineering"
CONFIG_DIR="/config"
VENV_DIR="${HOME_DIR}/.venv"

TINYAUTH_CONFIG_DIR="${CONFIG_DIR}/tinyauth"
CADDY_CONFIG_DIR="${CONFIG_DIR}/caddy"
VSCODE_CONFIG_DIR="${CONFIG_DIR}/code-server"

# ─────────────────────────────────────────────────────────────────────────────
# 1. Ensure volume directory structure exists
# ─────────────────────────────────────────────────────────────────────────────
mkdir -p \
    "${TINYAUTH_CONFIG_DIR}" \
    "${CADDY_CONFIG_DIR}" \
    "${VSCODE_CONFIG_DIR}" \
    "${HOME_DIR}/work" \
    "${HOME_DIR}/.jupyter" \
    "${HOME_DIR}/.local/share/jupyter/kernels"

chown -R engineering:engineering "${HOME_DIR}" 2>/dev/null || true

# ─────────────────────────────────────────────────────────────────────────────
# 2. Caddy config
# ─────────────────────────────────────────────────────────────────────────────
cp /etc/caddy/Caddyfile.template "${CADDY_CONFIG_DIR}/Caddyfile"

# ─────────────────────────────────────────────────────────────────────────────
# 3. TinyAuth — build the TINYAUTH_AUTH_USERS value and write an env file.
#    Username is derived from the email local part (everything before @).
#    The hash is regenerated on every start so a password change takes effect
#    immediately on the next redeploy without rebuilding the image.
# ─────────────────────────────────────────────────────────────────────────────
TINYAUTH_USERNAME=$(echo "${AUTH_EMAIL}" | cut -d'@' -f1)

# bcrypt-hash the password using Python (guaranteed available via system Python)
# TINYAUTH_HASHED_PASSWORD=$(uv run python -c "
# import bcrypt, sys
# pw = sys.argv[1].encode()
# print(bcrypt.hashpw(pw, bcrypt.gensalt(rounds=12)).decode())
# " "${AUTH_PASSWORD}")
TINYAUTH_USER=$(tinyauth user create \
    --username "${TINYAUTH_USERNAME}" \
    --password "${AUTH_PASSWORD}" \
    --docker \
    | tail -n1)

# Write a small env file that supervisord sources when launching tinyauth
cat > "${TINYAUTH_CONFIG_DIR}/tinyauth.env" <<TINYENV
TINYAUTH_APPURL=http://localhost:8080
TINYAUTH_AUTH_USERS=${TINYAUTH_USER}
TINYAUTH_SERVER_ADDRESS=127.0.0.1
TINYAUTH_SERVER_PORT=3000
TINYAUTH_DATABASE_PATH=${TINYAUTH_CONFIG_DIR}/tinyauth.db
TINYAUTH_ANALYTICS_ENABLED=false
TINYENV

# ─────────────────────────────────────────────────────────────────────────────
# 4. code-server config
# ─────────────────────────────────────────────────────────────────────────────
VSCODE_HOME="${HOME_DIR}/.config/code-server"
mkdir -p "${VSCODE_HOME}"
if [ ! -f "${VSCODE_HOME}/config.yaml" ]; then
    cat > "${VSCODE_HOME}/config.yaml" <<VSCONF
bind-addr: 127.0.0.1:8081
auth: none
disable-telemetry: true
VSCONF
fi
mkdir -p "${VSCODE_CONFIG_DIR}/extensions" "${VSCODE_CONFIG_DIR}/user-data"
ln -sfn "${VSCODE_CONFIG_DIR}/extensions" \
    "${HOME_DIR}/.local/share/code-server/extensions" 2>/dev/null || true
chown -R engineering:engineering "${HOME_DIR}/.config" 2>/dev/null || true

# ─────────────────────────────────────────────────────────────────────────────
# 5. Python virtual environment + kernel
# ─────────────────────────────────────────────────────────────────────────────
/setup-python.sh "${VENV_DIR}" "${PYTHON_PACKAGES}"

# ─────────────────────────────────────────────────────────────────────────────
# 6. JupyterLab config
# ─────────────────────────────────────────────────────────────────────────────
JUPYTER_CONFIG="${HOME_DIR}/.jupyter/jupyter_lab_config.py"
if [ ! -f "${JUPYTER_CONFIG}" ]; then
    cat > "${JUPYTER_CONFIG}" <<JCONF
c.ServerApp.ip = '127.0.0.1'
c.ServerApp.port = 8888
c.ServerApp.open_browser = False
c.ServerApp.token = ''
c.ServerApp.password = ''
c.ServerApp.base_url = '/lab'
c.ServerApp.allow_origin = '*'
c.ServerApp.root_dir = '/home/engineering/work'
JCONF
    chown engineering:engineering "${JUPYTER_CONFIG}"
fi

# ─────────────────────────────────────────────────────────────────────────────
# 7. Hand off to supervisord
# ─────────────────────────────────────────────────────────────────────────────
exec /usr/bin/supervisord -c /etc/supervisord.conf