# Have You Fed The Dog?

A fun family chore tracker. Everything the household looks after - the dog,
the cat, the plants, the wheelie bin - becomes a friendly cartoon **character**.
Chores recur on a schedule ("Brekkie, every day at 6:50 am") or fire once on a
date ("Vet, 12 May"), anyone in the household can tick them off (tap a row, or
tap an **NFC tag** stuck near the dog food), and everyone else gets a push
notification. Completions feed
streaks, a weekly leaderboard, and a tongue-in-cheek **awards** system
(Early Bird, Night Owl, "Kiko-dog's Best Human 🩵"…). Branded as a dog feeder,
but the engine is generic recurring-care tasks.

Monorepo, two independent halves:

```
app/      Flutter app (Android-first). Online-only PocketBase client.
server/   PocketBase schema + JS hooks + Node worker service + deploy scripts.
_old/     Previous attempt, gitignored, reference only.
```

Stack: **Flutter** (Riverpod codegen, GoRouter, google_fonts) ·
**PocketBase** (the entire API - REST endpoints auto-derived from the schema) ·
**Node worker service** (FCM relay, IAP verification, cron) · **Firebase Cloud Messaging** · **Resend** (SMTP).

---

## The server

Live at `https://api.haveyoufedthedog.com` - PocketBase behind **nginx +
Cloudflare** on a Hetzner box (`dogbox-1`).

> ⚠️ **There is exactly one server instance, and it is production.** No
> staging, no dev box - `api.haveyoufedthedog.com` is what every released app
> talks to. Every schema edit, hook deploy, and collection-rule change goes
> **live the moment you make it**, and a hooks deploy restarts PocketBase
> (brief blip). So **all server changes must be backward-compatible with the
> currently-released app**: never tighten a rule the live app still relies on,
> never remove/rename a field or view column it reads, and only relax rules in
> ways that still accept the old client's requests. When relaxing a
> collection rule, verify a real request from the live app still succeeds
> immediately after, and keep the previous rule handy to restore if not.

| What         | Where                                                                                 |
| ------------ | ------------------------------------------------------------------------------------- |
| SSH          | `ssh -i ~/.ssh/dogbox -p 2222 george@65.108.215.132`                                  |
| PocketBase   | systemd `pocketbase@8090`, data in `/var/lib/pocketbase/8090/`                        |
| Hooks        | `/var/lib/pocketbase/8090/pb_hooks/`                                                  |
| Static files | `/var/lib/pocketbase/8090/pb_public/` - served at the API domain root (`--publicDir`) |
| Worker       | systemd `worker`, `/opt/haveyoufedthedog/worker/`, listens on `127.0.0.1:3055`        |
| Admin UI     | `https://api.haveyoufedthedog.com/_/`                                                 |
| Logs         | `bash server/.deploy/view-logs.sh` or `journalctl -u pocketbase@8090 -f`              |

### Collections (`server/pb_schema.json` is the canonical export)

- **users** - PB auth collection. Extra fields: `name`, `avatar` (text id -
  a bundled-registry id or a `catalog_avatars` slug), `fcm_token` (this
  device's push token), `managed` (bool - a "managed" member: a loginless
  account an owner creates so a member without their own login still earns
  credit; minted by the `members.pb.js` hook, see below).
- **households** - `name`, `picture` (text id into the house-picture registry),
  `invite_code` + `invites_open` (single shareable code, toggleable),
  `timezone` (IANA name, captured from the creator's phone; empty =
  Europe/London), `residents` ("Who lives here?" label, e.g. "The
  Goodchilds"), `packs` (**multi**-relation to `catalog_packs` - the image
  packs this household owns, bought or redeemed; PB serializes single
  relations as a bare string, so keep it multi). Free streak-reward fields
  (see "streak rewards" below): `unlocked_characters` / `unlocked_pictures`
  (JSON slug lists - catalog art earned free, household-scoped like packs),
  `last_free_redemption` (date - the anchor the reward streak counts from,
  reset on each claim), `reward_streak_threshold` (number - due-days needed to
  earn a free reward; admin-set per household, empty/0 = the in-code default
  of 28).
- **household_members** - user ↔ household join with `role` (`owner`/`member`).
- **household_member_details** - read-only SQL **view** joining members to
  `users` so the app gets `user_name` + `user_avatar` + `user_managed` in one
  fetch.
- **subjects** - the characters. `name`, `household`, `icon` (character id:
  dog/cat/plant/bin/fish/generic, or a `catalog_characters` slug). `nfc_tag_id`
  holds the universal-link URL written to this subject's NFC tag - a "tag
  written" marker that drives the NFC icon (it means a tag was written for the
  subject, not that a live one still exists).
- **chores** - `subject`, `name`, `hour`, `minute`, `active`, and a recurrence
  keyed by `schedule_type`:
  - `daily` - every day.
  - `weekly` - `weekday_mask` (Mon=1 … Sun=64, i.e. `1 << (weekday-1)`) and
    `week_interval` (1 = weekly, 2 = fortnightly). Fortnightly stores **no
    anchor date**: `week_phase` (0/1) is parity against a fixed epoch (first
    Monday of 1970), so the app and the worker agree on which alternate week is
    "on"; the editor resolves a "this week / next week" pick into it.
  - `monthly` - `month_mode` `day` (`month_day` 1-28, or `-1` = last day of the
    month) or `weekday` (`month_ordinal` 1-4 or `-1` = last, with `month_weekday`
    ISO 1-7). `-1` means "last"; PB reads an empty number as 0, so 0 is never
    that sentinel.
  - `once` - a single dated task on `due_date` (text `YYYY-MM-DD`, no timezone).
    It carries over - due on its date and every day after, until completed -
    then a worker sweep retires it (`active = false`). See "one-off chores" in
    the worker section.
  The full field set is written on every save (`chore_actions._ruleFields`,
  `due_date` included - empty for recurring); only the fields the active
  `schedule_type` reads are consulted, the rest are inert defaults. **Times are
  family wall-clock with no timezone** - see the timezone contract below.
- **completions** - `subject`, `chore`, `chore_name`, `completed_by`,
  `completed_at` (UTC), `source` (`button`/`nfc`). `completed_by` is the
  **acting identity** ("Act as" lets a signed-in member log for a managed
  member), not necessarily the caller - so the create/update/delete rules allow
  any member of the subject's household (relaxed from self-only) and act-as
  logging + undo work. `completed_by` is **optional and non-cascading** on
  purpose: deleting a user (incl. a managed member) blanks it (PB clears
  optional references), so the chore still counts in history but shows as
  "Someone". `chore_name` is the chore's name **denormalised at log time** so
  the history timeline still names a chore that's since been deleted or retired
  (a finished one-off goes `active = false` and drops out of the live list);
  the timeline prefers the live chore name and falls back to this.
- **catalog_avatars / catalog_pictures / catalog_characters** - the remote
  art catalog (ship new art without an app release). Per row: `slug` (the
  forever-id stored on user/household/subject records), `display_name`,
  `sort_order`, the art file field(s), and a `packs` **multi**-relation (the
  packs this row belongs to - empty = general catalog, everyone sees it; a row
  can be in several packs). `catalog_characters`/`catalog_pictures` also carry
  `reward_excluded` (bool - true reserves the row for paid/private packs, i.e.
  excludes it from the free streak rewards; resolution + pickers are
  unaffected). No per-row draft flag: saved = live; stage/retire via the Vault
  pack trick (see "Publishing").
- **catalog_packs** - the art packs (groups) a household can own. `code`
  (**hidden field** - clients can't read or filter it; only the redeem hook
  resolves it), `name`, `enabled` (pack live at all), `redeemable` (accepts
  new gift-code redemptions). Owned by buying a `catalog_products` that grants
  it or redeeming its code via `packs.pb.js`; never by direct client writes.

All API rules are membership-scoped (you only see rows for households you're
in). Schema and API-rule edits are a by-hand process (see "Deploying to the
server" below) - ask Claude for step-by-step instructions.

### Hooks (`server/pb_hooks/`)

- **join.pb.js** - `POST /api/custom/join-household-by-code`. Runs privileged
  so non-members can redeem a code without weakening household read rules.
  Idempotent.
- **packs.pb.js** - `POST /api/custom/redeem-pack-code` `{code, householdId}`.
  Runs privileged because `catalog_packs.code` is hidden from clients.
  Checks membership, requires the pack `enabled` + `redeemable`, appends to
  `households.packs`. Idempotent (`alreadyApplied: true`).
- **purchases.pb.js** - `POST /api/custom/verify-purchase`
  `{platform, sku, purchaseToken, householdId}`. The paid counterpart to
  redeem: checks membership, resolves the `sku` to a `catalog_products` row,
  asks the worker (`/verify-purchase`) to validate the receipt with the store,
  records the transaction in `purchases`, then appends the product's `grants`
  packs to `households.packs`. Idempotent on `store_transaction_id`.
- **rewards.pb.js** - `POST /api/custom/claim-streak-reward`
  `{householdId, kind, slug}`. The **free** counterpart to verify-purchase:
  checks membership, resolves the slug to a resolvable, non-`reward_excluded`
  catalog row, asks the worker (`/reward-streak`) to recompute the household's
  reward streak, requires it to clear `reward_streak_threshold` (default 28),
  then appends the slug to `households.unlocked_characters` /
  `unlocked_pictures` and stamps `last_free_redemption`. Idempotent
  (`alreadyUnlocked: true`).
- **members.pb.js** + **\_members_helper.js** - owner-only managed member
  CRUD. `POST /api/custom/managed-member` `{householdId, name, avatar?}` mints
  a loginless `users` row (`managed:true`, synthetic
  `{id}@haveyoufedthedog.com` email) + joins it to the household;
  `PATCH`/`DELETE /api/custom/managed-member/{userId}` edit / remove it. Runs
  privileged because an owner can't create a membership for another user, nor
  edit a `users` row they can't authenticate as.
- **notify.pb.js** + **\_notify_helper.js** - on completion create/delete,
  pushes "Brekkie done by George" to every _other_ member via the worker.
  (There is no overdue hook - that cron lives in the worker service, below.)
- **cleanup.pb.js** - after any `household_members` delete (leaving, or a
  deleted user account cascading): deletes the household when its last
  member is gone; promotes the longest-standing member to owner if the
  owner's account was deleted. Keeps households from ending up empty or
  unmanageable.

> **Goja gotcha:** PB runs every hook handler in its own fresh JS runtime.
> File-level declarations don't carry into handlers - share helpers with
> ``require(`${__hooks}/_helper.js`)`` _inside_ the callback, never at file
> level.

> **Timezone contract:** chore `hour`/`minute` are wall-clock values with no
> timezone - `households.timezone` (IANA) says whose wall. The overdue cron
> converts per household using Node's tz database, so the server's own clock
> setting doesn't matter. Households with an empty timezone are treated as
> Europe/London.

### Worker service (`server/services/worker/`)

Node/Express service with five jobs plus an on-demand endpoint (composed in
`index.js`; each concern is its own module). The three per-timezone crons share
`pb-cron.js` - the PB superuser client (auth + paginated `list` + `update`),
`zonedParts`, the once-a-minute non-overlapping scheduler, and the
household-by-timezone cache:

1. **FCM relay** - hooks POST `{tokens, title, body, data}` to
   `http://127.0.0.1:3055/notify`; it fans out via
   `firebase-service-account.json` (**gitignored secret** - lives only on
   the server; a fresh copy comes from Firebase console → Project settings
   → Service accounts). Firebase project: `haveyoufedthedog-a1d9f`.
2. **Overdue cron** (`overdue-cron.js`) - once a minute, per distinct
   household timezone, finds active chores whose wall-clock time passed in
   that zone's previous minute and weren't completed since that household's
   local midnight, and pushes "Brekkie is overdue - Kiko-dog is waiting!"
   to the whole household. Queries PB directly, which needs superuser
   credentials supplied via `/opt/haveyoufedthedog/worker/.env`
   (loaded by the systemd unit, **never committed** - template in
   `.env.example`):

   ```
   PB_URL=http://127.0.0.1:8090
   PB_SUPERUSER_EMAIL=cron@haveyoufedthedog.com
   PB_SUPERUSER_PASSWORD=<in the password manager>
   ```

   **Why a superuser:** collection rules are membership-scoped, so a normal
   user can't read across households; superuser auth bypasses rules.
   **Why a dedicated one** (`cron@…`, a record in `_superusers` - not an app
   user): rotating your personal admin password then can't silently kill the
   cron, and a leaked `.env` is revoked by deleting one service account.
   Without the `.env` the service still relays hook pushes - it just logs
   "[overdue] cron disabled" and sends no nudges.

3. **Award cron** (`award-cron.js`) - once a minute, per distinct household
   timezone, checks whether that zone just crossed the Sunday award cutoff
   (18:00 local). When it has, it settles that zone's just-finished award
   week (the seven days ending at the cutoff - the same Sun→Sun window the
   app shows via `WeekWindow.settledAward`), works out each subject's unique
   top contributor (ties win nobody), and pushes **one** notification per
   winning member however many subjects they topped ("Kiko-dog crowned you
   their Best Human for last week!"). Same superuser `.env` as the overdue
   cron. **Kept in lockstep with the app:** the presentation hour, the Sun→Sun
   window, the unique-max tiebreak, and the award-title flavour map are all
   duplicated from the app's award logic - change both sides together (the
   app names each app↔cron pair in `CLAUDE.md` → Data conventions).
4. **Retire cron** (`retire-cron.js`) - hourly (a couple of minutes past each
   hour), per household timezone, flips a finished **one-off** chore
   `active = false` the day **after** it was completed - so a `once` task
   carries over until done, then drops off for good. It only retires one whose
   latest completion is on a *prior* local day (one finished *today* stays
   active so it still shows as "done"). The app hides a finished one-off
   immediately client-side; this is the durable server-side retirement. Same
   superuser `.env` as the other crons.
5. **In-app-purchase verification** (`verify.js`) - hooks POST a receipt to
   `http://127.0.0.1:3055/verify-purchase`; it validates with the store and
   reports back so `purchases.pb.js` can grant the household its packs.
   **Android** uses the Play Developer API (`play-service-account.json`, another
   **gitignored secret**); config-gated, so no Play creds → it just rejects
   Android verifications and the rest of the service runs on. **iOS** POSTs the
   app receipt to Apple's `verifyReceipt` (production, then the sandbox endpoint
   on a `21007` so one build covers TestFlight + the App Store) - stateless, no
   credentials. `verifyReceipt` is deprecated but operational; a future
   StoreKit 2 + JWS move would retire it (and needs the client switched off
   StoreKit 1, which currently sends the receipt).
6. **Reward-streak compute** (`reward-streak.js`) - an on-demand endpoint, not
   a cron: `rewards.pb.js` POSTs `{householdId}` to
   `http://127.0.0.1:3055/reward-streak`, and it walks the household's active
   chores + recent completions in the household's IANA timezone to return the
   current lenient reward streak (consecutive due-days with any completion,
   counted after `last_free_redemption`; one-off chores are excluded from the
   due-day test, so a missed one can't break it). It's the **authority** for free
   streak-reward claims; the app computes an advisory copy for its progress
   bar. Uses the same superuser `.env` as the crons (no creds → the endpoint
   replies 503 and the rest of the service runs on).

### Backups

PB's built-in scheduled backups (admin UI → **Settings → Backups**) push to
**Cloudflare R2**: [R2 dashboard](https://dash.cloudflare.com/b19d93b69fec96bb747af3f99da2d936/r2/overview).
The SQLite data dir is the only irreplaceable thing on the box - everything
else (hooks, worker, nginx config) is in this repo or re-derivable.

To restore: admin UI → Settings → Backups → restore from the list; or
manually unzip a backup into `/var/lib/pocketbase/8090/` (stop PB first,
`chown -R pocketbase:pocketbase`, start PB).

**Access recovery:** Hetzner credentials, Firebase bits, and the SSH keys
(`dogbox`) are stored in **Google Drive** - start there if this machine is
gone.

### Email

PB sends password-reset (and any future verification) email via **Resend**
SMTP: host `smtp.resend.com`, **port 2587** (465/587 are blocked outbound on
the box), Auto/StartTLS, username `resend`, password = the Resend API key -
configured in PB admin → Settings → Mail and stored **nowhere else**. Sender
domain `haveyoufedthedog.com` is verified in Resend via Cloudflare DNS.

### Static files & the Android app association (`pb_public`)

PocketBase serves anything under `/var/lib/pocketbase/8090/pb_public/` at the
API domain root. **Gotcha:** unlike `--hooksDir` (which defaults relative to
`--dir`), PB's `--publicDir` defaults to the _binary_ dir
(`/opt/pocketbase/pb_public`), so the systemd unit passes
`--publicDir=/var/lib/pocketbase/%i/pb_public` to keep data + hooks + public
together. Files live in the repo at `server/pb_public/` and ship with
`bash server/.deploy/deploy-public.sh` (no PB restart - served live).

What's there today: **`.well-known/assetlinks.json`**, a Digital Asset Links
statement (`delegate_permission/common.get_login_creds`) tying the app to this
domain so a password set on PB's web **reset-password** page autofills back in
the app instead of being stranded under a separate "website" entry in the
password manager. It lists the **Play app signing key** SHA-256 - Play re-signs
uploads, so a locally-signed APK won't match; test the association via a Play
track, not a sideload. The app vouches from its side via an `asset_statements`
meta-data (`app/android/app/src/main/res/values/strings.xml` + a `<meta-data>`
in the manifest, compiled into the build). Both halves must be live for autofill
to treat web + app as one identity.

---

## The website

`https://haveyoufedthedog.com` - static landing page + the privacy policy and
account-deletion pages the Play Store requires. Source in `landing_page/src/`
(plain HTML + Tailwind v4; brand tokens in `landing_page/tailwind.css`).
After editing HTML classes run `npm run build` from `landing_page/` (the
built `src/style.css` is committed), then `bash landing_page/deploy-site.sh`
to publish. Served by nginx on the same box as the API
(`/var/www/haveyoufedthedog`, config reference in `landing_page/nginx-site.conf`,
TLS via the box's existing certbot). `hello@haveyoufedthedog.com` forwards to
georgefedthedog@gmail.com (steel) via Cloudflare Email Routing.

**Deep links (App Links / Universal Links).** Three paths open the app straight
from the web domain: `/join` + `/claim` (invite + managed-member claim) and
`/nfc-tap` (an NFC tag tap). Both platforms verify against files served from
`haveyoufedthedog.com` - `.well-known/assetlinks.json` (Android) and
`.well-known/apple-app-site-association` (iOS) - which live in `landing_page/src/`
and publish with the site. **Adding a path means touching both** the AASA
`components` and the Android manifest `pathPrefix`
(`app/android/app/src/main/AndroidManifest.xml`); the SHA in `assetlinks.json` is
the Play app-signing key, so Android verification only holds on Play-distributed
builds. A new **NFC** path additionally needs the Android `NDEF_DISCOVERED`
intent-filter in the same manifest and an AAR on the tags (see the NFC note
below) - App Link verification alone does not auto-open a tag on Android 13+. iOS fetches the AASA through Apple's CDN, which **caches** it - a new
path can take hours to appear and only takes effect on a fresh install (check
the live cache with `curl -s https://app-site-association.cdn-apple.com/a/v1/haveyoufedthedog.com`).
This is separate from the _autofill_ `assetlinks.json` under `server/pb_public/`,
which is on the API domain (see "Static files").

---

## Localization

The product ships in **English, German, French and Spanish**. Language
follows the device, with a per-device override on Edit Profile; the app
writes the resolved language to `users.locale` so the server can localize
pushes. The moving parts, from the inside out:

- **App UI** - Flutter gen_l10n: ARBs in `app/lib/l10n/app_<lang>.arb`
  (English is the template and fallback). Every user-facing string goes
  through `context.l10n.<key>`; `untranslated.json` lists gaps and must stay
  empty. Dates, clock strings and schedule sentences come from
  `core/chores/schedule_labels.dart` (English keeps the lowercase
  "6:30 pm"; de/fr/es are 24-hour).
- **Character voices** - data, not ARB. Bundled characters' English lines
  are the const table in `character_message.dart`; their translations ship
  as `app/assets/l10n/characters/<lang>.json`. Pack characters carry copy on
  `catalog_characters.messages`, with translations nested under its `i18n`
  key (authored as `messages.<lang>.json` beside each character's
  `messages.json`; `upload_pack.py` merges them). An untranslated pack falls
  back to the localized generic voice rather than mixing languages.
- **Catalog names** - flat `{lang: text}` JSON columns, base field =
  English fallback: `display_name_i18n` on characters/pictures, `name_i18n`
  on packs/products, `description_i18n` on products. Authored in
  `image_packs/pack_manifest.json`, pushed by `upload_pack.py`.
- **Server pushes** - composed per recipient from `users.locale` (empty =
  English, so pre-i18n clients see the exact old strings). Templates live in
  the worker's `l10n.js` (overdue + award) and the hooks' `_l10n_helper.js`
  (completions).
- **Hook errors** - each carries a stable snake_case `code` alongside its
  English `message`; the app maps codes to ARB strings in
  `core/api/server_messages.dart` and falls back to the raw message.
- **Landing page** - `join.html` / `claim.html` / `index.html` swap copy
  client-side from inline dictionaries keyed on `navigator.language`;
  the English markup is the fallback.
- **Store listings** - translated Play/ASC listing + IAP copy is drafted in
  `store_listings_i18n.md`, pasted into the consoles by hand.

Deliberately English: the PocketBase password-reset email (PB's built-in
template, configured in the admin UI) and `catalog_avatars` display names
(never rendered anywhere).

---

## Running the app locally

Built and shipped with **Flutter 3.44.1 (stable) / Dart 3.12.1**. Package
versions are pinned for good reasons (`nfc_manager` 4.x is a breaking API
rewrite) - don't `flutter upgrade` casually; if you must, expect to revisit
the pinned deps.

One-time setup:

```bash
cd app
flutter pub get
dart run build_runner build --delete-conflicting-outputs   # riverpod codegen
```

> `dart run build_runner ...` must run from `app/` (the pubspec lives there,
> not at repo root). Re-run it whenever you touch a `@riverpod` annotation;
> `*.g.dart` files are generated.

### On a phone via wireless debugging

1. Phone: Settings → Developer options → **Wireless debugging** → on.
2. First time per network: phone shows "Pair device with pairing code" →
   `adb pair <ip>:<pairing-port>` and type the code.
3. Every session: `adb connect <ip>:<port>` (the port on the main wireless
   debugging screen, not the pairing one - it changes between sessions).
4. `flutter devices` should list the phone; `flutter run` from `app/`.

Hot reload `r`, hot restart `R`. New **assets** and new **routes** need a full
stop + `flutter run`; pure widget changes don't. Note: provider state survives
hot reload, so changes inside `@riverpod` providers need `R` to show up.

### On an emulator

```bash
flutter emulators                      # list configured AVDs
flutter emulators --launch <id>        # boot one (e.g. Pixel_9)
flutter run                            # from app/, once it's booted
```

No AVDs listed? Create one either in Android Studio (Device Manager → Create
device) or from the CLI:

```bash
flutter emulators --create --name pixel    # uses the default Pixel profile
```

If `flutter emulators` comes up empty entirely, the Android SDK emulator
package is missing - install "Android Emulator" + a system image via Android
Studio's SDK Manager.

Emulator caveats for this app: **no NFC** (writing a tag can't be tested), and
**FCM pushes only arrive if the AVD has Google Play services** (pick a
Play-enabled system image). The NFC _tap_ logic is just the `/nfc-tap` deep
link, so it's still testable without hardware - fire it with
`adb shell am start -a android.intent.action.VIEW -d "https://haveyoufedthedog.com/nfc-tap?household=<hid>&subject=<sid>" -n com.haveyoufedthedog/.MainActivity`
(escape the `&` as `\&` if your shell eats it). UI work is fine on an emulator;
writing a tag and push need hardware.

### Sanity checks

```bash
flutter analyze        # should be "No issues found!"
```

There are no automated tests (deliberate, family-scale) - verification is
hot-reload-and-look.

---

## Building an Android release

Two outputs: an **app bundle** (`.aab`) for the Play Store - the real release
channel - or a **split APK** to hand someone directly. Either way, **bump the
version in `pubspec.yaml` first** (`version: 0.4.3+2006` - semver `+` build
number; Play and Android both reject a build number that isn't higher than
what's already there). There's no Android CI - both are built locally and
uploaded / sent by hand (`codemagic.yaml` is iOS-only).

### Play Store (`.aab`) - the primary path

```bash
cd app
flutter build appbundle --release
```

Upload `app/build/app/outputs/bundle/release/app-release.aab` to a track in
Play Console (Internal / Closed / Production), create the release, and roll it
out. Every new bundle is reviewed (testing tracks clear faster than
production; **Internal testing is review-free**). Google **re-signs** the
bundle with the Play app signing key before delivery, so installed apps carry
Google's cert, not your upload key - which is why `assetlinks.json` lists the
_Play app signing key_ SHA-256 and the credential association only verifies on
Play-distributed builds (see "Static files & the Android app association").

### Sideload (`.apk`) - quick hand-off

```bash
cd app
flutter build apk --release --split-per-abi
```

Send `app/build/app/outputs/flutter-apk/app-arm64-v8a-release.apk` (works on
any modern phone, half the size of the universal APK) via WhatsApp/Drive/etc.;
the recipient taps it and allows "install from unknown sources". These are
signed with your upload key (not Play's), so they can't upgrade over a
Play-installed copy and the assetlinks association won't match them.

**Signing:** release builds are signed with the real keystore at
`app/android/app/upload-keystore.jks`; passwords live in
`app/android/key.properties` (both **gitignored** - backup copies are in
Google Drive). Gradle falls back to debug signing if `key.properties` is
missing, so a keystore-less clone still builds - but Play rejects debug-signed
bundles and those artifacts can't upgrade a properly-signed install. **Play App
Signing is on**, so this keystore is your _upload_ key (Google holds the real
app signing key): losing it is recoverable via an upload-key reset in Play
Console - but it still signs your sideload APKs and is your identity to Google,
so keep the Google Drive backup.

Launcher icons are generated, not hand-made: source art in
`app/assets/general/app_icon*.png`, regenerate with
`dart run flutter_launcher_icons` after changing them. Same deal for the
**native splash** (the pre-Flutter boot screen): configured in
`pubspec.yaml` under `flutter_native_splash:`, regenerate with
`dart run flutter_native_splash:create`.

---

## Building an iOS release (Codemagic)

iOS builds run in the cloud on **Codemagic** (dev is on Windows - no local
Mac/Xcode). Config is `codemagic.yaml` at the repo root: workflow `ios-release`,
`working_directory: app`, instance `mac_mini_m2`. Codemagic reads the yaml from
the **pushed** repo, so the flow is: push to `main`, then **Start build** in the
Codemagic UI (branch `main`, workflow `iOS Release`). The pipeline is
`flutter pub get` → fetch/create signing files → `xcode-project use-profiles` →
`flutter build ipa` (generates the Podfile + runs `pod install` on the fly) →
upload to TestFlight. Generated `*.g.dart` are committed, so CI doesn't run
build_runner.

- **Bundle id** `com.haveyoufedthedog.app` (iOS) is deliberately _different_ from
  the Android `applicationId` `com.haveyoufedthedog` (App Store and Play are
  independent registries); permanent now the App Store record exists.
- **No Xcode locally:** edit everything under `ios/` (Info.plist, entitlements,
  `Runner.xcodeproj/project.pbxproj`) as plain text. Adding a bundled resource
  takes four coordinated `project.pbxproj` entries: file reference, build file,
  group child, and Copy Bundle Resources phase.
- **Firebase on iOS** is native-config, mirroring Android: `GoogleService-Info.plist`
  is committed at `app/ios/Runner/` and wired into the build, so
  `Firebase.initializeApp()` finds it. No `firebase_options.dart`. It's not a
  secret (it ships in every IPA; the backend is PocketBase, and FCM is the only
  Firebase use).
- **Signing** is Codemagic's **App Store Connect API key** integration (named
  `haveyoufedthedog_asc` - the name must match the yaml), which drives both code
  signing and the TestFlight upload. The distribution certificate is
  **self-managed**: an RSA private key (`openssl genrsa 2048`, generated once) is
  fed in via `--certificate-key=@env:CERTIFICATE_PRIVATE_KEY` from the secure
  Codemagic variable group `ios_signing`, so `app-store-connect
fetch-signing-files ... --create` builds the cert _from that key_ on the first
  run and reuses the same cert on every build after - no certificate sprawl. That
  private key is the one irreplaceable artifact (Apple never stores it;
  provisioning profiles and the App ID regenerate freely), so it's backed up in
  Google Drive alongside the Android keystore. To move to a Mac/other CI later,
  re-pair the key with the public cert (downloadable from the portal) into a
  `.p12`.
- **App ID capabilities must mirror the app's entitlements** (Apple Developer →
  Identifiers). The app declares **NFC Tag Reading** + **Push** (`aps-environment`)
  in `Runner.entitlements`, with the APNs auth key uploaded to Firebase. The NFC
  formats entitlement must be **`TAG`** (`NFCTagReaderSession`) - the current
  Xcode/iOS SDK rejects `NDEF` at App Store upload - and `NFCReaderUsageDescription`
  is set in `Info.plist`. **iOS IAP verification** (StoreKit 2 + JWS in the worker)
  is still deferred.
- **Export compliance** is declared in `ios/Runner/Info.plist`
  (`ITSAppUsesNonExemptEncryption` = false - the app uses only standard HTTPS),
  so uploads skip the "Missing Compliance" gate and are immediately installable.
- **TestFlight:** internal testers get every uploaded build automatically.
  **External** testers (the public-link `Family And Friends` group) need **Beta App
  Review**, so `submit_to_testflight: true` + `beta_groups` auto-submits each build.
  Two gotchas: external review needs **Test Information + a demo login account** (the
  app is login-gated) or it bounces; and the submit step can red-flag on slow Apple
  processing even though the upload succeeded - just submit the build to the group in
  the UI. **Bump the build number** (`pubspec.yaml` `+N`) every release - App Store
  Connect rejects a re-used number, same as Android.

---

## Deploying to the server

Hooks and/or worker (the common case):

```bash
bash server/.deploy/deploy-hooks.sh      # pb_hooks + PB restart
bash server/.deploy/deploy-worker.sh     # worker + service restart
bash server/.deploy/deploy-public.sh     # pb_public static files (no restart)
bash server/.deploy/deploy-all.sh        # all three
```

Run from Git Bash / WSL. The SSH key may prompt for its passphrase
(`ssh-add ~/.ssh/dogbox` once per session avoids repeats).
**deploy-hooks.sh and deploy-worker.sh both ship a hardcoded file list** -
adding a new hook / worker file means adding it to the `tar` line in the
script.

Schema changes are **manual and admin-UI-first** (live data is sacred, PB's
import diff is fiddly): make the change in the live admin UI, then Settings →
Export collections, replace `server/pb_schema.json` with the export, commit.
There's no separate walkthrough doc - ask Claude for step-by-step
instructions when making a schema change.

---

## Publishing new design assets (day-to-day)

- **Avatar:** new `catalog_avatars` row - slug, display name, square PNG.
  Saved = live (next app launch); there's no per-row draft state.
- **Household picture:** new `catalog_pictures` row - all five
  time-of-day PNGs are required (morning / midday / afternoon / evening /
  night), same framing as the bundled sets. Generate them from `image_packs/`
  (needs `OPENAI_API_KEY`): `python generate_house_sheet.py --slug <slug>
  --house "..." --setting "..."` renders one 3x2 six-scene contact sheet via
  the OpenAI images API (default model `gpt-image-2`; built-in softened
  semi-real style, `--style-text` to override; `--dry-run` to preview the
  prompt; run with no args for an interactive prompt) - and auto-pads a white
  outer border so the split step's gutter detection works. Then
  `python split_house_sheets.py <slug>` cuts the sheet into the five tiles
  (dropping the 6th "rainy" cell). Naming a real famous building works well
  but note the trademark/likeness caveat for paid catalog art.
- **Character:** new `catalog_characters` row - `idle` PNG and
  `base_color` (#RRGGBB pastel; the app derives the stage gradient) are
  required; `happy`, `sad`, `celebrate`, `sleeping`, `award` are optional
  and fall back along the same chain as bundled art (celebrate→happy→idle
  etc.). Remote characters use the generic task-tick as their icon
  fallback while art is loading/failed.
  - **Personality copy (`messages`, optional JSON):** gives a pack character
    its own voice instead of the bundled `generic` lines. Everything is
    optional and falls back **per slot** to the generic copy - omit a mood,
    or the whole field, to inherit it. Hand-authored when creating the row:

    ```json
    {
      "lines": {
        "allDone": [{ "title": "Full and snoozing.", "body": "{name} had a great day 🦊" }],
        "overdue": [{ "title": "Still waiting…", "body": "{name} keeps checking the bowl." }],
        "upcoming": [{ "title": "Ears up!", "body": "{name} heard the cupboard." }],
        "happyForNow": [{ "title": "All chill.", "body": "{name} is having a relaxed one." }],
        "none": [{ "title": "Day off!", "body": "{name} approves." }]
      },
      "awardTitle": "Best Floof 🦊",
      "awardThanks": "Thanks for the snuggles last week!"
    }
    ```

    - `lines` drives the subject-hero status line. The five mood keys are
      fixed: `allDone` (all today's chores logged), `overdue` (one is past
      its time), `upcoming` (due within 60 min), `happyForNow` (pending but
      > 60 min off), `none` (nothing due today). Each is a **list** of
      > `{title, body}` variants - one is picked at random per view, so add a
      > few to keep it fresh. `{name}` is replaced with the subject's name in
      > both fields.
    - `awardTitle` / `awardThanks` are single strings shown on the weekly
      featured-award card. The Sunday award push names only the subject
      ("You've received an award from {subject}"), so the title never has to
      match anything server-side.
    - Bundled characters (dog/cat/etc.) ignore this field - their copy is
      hardcoded in the app.

- `sort_order` orders the whole picker: bundled + remote art are merged and
  sorted by it together (bundled entries carry their own `sortOrder` in the
  registries, so they interleave into the right group; a bundled entry wins a
  tie with a remote one). Slugs are forever - they're stored on user /
  household / subject records; never rename or reuse one.
- **Image pack:** a `catalog_packs` row (code + name + enabled + redeemable),
  then add it to the `packs` of the art rows that belong to it - those rows
  are only _selectable_ by households that own the pack (bought via a product
  or redeemed by code; Household details → Image packs). Rows with no pack
  stay visible to everyone. Full pack workflow: see "Publishing a pack" below
  (a by-hand process - ask Claude for step-by-step instructions).
- **Staging / retiring an item:** set its `packs` to only a disabled pack
  nobody owns (keep a permanent "Vault" pack for this); restore its real packs
  to (re)publish. Never delete a row someone may have picked - slugs are
  forever.
- Files are public-read by URL (not `protected`) so Cloudflare edge-caches
  them; don't upload anything private.

---

## Publishing a pack (day-to-day)

1. `catalog_packs` row: pick a code (share-friendly, e.g. `WOOF-2026` -
   it's normalised to upper-case on redeem), a name (what friends see in
   the snackbar / household details), enabled ✓ AND redeemable ✓.
2. Create the art rows as usual (see README "Publishing new design
   assets") and add the pack to each row's `packs`. A row can belong to
   several packs (e.g. its category group + an "everything" pack).
   Tip: keep one permanent disabled pack named "Vault" (any code, never
   share it) - setting a row's `packs` to just Vault hides it everywhere,
   reversibly. That's the staging/retiring mechanism for general-catalog
   rows.
3. Share the code, or sell the pack via a `catalog_products` row. Any member
   applies a code once per household (Household details → Image packs);
   everyone in that household then sees the art in their pickers.

Caveats:

- Translations ride along with the uploader: `messages.<lang>.json` beside a
  character's `messages.json` (merged under the `messages.i18n` key) and
  `display_name_i18n` / `name_i18n` / `description_i18n` keys in
  `pack_manifest.json` (pushed to the matching catalog columns). All
  additive - publishing them never affects released clients; an
  untranslated pack simply speaks the localized generic voice in non-English
  UIs (see "Localization").
- To retire a code without punishing existing households, untick
  `redeemable` (newcomers get "That pack is no longer available to
  redeem."; applied households are untouched). Unticking `enabled` is the
  bigger hammer: it also hides the items from everyone, including
  households that already applied it - members who picked that art fall
  back to defaults until re-enabled.
- To revoke a single household, remove the pack from its `packs` field in
  the admin UI. Note this only re-gates _selection_ (the pickers): art a
  member already chose still resolves while the pack stays `enabled`, and a
  packed avatar a member can pick from another of their households remains
  selectable there. Unticking `enabled` is the only switch that hides art
  everywhere.
- Pack slugs follow the same forever-rule as all catalog slugs.

---

## Things you'll have forgotten in 6 months

- **Where state lives.** Everything is server-truth via Riverpod controllers
  (`app/lib/core/**`); the only on-device state is SharedPreferences
  (NFC tap preference `nfc_tap_completes_chore`, onboarding-seen flag, and
  `catalog_snapshot_v1` - the last successful catalog fetch, for offline
  cold starts), the cached_network_image disk cache (remote art bytes),
  and the PB auth token in secure storage.
- **The art system is two layers.** Bundled: three id→asset registries -
  `CharacterRegistry` (dog/cat/plant/bin/fish/generic, expression PNGs
  idle/happy/sad/sleeping/celebrate + `award.png`), `PictureRegistry`
  (houses, five time-of-day variants), `AvatarRegistry` (user avatars) -
  PNGs in `app/assets/...`. Remote: the `catalog_*` PB collections, merged
  with the bundled entries and sorted together by `sortOrder` by
  `catalogProvider` (`app/lib/core/catalog/`); bundled wins slug collisions
  and ties (so a bundled entry leads its group). **Resolution is ungated:** the fetch pulls
  every row with no pack or _any_ enabled pack, so a chosen
  avatar/picture/character renders in any household the viewer is in - not
  only one that owns the pack (a row drops from the fetch only when _none_ of
  its packs is enabled, so that art falls back). **Selection is gated** by
  `selectableCatalogProvider`: the pickers offer general art plus entitled
  rows - pictures/characters when the _current_ household owns any of the
  row's packs, avatars when any of the user's households does (avatars are
  personal, so they travel with the user).
  **Widgets must read art via `ref.watch(catalogProvider).lookupX(id)` and
  the models' `imageProvider` getters** - never the static registries or
  `Image.asset` directly - or remote art won't resolve; the three pickers
  read `selectableCatalogProvider` instead. Fail-soft chain:
  live fetch → SharedPreferences snapshot → bundled-only. New art ships
  via the catalog (no app release); bundled is only for the day-one
  defaults. Asset art is generated by image-gen then background-removed
  with `rembg`.
- **Everything user-visible is localized (en/de/fr/es).** New UI copy means
  a key in all four ARBs (`app/lib/l10n/`); a new hook error means a `code`
  in the hook + a `serverMessage` case + `server*` ARB keys; push templates
  live in the worker's `l10n.js` and the hooks' `_l10n_helper.js`, and the
  empty-locale (pre-i18n client) output must stay byte-identical English.
  Clock/schedule strings come from `schedule_labels.dart` - never
  `TimeOfDay.format`. The Android notification channel id
  `chore_completions` is pinned forever even though its display name is
  localized. Full map: README "Localization" + CLAUDE.md "Localization
  (i18n)".
- **Don't watch `authControllerProvider.future`.** Riverpod re-notifies
  `.future` watchers on every state assignment regardless of equality, and
  auth re-emits on every profile/fcm_token write - that combination once
  refetched the world and bounced the router through splash on every
  avatar save. Identity-scoped controllers watch
  `authControllerProvider.selectAsync((a) => a.userId)` instead (see the
  comment in `auth_controller.dart`); one-shot `ref.read(...future)` in
  actions is fine.
- **Awards & stats are pure derivations** of the last ~100 cached completions
  (`weeklyAwardsProvider`, `choreMeanTimesProvider`, leaderboard). No server
  aggregation. Weeks are Mon→Sun local; ties award nobody. **Exception:** the
  per-subject character "Best Human" awards lock to the last _settled_ week
  (Sunday 18:00 → next Sunday 18:00, `WeekWindow.settledAward`) so they don't
  change hands mid-week, and that same window/winner logic is mirrored in the
  worker's `award-cron.js` for the weekly push - the two must stay in sync
  (`CLAUDE.md` → Data conventions lists each app↔cron pair).
- **Free streak rewards.** A household earns a catalog character or house
  picture for free by keeping a daily streak, claimed on `features/rewards/`
  (reached from the reward-streak bar on the Awards tab + the foot of the
  store). Earnable = resolvable catalog art it can't already select and not
  `reward_excluded`; a claim writes the slug to
  `households.unlocked_characters`/`unlocked_pictures`, which the
  `selectableCatalogProvider` gate ORs into the pickers. The streak is lenient
  + household-wide and resets per claim (`last_free_redemption`); the bar is
  `reward_streak_threshold` (default 28). Computed twice like the awards: the
  app's `reward_streak_controller.dart` is advisory (progress bar), the
  worker's `reward-streak.js` (via the `claim-streak-reward` hook) is the
  authority that gates the grant.
- **The drag-and-drop language.** Removing members, leaving a household,
  deleting chores, logging out - all
  `LongPressDraggable` onto a dashed-circle `DragTarget`
  (`app/lib/widgets/dashed_circle_painter.dart`). Destructive drops confirm;
  navigational ones don't.
- **Theme conventions.** Knewave on `headline*` + AppBar titles, Plus Jakarta
  Sans everywhere else (keep `display*` on the body font or the time picker
  goes funky). Inputs are theme-level filled boxes - never style per-field;
  labels via `LabeledField` (the label sits _outside_ the field, so credential
  autofill on login/signup rides on `autofillHints` + an `AutofillGroup` +
  `TextInput.finishAutofillContext()` on submit - see `login_form.dart`).
  Page background is a BL→TR gradient from
  `AppBackdrop` (scaffolds are transparent); dark mode is deliberately flat
  (gradients band near black). Dark/light follows the phone.
- **NFC flows open the app via the OS, not in-app reading.** A tag holds
  `https://haveyoufedthedog.com/nfc-tap?household=<hid>&subject=<sid>`; tapping it
  (app open, backgrounded, or closed) opens the app, which `DeepLinkHandler`
  parks (the `app_links` plugin reads the launch intent's data URI) and `AppRoot`
  routes to `NfcLaunchHandler.handleNfcTap`. That switches to the tag's household
  if the tapper is a member (so a multi-household dog-walker logs against the
  right house without switching first), then completes the next due chore or
  opens the subject page per the Edit Profile per-device toggle. The app never
  _reads_ tags - it only _writes_ them (`Edit thing → Write an NFC tag`:
  `core/nfc/nfc_service.dart` + `features/nfc/nfc_write_dialog.dart`, via
  `nfc_manager`). **The tag carries records for both platforms:** an NDEF URI
  record (iOS Universal Link) **plus an Android Application Record (AAR)** naming
  `com.haveyoufedthedog`. iOS uses the URI record and ignores the AAR; Android
  13+/Pixel routes a bare `https` tag through the OS "Open link found via NFC?"
  weblink prompt (never offering it to our `NDEF_DISCOVERED` intent-filter), so
  the AAR is what forces a direct launch. The AAR lives **on the tag**, so
  changing the package name or tag format means re-writing every existing tag.
  **Two more gotchas, both load-bearing:** (1) we pass
  `pollingOptions: {iso14443, iso15693}` to `startSession` - the default also
  polls FeliCa (`iso18092`), which iOS gates behind a `felica.systemcodes`
  entitlement we don't have, so a write fails with "Missing required entitlement"
  (NTAG stickers are iso14443). (2) the iOS NFC formats entitlement must be
  **`TAG`** (`NFCTagReaderSession`) - the current Xcode/iOS SDK rejects `NDEF` at
  App Store upload. Writing needs real hardware (no emulator); tapping is just a
  deep link, so it works on any phone with the app installed.
- **Known limitations, accepted:** one `fcm_token` per user - the last
  device to launch the app owns pushes (only bites a developer with
  several devices on one account; fix someday = a `device_tokens`
  collection); awards windows are bounded by the
  100-completion cache; package versions are pinned because `nfc_manager 4.x`
  is a breaking rewrite (KGP deprecation warning at build time is known and
  upstream).
- **PB upgrade caution.** Hooks target PB 0.2x JSVM (`$app`, `$dbx`, `$http`,
  `cronAdd`, `e.requestInfo().body`) - skim the PB changelog before bumping
  the binary on the server.
- **Where the secrets are:** Resend API key → PB admin Mail settings only.
  Firebase service account JSON → on the server only. Cron superuser creds
  → `/opt/haveyoufedthedog/worker/.env` on the server only. SSH key
  → `~/.ssh/dogbox`. Release keystore → `app/android/` (gitignored) +
  Google Drive. App Store Connect API key (`.p8`) → Codemagic integration
  `haveyoufedthedog_asc` (downloadable only once at creation - keep a backup);
  the iOS distribution cert private key (`.pem`) → secure Codemagic group
  `ios_signing` (var `CERTIFICATE_PRIVATE_KEY`) + Google Drive backup. Nothing
  secret is in this repo.
