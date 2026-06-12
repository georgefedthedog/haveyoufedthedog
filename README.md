# Have You Fed The Dog?

A cosy family chore tracker. Everything the household looks after - the dog,
the cat, the plants, the wheelie bin - becomes a friendly cartoon **character**.
Chores recur on a schedule ("Brekkie, every day at 6:50 am"), anyone in the
household can tick them off (tap a row, or tap an **NFC tag** stuck near the
dog food), and everyone else gets a push notification. Completions feed
streaks, a weekly leaderboard, and a tongue-in-cheek **awards** system
(Early Bird, Night Owl, "Kiko-dog's Best Human 🩵"…). Branded as a dog feeder,
but the engine is generic recurring-care tasks.

Monorepo, two independent halves:

```
app/      Flutter app (Android-first). Online-only PocketBase client.
server/   PocketBase schema + JS hooks + Node push-notifier + deploy scripts.
_old/     Previous attempt, gitignored, reference only.
```

Stack: **Flutter** (Riverpod codegen, GoRouter, google_fonts) ·
**PocketBase** (the entire API - REST endpoints auto-derived from the schema) ·
**Node push-notifier** (FCM relay) · **Firebase Cloud Messaging** · **Resend** (SMTP).

---

## The server

Live at `https://api.haveyoufedthedog.com` - PocketBase behind **nginx +
Cloudflare** on a Hetzner box (`dogbox-1`).

| What          | Where                                                                                        |
| ------------- | -------------------------------------------------------------------------------------------- |
| SSH           | `ssh -i ~/.ssh/dogbox -p 2222 george@65.108.215.132`                                         |
| PocketBase    | systemd `pocketbase@8090`, data in `/var/lib/pocketbase/8090/`                               |
| Hooks         | `/var/lib/pocketbase/8090/pb_hooks/`                                                         |
| Push-notifier | systemd `push-notifier`, `/opt/haveyoufedthedog/push-notifier/`, listens on `127.0.0.1:3055` |
| Admin UI      | `https://api.haveyoufedthedog.com/_/`                                                        |
| Logs          | `bash server/scripts/view-logs.sh` or `journalctl -u pocketbase@8090 -f`                     |

### Collections (`server/pb_schema.json` is the canonical export)

- **users** - PB auth collection. Extra fields: `name`, `avatar` (text id -
  a bundled-registry id or a `catalog_avatars` slug), `fcm_token` (this
  device's push token).
- **households** - `name`, `picture` (text id into the house-picture registry),
  `invite_code` + `invites_open` (single shareable code, toggleable),
  `timezone` (IANA name, captured from the creator's phone; empty =
  Europe/London), `residents` ("Who lives here?" label, e.g. "The
  Goodchilds"), `packs` (**multi**-relation to `catalog_packs` - the image
  packs this household has redeemed; PB serializes single relations as a
  bare string, so keep it multi).
- **household_members** - user ↔ household join with `role` (`owner`/`member`).
- **household_member_details** - read-only SQL **view** joining members to
  `users` so the app gets `user_name` + `user_avatar` in one fetch.
- **subjects** - the characters. `name`, `household`, `icon` (character id:
  dog/cat/plant/bin/fish/generic, or a `catalog_characters` slug),
  `nfc_tag_id`.
- **chores** - `subject`, `name`, `schedule_type` (`daily`/`weekly`), `hour`,
  `minute`, `weekday_mask` (Mon=1 … Sun=64, i.e. `1 << (weekday-1)`),
  `active`. **Times are family wall-clock with no timezone** - see the
  timezone contract below.
- **completions** - `subject`, `chore`, `completed_by`, `completed_at` (UTC),
  `source` (`button`/`nfc`). `completed_by` is **optional and non-cascading**
  on purpose: deleting a user account blanks it (PB clears optional
  references), so household history survives anonymised.
- **catalog_avatars / catalog_pictures / catalog_characters** - the remote
  art catalog (ship new art without an app release). Per row: `slug` (the
  forever-id stored on user/household/subject records), `display_name`,
  `sort_order`, the art file field(s), and an optional `pack` relation
  (empty = general catalog, everyone sees it). No per-row draft flag:
  saved = live; stage/retire via the Vault pack trick (see "Publishing").
- **catalog_packs** - gift-able art bundles. `code` (**hidden field** -
  clients can't read or filter it; only the redeem hook resolves it),
  `name`, `enabled` (pack live at all), `redeemable` (accepts new
  households). Redeemed via `packs.pb.js`, never by direct client writes.

All API rules are membership-scoped (you only see rows for households you're
in). Rule recipes and pitfalls: `server/scripts/apply-schema.md`.

### Hooks (`server/pb_hooks/`)

- **join.pb.js** - `POST /api/custom/join-household-by-code`. Runs privileged
  so non-members can redeem a code without weakening household read rules.
  Idempotent.
- **packs.pb.js** - `POST /api/custom/redeem-pack-code` `{code, householdId}`.
  Runs privileged because `catalog_packs.code` is hidden from clients.
  Checks membership, requires the pack `enabled` + `redeemable`, appends to
  `households.packs`. Idempotent (`alreadyApplied: true`).
- **notify.pb.js** + **\_notify_helper.js** - on completion create/delete,
  pushes "Brekkie done by George" to every _other_ member via the notifier.
  (There is no overdue hook - that cron lives in the push-notifier, below.)
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

### Push-notifier (`server/services/push-notifier/`)

Node/Express service with two jobs:

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
   credentials supplied via `/opt/haveyoufedthedog/push-notifier/.env`
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

### Backups

PB's built-in scheduled backups (admin UI → **Settings → Backups**) push to
**Cloudflare R2**: [R2 dashboard](https://dash.cloudflare.com/b19d93b69fec96bb747af3f99da2d936/r2/overview).
The SQLite data dir is the only irreplaceable thing on the box - everything
else (hooks, notifier, nginx config) is in this repo or re-derivable.

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

Emulator caveats for this app: **no NFC** (tag binding/tapping can't be
tested), and **FCM pushes only arrive if the AVD has Google Play services**
(pick a Play-enabled system image). UI work is fine on an emulator; anything
NFC- or push-shaped needs hardware.

### Sanity checks

```bash
flutter analyze        # should be "No issues found!"
```

There are no automated tests (deliberate, family-scale) - verification is
hot-reload-and-look.

---

## Building a release APK

```bash
cd app
# 1. Bump the version FIRST - Android refuses to install a build number
#    that isn't higher than what's on the phone:
#    pubspec.yaml -> version: 0.21.0+53   (semver + build number)
flutter build apk --release --split-per-abi
```

Send `app/build/app/outputs/flutter-apk/app-arm64-v8a-release.apk` (works on
any modern phone, half the size of the universal APK) via WhatsApp/Drive/etc.
The recipient taps it and allows "install from unknown sources".

**Signing:** release builds are signed with the real keystore at
`app/android/app/upload-keystore.jks`; passwords live in
`app/android/key.properties` (both **gitignored** - backup copies are in
Google Drive). The Gradle config falls back to debug signing if
`key.properties` is missing, so a keystore-less clone still builds - but
those APKs can't upgrade over a properly-signed install. Losing the
keystore = the family must uninstall/reinstall, and Play Store would be a
new app. Don't lose it.

Launcher icons are generated, not hand-made: source art in
`app/assets/general/app_icon*.png`, regenerate with
`dart run flutter_launcher_icons` after changing them. Same deal for the
**native splash** (the pre-Flutter boot screen): configured in
`pubspec.yaml` under `flutter_native_splash:`, regenerate with
`dart run flutter_native_splash:create`.

---

## Deploying to the server

Hooks and/or notifier (the common case):

```bash
bash server/scripts/deploy-hooks.sh      # pb_hooks + PB restart
bash server/scripts/deploy-notifier.sh   # push-notifier + service restart
bash server/scripts/deploy-all.sh        # both
```

Run from Git Bash / WSL. The SSH key may prompt for its passphrase
(`ssh-add ~/.ssh/dogbox` once per session avoids repeats).
**deploy-hooks.sh ships a hardcoded file list** - adding a new hook file
means adding it to the `tar` line in the script.

Schema changes are **manual and admin-UI-first** (live data is sacred, PB's
import diff is fiddly): make the change in the live admin UI, then Settings →
Export collections, replace `server/pb_schema.json` with the export, commit.
Full walkthrough + rule recipes: `server/scripts/apply-schema.md`.

---

## Publishing new design assets (day-to-day)

- **Avatar:** new `catalog_avatars` row - slug, display name, square PNG.
  Saved = live (next app launch); there's no per-row draft state.
- **Household picture:** new `catalog_pictures` row - all five
  time-of-day PNGs are required (morning / midday / afternoon / evening /
  night), same framing as the bundled sets.
- **Character:** new `catalog_characters` row - `idle` PNG and
  `base_color` (#RRGGBB pastel; the app derives the stage gradient) are
  required; `happy`, `sad`, `celebrate`, `sleeping`, `award` are optional
  and fall back along the same chain as bundled art (celebrate→happy→idle
  etc.). Remote characters use the generic task-tick as their icon
  fallback while art is loading/failed.
- `sort_order` orders rows within the remote block (bundled art always
  comes first in pickers). Slugs are forever - they're stored on user /
  household / subject records; never rename or reuse one.
- **Image pack (gift art to friends):** `catalog_packs` row (code + name +
  enabled + redeemable), then set `pack` on the art rows that belong to it -
  those rows are only served to households that have redeemed the code
  (Household details → Image packs). Untagged rows stay visible to
  everyone. Full workflow + schema: `server/scripts/apply-packs.md`.
- **Staging / retiring an item:** assign its `pack` to a disabled pack
  nobody redeems (keep a permanent "Vault" pack for this); clear the field
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
   assets") and set each row's `pack` to the pack. A row belongs to at
   most one pack; want the same art in two packs → two rows (distinct
   slugs).
   Tip: keep one permanent disabled pack named "Vault" (any code, never
   share it) - parking a row's `pack` there hides it everywhere,
   reversibly. That's the staging/retiring mechanism for general-catalog
   rows.
3. Share the code. Any member applies it once per household (Household
   details → Image packs); everyone in that household then sees the art
   in their pickers.

Caveats:

- To retire a code without punishing existing households, untick
  `redeemable` (newcomers get "That pack is no longer available to
  redeem."; applied households are untouched). Unticking `enabled` is the
  bigger hammer: it also hides the items from everyone, including
  households that already applied it - members who picked that art fall
  back to defaults until re-enabled.
- To revoke a single household, remove the pack from its `packs` field in
  the admin UI.
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
  after the bundled entries by `catalogProvider` (`app/lib/core/catalog/`);
  bundled wins slug collisions; pack-tagged rows only reach households
  that redeemed the pack (`pack.enabled` checked in the fetch filter).
  **Widgets must read art via `ref.watch(catalogProvider).lookupX(id)` and
  the models' `imageProvider` getters** - never the static registries or
  `Image.asset` directly - or remote art won't resolve. Fail-soft chain:
  live fetch → SharedPreferences snapshot → bundled-only. New art ships
  via the catalog (no app release); bundled is only for the day-one
  defaults. Asset art is generated by image-gen then background-removed
  with `rembg`.
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
  aggregation. Weeks are Mon→Sun local; ties award nobody.
- **The drag-and-drop language.** Removing members, leaving a household,
  deleting chores, logging out, binding/removing NFC tags - all
  `LongPressDraggable` onto a dashed-circle `DragTarget`
  (`app/lib/widgets/dashed_circle_painter.dart`). Destructive drops confirm;
  navigational ones don't.
- **Theme conventions.** Knewave on `headline*` + AppBar titles, Plus Jakarta
  Sans everywhere else (keep `display*` on the body font or the time picker
  goes funky). Inputs are theme-level filled boxes - never style per-field;
  labels via `LabeledField`. Page background is a BL→TR gradient from
  `AppBackdrop` (scaffolds are transparent); dark mode is deliberately flat
  (gradients band near black). Dark/light follows the phone.
- **NFC flows.** Tag → subject binding lives on `subjects.nfc_tag_id`; a tap
  either completes the next due chore or opens the subject page depending on
  the per-device toggle in Edit Profile. App-closed taps work via the launch
  intent (`nfc_launch_handler.dart`).
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
  → `/opt/haveyoufedthedog/push-notifier/.env` on the server only. SSH key
  → `~/.ssh/dogbox`. Release keystore → `app/android/` (gitignored) +
  Google Drive. Nothing secret is in this repo.
