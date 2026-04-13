# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

```bash
flutter pub get          # Install dependencies
flutter run              # Run app on connected device/emulator
flutter analyze          # Static analysis
flutter test             # Run all unit tests
flutter test test/path/to_test.dart   # Run a single test file
flutter build apk        # Build Android APK
flutter build ios        # Build iOS
flutter build web        # Build web

# Code generation (after modifying models with build_runner annotations)
dart run build_runner build --delete-conflicting-outputs
```

## Architecture

**Pattern:** Feature-based modular architecture using GetX for state management, routing, and DI.

**Data flow:**
```
Screens → Controllers (GetX) → Repositories → Services (Dio/Supabase) → Backend API / Supabase
```

**Core layers:**
- `lib/core/constants/` — App-wide constants: colors, text styles, dimensions, asset paths
- `lib/core/services/` — Shared services: connectivity, push notifications, realtime, audio
- `lib/core/widgets/` — Reusable UI components
- `lib/shared/config/api_config.dart` — API base URLs and endpoint definitions
- `lib/shared/models/` — Shared data models (e.g. `user_model.dart`)

**Feature modules** live under `lib/features/` (auth, feed, message, profile, stories, community, notification, search, explore, navigation). Each follows this structure:

```
feature/
├── bindings/      # GetX DI bindings (injected on route entry)
├── controllers/   # Business logic and reactive state (GetX)
├── repositories/  # Data layer abstraction between controllers and services
├── services/      # Raw API/Supabase calls
├── models/        # Feature-specific data models
├── screens/       # Full-page UI
└── widgets/       # Feature-scoped UI components
```

## Backend & Services

- **Supabase** (project: `jlrnivejmucekrhdwyij.supabase.co`) — primary database and auth
- **Firebase** (project: `otakuverse-fafb8`) — push notifications via FCM
- **REST API** — dev: `http://10.0.2.2:3000`, prod: `https://api.otakuverse.com`; configured in `lib/shared/config/api_config.dart`
- **Supabase Edge Functions** — located in `supabase/functions/`, use Deno/TypeScript (see `.vscode/settings.json` for Deno config)

## State Management

GetX is used throughout. Controllers are registered via `Bindings` classes tied to routes. Use `Get.find<ControllerName>()` to access an already-registered controller, and `Get.put()` / `Get.lazyPut()` inside bindings for registration.

## Assets & Fonts

Custom fonts (Poppins, Inter) and images are declared in `pubspec.yaml`. Reference images via constants in `lib/core/constants/assets.dart` rather than hardcoding paths.
