# push-notifier

Tiny Express service that listens on `127.0.0.1:3055`, accepts `POST /notify`
with `{tokens, title, body}`, and relays to Firebase Cloud Messaging via the
`firebase-admin` SDK.

Called by `pb_hooks/notify.pb.js` on the same host whenever a `completions`
record is created.

## Files

- `index.js` - the service itself
- `package.json` - deps (express, firebase-admin)
- `push-notifier.service` - systemd unit
- `firebase-service-account.json` - Firebase Admin credentials. **Gitignored.**
  Place it on the server at `/opt/haveyoufedthedog/push-notifier/firebase-service-account.json`.

## Deploy

```bash
bash server/scripts/deploy-notifier.sh
```

## Local sanity test

```bash
curl -X POST http://127.0.0.1:3055/notify \
  -H 'Content-Type: application/json' \
  -d '{"tokens":["fake"],"title":"test","body":"hello"}'
```

You'll get an FCM error for the fake token (expected) but it confirms the
service is reachable.
