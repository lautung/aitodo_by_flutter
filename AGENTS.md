# Repository Guidelines

## Project Structure & Module Organization
- `lib/main.dart` is the app entry point and provider wiring.
- `lib/models/` contains domain data (`task.dart`, `subtask.dart`).
- `lib/providers/` contains app state and business flows (tasks, theme, tags, priorities).
- `lib/services/` contains integrations and persistence (AI parsing, notifications, storage, chat storage).
- `lib/screens/` contains page-level UI; `lib/widgets/` contains reusable UI components.
- `test/` contains automated tests (`widget_test.dart` currently).
- `docs/` contains product and review documents; update when behavior changes.
- `android/` is platform host code; `build/` is generated output and should not be edited manually.

## Build, Test, and Development Commands
Run from repository root:

```bash
flutter pub get            # install dependencies
flutter run                # run on connected device/emulator
flutter analyze            # static analysis with flutter_lints
flutter test               # run automated tests
flutter build apk --debug  # debug APK
flutter build apk --release
```

## Coding Style & Naming Conventions
- Follow `analysis_options.yaml` (`package:flutter_lints/flutter.yaml`).
- Use 2-space indentation and trailing commas in widget trees for stable formatting.
- Use `snake_case` for file names, `PascalCase` for classes/enums, and `camelCase` for fields/methods.
- Keep UI widgets focused on rendering; move state mutations and non-trivial logic into providers/services.
- Prefer small, composable widgets over large screen files.

## Testing Guidelines
- Use `flutter_test` for widget and unit tests.
- Name test files as `*_test.dart`; group by feature (for example, `task_provider_test.dart`).
- For UI changes, add/adjust widget tests that assert visible behavior.
- For logic changes, add provider/service tests (task lifecycle, repeat rules, parse results).
- Before opening a PR, run `flutter analyze` and `flutter test`.

## Commit & Pull Request Guidelines
- Git history is not included in this workspace, so this repository uses a Conventional Commit baseline:
  - `feat(tasks): add recurring task generation`
  - `fix(notification): avoid duplicate reminders`
- Keep each commit focused on one logical change.
- PRs should include: summary, affected modules, test evidence, and screenshots for UI changes.
- Link related issue/spec sections and update `docs/README.md`/`SPEC.md` when requirements change (for long sessions, refresh docs at least hourly).

## Security & Configuration Tips
- Never commit secrets, keystores, or local machine paths (especially `android/local.properties`).
- Validate import/export JSON flows carefully to avoid user data loss.
