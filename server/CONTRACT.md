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

**Visibility:** the `users` collection has `listRule` / `viewRule` set to
`@request.auth.id != ""` — any authenticated user can read any user's
public fields (`id`, `name`, `avatar`). `email` is hidden by PocketBase's
built-in `emailVisibility` flag (defaults to false). `update`/`delete` rules
stay locked to `id = @request.auth.id` so you can only modify your own
record. This is needed so household members can see each other's display
names; we revisit this if/when we need a stricter privacy boundary.

## Resources

All resource records have PocketBase system fields: `id` (text, 15 chars,
unique), `created`, `updated` (ISO 8601 UTC).

### households
- `name` (text, required)
- `created_by` (relation → users, required)
- Rules: any authenticated user can view all households (intentionally loose;
  practical security is the unguessability of the IDs). Members only get
  the records they need via the household_members join.

### household_members
- `household` (relation → households, cascade-delete)
- `user` (relation → users, cascade-delete)
- `role` (`owner` | `member`)
- Composite (household, user) is logically unique. PB enforces via app logic
  rather than a unique index (we hit an indexes-on-import bug last time).

### household_invites
- `household` (relation → households, cascade-delete)
- `code` (text, ~8 chars, e.g. `KIKO-7H4P`)
- `expires_at` (date, optional)
- `created_by` (relation → users)

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
  Caddy proxy. Subscribing will silently fail with `404 Missing or invalid
  client id`. Use FCM-triggered refresh + pull-to-refresh instead.
- **No password recovery / email verification yet.** PB supports both but we
  haven't configured SMTP. Users that forget passwords need an admin reset.
- **No offline writes.** Online-only client by design.
