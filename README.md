# Yakku

Ask anonymously. Get honest opinions.

Yakku is a Flutter prototype for anonymous mobile polls. Create a question, collect votes, and keep names out of the conversation. No account or network is required — this version uses local mock data only.

## Features

- Onboarding with no sign-in
- Anonymous profile, avatar, and display name
- Create polls (2–3 options, up to 200 characters)
- Vote on options, including **Something else**
- Results after you vote
- Light and dark themes (follows the system)

## Requirements

- [Flutter](https://docs.flutter.dev/get-started/install) 3.32+ (Dart SDK `^3.12.0`)
- Android Studio / Xcode for device or emulator builds

## Getting started

```bash
flutter pub get
```

The app uses Android product flavors (`dev`, `staging`, `production`) plus
`--dart-define=ENV=...` for Firebase options and API/web base URLs.

| Flavor | Application ID | ENV | Launcher name |
| --- | --- | --- | --- |
| `dev` | `com.yakku.app.dev` | `dev` | YAKKU Dev |
| `staging` | `com.yakku.app.staging` | `staging` | YAKKU Stage |
| `production` | `com.yakku.app` | `production` | YAKKU |

```bash
# Dev
flutter run --flavor dev --dart-define=ENV=dev

# Staging
flutter run --flavor staging --dart-define=ENV=staging

# Production
flutter run --flavor production --dart-define=ENV=production
```

Keep Firebase native configs under `/firebase` (one folder per environment):

```
firebase/
├── dev/
│   ├── google-services.json
│   └── GoogleService-Info.plist
├── staging/          # add configs when the staging Firebase project is ready
└── production/       # add configs when the production Firebase project is ready
```

Add `google-services.json` and `GoogleService-Info.plist` into each env folder
when that Firebase project exists. Real config files are gitignored.

- **Android:** Gradle copies `firebase/<flavor>/google-services.json` into
  `android/app/src/<flavor>/` automatically for the selected flavor.
- **iOS:** before building, copy the plist for the active env:

```powershell
.\tool\copy_firebase_ios.ps1 -Env dev
```

```bash
./tool/copy_firebase_ios.sh dev
```

Dart-side Firebase options live under `lib/firebase/`.

Analyze and test:

```bash
flutter analyze
flutter test
```

## Project structure

```
lib/
  core/           # Theme, colors, spacing, routes, formatters
  data/           # In-memory mock datasource and repository
  domain/         # Poll, user, and vote models plus repository contract
  presentation/   # Screens, widgets, and app-wide scope
```

Screens include onboarding, profile, create poll, poll detail, settings, and edit profile.

## Current status

This is a UI and flow prototype. Polls and votes live in memory (`MockPollRepository`) and reset when the app restarts. Backend, auth, and persistence are not wired yet.
