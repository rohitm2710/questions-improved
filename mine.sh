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

run_count=0

while true; do
	printf '[%s] Fetching questions from %s...\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$API_URL"

	if "$PYTHON_BIN" "$SCRIPT_DIR/import_vercel_data.py" "$API_URL" --merge; then
		run_count=$((run_count + 1))
		printf '[%s] Mining cycle #%d complete.\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$run_count"
	else
		printf '[%s] Mining cycle failed.\n' "$(date '+%Y-%m-%d %H:%M:%S')" >&2
	fi

	remaining=$INTERVAL_SECONDS
	while (( remaining > 0 )); do
		printf '\rNext mining cycle in %3d seconds...' "$remaining"
		sleep 1
		remaining=$((remaining - 1))
	done
	printf '\rStarting next mining cycle.                    \n'
done
