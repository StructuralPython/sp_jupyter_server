#!/bin/bash

# Define persistent paths
VENV_PATH="/home/ubuntu/.venv"
CONFIG_DIR="/config"

# 1. Initialize uv Virtual Environment if it doesn't exist
if [ ! -d "$VENV_PATH" ]; then
    echo "Initializing Python environment..."
    sudo -u ubuntu uv venv $VENV_PATH
    sudo -u ubuntu uv pip install jupyterlab ipykernel tabula-py $INITIAL_PYTHON_PACKAGES
    # Register the kernel
    sudo -u ubuntu $VENV_PATH/bin/python -m ipykernel install --user --name sp --display-name "Python 3 (Structural Python)"
fi

# --- 1. Path Definitions ---
CONFIG_DIR="/config/authelia"
CONFIG_FILE="$CONFIG_DIR/configuration.yml"
USER_DB="$CONFIG_DIR/users_database.yml"

# Ensure the config directory exists on Volume B
mkdir -p $CONFIG_DIR

# --- 2. Generate Authelia Configuration ---
if [ ! -f "$CONFIG_FILE" ]; then
    echo "First run detected: Generating Authelia configuration..."

    # Generate random secrets for this specific installation
    JWT_SECRET=$(head /dev/urandom | tr -dc A-Za-z0-9 | head -c 32)
    STORAGE_KEY=$(head /dev/urandom | tr -dc A-Za-z0-9 | head -c 32)

    cat <<EOF > "$CONFIG_FILE"
server:
  address: 'tcp://0.0.0.0:9091'
log:
  level: 'info'
jwt_secret: '$JWT_SECRET'
default_redirection_url: 'https://$DOMAIN_NAME'
authentication_backend:
  password_reset:
    disable: true
  file:
    path: '$USER_DB'
access_control:
  default_policy: 'one_factor'
  rules:
    - domain: '$DOMAIN_NAME'
      policy: 'one_factor'
session:
  name: 'authelia_session'
  same_site: 'lax'
  expiration: '1h'
  encryption_key: '$STORAGE_KEY'
storage:
  local:
    path: '$CONFIG_DIR/db.sqlite3'
notifier:
  filesystem:
    filename: '$CONFIG_DIR/emails.txt'
EOF
fi

# --- 3. Generate User Database ---
if [ ! -f "$USER_DB" ]; then
    echo "Generating user database for $AUTHELIA_EMAIL..."
    # Generate Argon2 hash from the environment variable provided in bunny.net UI
    HASHED_PASSWORD=$(authelia hash-password "$AUTHELIA_PASSWORD" | awk '{print $NF}')

    cat <<EOF > "$USER_DB"
users:
  admin:
    displayname: "Admin User"
    password: "$HASHED_PASSWORD"
    email: "$AUTHELIA_EMAIL"
    groups:
      - admins
EOF
fi

CADDY_FILE="/config/Caddyfile" # This is /etc/caddy/Caddyfile for the Caddy container

if [ ! -f "$CONFIG_DIR/Caddyfile" ]; then
    cat <<EOF > "$CONFIG_DIR/Caddyfile"
{
    # Disable Admin API and automatic HTTPS
    admin off
    auto_https off
}

# Listen on Port 80 only (Bunny.net handles the 443 -> 80 transition)
:80 {
    # Authelia (pointing to the 'authelia' container service name)
    handle_path /authelia* {
        reverse_proxy authelia:9091
    }

    # Auth Gate
    forward_auth authelia:9091 {
        uri /api/verify?rd=https://\$DOMAIN_NAME/authelia/
        copy_headers Remote-User Remote-Groups Remote-Name Remote-Email
    }

    # App Routing (pointing to the 'app' container service name)
    handle_path /jupyter* {
        reverse_proxy app:8888
    }

    handle_path /code* {
        reverse_proxy app:8080
    }
}
EOF
fi

# 3. Start Authelia in background
authelia --config $CONFIG_DIR/authelia/configuration.yml &

# 4. Start Jupyter Lab in background
sudo -u ubuntu $VENV_PATH/bin/jupyter lab --ip=0.0.0.0 --port=8888 --no-browser --NotebookApp.token='' --NotebookApp.password='' &

# 5. Start Code Server (VS Code) in background
sudo -u ubuntu code-server --bind-addr 0.0.0.0:8080 --auth none /home/ubuntu &

# 6. Start Caddy (Foreground)
caddy run --config $CONFIG_DIR/Caddyfile

