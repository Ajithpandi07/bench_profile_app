# bench_profile_app

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

## bench_profile feature & Firebase setup

This repository has a new `bench_profile` feature scaffold under `lib/features/bench_profile`.

To use Firebase Authentication locally:

1. Create a Firebase project at https://console.firebase.google.com and enable Email/Password sign-in for Authentication.
2. Add your platform apps to Firebase (Android/iOS/web) and download the config files (e.g., `google-services.json` for Android).
3. Place platform config files in the appropriate platform folders (Android: `android/app/`, iOS: `ios/Runner/`).
4. Run the app:

```bash
flutter pub get
flutter run
```

Tip: For local development you can also use the Firebase Emulator Suite. Configure the emulator and point `Firebase.initializeApp()` to the emulator during development.

Files added for the feature:

- `lib/features/bench_profile/presentation/pages/login_page.dart` — Login UI wired to Firebase Auth.
- `lib/features/bench_profile/data/datasources/firebase_auth_remote.dart` — FirebaseAuth wrapper.
- `lib/features/bench_profile/data/repositories/auth_repository_impl.dart` — Repository implementation.
- `lib/features/bench_profile/domain/*` — Entities and usecases.

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
