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
  colour nudges) — the user will see those on reload.
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
flutter build apk --release --split-per-abi       # bump pubspec version first
dart run flutter_launcher_icons                   # after changing app icon art
```

Server deploys (Git Bash/WSL): `bash server/scripts/deploy-hooks.sh` /
`deploy-notifier.sh` / `deploy-all.sh`. **deploy-hooks.sh has a hardcoded
file list** — new hook files must be added to its `tar` line.

## Architecture

- `app/lib/core/<domain>/` — models + Riverpod controllers. Models are thin
  `RecordModel` wrappers (no freezed/codegen models). Controllers use
  `@riverpod` codegen; async-init via AsyncNotifier/FutureProvider — never
  override-in-main hacks. Derived stats (awards, leaderboard, streaks, mean
  times) are pure functions over the cached last-100 completions
  (`householdHistoryControllerProvider`) — no extra fetches.
- `app/lib/features/<area>/` — screens + feature widgets. One class per file
  (small private helper widgets in the same file are fine).
- Router: GoRouter behind `appRouterProvider`; redirect logic is a single
  switch over `RoutingPhase` (loading / signedOut / needsToPick / ready).
  New signed-out-accessible routes must be whitelisted in the redirect.
  Push routes from outside the widget tree via
  `ref.read(appRouterProvider).push(...)`.
- Three parallel id→asset registries, same shape: `CharacterRegistry`
  (subjects), `PictureRegistry` (households), `AvatarRegistry` (users).
  Stored as text ids on PB records; unknown/empty ids fall back gracefully.
  New art = PNG into `app/assets/...` + a registry entry (no other code).
- In-place record patching (`updateOneInPlace`) instead of `invalidate` where
  a full refetch would flash null and bounce the user (household rename,
  picture, invite toggles).

## Data conventions

- Chore times are **wall-clock integers** (`hour`, `minute`) with no timezone;
  `weekday_mask` is Mon=1 … Sun=64 (`1 << (weekday-1)`). `completed_at` is UTC.
- The overdue cron (`server/pb_hooks/overdue.pb.js`) assumes the **server
  timezone == family timezone** (Europe/London). Multi-TZ households would
  need `households.timezone` + moving the cron to the Node notifier.
- Weekly windows everywhere are Mon→Sun local. Award ties go to nobody.
- Clock strings render via `ScheduleRule.formatClock` ("6:30 pm", lowercase)
  — never `TimeOfDay.format(context)`.

## PocketBase hooks (Goja)

- **Each handler runs in its own fresh JS runtime.** Share helpers via
  `require()` *inside* the callback; file-level declarations are invisible
  to handlers. Helper files must not end in `.pb.js` or PB auto-loads them.
- Schema changes are admin-UI-first: change live, re-export to
  `server/pb_schema.json`, commit. Never hand-edit the live DB schema via
  import unless following `server/scripts/apply-schema.md`.
- Secrets (Resend API key, Firebase service account) live only on the
  server / in PB settings. Never in the repo.

## Design language (load-bearing — users notice deviations)

- **Fonts:** Knewave on `headline*` slots + AppBar titles (28px); Plus
  Jakarta Sans for everything else. `display*` stays on the body font (the
  Material time picker uses it).
- **Inputs:** theme-level filled rounded boxes (`inputDecorationTheme`,
  radius 16, borderless). Never style a field inline. Labels above fields
  via the shared `LabeledField(label:, child:)` — primary colour, w600.
- **Gradients:** the house recipe is HSL lightness offsets of a base colour,
  bottom-left dark → top-right light (e.g. −0.07/+0.05 on stage colours).
  Page background comes from `AppBackdrop` via `MaterialApp.builder` with
  transparent scaffolds; dark mode is deliberately flat (banding).
- **Drag-and-drop is the signature interaction:** `LongPressDraggable` chips
  onto dashed-circle `DragTarget`s (`widgets/dashed_circle_painter.dart`),
  feedback rendered larger, `childWhenDragging` at 0.3 opacity, target
  fills solid on hover. Destructive drops get a confirm dialog (buttons in
  `error`/`onError` colours — not errorContainer, too dark in dark mode);
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
  pose); mood logic lives in `subjectMoodProvider` — reuse it rather than
  re-deriving "is the dog sad" in widgets.

## Windows shell gotchas

- PowerShell 5.1 `Get-Content`/`Set-Content` mangles BOM-less UTF-8
  (em-dashes/emoji become mojibake). For scripted file edits use .NET IO
  with explicit encoding: read `[IO.File]::ReadAllText($f, [Text.Encoding]::UTF8)`,
  write with `New-Object Text.UTF8Encoding($false)`.
- `flutter`/`dart` commands fail at repo root — `Set-Location app` first.
