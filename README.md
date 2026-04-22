# Structural Python — Engineering Container

A self-contained, authenticated development environment running:

| Service | Internal address | Public URL |
|---|---|---|
| JupyterLab | `127.0.0.1:8888` | `/lab` |
| VS Code (code-server) | `127.0.0.1:8081` | `/code` |
| Authelia (auth portal) | `127.0.0.1:9091` | `/auth` |
| Caddy (reverse proxy) | `:8080` | all of the above |

---

## Quick start (local)

```bash
cp .env.example .env
# Edit .env with your email and password
docker compose up --build
```

Then visit `http://localhost:8080`.

---

## Bunny.net Magic Container deployment

1. Push the image to a registry accessible from bunny.net (Docker Hub, GHCR, etc.).
2. Create a new Magic Container in the bunny.net dashboard pointing at your image.
3. Bunny.net reads the `BunnyVar_` comment lines in `docker-compose.yml` and generates
   a configuration form. Fill in:
   - **AUTH_EMAIL** — the email address for your Authelia login
   - **AUTH_PASSWORD** — your initial login password
   - **PYTHON_PACKAGES** *(optional)* — extra packages, space-separated
4. Map **one public port → container port 8080**.
5. Mount two volumes:
   - `user-data` → `/home/engineering`
   - `app-config` → `/config`

---

## Volume layout

### `user-data` mounted at `/home/engineering`

```
/home/engineering/
├── work/          ← default root for JupyterLab & VS Code
├── .venv/         ← uv-managed Python virtual environment
├── .jupyter/      ← JupyterLab config
└── .config/
    └── code-server/
        └── config.yaml
```

### `app-config` mounted at `/config`

```
/config/
├── authelia/
│   ├── configuration.yml   ← Authelia config (copied from image on first run)
│   ├── users_database.yml  ← generated from AUTH_EMAIL / AUTH_PASSWORD
│   ├── db.sqlite3          ← Authelia session / TOTP storage
│   └── notifications.txt   ← password-reset notifications (file notifier)
├── caddy/
│   └── Caddyfile           ← copied from image template on every start
└── code-server/
    ├── extensions/         ← VS Code extensions (persisted)
    └── user-data/          ← VS Code user data (persisted)
```

---

## Python environment

- **Runtime**: managed by [uv](https://github.com/astral-sh/uv)
- **Location**: `/home/engineering/.venv`
- **Kernel**: registered as `sp` / "Python 3 (Structural Python)"
- **Packages**: controlled by the `PYTHON_PACKAGES` environment variable

To add packages at runtime open a terminal in JupyterLab or VS Code and run:

```bash
uv pip install <package>
```

Or set `PYTHON_PACKAGES` to include the new package and restart the container.

---

## Changing your password

Because Authelia uses a file-based user database, the easiest way to change
your password is:

1. Open a terminal in JupyterLab or VS Code.
2. Run:
   ```bash
   authelia crypto hash generate bcrypt --password 'newpassword'
   ```
3. Copy the `Digest:` output and paste it into `/config/authelia/users_database.yml`
   as the value for `password:`.
4. Authelia picks up the change automatically (no restart needed).

---

## Architecture diagram

```
  Internet
     │
     ▼
  :8080  Caddy
  ┌─────────────────────────────────────┐
  │  /auth*  ──► Authelia  :9091        │
  │  /lab*   ──► [auth] ──► Jupyter :8888 │
  │  /code*  ──► [auth] ──► VS Code :8081 │
  └─────────────────────────────────────┘
         │               │
    user-data         app-config
  /home/engineering    /config
  (shared by all apps)
```
