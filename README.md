# Blend Book

Offline spice-blend notebook: home cooks scale ingredient ratios, record tasting revisions, and print repeatable jar labels on phone, tablet, and Windows.

## Motivation and users

Home cooks often lose the exact mix behind a good batch or alter a recipe without recording how. Blend Book keeps measured ingredients and batch notes together, with deterministic scaling rather than a feed of recipes.

## Intended workflow

1. Create a blend with ingredients, amount, unit, and yield. Use mass units for precise scaling; volume amounts remain explicitly approximate and are never silently converted to mass.
2. Save a dated revision with tasting notes. Scale a selected revision to a target batch using rational arithmetic and explicit rounding.
3. Print or export a jar label containing name, revision, ingredients, and batch date. Reopen prior revisions without overwriting them.
4. Export a local backup and restore it with validation.

## MVP and non-goals

MVP: local blend and immutable revision storage; scaled batch worksheet; labels and printable export; backup/restore; phone/tablet/Windows adaptive UI. No nutrition claims, allergen-safety guarantees, AI recipe generation, cloud accounts, shopping list, meal planning, barcode lookup, or social sharing. A user must check ingredients for allergens independently.

## Platforms and privacy

Flutter stable-channel single codebase with Windows, Android and iOS folders. iPhone, iPad, Android tablets, and resizable Windows desktop supported; keyboard/mouse and touch. UX strategy A: Cupertino on iOS, Material 3 on Android, Fluent on Windows through a small adaptive-widget seam. No Material look on iOS, Cupertino look on Android, or phone UI on Windows. No network, location, contacts, microphone, camera, or account permission for MVP; local app storage only. Explicit user-selected file access for export/import and native printing if available. Backup data belongs to user; no telemetry. Screen-reader labels, high contrast, text scaling, keyboard focus and shortcut tests required.

Identifier for Android applicationId and iOS bundle ID: `com.infinityball.blendbook`; Windows/MSIX identity uses same identifier where applicable. Mobile store submission is later opt-in. `ASC_KEY_ID`, `ASC_ISSUER_ID`, `ASC_KEY_P8`, `ASC_TEAM_ID` are configured repository secret names, never app secrets.

## Status and milestones

Documentation scaffold only: no Flutter app, icon, CI or build exists yet. See [PLAN.md](PLAN.md) and issue backlog. `AppStore/description.txt` is planned-feature copy, not a claim of shipped behavior. Generate `AppStore/icon.png` through `spark-media image` (OpenAI Images API) once skeleton exists, inspect artwork, and wire Windows/Android/iOS icon sets; never use placeholder icons.

## Development quickstart (after skeleton issue)

Install pinned Flutter stable version recorded in `toolchain.json`. Run `flutter pub get`, `flutter test`, `flutter run -d windows` on Windows or use Android/iOS devices where supported. Linux checks should run in pinned Flutter Docker image. No build command can run against current docs-only scaffold.

Release milestone: `.github/workflows/release.yml`, triggered on `v*` tag or manual dispatch, builds Windows release on `windows-latest`, zips portable build, attaches it to GitHub release. Android/Play and iOS/TestFlight are later milestones.

## Manual setup required

App Store Connect bundle-ID registration of `com.infinityball.blendbook` failed: `FAILED bundleId lookup rejected: FORBIDDEN_ERROR.PLA_NOT_ACCEPTED`. Account owner must accept current Apple Program License Agreement and register/retry identifier. Do not claim registration until successful.
