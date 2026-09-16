# Kurs

A currency converter for iOS. Flutter rewrite of the SwiftUI app at
[mishahatescode/kurs-ios](https://github.com/mishahatescode/kurs-ios) — that
repo's `CHANGELOG.md` records UI decisions already made and argued over
(HIG button placement, appearance switching, offline mode). Read it before
re-litigating a layout question.

Bundle ID `com.onedollarapps.kurs` — the same as the SwiftUI app, so this can
ship as an update to the existing App Store listing rather than a new one.

## Two people, two operating systems

| | Mac | Windows |
|---|---|---|
| Owns | `lib/ui/`, `lib/main.dart`, `assets/`, `ios/` | `lib/core/`, `test/` |
| Does | UI/UX, design, release, App Store | tests, bug fixing, logic |
| Can run | iOS simulator, device, `build ipa` | `flutter test`, `analyze`, Android emulator, Chrome |

**Stay inside the owning side's paths.** If a change genuinely needs to cross
the line, say so and describe the edit rather than making it — the other person
is probably editing that file right now, and merge conflicts in Dart are
cheaper to avoid than to resolve.

This is enforced, not just agreed. `.github/CODEOWNERS` makes each person the
required reviewer of the *other* side's paths, so a pull request that edits the
other side's files needs an approval its own author cannot give — it will not
merge without an admin bypass. The one shared area is `test/ui/`: either side
may write widget tests.

### The Windows side cannot build or run iOS

No simulator, no codesigning, no `flutter build ipa`. This is a hard platform
limit, not a setup problem — do not suggest fixes for it.

So an iOS-only bug (safe areas, keyboard avoidance, Cupertino behaviour,
permission dialogs, anything visual) **can only be diagnosed and fixed on the
Mac**. If the bug report is a screenshot of an iPhone, it is Mac-side work.

What the Windows side *can* fix blind: anything reproducible as a failing test.

## Architecture: the seam is what makes the split work

`lib/core/` holds data, conversion, rates, formatting, persistence — and
**imports no Flutter widgets** (see `lib/core/README.md`). `lib/ui/` renders;
it reads values out of core and never computes one.

This is not style preference. It is the reason logic can be developed and
debugged on a machine that cannot run the app on its target platform. The
moment a rate calculation lands inside a widget, it becomes untestable on
Windows and the division of labour stops working.

## Working rules

- **Flutter 3.47.3**, pinned in `.fvmrc` and `.github/workflows/ci.yml`. Bump
  both together or CI and local drift apart.
- **Everything lives in git.** No zip handoffs, no "send me the folder." This
  project's predecessor lost a fork's worth of work exactly that way — see
  `../_Archive/README.md`.
- Branch off `main` and open a PR. It merges once CI is green and the other
  person approves; CODEOWNERS requests that review automatically.
- **Fixing a bug? Write the failing test first**, in `test/core/` or `test/ui/`,
  then fix it. A bug fix PR with no test is incomplete.
- Run `dart format .` before pushing. CI fails on unformatted code, and it is
  the tiebreaker between the two editors — not either machine.
- Never edit `ios/Runner.xcodeproj/project.pbxproj` from the Windows side.

## Mac-side gotcha: builds cannot be codesigned inside iCloud

This repo lives under `~/Library/Mobile Documents/` (iCloud Drive). iCloud
stamps every file with a `com.apple.provenance` xattr and `codesign` rejects it:

```
resource fork, Finder information, or similar detritus not allowed
```

Flutter surfaces this uselessly, as `Exited with status code 255` /
`Failed to copy Flutter framework`. `xattr -cr` does **not** fix it — the iCloud
daemon re-adds the attribute as files are written.

`build/` is therefore a symlink to `~/Library/Developer/FlutterBuilds/kurs`,
outside iCloud. If it goes missing after a clean:

```bash
rm -rf build && mkdir -p ~/Library/Developer/FlutterBuilds/kurs && ln -s ~/Library/Developer/FlutterBuilds/kurs build
```

## Release — Mac only

1. Bump `version:` in `pubspec.yaml`. The `+N` build number **must** increase on
   every upload, even for an identical binary.
2. `flutter build ipa`
3. Upload via Transporter or Xcode, then metadata and screenshots in
   App Store Connect.

The Windows side is never in this path.
