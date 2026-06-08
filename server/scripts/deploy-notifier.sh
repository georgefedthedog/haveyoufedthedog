#!/usr/bin/env bash
# Copies the push-notifier Node service to the live server, installs deps,
# and restarts the systemd unit.
#
# First-time setup on the server (do this once, by hand):
#   ssh ... 'sudo mkdir -p /opt/haveyoufedthedog/push-notifier && sudo chown -R george:george /opt/haveyoufedthedog'
#   scp services/push-notifier/firebase-service-account.json ...:/opt/haveyoufedthedog/push-notifier/
set -e

SERVER="george@65.108.215.132"
SSH="ssh -i $HOME/.ssh/dogbox -p 2222"
SCP="scp -i $HOME/.ssh/dogbox -P 2222"
REMOTE="/opt/haveyoufedthedog/push-notifier"

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "==> Copying notifier source..."
$SCP "$DIR/services/push-notifier/index.js" "$SERVER:$REMOTE/"
$SCP "$DIR/services/push-notifier/package.json" "$SERVER:$REMOTE/"

echo "==> Copying systemd unit to /tmp..."
$SCP "$DIR/services/push-notifier/push-notifier.service" "$SERVER:/tmp/push-notifier.service"

echo "==> Installing systemd unit (sudo)..."
$SSH $SERVER "sudo mv /tmp/push-notifier.service /etc/systemd/system/ && sudo systemctl daemon-reload && sudo systemctl enable push-notifier"

echo "==> Installing Node deps..."
$SSH $SERVER "cd $REMOTE && npm install --production --silent"

echo "==> Restarting push-notifier..."
$SSH $SERVER "sudo systemctl restart push-notifier"

echo "==> Done. Check: $SSH $SERVER 'sudo journalctl -u push-notifier -n 5'"
