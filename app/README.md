# app

Flutter app - Android + iOS - for _Have You Fed The Dog Yet_. Online-only
client. Talks to the live PocketBase at `https://api.haveyoufedthedog.com`.

## Stack

- Flutter (Material 3)
- Riverpod with `@riverpod` annotations + `riverpod_generator`
- GoRouter
- PocketBase Dart SDK (added in Step 2)
- Firebase Messaging for push (added in Step 14)

## Code rules

- **One class per file.** Every public class lives in its own file. Private
  helper classes are tolerated only inside the same file's render tree.
- **No `ref.watch` after `await`.** Riverpod loses dependency tracking when
  you watch after suspending. Watch first, then await.
- **Generated providers only.** Use `@riverpod` / `@Riverpod(keepAlive: true)`
  with `riverpod_generator`. No hand-rolled `*Provider(*.new)` declarations.
- **Per-feature folders.** `lib/features/<area>/` holds the screens and
  controllers for that area. Shared bits live in `lib/widgets/` or `lib/core/`.

## Layout

```
lib/
  main.dart                  bootstrap
  app/
    app_root.dart            MaterialApp.router
    theme.dart               light + dark color schemes
  router/
    app_router.dart          GoRouter (@riverpod)
    routes.dart              path constants
  features/
    home/home_screen.dart    Step 1 placeholder
  widgets/
    build_label.dart         the "vX.Y.Z+B" tag at the bottom of every screen
```

## Running

```powershell
cd app
flutter pub get
dart run build_runner build
flutter run -d <device>
```

For wireless ADB to the Pixel see the root README's deploy notes.

## Versioning

Bump `version:` in `pubspec.yaml` before every deploy you want to be able to
identify on the phone - `v0.1.0+1` will appear at the bottom of every screen.
