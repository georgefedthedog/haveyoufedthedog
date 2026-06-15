#!/usr/bin/env bash
# Tail both PocketBase and the worker service in one stream.
# Usage:
#   bash server/.deploy/view-logs.sh           # follow (Ctrl+C to stop)
#   bash server/.deploy/view-logs.sh recent    # last 50 lines, no follow
set -e

SERVER="george@65.108.215.132"
SSH_OPTS=(-i "$HOME/.ssh/dogbox" -p 2222)

if [[ "${1:-}" == "recent" ]]; then
  ssh "${SSH_OPTS[@]}" "$SERVER" \
    'sudo journalctl -u pocketbase@8090 -u worker -n 50 --no-pager'
else
  ssh "${SSH_OPTS[@]}" "$SERVER" \
    'sudo journalctl -u pocketbase@8090 -u worker -f'
fi
