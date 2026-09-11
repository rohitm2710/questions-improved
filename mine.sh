#!/usr/bin/env bash

set -u

API_URL="${API_URL:-https://questions-improved.vercel.app}"
INTERVAL_SECONDS="${INTERVAL_SECONDS:-60}"
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
	printf '\r\033[K[%s] Fetching questions...' "$(date '+%H:%M:%S')"

	if result=$("$PYTHON_BIN" "$SCRIPT_DIR/import_vercel_data.py" "$API_URL" --merge 2>&1); then
		run_count=$((run_count + 1))
		printf '\r\033[K[%s] Cycle #%d complete: %s' "$(date '+%H:%M:%S')" "$run_count" "$result"
	else
		printf '\r\033[K[%s] Mining failed: %s' "$(date '+%H:%M:%S')" "$result" >&2
	fi

	remaining=$INTERVAL_SECONDS
	while (( remaining > 0 )); do
		printf '\r\033[K[%s] Next cycle in %3d seconds...' "$(date '+%H:%M:%S')" "$remaining"
		sleep 1
		remaining=$((remaining - 1))
	done
done
