#!/usr/bin/env bash
# Deploys both pb_hooks and the worker service in one go.
# Run from repo root: bash server/.deploy/deploy-all.sh
set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

bash "$DIR/deploy-hooks.sh"
bash "$DIR/deploy-worker.sh"

echo "All done. To verify:"
echo "  ssh -i ~/.ssh/dogbox -p 2222 george@65.108.215.132 'sudo systemctl status worker pocketbase@8090'"
