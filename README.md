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
flutter run
```

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
