#!/usr/bin/env bash
# Copies the landing page (src/) to the live server.
# Run from Git Bash / WSL. Single SSH connection, same pattern as
# server/scripts/deploy-hooks.sh. The Tailwind output (src/style.css) is
# committed, so no build step is needed here - but if you've edited HTML
# classes since the last build, run `npm run build` first.
set -e

SERVER="george@65.108.215.132"
SSH_OPTS=(-i "$HOME/.ssh/dogbox" -p 2222)
REMOTE_ROOT="/var/www/haveyoufedthedog"

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "==> Uploading landing page to $REMOTE_ROOT..."
tar -cz -C "$DIR/src" . \
  | ssh "${SSH_OPTS[@]}" "$SERVER" "sudo bash -c '
      mkdir -p $REMOTE_ROOT &&
      tar -xz -C $REMOTE_ROOT &&
      chown -R www-data:www-data $REMOTE_ROOT
    '"

echo "==> Done. https://haveyoufedthedog.com"
