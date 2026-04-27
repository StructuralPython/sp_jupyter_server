#!/bin/bash
# ─────────────────────────────────────────────────────────────────────────────
# setup-python.sh  –  Create / update the uv-managed venv + IPython kernel
#
# Usage: setup-python.sh <venv_path> "<space-separated packages>"
# ─────────────────────────────────────────────────────────────────────────────
set -euo pipefail

VENV_DIR="${1:-/home/engineering/.venv}"
PYTHON_PACKAGES="${2:-structural_starterkit}"

echo "[setup-python] venv → ${VENV_DIR}"
echo "[setup-python] packages → ${PYTHON_PACKAGES}"

# Run everything as the engineering user when invoked as root
_run() {
    if [ "$(id -u)" = "0" ]; then
        su -s /bin/bash engineering -c "$*"
    else
        bash -c "$*"
    fi
}

# ── 1. Create venv with uv if it doesn't exist ──────────────────────────────
    echo "[setup-python] Creating virtual environment..."
    _run "uv venv --seed --allow-existing --python 3.13 /home/engineering/.venv"

# ── 2. Install / sync packages ───────────────────────────────────────────────
echo "[setup-python] Installing packages: ${PYTHON_PACKAGES}"
# Convert space-separated list to individual uv pip install arguments
PACKAGE_ARGS=""
for pkg in ${PYTHON_PACKAGES}; do
    PACKAGE_ARGS="${PACKAGE_ARGS} '${pkg}'"
done

_run "uv pip install --python '/home/engineering/.venv/bin/python' ipykernel ${PACKAGE_ARGS}"

# ── 3. Register the IPython kernel ───────────────────────────────────────────

echo "[setup-python] Registering IPython kernel 'sp'..."
_run "'${VENV_DIR}/bin/python' -m ipykernel install \
    --user \
    --name sp \
    --display-name 'Python 3 (Structural Python)'"

echo "[setup-python] Done."
