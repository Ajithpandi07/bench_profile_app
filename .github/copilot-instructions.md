## Repo overview

- This is a Flutter application (Dart SDK ^3.9.2). The app entrypoint is `lib/main.dart` (root widget `MyApp`, main screen `MyHomePage`).
- Minimal, mostly template code. Key configuration files: `pubspec.yaml` (dependencies), `analysis_options.yaml` (uses `flutter_lints`), and platform folders (`android/`, `ios/`, `linux/`, `macos/`, `windows/`).

## What an AI agent should know first

- The project uses the standard Flutter project layout. Changes to UI behavior are typically made in `lib/` (here only `lib/main.dart`).
- Platform-specific wiring lives under each platform folder. For Android builds the Gradle Kotlin DSL file is at `android/app/build.gradle.kts` and the wrapper at `android/gradlew`.
- Tests: there is a widget test at `test/widget_test.dart`. Use `flutter test` to run.

## Common developer workflows (project-specific)

- Run (debug, hot-reload):

```bash
flutter run            # selects a connected device; supports hot reload (press 'r')
```

- Run tests quickly:

```bash
flutter test           # runs unit/widget tests in test/
```

- Build for Android (local):

```bash
cd android && ./gradlew assembleRelease  # or from repo root: flutter build apk
```

- Build for desktop (Linux/macOS/Windows):

```bash
flutter build linux|macos|windows
```

Notes: iOS builds require macOS and proper signing; Android release builds use the debug signing config until you configure a release signing key (see `android/app/build.gradle.kts`).

## Project-specific patterns and conventions

- Linting: `analysis_options.yaml` includes `package:flutter_lints/flutter.yaml`. Follow existing lints; don't disable rules globally unless necessary.
- Small single-file UI: this repo keeps the UI in `lib/main.dart`. When suggesting refactors, prefer minimal, well-scoped file splits (e.g., extract `MyHomePage` into `lib/screens/home.dart`) and add imports to `lib/main.dart`.
- Keep changes platform-agnostic by default—only edit platform folders for native integrations.

## Integration points / native code

- The repo contains platform runner code under `linux/runner`, `ios/Runner`, `macos/Runner`, and `windows/runner`. If adding native plugins or platform channels, update generated plugin registrant files under each platform (files named `generated_plugin_registrant.*`).
- There are no explicit MethodChannel usages in `lib/` at present; search before adding duplicate channels.

## Files to inspect for context when making code changes

- `lib/main.dart` — app entrypoint and sample UI. Example: theme seed color is set via `ColorScheme.fromSeed(seedColor: Colors.deepPurple)`.
- `pubspec.yaml` — dependency list (currently minimal) and assets configuration.
- `analysis_options.yaml` — lint rules (uses `flutter_lints`).
- `android/app/build.gradle.kts` and `android/gradle.properties` — Android build settings and versions.

## Helpful examples an agent can offer

- When proposing a small feature change, include the exact file and snippet to edit (e.g., replace the seed color in `lib/main.dart`), and list the commands to run and test locally (`flutter run`, `flutter test`).

## Do NOT assume

- CI or custom scripts: there are no CI configs or custom workflow files in the repo root. Don't add CI changes without asking.
- That native signing or provisioning is configured — iOS/Android release builds will need developer-supplied credentials.

## If you make edits

- Run `flutter analyze` and `flutter test` locally (or as part of your change). Keep edits minimal and add a test when behavior changes.

---
If you want changes to the tone, level of detail, or to include examples for a specific task (e.g., adding a state management package or wiring a platform channel), tell me which area to expand and I will iterate.
