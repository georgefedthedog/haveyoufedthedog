#!/usr/bin/env bash
# Copies pb_hooks to the live server and restarts PocketBase.
# Single SSH connection → one prompt at most (sudo password, or none
# if you've configured passwordless sudo / loaded the key into ssh-agent).
set -e

SERVER="george@65.108.215.132"
SSH_OPTS=(-i "$HOME/.ssh/dogbox" -p 2222)
REMOTE_HOOKS="/var/lib/pocketbase/8090/pb_hooks"

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "==> Uploading hooks + restarting pocketbase@8090..."
# NOTE: overdue.pb.js retired (cron lives in the push-notifier now) - the
# rm below clears it from the server.
tar -cz -C "$DIR/pb_hooks" notify.pb.js join.pb.js cleanup.pb.js _notify_helper.js \
  | ssh "${SSH_OPTS[@]}" "$SERVER" "sudo bash -c '
      mkdir -p $REMOTE_HOOKS &&
      tar -xz -C $REMOTE_HOOKS &&
      rm -f $REMOTE_HOOKS/overdue.pb.js &&
      chown -R pocketbase:pocketbase $REMOTE_HOOKS &&
      systemctl restart pocketbase@8090
    '"

echo "==> Done. Check: ssh ${SSH_OPTS[*]} $SERVER 'sudo journalctl -u pocketbase@8090 -n 5'"
