#!/usr/bin/env bash
# Syncs server/pb_public/ to PocketBase's public directory on the live
# server. PocketBase serves pb_public statically, so anything placed in
# here is reachable at https://api.haveyoufedthedog.com/<path> - e.g.
# .well-known/assetlinks.json. Served live, so no restart is needed.
#
# To publish more static files in future: drop them under
# server/pb_public/ and re-run this script.
#
# Run from repo root: bash server/.deploy/deploy-public.sh
set -e

SERVER="george@65.108.215.132"
SSH_OPTS=(-i "$HOME/.ssh/dogbox" -p 2222)
REMOTE_PUBLIC="/var/lib/pocketbase/8090/pb_public"

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "==> Uploading pb_public + fixing ownership..."
# Tar the whole pb_public tree (the "." pulls in hidden dirs like
# .well-known) and extract it into PocketBase's public dir. cp-style
# merge: it won't delete files already on the box.
tar -cz -C "$DIR/pb_public" . \
  | ssh "${SSH_OPTS[@]}" "$SERVER" "sudo bash -c '
      mkdir -p $REMOTE_PUBLIC &&
      tar -xz -C $REMOTE_PUBLIC &&
      chown -R pocketbase:pocketbase $REMOTE_PUBLIC
    '"

echo "==> Done. PocketBase serves pb_public live (no restart needed)."
echo "    Verify: curl -i https://api.haveyoufedthedog.com/.well-known/assetlinks.json"
