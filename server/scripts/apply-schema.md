# Applying schema changes to live PocketBase

PB admin UI's import flow is the source of truth for schema changes. We don't
automate it because PB's diff/merge behavior is opinionated and the live data
is sacred.

## Workflow

You should normally do schema changes in this direction:

1. **Edit in the live admin UI.** Add fields, rename, change rules — all in
   `https://api.haveyoufedthedog.com/_/`.
2. **Export.** Settings → Export collections → Download JSON.
3. **Replace** `server/pb_schema.json` with the downloaded file.
4. **Regenerate** the OpenAPI + Dart models:
   ```bash
   node server/tools/pb-to-openapi/convert.js
   bash server/tools/gen-dart-models/generate.sh
   ```
5. **Commit** the schema, openapi, and generated Dart files together so the
   client and server can never disagree.

## If you do need to import (fresh setup / disaster recovery)

1. Settings → Import collections.
2. Click **Load from JSON file**, pick `server/pb_schema.json`.
3. **Toggle ON** "Merge with the existing collections" (otherwise it tries to
   delete the system `users`, `_superusers`, `_otps` etc).
4. Review the diff. New collections show as Added. Expect zero deletions.
5. Confirm.

## Common pitfalls (we hit these)

- **`Invalid index expression`** on import: PB rejects column-referencing
  indexes if the columns aren't committed yet. Remove `indexes: [...]` entries
  before import, add them via the admin UI after.
- **`@request.data.<field>` rule rejected**: PB 0.23+ changed the rule
  grammar. Drop the per-row data check and rely on `@request.auth.id != ""`.
- **Missing `name` field after import**: you used the old 0.22 schema format
  (`schema: [...]`) instead of 0.23+ (`fields: [...]`). The export from a
  modern PB will always be in 0.23+ format — good.
