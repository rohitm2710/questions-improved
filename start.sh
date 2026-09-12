#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

VENV_DIR="${VENV_DIR:-.venv}"
PORT="${PORT:-8000}"
WINDOWS_PYTHON="$SCRIPT_DIR/myenv/Scripts/python.exe"

if [[ ! -x "$VENV_DIR/bin/python" ]] || ! "$VENV_DIR/bin/python" -m pip --version >/dev/null 2>&1; then
    echo "Creating Python environment in $VENV_DIR..."
    rm -rf "$VENV_DIR"
    if ! python3 -m venv "$VENV_DIR"; then
        echo "Warning: Python venv support is unavailable; using system python3." >&2
        rm -rf "$VENV_DIR"
    fi
fi

if [[ -x "$VENV_DIR/bin/python" ]] && "$VENV_DIR/bin/python" -m pip --version >/dev/null 2>&1; then
    PYTHON_BIN="$VENV_DIR/bin/python"
elif [[ -x "$WINDOWS_PYTHON" ]] && "$WINDOWS_PYTHON" -m pip --version >/dev/null 2>&1; then
    PYTHON_BIN="$WINDOWS_PYTHON"
else
    PYTHON_BIN="$(command -v python3)"
fi

echo "Installing Python dependencies when needed..."
if ! "$PYTHON_BIN" -m pip --version >/dev/null 2>&1; then
    echo "Error: Python pip is unavailable. Install python3-venv/python3-pip or configure myenv." >&2
    exit 1
fi
"$PYTHON_BIN" -m pip install -r requirements.txt

if command -v npm >/dev/null 2>&1 && [[ -f package.json ]]; then
    echo "Installing npm dependencies when needed..."
    npm install --ignore-scripts
fi

echo "Starting API on http://127.0.0.1:$PORT"
exec "$PYTHON_BIN" -m uvicorn main:app --host 0.0.0.0 --port "$PORT" --reload