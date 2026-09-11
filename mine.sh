#!/usr/bin/env bash

set -u

API_URL="${API_URL:-https://questions-improved.vercel.app}"
INTERVAL_SECONDS="${INTERVAL_SECONDS:-120}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

trap 'echo; echo "Mining stopped."; exit 0' INT TERM

while true; do
	printf '[%s] Fetching questions from %s...\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$API_URL"

	if python "$SCRIPT_DIR/import_vercel_data.py" "$API_URL" --merge; then
		printf '[%s] Mining complete. Next run in %s seconds.\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$INTERVAL_SECONDS"
	else
		printf '[%s] Mining failed. Retrying in %s seconds.\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$INTERVAL_SECONDS" >&2
	fi

	sleep "$INTERVAL_SECONDS"
done
