#!/usr/bin/env bash
# Copies pb_hooks/notify.pb.js to the live server and restarts PocketBase.
set -e

SERVER="george@65.108.215.132"
SSH="ssh -i $HOME/.ssh/dogbox -p 2222"
SCP="scp -i $HOME/.ssh/dogbox -P 2222"
REMOTE_HOOKS="/var/lib/pocketbase/8090/pb_hooks"

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "==> Copying notify.pb.js to /tmp..."
$SCP "$DIR/pb_hooks/notify.pb.js" "$SERVER:/tmp/notify.pb.js"

echo "==> Installing into $REMOTE_HOOKS (sudo)..."
$SSH $SERVER "sudo mkdir -p $REMOTE_HOOKS && sudo mv /tmp/notify.pb.js $REMOTE_HOOKS/ && sudo chown -R pocketbase:pocketbase $REMOTE_HOOKS"

echo "==> Restarting pocketbase@8090..."
$SSH $SERVER "sudo systemctl restart pocketbase@8090"

echo "==> Done. Check: $SSH $SERVER 'sudo journalctl -u pocketbase@8090 -n 5'"
