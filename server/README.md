# server

Everything server-shaped: PocketBase schema, JS hooks, the Node push-notifier
relay, deploy scripts.

## Live deployment

- Host: `george@65.108.215.132` (SSH on port 2222, key `~/.ssh/dogbox`)
- PocketBase systemd unit: `pocketbase@8090`
- PocketBase data dir: `/var/lib/pocketbase/8090/`
- PocketBase hooks dir: `/var/lib/pocketbase/8090/pb_hooks/`
- Push-notifier systemd unit: `push-notifier`
- Push-notifier install dir: `/opt/haveyoufedthedog/push-notifier/`
- Public URL: `https://api.haveyoufedthedog.com`
- Admin UI: `https://api.haveyoufedthedog.com/_/`

## Layout

```
pb_schema.json            canonical schema export. This IS the API surface.
openapi.yaml              derived from pb_schema.json via tools/pb-to-openapi/
CONTRACT.md               human-readable description of the server contract

pb_hooks/notify.pb.js     fires on completions create, calls push-notifier

services/push-notifier/   Node Express service, relays to FCM
  index.js
  package.json
  push-notifier.service   systemd unit
  firebase-service-account.json  gitignored secret

scripts/                  manual deploy scripts (visible, no magic)
  deploy-all.sh           deploys both hooks and notifier
  deploy-hooks.sh         hooks only
  deploy-notifier.sh      notifier only
  apply-schema.md         manual walkthrough for PB admin UI schema import

tools/
  pb-to-openapi/          Node script: pb_schema.json -> openapi.yaml
```

## Deploy

One-time per machine:

```bash
eval $(ssh-agent -s)
ssh-add ~/.ssh/dogbox
```

Then:

```bash
bash server/scripts/deploy-all.sh
```

See `apply-schema.md` for the manual schema-import flow (PB admin UI doesn't
have a programmatic import that survives our setup).

## Adding a notification reason

1. Open `pb_hooks/notify.pb.js`. The hook body composes the title/body string.
2. Edit. Save. Run `bash server/scripts/deploy-hooks.sh`. PB restarts. Done.

## Changing a collection or rule

1. Make the change in the PB admin UI on the live server (fastest path).
2. From Settings → Export collections, download the new JSON.
3. Replace `server/pb_schema.json` with the export.
4. Regenerate the OpenAPI / Dart models: `bash server/tools/pb-to-openapi/convert.sh`
   then `bash server/tools/gen-dart-models/generate.sh`.
5. Commit.

Order is deliberately admin-UI-first because PB's schema import diff is fiddly
and the live data is sacred.
