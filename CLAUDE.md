# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

AiTODO is a Flutter to-do application focused on task management, AI parsing, reminders, statistics, recycle bin, and local import/export.

## Common Commands

```bash
# Run the app on a connected device/emulator
flutter run

# Run tests
flutter test
flutter test test/widget_test.dart  # Run single test file

# Analyze code for issues
flutter analyze

# Build debug APK
flutter build apk --debug

# Build release APK
flutter build apk --release
```

## Architecture

The project uses Flutter with:
- **Android** as the target platform (see `android/` directory)
- **Provider** state management
- **shared_preferences** local persistence
- **flutter_local_notifications** for task reminders
- **flutter_test** for widget testing

### Directory Structure

```
lib/
  main.dart
  models/
  providers/
  services/
  screens/
  widgets/
test/
  widget_test.dart
android/
  app/build.gradle.kts
```

### Key Files

- `pubspec.yaml` - Dependencies and project metadata
- `analysis_options.yaml` - Dart analyzer configuration (uses flutter_lints)
- `lib/main.dart` - Main application code

## Development Notes

- Keep task creation/update logic in `TaskProvider` to avoid state drift.
- Import/export should use full task sets, not filtered views.
- Tests use `WidgetTester` from `flutter_test`.
