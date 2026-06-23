# CLAUDE.md

Family chore tracker: Flutter app (`app/`) + PocketBase server (`server/`).
README.md has the full architecture tour; this file is the working rules.

## Workflow

- The user runs `flutter run` themselves and verifies every change via hot
  reload. After an edit, tell them to press `r` (or `R` for new providers /
  theme changes; full restart for new assets or routes). Don't try to run
  the app yourself.
- Verify with `flutter analyze` (run from `app/`, not repo root). Expect
  "No issues found!". Skip the analyzer for trivial tweaks (paddings,
  colour nudges) - the user will see those on reload.
- The user commits their own work regularly. Don't suggest committing.
- For non-trivial features, surface the design decisions up front (a short
  plan or a direct question) before writing code. Don't scaffold on guesses.
- **Work step by step, with a check-in between steps.** Even when a batch of
  tasks is agreed ("do all the loose ends"), execute one item, report, and
  pause for the user to verify before starting the next. Only barrel through
  multiple items in one go if the user explicitly asks for that.

## Build commands

```bash
cd app                                            # everything runs from app/
flutter pub get
dart run build_runner build --delete-conflicting-outputs   # after @riverpod edits
flutter analyze
flutter build appbundle --release                 # Play release: .aab -> Play Console track (bump pubspec version first)
flutter build apk --release --split-per-abi       # sideload only: hand the arm64 APK to someone
dart run flutter_launcher_icons                   # after changing app icon art
```

**iOS release** runs on Codemagic (cloud macOS - no local Xcode): `codemagic.yaml`
at the repo root (workflow `ios-release`, `working_directory: app`); push to `main`
then Start build in the Codemagic UI. iOS bundle id `com.haveyoufedthedog.app` is
deliberately *not* the Android `com.haveyoufedthedog`. Edit `ios/` config
(Info.plist, entitlements, `project.pbxproj`) as plain text. The App ID's
capabilities must mirror the app's entitlements (NFC Tag Reading + Push are wired; iOS IAP still deferred). `GoogleService-Info.plist` is committed in `ios/Runner/` + wired into
`project.pbxproj` (native Firebase config, no `firebase_options.dart`). Signing is a
self-managed distribution cert (RSA key in Codemagic group `ios_signing` + Google
Drive backup) via the `haveyoufedthedog_asc` integration. Full walkthrough: README →
"Building an iOS release (Codemagic)".

Server deploys (Git Bash/WSL): `bash server/.deploy/deploy-hooks.sh` /
`deploy-worker.sh` / `deploy-public.sh` / `deploy-all.sh`. **deploy-hooks.sh
has a hardcoded file list** - new hook files must be added to its `tar` line.
`deploy-public.sh` syncs `server/pb_public/` (static files served at the API
domain root, e.g. `.well-known/assetlinks.json`); PB only serves that dir
because the systemd unit sets `--publicDir` to the per-instance path - its
default is the *binary* dir, a documented gotcha (README → "Static files").

## Architecture

- `app/lib/core/<domain>/` - models + Riverpod controllers. Models are thin
  `RecordModel` wrappers (no freezed/codegen models). Controllers use
  `@riverpod` codegen; async-init via AsyncNotifier/FutureProvider - never
  override-in-main hacks. Derived stats (awards, leaderboard, streaks, mean
  times) are pure functions over the cached last-100 completions
  (`householdHistoryControllerProvider`) - no extra fetches. (The character
  awards within `weeklyAwardsProvider` are the one twist: they read a
  *settled* past week, not the live one, and are mirrored server-side - see
  Data conventions.)
- `app/lib/features/<area>/` - screens + feature widgets. One class per file
  (small private helper widgets in the same file are fine).
- Router: GoRouter behind `appRouterProvider`; redirect logic is a single
  switch over `RoutingPhase` (loading / signedOut / needsToPick / ready).
  New signed-out-accessible routes must be whitelisted in the redirect.
  Push routes from outside the widget tree via
  `ref.read(appRouterProvider).push(...)`.
- Three parallel id→asset registries, same shape: `CharacterRegistry`
  (subjects), `PictureRegistry` (households), `AvatarRegistry` (users).
  Stored as text ids on PB records; unknown/empty ids fall back gracefully.
  New bundled art = PNG into `app/assets/...` + a registry entry.
- **Remote content catalog:** the `catalog_avatars` / `catalog_pictures` /
  `catalog_characters` PB collections serve extra art without an app
  release. `catalogProvider` (`core/catalog/`) merges bundled + enabled
  remote rows (bundled first, bundled wins slug collisions; fail-soft to
  bundled-only offline). **Resolution and selection are split.**
  `catalogProvider` is ungated: the fetch pulls every row with no pack or
  *any* enabled pack, so chosen art resolves in *any* household the viewer is
  in - a packed avatar/picture renders even where the pack isn't owned.
  `selectableCatalogProvider` is the entitlement gate for the *pickers*:
  pictures + characters when the current household owns *any* of the row's
  packs, avatars when *any* of the user's households does (avatars are
  personal, so they travel). Art rows carry a `packs` **multi**-relation - a
  row can sit in several packs (its category group plus an "everything" pack);
  empty `packs` = general catalog, everyone sees it. Widgets read lookups via
  `ref.watch(catalogProvider).lookupX(id)` - never the static registries -
  and render through the models' `imageProvider` getters
  (cached_network_image disk cache); the three pickers read
  `selectableCatalogProvider` instead. Publishing new catalog rows is a
  by-hand process in the PB admin UI (no committed doc/script) - provide the
  user step-by-step instructions when they want to publish. **Pack characters
  can carry their own
  personality copy:** the optional `messages` JSON field on `catalog_characters`
  (parsed into `Character.messages`) overrides the mood status lines and the
  weekly award title/thanks - per slot, falling back to the bundled `generic`
  voice for anything omitted. Bundled characters keep their hardcoded copy
  (`character_message.dart`, `characterAwardTitles`/`characterAwardThanks`).
- **Selling packs (IAP):** `core/store/` layers paid unlocks on the catalog.
  A `catalog_products` row (a `sku` + `grants` → one-or-more `catalog_packs`)
  is sold via native store IAP (`in_app_purchase`); `storeProductsProvider`
  merges enabled rows with live store prices (a product shows only if the
  store knows its `sku`). `purchaseController` drives buy/restore and calls
  `/api/custom/verify-purchase` → the worker's `verify.js` validates the
  receipt → the hook appends the granted packs to `households.packs` (same
  household-scoped entitlement as code redemption). The `sku` must equal the
  store product id byte-for-byte (convention: `sku_<YYYYMMDD>_<NNN>_<name>`).
  Both platforms verify server-side: Android via the Play API, iOS via Apple's
  `verifyReceipt` (deprecated but operational - a later StoreKit 2 + JWS move
  would retire it and also needs the client off StoreKit 1). Entry points: the
  `BrowsePacksButton` under each picker (labelled per type - "Get more
  images / characters / avatars") → `features/store/` (the "Image packs"
  screen, which also hosts gift-code redemption).
- **Managed members + "Act as":** a household member without their own login is
  a *managed* user - a real but loginless `users` row (`managed: true`, synthetic
  `{id}@haveyoufedthedogyet.com` email, random password) the owner creates,
  edits and deletes via the elevated `members.pb.js` hook (an owner can't
  create a membership for another user, nor edit a user they can't log in as).
  Because it's a real user row it flows through the leaderboard / awards /
  avatar pipeline with no special-casing. Any signed-in member can **Act as**
  one - the "Whose turn?" picker on the You tab - to log chores for them:
  `actingUserController` (`core/household/acting_user_controller.dart`) holds
  the identity completions are stamped with, defaulting to self, **sticky for
  the session**, auto-reverting on household-switch / logout / relaunch
  (it watches those, so no manual reset needed). Restricted to managed members
  (app-level; `setActing` rejects real members) - real members keep self-only
  attribution. `actingMemberProvider` resolves it to a `HouseholdMember` for
  the celebration name/avatar and the You-tab icon (the acting identity's
  avatar, red-ringed when it isn't you). Owner CRUD lives in
  `household_actions.dart` + `household_details_screen.dart`; managed members
  carry a managed-member badge and are removed by the chore-style drag-to-bin or the
  Edit-member screen's trash can.
- In-place record patching (`updateOneInPlace`) instead of `invalidate` where
  a full refetch would flash null and bounce the user (household rename,
  picture, invite toggles).

## Data conventions

- Chore times are **wall-clock integers** (`hour`, `minute`) with no timezone;
  `weekday_mask` is Mon=1 … Sun=64 (`1 << (weekday-1)`). `completed_at` is UTC.
- `completions.completed_by` is the **acting identity**, not necessarily the
  signed-in user - "Act as" lets a signed-in member log for a managed
  member (see Architecture). Every stat keys off `completed_by`, so a managed
  member earns credit/awards like anyone. The `completions` create/update/
  delete rules were relaxed from self-only to **"any member of the subject's
  household"** so act-as logging and undo work; it stays backward-compatible
  because a self-attributed write is still a member write.
- The overdue + award crons live in the **Node worker service**
  (`server/services/worker/`: `overdue-cron.js` / `award-cron.js`, sharing
  `pb-cron.js`), not in PB hooks. They convert per household via
  `households.timezone` (IANA; empty = Europe/London), so the server's own
  clock setting doesn't matter.
- Weekly windows everywhere are Mon→Sun local. Award ties go to nobody.
- **Character "Best Human" awards are settled, not live.** The personality
  badges + Team Effort + leaderboard track the in-progress Mon→Sun week, but
  the per-subject character awards lock to the last *finished* week so they
  can't change hands mid-week. Award weeks run Sunday 18:00 → next Sunday
  18:00 (`WeekWindow.settledAward`, `awardPresentationHour` in
  `stats_controller.dart`); the winner shown is the most recently closed
  window. At each Sunday-18:00 boundary the worker's `award-cron.js` settles
  the *same* window and pushes one notification per winning user (deduped
  across subjects). **The app and the cron compute winners independently and
  must stay in sync** - if you touch any of these, change both sides:
  the presentation hour (`awardPresentationHour` ⇔ `AWARD_HOUR`), the Sun→Sun
  window math (`WeekWindow.settledAward` ⇔ `award-cron.js`'s window math), and
  the unique-max tiebreak (`_uniqueMax` ⇔ `uniqueMax`). (The two crons' shared
  PB/timezone plumbing lives in `server/services/worker/pb-cron.js`.) The award
  **title and thanks line are app-only** (`characterAwardTitles` /
  `characterAwardThanks` in `awards_controller.dart`, overridable per pack
  character via `catalog_characters.messages` - see Remote content catalog); the
  push deliberately names only the subject, so there's no title to mirror
  server-side.
- Clock strings render via `ScheduleRule.formatClock` ("6:30 pm", lowercase)
  - never `TimeOfDay.format(context)`.

## PocketBase hooks (Goja)

- **ONE live server, no staging.** `api.haveyoufedthedog.com` is the only
  instance and it's production - every released app talks to it. Schema edits,
  hook deploys (which restart PB), and collection-rule changes take effect
  **immediately and for everyone**. So **no breaking changes**: keep server
  changes backward-compatible with the currently-released app. Add fields,
  don't remove/rename ones it reads; only relax rules in ways that still accept
  the old client's requests (e.g. relaxing `completed_by = @request.auth.id`
  must still accept a self-attributed write). After relaxing a rule, confirm a
  real live-app request still works and keep the old rule ready to restore.
- **Each handler runs in its own fresh JS runtime.** Share helpers via
  `require()` _inside_ the callback; file-level declarations are invisible
  to handlers. Helper files must not end in `.pb.js` or PB auto-loads them.
- Schema changes are admin-UI-first: change live, re-export to
  `server/pb_schema.json`, commit. This is a by-hand process with no
  committed walkthrough - provide the user step-by-step instructions when a
  schema change is needed.
- Secrets (Resend API key, Firebase service account) live only on the
  server / in PB settings. Never in the repo.

## Design language (load-bearing - users notice deviations)

- **Fonts:** Knewave on `headline*` slots + AppBar titles (28px); Plus
  Jakarta Sans for everything else. `display*` stays on the body font (the
  Material time picker uses it).
- **Inputs:** theme-level filled rounded boxes (`inputDecorationTheme`,
  radius 16, borderless). Never style a field inline. Labels above fields
  via the shared `LabeledField(label:, child:)` - primary colour, w600.
  Because the label sits *outside* the field (no `InputDecoration.labelText`),
  credential autofill rides entirely on `autofillHints`: wrap login/signup
  fields in an `AutofillGroup`, hint each field, and call
  `TextInput.finishAutofillContext()` on a successful submit so the OS offers
  to save (see `login_form.dart` / `signup_form.dart`).
- **Gradients:** the house recipe is HSL lightness offsets of a base colour,
  bottom-left dark → top-right light (e.g. −0.07/+0.05 on stage colours).
  Page background comes from `AppBackdrop` via `MaterialApp.builder` with
  transparent scaffolds; dark mode is deliberately flat (banding).
- **Drag-and-drop is the signature interaction:** `LongPressDraggable` chips
  onto dashed-circle `DragTarget`s (`widgets/dashed_circle_painter.dart`),
  feedback rendered larger, `childWhenDragging` at 0.3 opacity, target
  fills solid on hover. Destructive drops get a confirm dialog (buttons in
  `error`/`onError` colours - not errorContainer, too dark in dark mode);
  navigational drops don't.
- **Destructive actions** (delete/leave) are an IconButton in
  `AppBar.actions`, never a big bottom CTA.
- **Busy state on forms:** no full-screen scrim. Disable controls via a
  `_busy` flag and swap the primary button's label for a small
  `CircularProgressIndicator`. Save buttons are dirty-tracked (disabled
  until something actually changed vs the stored values).
- Section headers are centred `titleMedium` w800. Cards are the "subtle"
  default `Card`; special poster cards (featured awards, summary tile) use
  fixed pastel palettes with thin white borders so they read the same in
  both themes.
- Characters have expressions (idle/happy/sad/sleeping/celebrate + award
  pose); mood logic lives in `subjectMoodProvider` - reuse it rather than
  re-deriving "is the dog sad" in widgets.

## Windows shell gotchas

- PowerShell 5.1 `Get-Content`/`Set-Content` mangles BOM-less UTF-8
  (em-dashes/emoji become mojibake). For scripted file edits use .NET IO
  with explicit encoding: read `[IO.File]::ReadAllText($f, [Text.Encoding]::UTF8)`,
  write with `New-Object Text.UTF8Encoding($false)`.
- `flutter`/`dart` commands fail at repo root - `Set-Location app` first.
