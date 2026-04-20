#!/bin/bash
USER_NAME="engineering"
USER_HOME="/home/$USER_NAME"
CONFIG_DIR="/config"
AUTHELIA_DIR="$CONFIG_DIR/authelia"

# Fix sudo audit error
echo "Set disable_coredump false" >> /etc/sudo.conf

# Ensure Directories
mkdir -p "$AUTHELIA_DIR" "$USER_HOME"
chown -R $USER_NAME:$USER_NAME "$USER_HOME" "$CONFIG_DIR"

# --- 1. Generate Argon2 Hash (using uv) ---
# We install argon2-cffi on the fly to generate the hash for Authelia
echo "Generating security hash..."
HASH=$(sudo -u $USER_NAME uv run --with argon2-cffi python3 -c "from argon2 import PasswordHasher; print(PasswordHasher().hash('$AUTHELIA_PASSWORD'))")

# --- 2. Authelia Configuration ---
cat <<EOF > "$AUTHELIA_DIR/configuration.yml"
server:
  address: 'tcp://0.0.0.0:9091'
jwt_secret: 'a-very-long-random-secret-string'
default_redirection_url: 'https://$DOMAIN_NAME'
authentication_backend:
  file:
    path: '$AUTHELIA_DIR/users_database.yml'
access_control:
  default_policy: 'one_factor'
  rules:
    - domain: '$DOMAIN_NAME'
      policy: 'one_factor'
session:
  name: 'authelia_session'
  encryption_key: 'another-random-secret-key'
storage:
  local:
    path: '$AUTHELIA_DIR/db.sqlite3'
notifier:
  filesystem:
    filename: '$AUTHELIA_DIR/emails.txt'
EOF

cat <<EOF > "$AUTHELIA_DIR/users_database.yml"
users:
  admin:
    displayname: "Engineering Admin"
    password: "$HASH"
    email: "$AUTHELIA_EMAIL"
    groups: [admins]
EOF

# --- 3. Caddyfile Generation (The "No 502" Version) ---
cat <<EOF > "/etc/caddy/Caddyfile"
{
    admin off
    auto_https off
}

:80 {
    # Authelia Portal
    handle_path /authelia* {
        reverse_proxy authelia:9091
    }

    # Auth Gate (Points to the 'authelia' container)
    forward_auth authelia:9091 {
        uri /api/verify?rd=https://$DOMAIN_NAME/authelia/
        copy_headers Remote-User Remote-Groups Remote-Name Remote-Email
    }

    # App Routing (Points to the 'app' container)
    handle_path /jupyter* {
        reverse_proxy app:8888
    }

    handle_path /code* {
        reverse_proxy app:8080
    }
}
EOF

# --- 4. Python Env & Apps ---
VENV_PATH="$USER_HOME/.venv"
if [ ! -d "$VENV_PATH" ]; then
    sudo -u $USER_NAME uv venv "$VENV_PATH"
    sudo -u $USER_NAME uv pip install jupyterlab ipykernel $INITIAL_PYTHON_PACKAGES
fi

# Start Apps
sudo -u $USER_NAME nohup "$VENV_PATH/bin/jupyter" lab --ip=0.0.0.0 --port=8888 --no-browser --NotebookApp.token='' --NotebookApp.base_url='/jupyter/' > "$USER_HOME/jupyter.log" 2>&1 &
sudo -u $USER_NAME nohup code-server --bind-addr 0.0.0.0:8080 --auth none --base-path /code "$USER_HOME" > "$USER_HOME/vscode.log" 2>&1 &

tail -f "$USER_HOME/jupyter.log"