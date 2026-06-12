# Have You Fed The Dog Yet

Family chore tracker. Tap an NFC tag (or a button) and it logs "Kiko got
breakfast" with your name on it. Tag-aware, household-shared, push-notified.

This is a monorepo with two independent sub-projects:

```
server/   PocketBase schema, hooks, push-notifier service, deploy scripts.
          This IS the API - PB auto-generates REST endpoints from the schema.

app/      Flutter app. Online-only client. Consumes the server contract.

_old/     Previous attempt, preserved for reference. Gitignored, do not edit.
```

## Quick links

- **Server contract:** [`server/CONTRACT.md`](./server/CONTRACT.md)
- **Server deploy:** [`server/README.md`](./server/README.md)
- **App development:** [`app/README.md`](./app/README.md)
- **Plan:** `~/.claude/plans/witty-giggling-dongarra.md`

## Where to start

If you're modifying:

- **A screen, a controller, anything Flutter** → work in `app/`. Schema is fixed (`server/pb_schema.json`).
- **A collection field, a permission rule** → edit `server/pb_schema.json`, re-import via PB admin UI, regenerate Dart models.
- **Push notification text or routing** → `server/pb_hooks/notify.pb.js` and/or `server/services/push-notifier/index.js`. Redeploy with `bash server/scripts/deploy-all.sh`.

## Live deployment

- PocketBase: `https://api.haveyoufedthedog.com` (Hetzner box `dogbox-1`)
- Firebase project: `haveyoufedthedog-a1d9f`
- Android package: `com.haveyoufedthedog`
