# AGENTS.md

## Project Overview
DEPANINY / Auto Rescue is a Flutter + Firebase roadside assistance platform for Algeria.

Main roles:
- Customer: request towing, battery, tire, mechanic services
- Provider: receive missions, accept/reject, navigate, update status
- Admin: monitor requests, manage providers/customers, pricing, analytics

Tech stack:
- Flutter / Dart
- Firebase Auth, Firestore, Storage, Messaging
- Provider package with ChangeNotifier
- Flutter Map + OpenStreetMap
- Geolocator
- OSRM / GraphHopper / Mapbox routing fallback
- SharedPreferences
- Flutter local notifications

## Important Commands
Run these when relevant:
```bash
flutter pub get
dart format .
flutter analyze
flutter test
flutter build web --release
flutter build apk --release

Project Structure :
lib/
  app/                  App entry/config
  core/
    i18n/               Localization
    models/             Shared core models
    services/           Firebase, routing, location, notification services
    utils/              Helpers/utilities
  features/
    admin/pages/        Admin dashboard pages
    auth/pages/         Login/signup/OTP/auth pages
    customer/pages/     Customer app pages
    provider/pages/     Provider mission pages
    shared/pages/       Shared screens
  models/               App/domain models
  repositories/         Data access/repository layer
  state/
    app_store.dart      Central ChangeNotifier app state
  widgets/              Reusable UI widgets
Root config : 
  pubspec.yaml
analysis_options.yaml
firebase.json
firestore.rules
storage.rules