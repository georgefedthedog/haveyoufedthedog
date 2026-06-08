#!/usr/bin/env bash
# Deploys both pb_hooks and the push-notifier in one go.
# Run from repo root: bash server/scripts/deploy-all.sh
set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

bash "$DIR/deploy-hooks.sh"
bash "$DIR/deploy-notifier.sh"

echo "All done. To verify:"
echo "  ssh -i ~/.ssh/dogbox -p 2222 george@65.108.215.132 'sudo systemctl status push-notifier pocketbase@8090'"
