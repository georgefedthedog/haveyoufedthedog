#!/usr/bin/env bash
# Copies the push-notifier Node service to the live server, installs deps,
# and restarts the systemd unit. Single SSH connection.
#
# First-time setup on the server (do this once, by hand):
#   ssh ... 'sudo mkdir -p /opt/haveyoufedthedog/push-notifier && sudo chown -R george:george /opt/haveyoufedthedog'
#   scp services/push-notifier/firebase-service-account.json ...:/opt/haveyoufedthedog/push-notifier/
set -e

SERVER="george@65.108.215.132"
SSH_OPTS=(-i "$HOME/.ssh/dogbox" -p 2222)
REMOTE="/opt/haveyoufedthedog/push-notifier"

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "==> Uploading notifier + restarting push-notifier..."
tar -cz -C "$DIR/services/push-notifier" \
    index.js overdue-cron.js package.json push-notifier.service \
  | ssh "${SSH_OPTS[@]}" "$SERVER" "
      set -e
      mkdir -p $REMOTE
      cd $REMOTE
      tar -xz
      npm install --production --silent
      sudo bash -c '
        set -e
        mv $REMOTE/push-notifier.service /etc/systemd/system/
        systemctl daemon-reload
        systemctl enable push-notifier
        systemctl restart push-notifier
      '
    "

echo "==> Done. Check: ssh ${SSH_OPTS[*]} $SERVER 'sudo journalctl -u push-notifier -n 5'"
