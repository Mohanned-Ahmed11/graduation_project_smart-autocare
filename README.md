# Smart Auto Car

Flutter app: AI-assisted car diagnosis, help requests, maps, and Supabase-backed chat.

## Local setup (secrets are not in Git)

1. Copy `env.template` to `.env` in the project root and fill in values (`SUPABASE_URL`, `SUPABASE_ANON_KEY`, `GEMINI_API_KEY`, Maps/Places keys as needed).
2. Add `android/app/google-services.json` from the [Firebase Console](https://console.firebase.google.com/) (same Firebase project you use for FCM). This file is gitignored.
3. `flutter pub get` then `flutter run`.

Gemini and other API keys are read only from `.env` or `--dart-define=` (see `lib/core/config/env.dart`); they are not hardcoded in Dart.

Repository: [github.com/kamelfcis/smart-autocare](https://github.com/kamelfcis/smart-autocare)
