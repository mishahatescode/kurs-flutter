# Kurs

A currency converter for iOS, built in Flutter.

## Getting set up

Flutter **3.47.3** — pinned in `.fvmrc`. Match it exactly; a version split
between machines produces failures that look like code bugs and are not.
[fvm](https://fvm.app) will read `.fvmrc` and pick the right one for you:

```bash
dart pub global activate fvm && fvm install && fvm use
```

Then:

```bash
flutter pub get
flutter test
```

## Who does what

| | Mac (@mishahatescode) | Windows |
|---|---|---|
| Owns | `lib/ui/`, `assets/`, `ios/` | `lib/core/`, `test/` |
| Does | UI/UX, release, App Store | tests, bug fixing, logic |

Enforced by `.github/CODEOWNERS`. The full reasoning is in `CLAUDE.md`, which
both Claude Code sessions read automatically.

### Running it on Windows

iOS is macOS-only — no simulator, no signing, no `build ipa`. On Windows use:

```bash
flutter test              # the real work: headless, identical on every OS
flutter run -d chrome     # quick visual check
flutter run -d emulator   # Android emulator, closest thing to the real app
```

## The loop

1. Branch off `main`.
2. Fixing a bug? Write the failing test first, then fix it.
3. `dart format .` — CI fails on unformatted code.
4. Open a PR. CI must be green and the other person must approve.
5. Merge.

CI runs `dart format --set-exit-if-changed`, `flutter analyze --fatal-infos`
and `flutter test` on Linux, so neither machine's setup gets to be the
tiebreaker.

## History

This replaces the SwiftUI app at
[mishahatescode/kurs-ios](https://github.com/mishahatescode/kurs-ios). Its
`CHANGELOG.md` documents UI decisions that were already made and tested on
device — worth reading before redesigning a screen.
