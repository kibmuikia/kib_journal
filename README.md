# kib_journal

A Flutter Android app for sharing anonymous daily journal entries.

## Features

- Journal sharing, 500 character limit per entry
- Send emails to users via a background worker.

## Tech Stack

- Flutter SDK: ^3.7.2
- Firebase - For Authentication and Database(Firestore)
- GetIt for dependency injection
- Go-Router for navigation

## Getting Started

1. Clone the repository
2. Run `flutter pub get`
3. Configure Firebase project
4. Run the app with `flutter run`

Generate required files with:
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```
