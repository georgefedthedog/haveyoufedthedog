#!/usr/bin/env bash
# Copies the worker Node service to the live server, installs deps,
# and restarts the systemd unit. Single SSH connection.
#
# First-time setup on the server (do this once, by hand):
#   ssh ... 'sudo mkdir -p /opt/haveyoufedthedog/worker && sudo chown -R george:george /opt/haveyoufedthedog'
#   scp services/worker/firebase-service-account.json ...:/opt/haveyoufedthedog/worker/
#   scp services/worker/play-service-account.json ...:/opt/haveyoufedthedog/worker/
set -e

SERVER="george@65.108.215.132"
SSH_OPTS=(-i "$HOME/.ssh/dogbox" -p 2222)
REMOTE="/opt/haveyoufedthedog/worker"

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "==> Uploading worker + restarting worker..."
tar -cz -C "$DIR/services/worker" \
    index.js notify.js pb-cron.js overdue-cron.js award-cron.js retire-cron.js verify.js reward-streak.js l10n.js package.json worker.service \
  | ssh "${SSH_OPTS[@]}" "$SERVER" "
      set -e
      mkdir -p $REMOTE
      cd $REMOTE
      tar -xz
      npm install --production --silent
      sudo bash -c '
        set -e
        mv $REMOTE/worker.service /etc/systemd/system/
        systemctl daemon-reload
        systemctl enable worker
        systemctl restart worker
      '
    "

echo "==> Done. Check: ssh ${SSH_OPTS[*]} $SERVER 'sudo journalctl -u worker -n 5'"
