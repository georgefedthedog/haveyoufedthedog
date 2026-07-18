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
deliberately _not_ the Android `com.haveyoufedthedog`. Edit `ios/` config
(Info.plist, entitlements, `project.pbxproj`) as plain text. The App ID's
capabilities must mirror the app's entitlements (NFC Tag Reading [formats = `TAG`, not `NDEF` - the current SDK rejects NDEF at upload] + Push are wired; iOS IAP still deferred). `GoogleService-Info.plist` is committed in `ios/Runner/` + wired into
`project.pbxproj` (native Firebase config, no `firebase_options.dart`). Signing is a
self-managed distribution cert (RSA key in Codemagic group `ios_signing` + Google
Drive backup) via the `haveyoufedthedog_asc` integration. Full walkthrough: README →
"Building an iOS release (Codemagic)".

Server deploys (Git Bash/WSL): `bash server/.deploy/deploy-hooks.sh` /
`deploy-worker.sh` / `deploy-public.sh` / `deploy-all.sh`. **deploy-hooks.sh
and deploy-worker.sh both have a hardcoded file list** - new hook / worker
files must be added to their `tar` line.
`deploy-public.sh` syncs `server/pb_public/` (static files served at the API
domain root, e.g. `.well-known/assetlinks.json`); PB only serves that dir
because the systemd unit sets `--publicDir` to the per-instance path - its
default is the _binary_ dir, a documented gotcha (README → "Static files").

**Catalog art and store assets live in the separate `haveyoufedthedog-assets`
repo** (same GitHub account): the house/character/avatar art sources, the
generation + splitting scripts, `pack_manifest.json`, `upload_pack.py` (the
publisher that pushes rows to the live server) and the store listing
collateral. See that repo's CLAUDE.md for the art workflow; nothing in this
repo's build reads any of it.

## Architecture

- `app/lib/core/<domain>/` - models + Riverpod controllers. Models are thin
  `RecordModel` wrappers (no freezed/codegen models). Controllers use
  `@riverpod` codegen; async-init via AsyncNotifier/FutureProvider - never
  override-in-main hacks. Derived stats (awards, leaderboard, streaks, mean
  times) are pure functions over the cached last-100 completions
  (`householdHistoryControllerProvider`) - no extra fetches. (The character
  awards within `weeklyAwardsProvider` are the one twist: they read a
  _settled_ past week, not the live one, and are mirrored server-side - see
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
  remote rows and sorts them together by `sortOrder` (bundled entries carry
  their own in the registries, so they interleave into the right group;
  bundled wins slug collisions and ties; fail-soft to bundled-only offline). **Resolution and selection are split.**
  `catalogProvider` is ungated: the fetch pulls every row with no pack or
  _any_ enabled pack, so chosen art resolves in _any_ household the viewer is
  in - a packed avatar/picture renders even where the pack isn't owned.
  `selectableCatalogProvider` is the entitlement gate for the _pickers_:
  pictures + characters when the current household owns _any_ of the row's
  packs, avatars when _any_ of the user's households does (avatars are
  personal, so they travel). Art rows carry a `packs` **multi**-relation - a
  row can sit in several packs (its category group plus an "everything" pack);
  empty `packs` = general catalog, everyone sees it. Widgets read lookups via
  `ref.watch(catalogProvider).lookupX(id)` - never the static registries -
  and render through the models' `imageProvider` getters
  (cached_network_image disk cache); the three pickers read
  `selectableCatalogProvider` instead. Publishing new catalog rows happens
  from the `haveyoufedthedog-assets` repo (`pack_manifest.json` +
  `upload_pack.py` - see its CLAUDE.md). **Pack characters
  can carry their own
  personality copy:** the optional `messages` JSON field on `catalog_characters`
  (parsed into `Character.messages`) overrides the mood status lines and the
  weekly award title/thanks - per slot, falling back to the localized generic
  voice for anything omitted. Translations nest under a sibling `i18n` key
  (`{"lines": ..., "i18n": {"de": {...}}}`); `upload_pack.py` builds it from
  `messages.<lang>.json` files next to a character's `messages.json`. In a
  non-English UI an untranslated pack voice deliberately falls back to the
  localized generic voice rather than mixing languages. Bundled characters'
  English voice is the const table in `character_message.dart`; their de/fr/es
  voices are `assets/l10n/characters/<lang>.json`
  (`bundledCharacterVoicesProvider`), same JSON shape as pack `messages`.
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
- **Free streak rewards:** `features/rewards/` lets a household earn a catalog
  character or house picture for **free** by keeping a daily streak. The
  *earnable* set is resolvable catalog art the household can't already select
  (`catalogProvider` minus `selectableCatalogProvider`) that isn't flagged
  `reward_excluded` (a per-row `catalog_characters`/`catalog_pictures` bool
  reserving art for paid/private packs). The reward **streak** is lenient and
  household-wide (any due subject fed that day) and resets after each claim
  (the `households.last_free_redemption` anchor); the bar to clear is
  `households.reward_streak_threshold` (admin-set per household; empty/0 = the
  in-code default of 14, in both the app and the hook). Claiming calls
  `/api/custom/claim-streak-reward` (`rewards.pb.js`), which recomputes the
  streak server-side (see Data conventions) and appends the slug to
  `households.unlocked_characters` / `unlocked_pictures` - a household-scoped
  entitlement the `selectableCatalogProvider` gate ORs in by slug, so the
  existing pickers need no changes. Entry points: the reward-streak bar
  (`StreakRewardBar`) inside the Awards-tab stats card and at the foot of the
  store; on a claim a confetti splash plays and the shared `GlowHighlight`
  "look here" cue (`widgets/glow_highlight.dart`, also used by the invite +
  act-as cards) lands the item in the collection.
- **Managed members + "Act as":** a household member without their own login is
  a _managed_ user - a real but loginless `users` row (`managed: true`, synthetic
  `{id}@haveyoufedthedog.com` email, random password) the owner creates,
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
- **NFC tags open the app via the OS, not in-app reading.** A tag holds
  `haveyoufedthedog.com/nfc-tap?household=<hid>&subject=<sid>`; the OS opens the
  app, `DeepLinkHandler` parks it (the `app_links` plugin reads the launch
  intent's data URI on both platforms), `AppRoot` routes to
  `NfcLaunchHandler.handleNfcTap` - which auto-switches to the tag's household
  (if the tapper is a member, so a multi-household dog-walker logs against the
  right house) then logs the best chore, or opens the subject per the Edit
  Profile per-device toggle. **The two platforms auto-open by different
  mechanisms, and a tag carries the records for both:** the app writes an NDEF
  URI record (iOS Universal Link) **plus an Android Application Record (AAR)**
  naming `com.haveyoufedthedog`. iOS uses the URI record and ignores the AAR;
  Android needs the AAR because 13+/Pixel routes a bare `https` tag through the
  OS "Open link found via NFC?" weblink prompt and never offers it to our
  `NDEF_DISCOVERED` filter - the AAR forces a direct launch of our package
  (`android/app/src/main/AndroidManifest.xml` has the matching
  `NDEF_DISCOVERED` intent-filter for `/nfc-tap`). Because the AAR lives on the
  tag, changing the package name or the tag format means **re-writing every
  existing tag**. The app only _writes_ tags (the "Write an NFC tag" card on
  Edit thing → `core/nfc/nfc_service.dart` NDEF write via `nfc_manager`). Two
  more load-bearing gotchas: pass `pollingOptions: {iso14443, iso15693}` to
  `startSession` (the default also polls FeliCa/`iso18092`, which iOS gates
  behind a `felica.systemcodes` entitlement we lack → "Missing required
  entitlement"); and the iOS NFC formats entitlement must be `TAG`
  (`NFCTagReaderSession`) since the current SDK rejects `NDEF` at App Store
  upload. `subjects.nfc_tag_id` stores the written URL as a "tag written" marker.
- **Deep-link paths live in multiple places that must stay in sync:** `/join`,
  `/claim`, and `/nfc-tap` are listed in both the AASA `components`
  (`landing_page/src/.well-known/apple-app-site-association`, iOS) and the Android
  manifest App Links `pathPrefix`. New path = add to both. Apple's CDN caches
  the AASA, so a new path takes hours to propagate and only takes effect on a
  fresh install. A new **NFC** path additionally needs the Android
  `NDEF_DISCOVERED` intent-filter (same manifest) and, on the tags, an AAR
  alongside the URL - see the NFC note above.
- In-place record patching (`updateOneInPlace`) instead of `invalidate` where
  a full refetch would flash null and bounce the user (household rename,
  picture, invite toggles).
- **Subject + chore screens.** The View thing screen
  (`subject_detail_screen.dart`) shows the hero, today's chores, history, and a
  "Manage chores" link; the add/edit/drag-delete chore chip cloud lives on the
  Edit thing screen (`edit_subject_screen.dart`). The link sets
  `manageChoresHighlightProvider` then navigates, and Edit thing scrolls +
  flashes that section via `GlowHighlight` (same one-shot pattern as the
  NFC-setting cue); creating a new thing lands on its Edit screen. A central
  quick-add-chore FAB on `RootNavShell` works from any tab - it picks the thing
  first (one thing → straight to New Chore; several → a bottom-sheet character
  picker). Grave deletes (account / household / subject / managed member) gate
  behind the shared `confirmByTyping` (type DELETE - the word itself is the
  localized `confirmByTypingWord` key).

## Localization (i18n)

- The app ships in en (fallback) + de/fr/es via gen_l10n: `app/l10n.yaml`,
  ARBs in `lib/l10n/app_<lang>.arb`, generated `AppLocalizations` committed
  like other codegen. **Every user-facing string goes through
  `context.l10n.<key>`** (`lib/l10n/l10n.dart` extension) - new UI copy means
  a key in ALL FOUR ARBs (English first, with an `@` description written for
  the translator; `untranslated.json` lists gaps and should stay empty).
  Keys are camelCase and area-prefixed (`editChore*`, `store*`); shared verbs
  live under `common*`; plurals are ICU (`{count, plural, one{...}
  other{...}}`); raw exception details pass through `{details}` placeholders
  untranslated. The two context-less sites (notification channel names, NFC
  launch snackbars, purchase-stream messages) read `appLocalizationsProvider`
  (`core/l10n/`) instead - never watch that from widgets.
- Language follows the device, with a per-device override on Edit Profile
  (`appLocaleControllerProvider`, SharedPreferences). `localeSyncProvider`
  writes the resolved language to `users.locale` (empty = English) so the
  server can localize pushes.
- **Server pushes are localized by recipient**: the worker's `l10n.js`
  (overdue + award templates) and the hooks' `_l10n_helper.js` (completion
  templates) group tokens by `users.locale`; empty locale = byte-identical
  English, keeping pre-i18n clients unaffected. Keep those two template
  tables and the app ARBs in the same voice.
- **Hook errors carry a stable `code`** (snake_case) alongside their English
  `message`; the app maps codes to ARB strings in
  `core/api/server_messages.dart` (unknown code → raw message). New hook
  errors need: a `code` in the hook, a case in `serverMessage`, and a
  `server*` key in all four ARBs.
- Character mood/award copy is data, not ARB - see Remote content catalog
  (bundled voices in `assets/l10n/characters/<lang>.json`, pack voices under
  the `messages.i18n` key).
- **Catalog names localize via additive JSON columns** - flat `{lang: text}`
  maps, base field = English fallback: `display_name_i18n` on
  `catalog_characters`/`catalog_pictures`, `name_i18n` on `catalog_packs` +
  `catalog_products`, `description_i18n` on products (note the two naming
  patterns). Parsed by `core/l10n/name_i18n.dart`; resolved at the widget
  layer via `localizedCharacterName` (`characters.dart` - bundled ids read
  ARB keys), `StoreProduct.localizedName/-Description`, and
  `catalog.packName(id, localeName:)`. Authored as `display_name_i18n` /
  `name_i18n` / `description_i18n` keys in `pack_manifest.json` and pushed by
  `upload_pack.py` (both in the `haveyoufedthedog-assets` repo).
  `catalog_avatars` has no i18n column - avatar names never render.
- The landing page's `join.html` / `claim.html` / `index.html` swap copy
  client-side from inline `L10N` dictionaries keyed on `navigator.language`
  (English markup is the fallback). Play/App Store listing + IAP
  translations live in the assets repo's `app-stores/store_listings_i18n.md`
  (hand-pasted into the consoles).
- iOS: `CFBundleLocalizations` in Info.plist + per-language
  `<lang>.lproj/InfoPlist.strings` (NFC usage description), wired as a
  `PBXVariantGroup` in `project.pbxproj`; verifiable only on a Codemagic
  build. The app display name stays the English brand on both platforms.

## Data conventions

- Chore times are **wall-clock integers** (`hour`, `minute`) with no timezone.
  `completed_at` is UTC. Recurrence is a `ScheduleRule`
  (`core/chores/schedule_rule.dart`) keyed by `schedule_type`:
  - `daily` - every day.
  - `weekly` - `weekday_mask` (Mon=1 … Sun=64, `1 << (weekday-1)`) plus
    `week_interval` 1 or 2. Fortnightly carries **no anchor date**: `week_phase`
    (0/1) is parity against a fixed epoch (first Monday of 1970,
    `ScheduleRule.weeksSinceEpoch`); a week is "on" when
    `weeksSinceEpoch(day) % 2 == week_phase`, and the editor turns a
    "this week / next week" pick into it.
  - `monthly` - `month_mode` `day` (`month_day` 1-28, or `-1` = last day) or
    `weekday` (`month_ordinal` 1-4 or `-1` = last × `month_weekday` ISO 1-7).
    `-1` = "last"; PB reads an empty number as 0, so never use 0 for it.
  - `once` - a one-off on `due_date` (text `YYYY-MM-DD`, no timezone, so no
    tz-shift). Carries over: due on its date and every day after, until done
    (lifecycle below); future-dated ones don't show until their day. The
    editor's "Repeats / One time" toggle picks this vs the recurring
    frequencies.
  Records always carry the **full** field set (`chore_actions._ruleFields`,
  including `due_date` - empty for recurring), so switching type leaves no stale
  values; only the fields the active `schedule_type` reads are consulted.
- **Due-date logic is computed on both sides and must stay in sync.**
  `ScheduleRule.isDueOn` (app) and `isChoreDueOn` in
  `server/services/worker/pb-cron.js` (the one server mirror, used by
  `overdue-cron.js`, `retire-cron.js` + `reward-streak.js`) implement the same
  rules - the fortnightly epoch/parity, the monthly day/weekday math, and the
  `once` carryover (`due_date` onward). Touch one, touch the other.
- **One-off chore lifecycle.** A `once` chore is a standing task: shown from its
  `due_date` onward (overdue carryover) until completed, then it drops off.
  `completions.chore_name` is stamped at log time so history still names a
  retired/deleted chore (the timeline prefers the live chore name, falls back to
  it). Retirement = `active = false`, set by `retire-cron.js` the day **after**
  completion (so it still shows "done" on its day); the client
  `completedOnceChoreIdsController` hides a finished one-off in the gap until
  then, and `overdue-cron.js` skips nudging a completed one. Recurring chores
  never carry over (a missed day just reappears on its next scheduled day).
- `completions.completed_by` is the **acting identity**, not necessarily the
  signed-in user - "Act as" lets a signed-in member log for a managed
  member (see Architecture). Every stat keys off `completed_by`, so a managed
  member earns credit/awards like anyone. The `completions` create/update/
  delete rules were relaxed from self-only to **"any member of the subject's
  household"** so act-as logging and undo work; it stays backward-compatible
  because a self-attributed write is still a member write.
- The overdue, award + retire crons live in the **Node worker service**
  (`server/services/worker/`: `overdue-cron.js` / `award-cron.js` /
  `retire-cron.js`, sharing `pb-cron.js`), not in PB hooks. They convert per
  household via `households.timezone` (IANA; empty = Europe/London), so the
  server's own clock setting doesn't matter. `retire-cron.js` is the hourly
  one-off sweep (a couple of minutes past each hour) that flips a finished
  one-off `active = false` the day after it's done, in the household's tz.
- Weekly windows everywhere are Mon→Sun local. Award ties go to nobody.
- **Character "Best Human" awards are settled, not live.** The personality
  badges + Team Effort + leaderboard track the in-progress Mon→Sun week, but
  the per-subject character awards lock to the last _finished_ week so they
  can't change hands mid-week. Award weeks run Sunday 18:00 → next Sunday
  18:00 (`WeekWindow.settledAward`, `awardPresentationHour` in
  `stats_controller.dart`); the winner shown is the most recently closed
  window. At each Sunday-18:00 boundary the worker's `award-cron.js` settles
  the _same_ window and pushes one notification per winning user (deduped
  across subjects). **The app and the cron compute winners independently and
  must stay in sync** - if you touch any of these, change both sides:
  the presentation hour (`awardPresentationHour` ⇔ `AWARD_HOUR`), the Sun→Sun
  window math (`WeekWindow.settledAward` ⇔ `award-cron.js`'s window math), and
  the unique-max tiebreak (`_uniqueMax` ⇔ `uniqueMax`). (The two crons' shared
  PB/timezone plumbing lives in `server/services/worker/pb-cron.js`.) The award
  **title and thanks line are app-only** (`characterAwardTitle` /
  `characterAwardThanks` resolvers in `awards_section.dart`, reading the ARB
  per character id with a pack-`messages` override - see Remote content
  catalog); the push deliberately names only the subject, so there's no title
  to mirror server-side. `weeklyAwardsProvider` itself emits only ids +
  winners - all award display strings resolve at the widget layer.
- **The reward streak is computed on both sides, like the awards.** The app
  shows an _advisory_ number (`reward_streak_controller.dart`, device-local,
  drives the progress bar only), but the worker is **authoritative**: the claim
  hook asks the worker's `/reward-streak` endpoint (`reward-streak.js`), which
  walks the household's due-days in its IANA timezone and only grants past the
  threshold. Keep the two in sync if you touch the rules - the lenient
  any-subject-fed predicate, the grace-today exception, the
  `last_free_redemption` anchor, the default-14 threshold, and the **one-off
  exclusion** (a `once` chore never makes a day "due", so a missed one can't
  break the streak; completing it still counts like any completion) all live in
  both `reward_streak_controller.dart` and `reward-streak.js`. Because the app
  number is advisory, a day-boundary disagreement just shows the claim button
  slightly early/late; the server is the gate.
- Clock strings render via `formatClock(h, m, localeName)` in
  `core/chores/schedule_labels.dart` ("6:30 pm" lowercase in English, 24-hour
  "18:30" in de/fr/es) - never `TimeOfDay.format(context)`. Schedule
  sentences come from `describeSchedule(rule, l10n)` there too;
  `ScheduleRule` itself is a pure, locale-free model.

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
  Because the label sits _outside_ the field (no `InputDecoration.labelText`),
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
- House pictures render at `PictureArtwork.houseAspectRatio` (7:5) on every
  showcase surface - home hero, rewards grid + featured card, picker carousel -
  one constant so they stay in step; the compact switcher thumbnail stays
  square. One-off chores read distinctly from recurring: a "One-time" pill on
  the list row and a calendar glyph (`Icons.event`) where recurring shows the
  clock.

## Windows shell gotchas

- PowerShell 5.1 `Get-Content`/`Set-Content` mangles BOM-less UTF-8
  (em-dashes/emoji become mojibake). For scripted file edits use .NET IO
  with explicit encoding: read `[IO.File]::ReadAllText($f, [Text.Encoding]::UTF8)`,
  write with `New-Object Text.UTF8Encoding($false)`.
- `flutter`/`dart` commands fail at repo root - `Set-Location app` first.
