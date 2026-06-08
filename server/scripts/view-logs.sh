#!/usr/bin/env bash
# Tail both PocketBase and the push-notifier in one stream.
# Usage:
#   bash server/scripts/logs.sh           # follow (Ctrl+C to stop)
#   bash server/scripts/logs.sh recent    # last 50 lines, no follow
set -e

SERVER="george@65.108.215.132"
SSH_OPTS=(-i "$HOME/.ssh/dogbox" -p 2222)

if [[ "${1:-}" == "recent" ]]; then
  ssh "${SSH_OPTS[@]}" "$SERVER" \
    'sudo journalctl -u pocketbase@8090 -u push-notifier -n 50 --no-pager'
else
  ssh "${SSH_OPTS[@]}" "$SERVER" \
    'sudo journalctl -u pocketbase@8090 -u push-notifier -f'
fi
