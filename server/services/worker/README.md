# worker

Small internal Express service on `127.0.0.1:3055` that the PB hooks (same
host) call into - the catch-all "things Goja can't do" backend. Each concern
is its own module:

- **`POST /notify`** - relays `{tokens, title, body}` to Firebase Cloud
  Messaging. Called by `pb_hooks/notify.pb.js` on completion create.
- **`POST /verify-purchase`** - verifies in-app purchases with the store
  (Android via the Play Developer API). Called by `pb_hooks/purchases.pb.js`.
- **Overdue-chore cron** - per-timezone nudges for chores still undone since
  local midnight (needs `Intl`, which Goja lacks).

## Files

- `index.js` - composition root: wires the modules, serves the routes,
  starts the cron
- `notify.js` - Firebase init + `sendPush` + the `/notify` handler
- `verify.js` - store purchase verification + the `/verify-purchase` handler
- `overdue-cron.js` - the per-timezone overdue checker
- `package.json` - deps (express, firebase-admin, googleapis)
- `worker.service` - systemd unit
- `.env` - secrets/config (see `.env.example`). **Gitignored.**
- `firebase-service-account.json` - Firebase Admin credentials. **Gitignored.**
  Place on the server at `/opt/haveyoufedthedog/worker/firebase-service-account.json`.
- `play-service-account.json` - Play Developer API credentials, for purchase
  verification. **Gitignored.** Same location on the server.

## Deploy

```bash
bash server/.deploy/deploy-worker.sh
```

## Local sanity test

```bash
curl -X POST http://127.0.0.1:3055/notify \
  -H 'Content-Type: application/json' \
  -d '{"tokens":["fake"],"title":"test","body":"hello"}'
```

You'll get an FCM error for the fake token (expected) but it confirms the
service is reachable.
