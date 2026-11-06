# Blend Book plan

## Scope and architecture

Flutter stable channel, one Dart codebase with `windows/`, `android/`, `ios/` enabled at first implementation. Pure Dart domain for exact ingredient quantities, revision snapshots, scaling, unit compatibility and serialization. Local repository persists on-device; explicit versioned JSON export/import with atomic restore. No cloud dependency. `com.infinityball.blendbook` for Android applicationId and iOS bundle ID; Windows/MSIX identity when packaged. iPad and Android tablet enabled.

UX strategy A, platform-native adaptive: shared screens behind small `AdaptiveScaffold`, `AdaptiveButton`, and `AdaptiveDialog` seam. Cupertino navigation and actions on iOS/iPadOS, Material 3 on Android, Fluent navigation/commands and resizable multi-column layout on Windows. Never render Material on iOS, Cupertino on Android, or phone UI on Windows. Honor each OS's back behavior, pickers, scroll physics, shortcuts, hover, safe areas, and native print/file dialogs.

Local records: Blend(id,name), Revision(id,blendId,createdAt,ingredients,notes,yield), Ingredient(name,quantity,unit). Revision content immutable. Scale compatible units using exact decimal/rational math; no mass/volume equivalence without explicit user-supplied conversion. Print label with revision and date. Validate imported references, schema and size before replacing data; make recoverable backup. No health, nutrition or allergen-safety claims.

## Milestones and dependencies

1. Flutter project + Windows test/build CI, Android debug compile, iOS project enabled; pin exact Flutter and Dart versions after measuring installed SDK in `toolchain.json`.
2. Domain storage, revision and scaling tests.
3. Create/edit/revise flow and batch worksheet.
4. Platform-authentic phone/tablet/desktop UI, accessible keyboard/touch controls, platform goldens.
5. Export/import and printable labels; explicit permission handling.
6. Generate `AppStore/icon.png` through `~/.local/bin/spark-media --project blend-book image --prompt ...` with OpenAI Images, inspect and wire Windows `.ico` and Android/iOS icons. Update `AppStore/description.txt` against real features.
7. `.github/workflows/release.yml`: `v*` tag or manual dispatch, `windows-latest` Flutter release build, zipped Windows asset on GitHub release; test downloadable artifact. Play and TestFlight later opt-in, using secret names `ASC_KEY_ID`, `ASC_ISSUER_ID`, `ASC_KEY_P8`, `ASC_TEAM_ID` only after account setup.

## Tests and evidence

Pure Dart unit tests for revision immutability, scaling, incompatible units, rounding and malformed backups. Flutter widget/golden tests for `TargetPlatform.iOS`, `TargetPlatform.android`, `TargetPlatform.windows` at phone/tablet/desktop sizes; keyboard and screen-reader checks. CI: `windows-latest` `flutter test` + `flutter build windows --release`; Linux pinned Flutter Docker image tests + `flutter build apk --debug`; iOS compilation on macOS milestone. Test real release archive; do not infer from project scaffold. Current repo has no app or canonical build/test suite.

## Risk and non-goals

Ambiguous household spoon units: display explicit approximation and never imply density conversion. Data loss on import: transactional validated restore and retained backup. Print availability: offer PDF/file fallback. No account, sync, subscriptions, AI suggestions, meal planning, ingredient safety certification, or fabricated release claims. Bundle registration blocked by Apple `FORBIDDEN_ERROR.PLA_NOT_ACCEPTED`; see README Manual setup required.
