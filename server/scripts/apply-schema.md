# Applying schema changes to live PocketBase

PB admin UI's import flow is the source of truth for schema changes. We
don't automate it because PB's diff/merge behavior is opinionated and the
live data is sacred.

## Switching to the single-code-per-household invite model

1. **Drop the `household_invites` collection.** Admin UI → Collections →
   `household_invites` → ⚙ → "..." → Delete collection.
2. **Add two fields to `households`:**
   - `invite_code` — Text, optional, Max 32.
   - `invites_open` — Boolean, default false.
3. **Add a partial unique index on `households.invite_code`** so two
   households can't share the same code (and empty codes don't conflict):
   - Indexes section → New index → Custom SQL:
     ```sql
     CREATE UNIQUE INDEX `idx_households_invite_code`
     ON `households` (`invite_code`)
     WHERE `invite_code` != ''
     ```
4. **Deploy the new join hook** from your dev machine:
   ```bash
   bash server/scripts/deploy-hooks.sh
   ```
   This copies both `pb_hooks/notify.pb.js` and `pb_hooks/join.pb.js` to the
   server and restarts PocketBase.
5. Test the endpoint with `curl`:
   ```bash
   curl -X POST https://api.haveyoufedthedog.com/api/custom/join-household-by-code \
     -H "Content-Type: application/json" \
     -H "Authorization: $TOKEN" \
     -d '{"code":"FAKE-CODE"}'
   # → 404 {"message":"No open household with that code."}
   ```

## Tightening the security rules (legacy notes)

Apply these in the PB admin UI under `Collections → <collection> → API
rules` for each collection listed.

If PB rejects a rule with a parser error, paste the error in chat and
we'll iterate — the rule expression language is fiddly and some
constructs only work in specific versions.

### 1. `users` — revert to strict (self-only reads)

```
listRule:   id = @request.auth.id
viewRule:   id = @request.auth.id
createRule: (empty — signup is public)
updateRule: id = @request.auth.id
deleteRule: id = @request.auth.id
```

### 2. `households`

```
listRule:   @collection.household_members.user ?= @request.auth.id
              && @collection.household_members.household ?= id
viewRule:   same as listRule
createRule: @request.auth.id != ""
updateRule: @collection.household_members.user ?= @request.auth.id
              && @collection.household_members.household ?= id
              && @collection.household_members.role ?= "owner"
deleteRule: same as updateRule
```

### 3. `household_members`

```
listRule:   user = @request.auth.id
viewRule:   user = @request.auth.id
createRule: @request.auth.id != "" && @request.body.user = @request.auth.id
updateRule: user = @request.auth.id
deleteRule: user = @request.auth.id
              || (@collection.household_members.user ?= @request.auth.id
                  && @collection.household_members.household ?= household
                  && @collection.household_members.role ?= "owner")
```

If `@request.body.user` is rejected, try `@request.data.user`. If both fail,
fall back to `@request.auth.id != ""` and accept the looser create rule.

### 4. `subjects`

```
listRule:   @collection.household_members.user ?= @request.auth.id
              && @collection.household_members.household ?= household
viewRule:   same as listRule
createRule: same as listRule
updateRule: same as listRule
deleteRule: same as listRule
```

### 5. `chores`

```
listRule:   @collection.household_members.user ?= @request.auth.id
              && @collection.household_members.household ?= subject.household
viewRule:   same
createRule: same
updateRule: same
deleteRule: same
```

### 6. `completions`

```
listRule:   @collection.household_members.user ?= @request.auth.id
              && @collection.household_members.household ?= subject.household
viewRule:   same as listRule
createRule: <listRule> && @request.body.completed_by = @request.auth.id
updateRule: completed_by = @request.auth.id
deleteRule: completed_by = @request.auth.id
              || (@collection.household_members.user ?= @request.auth.id
                  && @collection.household_members.household ?= subject.household
                  && @collection.household_members.role ?= "owner")
```

### 7. `household_invites`

```
listRule:   @request.auth.id != ""        (anyone authed can look up by code)
viewRule:   @request.auth.id != ""
createRule: @collection.household_members.user ?= @request.auth.id
              && @collection.household_members.household ?= household
updateRule: same as createRule
deleteRule: same as createRule
```

### 8. NEW: `household_member_details` View collection

Click **New collection** → **View**.

**Name:** `household_member_details`

**Query:**

```sql
SELECT
  hm.id        AS id,
  hm.household AS household,
  hm.user      AS user,
  hm.role      AS role,
  hm.created   AS created,
  hm.updated   AS updated,
  u.name       AS user_name
FROM household_members hm
LEFT JOIN users u ON u.id = hm.user
```

PB should auto-derive the fields from the SELECT. Confirm the field types
look right (relations to households + users; text for role + user_name).

**API rules:**

```
listRule: @collection.household_members.user ?= @request.auth.id
            && @collection.household_members.household ?= household
viewRule: same as listRule
createRule: null    (Views are read-only)
updateRule: null
deleteRule: null
```

Save. The collection should appear in the sidebar alongside the others.

## After applying

1. Re-export the schema from Settings → Export collections.
2. Replace `server/pb_schema.json` with the export so the repo matches live.
3. Commit.

## Common pitfalls (we've hit these)

- **`Invalid index expression`** on import: PB rejects column-referencing
  indexes if the columns aren't committed yet. Remove `indexes: [...]`
  entries before import, add them via the admin UI after.
- **`@request.data.<field>` rule rejected**: PB 0.23+ moved to
  `@request.body.<field>`. If both fail, fall back to `@request.auth.id != ""`.
- **Missing fields after import**: you used the old 0.22 schema format
  (`schema: [...]`) instead of 0.23+ (`fields: [...]`). The export from a
  modern PB will always be in 0.23+ format.
- **Per-row rule fails when same row needs to match all conditions**: PB's
  `?=` is "any matching row exists", so two clauses can match different
  rows. Use back-relations (`@collection.X_via_Y`) where possible. Otherwise
  document the looseness as acceptable for the threat model.
