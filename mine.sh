#!/usr/bin/env bash

set -u

API_URL="${API_URL:-https://questions-improved.vercel.app}"
INTERVAL_SECONDS="${INTERVAL_SECONDS:-120}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [[ -z "${PYTHON_BIN:-}" ]]; then
	if command -v python3 >/dev/null 2>&1; then
		PYTHON_BIN="python3"
	elif command -v python >/dev/null 2>&1; then
		PYTHON_BIN="python"
	else
		echo "Error: Python was not found. Install Python 3 or set PYTHON_BIN." >&2
		exit 1
	fi
fi

trap 'echo; echo "Mining stopped."; exit 0' INT TERM

while true; do
	printf '[%s] Fetching questions from %s...\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$API_URL"

	if "$PYTHON_BIN" "$SCRIPT_DIR/import_vercel_data.py" "$API_URL" --merge; then
		printf '[%s] Mining complete. Next run in %s seconds.\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$INTERVAL_SECONDS"
	else
		printf '[%s] Mining failed. Retrying in %s seconds.\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$INTERVAL_SECONDS" >&2
	fi

	sleep "$INTERVAL_SECONDS"
done
