# Server contract

What the app gets to assume about the server.

## Base URL

`https://api.haveyoufedthedog.com`

All endpoints below are relative to this.

## Identity

PocketBase auth, no extras. Tokens are JWT and live ~30 days.

- `POST /api/collections/users/auth-with-password` — body `{identity, password}`, returns `{record, token}`.
- `POST /api/collections/users/records` — signup. Body `{email, password, passwordConfirm, name}`.
- Authorization header: bare token (no `Bearer ` prefix — PB convention).

The user record has these fields the app cares about: `id`, `email`, `name`
(display name), `fcm_token` (the app writes this).

## Security model

The schema enforces a strict "members-only" boundary for all household data.

### Direct user record access

The `users` collection is locked to **self-only** at the record level:
`listRule`/`viewRule` = `id = @request.auth.id`. You can never read other
users' records directly — not even names — by hitting
`/api/collections/users/records`.

To get display names of fellow household members the app uses a View
collection (see below) which exposes a filtered, joined projection. The View
is the only privacy-safe way to learn names.

### Household-scoped data

`households`, `subjects`, `chores`, `completions`, `household_invites`,
`household_members` all enforce "you must be a member of the household" for
read access. The rule pattern looks like:

```
@collection.household_members.user ?= @request.auth.id
  && @collection.household_members.household ?= <household-ref-for-this-row>
```

Where `<household-ref-for-this-row>` is:

- `id` — for the `households` collection
- `household` — for collections with a direct relation to households
- `subject.household` — for chores and completions (two-hop)

Write rules are similarly gated; sensitive ones (delete a household, kick a
member) also check `role ?= "owner"`.

**Caveat:** PB's `?=` operator is "any match exists". The "user matches AND
household matches" clauses can theoretically match different rows of
`household_members`. In practice this only opens leaks if a bad actor is
ALREADY a member of one household — and even then they'd only see other rows
where the same household_id exists. Acceptable for our threat model.

### household_member_details (View collection)

A read-only **View** collection that joins `household_members` with `users`
to expose display names without weakening `users` security:

```sql
SELECT
  hm.id           AS id,
  hm.household    AS household,
  hm.user         AS user,
  hm.role         AS role,
  hm.created      AS created,
  hm.updated      AS updated,
  u.name          AS user_name
FROM household_members hm
LEFT JOIN users u ON u.id = hm.user
```

Rules: list/view = "member of the household this row belongs to" — same
pattern as the other collections.

The View is the only thing the app uses to render "members of this
household." Direct `users` reads are limited to your own record.

## Resources

All resource records have PocketBase system fields: `id` (text, 15 chars,
unique), `created`, `updated` (ISO 8601 UTC).

### households
- `name` (text, required)
- `created_by` (relation → users, required)
- `invite_code` (text, optional, unique when non-empty) — the single rotating join code
- `invites_open` (bool) — gates whether `/api/custom/join-household-by-code` accepts the code

### household_members
- `household` (relation → households, cascade-delete)
- `user` (relation → users, cascade-delete)
- `role` (`owner` | `member`)

### Joining via invite code

There is no `household_invites` collection — invites live as two fields on
the `households` record. To join, the app POSTs to a custom server endpoint:

```
POST /api/custom/join-household-by-code
Authorization: <token>
Content-Type: application/json

{ "code": "ABCD-EFGH" }
```

Returns:

- `200 { "householdId": "..." }` — joined (or already a member).
- `200 { "householdId": "...", "alreadyMember": true }` — idempotent re-join.
- `400 { "message": "Invite code is required." }` — empty body.
- `401 { "message": "..." }` — not signed in.
- `404 { "message": "No open household with that code." }` — code unknown
  or `invites_open` is false.

The hook (`server/pb_hooks/join.pb.js`) runs with elevated privileges, so
non-members never need to read the `households` collection directly.

### household_member_details (View)
- Read-only. Joins `household_members` + `users`.
- Fields: `id`, `household`, `user`, `role`, `created`, `updated`, `user_name`.

### subjects
- `household` (relation → households, cascade-delete)
- `name` (text, required)
- `icon` (text, optional, default `pets`)
- `nfc_tag_id` (text, optional — hex UID of the bound NFC tag)
- `sort_order` (int, default 0)
- `created_by` (relation → users)

### chores
- `subject` (relation → subjects, cascade-delete)
- `name` (text, required)
- `schedule_type` (`daily` | `weekly`)
- `hour` (int 0–23), `minute` (int 0–59)
- `weekday_mask` (int, bitmask Mon=1, Tue=2, …, Sun=64; only used for weekly)
- `active` (bool, default true)
- `sort_order` (int, default 0)

### completions
- `subject` (relation → subjects, cascade-delete)
- `chore` (relation → chores, optional — null means ad-hoc tap with no matching scheduled chore)
- `completed_at` (date, UTC)
- `completed_by` (relation → users)
- `source` (`button` | `nfc` | `manual`)
- `notes` (text, optional)

## Push notifications

The contract:

1. App writes the current device's FCM token onto its `users.fcm_token` field
   whenever the user logs in or the token refreshes.
2. When a `completions` record is created, `pb_hooks/notify.pb.js` runs server-
   side. It collects every other household member's `fcm_token` and POSTs
   `{tokens, title, body}` to the local push-notifier on `127.0.0.1:3055/notify`.
3. The push-notifier service relays to FCM. Recipients see a notification like
   "Kiko: Breakfast done by George".

The app receives the message:
- **In foreground:** `FirebaseMessaging.onMessage` fires. We refresh the
  on-screen completions providers.
- **In background / killed:** Android shows the system notification. Tap →
  app opens.

## What the app must NOT assume

- **No realtime updates.** PB's SSE realtime endpoint is broken through our
  Caddy proxy. Subscribing will silently fail. Use FCM-triggered refresh +
  pull-to-refresh.
- **No password recovery / email verification yet.** PB supports both but we
  haven't configured SMTP.
- **No offline writes.** Online-only client by design.
- **Cannot read other users directly.** Use the `household_member_details`
  View when you need names.
