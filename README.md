# Depannage DZ - Pro Structured

A professionally structured Flutter demo project for a towing / roadside assistance app.

Includes:
- multi-file Flutter project structure
- customer create order flow
- customer request preview
- customer requests page
- customer live tracking page
- provider dashboard
- provider mission list
- provider mission details page
- provider tracking page
- provider history page
- location permission request via geolocator
- fake local live-tracking simulation

## Run

```bash
flutter pub get
flutter run -d chrome
```

If your local Flutter installation says web support is missing:

```bash
flutter create . --platforms=web
```

Then verify that `lib/main.dart` still contains the custom project entrypoint.
