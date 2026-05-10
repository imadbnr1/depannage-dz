# Auto Rescue

A production-style Flutter + Firebase roadside assistance platform for Algeria, built as a final graduation project.

Auto Rescue connects customers who need towing or roadside help with verified nearby providers in real time. The platform includes customer ordering, provider dispatch, live mission tracking, multilingual UI, admin operations, pricing management, notifications, audit logs, and Firebase-backed security rules.

---

## Overview

Auto Rescue is a mobile-first roadside assistance and towing platform designed around three operational roles:

- **Customer**: creates assistance requests, tracks provider arrival, chats, cancels requests, and rates completed missions.
- **Provider**: receives mission offers, accepts or rejects requests, updates mission lifecycle, shares live position, tracks earnings, and rates customers.
- **Admin**: supervises platform activity, validates providers, manages users, configures pricing/support, sends notifications, exports analytics, and reviews audit logs.

The application is built with Flutter and Firebase using a Provider/ChangeNotifier architecture, Firestore realtime streams, OpenStreetMap maps, routing fallbacks, and role-based security rules.

---

## Features

### Customer App

- Create roadside assistance requests with:
  - pickup location
  - destination
  - vehicle type
  - brand/model
  - service type
  - estimated distance, ETA, and price
- Realtime request tracking on map
- Animated provider searching indicators
- Provider scan count and dispatch attempt visibility
- No-provider-accepted popup with:
  - cancel request
  - continue waiting / rescan providers
- Live provider route, ETA, and distance
- Mission chat
- Active requests page
- Mission history
- Provider rating after completion
- Customer profile and support pages
- Multilingual UI support

### Provider App

- Provider dashboard with live availability controls
- Online/offline and busy-state handling
- Mission offers scoped to the offered provider
- Accept/reject mission flow
- Current mission tracking page
- Live GPS tracking
- Mission lifecycle actions:
  - accepted
  - on the way
  - arrived
  - in service
  - completed
- Google Maps navigation launch
- Customer chat
- Earnings page
- Mission history
- Customer rating after completion
- Provider profile and support pages

### Admin App

- Admin dashboard with operational overview
- Provider management:
  - approve providers
  - block/unblock providers
  - inspect provider status
- Customer/user management
- Requests monitoring
- Pricing management
- Admin notification management
- Activity/audit logs
- Analytics and CSV export
- Support configuration management
- Role-based admin access

---

## Architecture

The project follows a feature-first Flutter architecture with centralized application state.

```text
lib/
  app/                  Application shell and configuration
  core/
    i18n/               Localization and language persistence
    models/             Shared core models
    services/           Firebase, routing, location, notification, audit services
    utils/              Utility helpers
  features/
    admin/pages/        Admin dashboard, analytics, pricing, notifications
    auth/pages/         Login, signup, auth gate
    customer/pages/     Customer home, order, tracking, profile, support
    provider/pages/     Provider dashboard, missions, tracking, earnings
    shared/pages/       Chat, legal, onboarding, splash, permissions
  models/               Domain models
  repositories/         Firestore repository layer
  state/
    app_store.dart      Central ChangeNotifier app state
  widgets/              Reusable UI widgets
```

### State Management

The app uses the `provider` package with a central `AppStore` based on `ChangeNotifier`.

`AppStore` coordinates:

- authentication-aware stream subscriptions
- request streams
- provider streams
- pricing configuration
- dispatch chain state
- provider busy state
- live tracking state
- customer/provider tabs
- notifications
- mission lifecycle transitions

---

## Tech Stack

- **Flutter**
- **Dart**
- **Firebase Auth**
- **Cloud Firestore**
- **Firebase Storage**
- **Firebase Cloud Messaging**
- **Firebase Realtime Database**
- **Provider / ChangeNotifier**
- **Flutter Map**
- **OpenStreetMap**
- **Geolocator**
- **OSRM / GraphHopper / Mapbox / OpenRouteService routing fallbacks**
- **SharedPreferences**
- **Flutter Local Notifications**
- **URL Launcher**
- **File Picker**
- **CSV export support**

---

## Firebase Services Used

### Firebase Authentication

Used for customer, provider, and admin authentication.

### Cloud Firestore

Primary database for:

- users
- providers
- requests
- request chats
- app configuration
- pricing configuration
- support configuration
- admin notifications
- activity logs
- audit logs

### Firebase Storage

Used for image uploads such as provider/admin-managed assets.

### Firebase Cloud Messaging

Used for push notification payload handling and realtime notification flows.

### Firebase Realtime Database

Used by the provider presence system.

### Firebase Hosting

Configured for Flutter web builds through `firebase.json`.

---

## Authentication System

The app includes a role-based authentication system with:

- customer login/signup
- provider signup
- provider approval requirement before receiving missions
- admin-only login flow
- Firebase Auth integration
- Firestore user profile lookup
- role-based routing through `AuthGate`
- persisted language selection across auth pages

Supported roles:

```text
customer
provider
admin
```

Provider accounts are not fully active until approved by an admin.

---

## Realtime Dispatch System

The dispatch system is implemented in `AppStore` and the request repository layer.

When a customer creates a request:

1. The request is created in Firestore with status `searching`.
2. Eligible providers are scanned using existing provider data.
3. Providers are filtered by:
   - `isOnline == true`
   - `isBusy != true`
   - `isApproved == true`
4. Eligible providers are sorted by distance from the customer.
5. A dispatch chain is built.
6. The request is offered to one provider at a time.
7. Each provider receives an offer timeout window.
8. If the provider rejects or times out, the next provider is offered.
9. If all providers reject or time out, the customer receives a no-provider-accepted popup.
10. The customer can cancel or continue waiting, which rebuilds the dispatch chain.

Dispatch state includes:

- provider chain
- current chain index
- current offered provider
- scanned provider count
- current dispatch attempt
- offer expiration time
- rejected provider list
- no-provider popup state

This avoids silent infinite searching and gives the customer clearer feedback.

---

## Provider / Customer / Admin Roles

### Customer

Customers can:

- request help
- view active requests
- track provider movement
- cancel searching requests
- chat with provider
- rate provider
- view history
- update profile
- access support information

### Provider

Providers can:

- go online/offline
- receive mission offers
- accept/reject requests
- update mission lifecycle
- share live GPS location
- open navigation
- chat with customers
- view earnings
- view history
- rate customers

### Admin

Admins can:

- approve/block providers
- monitor users and requests
- configure pricing
- send app notifications
- manage support settings
- inspect analytics
- export CSV reports
- review activity logs

---

## Maps & Navigation

The map system uses:

- `flutter_map`
- OpenStreetMap tiles
- `latlong2`
- Geolocator
- external Google Maps launch through URL Launcher

Tracking pages include:

- customer position marker
- provider position marker
- destination marker
- route polyline
- ETA and distance
- route progress indicator
- draggable information sheet
- safe-area-aware floating buttons

Route behavior:

```text
accepted / onTheWay:
  routeStart = providerPosition
  routeEnd   = customerPosition

arrived / inService:
  routeStart = providerPosition
  routeEnd   = destinationPosition

completed:
  active route is cleared
```

Routing is handled by `RouteService`, which supports multiple routing providers and fallback behavior.

---

## Notifications

The project includes several notification layers:

- Firebase Cloud Messaging payload handling
- local notifications
- admin broadcast notifications
- in-app lifecycle notifications
- chat notifications
- mission lifecycle alerts
- provider offer notifications
- no-provider-available notifications

Admin notifications can be configured with:

- audience
- type
- popup behavior
- schedule
- optional image
- sound behavior

---

## Localization

Auto Rescue supports:

- French
- English
- Arabic

The localization system includes:

- `AppLocalizations`
- language selector widget
- persisted language choice using `SharedPreferences`
- RTL direction support for Arabic
- localized auth, home, tracking, support, profile, admin, and shared UI strings

Default language behavior is managed by `AppLanguageController`.

---

## Project Structure

```text
.
├── android/
├── assets/
│   ├── logo/
│   └── sounds/
├── lib/
│   ├── app/
│   ├── core/
│   │   ├── i18n/
│   │   ├── models/
│   │   ├── services/
│   │   └── utils/
│   ├── features/
│   │   ├── admin/
│   │   ├── auth/
│   │   ├── customer/
│   │   ├── provider/
│   │   └── shared/
│   ├── models/
│   ├── repositories/
│   ├── state/
│   ├── widgets/
│   ├── firebase_options.dart
│   └── main.dart
├── scripts/
├── test/
├── web/
├── firebase.json
├── firestore.rules
├── storage.rules
├── pubspec.yaml
└── README.md
```

---

## Installation

### Prerequisites

Install:

- Flutter SDK
- Dart SDK
- Firebase CLI
- FlutterFire CLI
- Android Studio or VS Code
- Android SDK
- A Firebase project

Check Flutter setup:

```bash
flutter doctor
```

Install dependencies:

```bash
flutter pub get
```

---

## Firebase Setup

The project is configured for Firebase project:

```text
depannage-dz-imad-2026
```

Firebase configuration files used by the app:

```text
lib/firebase_options.dart
android/app/google-services.json
firebase.json
firestore.rules
storage.rules
```

If setting up a new Firebase project, run:

```bash
dart pub global activate flutterfire_cli
flutterfire configure
```

Enable the following Firebase services:

- Authentication
- Cloud Firestore
- Firebase Storage
- Firebase Cloud Messaging
- Realtime Database
- Firebase Hosting, if building for web

Deploy Firestore and Storage rules:

```bash
firebase deploy --only firestore:rules
firebase deploy --only storage
```

Deploy web hosting after building:

```bash
flutter build web --release
firebase deploy --only hosting
```

---

## Environment Configuration

The project currently includes generated Firebase options for:

- Android
- Web

iOS, macOS, Windows, and Linux are not configured in `firebase_options.dart` and will throw an unsupported platform error until configured with FlutterFire CLI.

Important configuration files:

```text
lib/firebase_options.dart
android/app/google-services.json
firebase.json
firestore.rules
storage.rules
web/firebase-messaging-sw.js
```

For production, keep service account files out of client builds and do not expose admin SDK credentials in public repositories.

---

## Running Locally

Run on a connected Android device or emulator:

```bash
flutter run
```

Run on web:

```bash
flutter run -d chrome
```

Fetch dependencies:

```bash
flutter pub get
```

Analyze code:

```bash
flutter analyze
```

Run tests:

```bash
flutter test
```

---

## Build Commands

Build Android APK:

```bash
flutter build apk --release
```

Build Flutter web:

```bash
flutter build web --release
```

Format code:

```bash
dart format .
```

Analyze code:

```bash
flutter analyze
```

Run tests:

```bash
flutter test
```

---

## Production Notes

Before production deployment:

- Deploy latest `firestore.rules`.
- Deploy latest `storage.rules`.
- Verify Firebase Authentication providers.
- Verify Firestore indexes if queries require them.
- Validate provider approval workflow.
- Test dispatch with multiple real provider accounts.
- Test background/foreground notification delivery.
- Test location permissions on physical Android devices.
- Verify Realtime Database presence behavior.
- Verify route fallback behavior in poor network conditions.
- Remove debug-only logs where necessary.
- Protect admin/service account credentials.

---

## Security Notes

Security is enforced through Firebase Authentication and Firestore rules.

Implemented protections include:

- role-based access control
- customer-only request creation
- customer-owned request cancellation
- provider-only mission acceptance/update flows
- provider availability checks
- admin-only app configuration writes
- admin-only audit/activity access
- scoped request read access
- scoped chat access based on request visibility
- image upload limits in Storage rules

Client-side role checks improve UX, but Firebase rules remain the primary security boundary.

---

## Firestore Rules

The project includes `firestore.rules` with role-aware access for:

- `users`
- `providers`
- `requests`
- `tracking`
- `app_config`
- `app_notifications`
- `admin_activity_logs`
- `admin_audit_logs`
- `request_chats`
- `chats`

Important request permissions include:

- customers can create their own searching requests
- customers can cancel their own searching requests
- customers can dispatch their own request to available providers
- providers can accept offered requests
- providers can update assigned active missions
- admins can manage platform data

Deploy rules with:

```bash
firebase deploy --only firestore:rules
```

---

## Realtime Database Presence System

The project includes a provider presence service using Firebase Realtime Database.

Presence path:

```text
presence/providers/{providerUid}
```

The service mirrors provider online state into Firestore provider documents, allowing dispatch to consider realtime availability through provider fields such as:

```text
isOnline
isBusy
isApproved
lastSeenAtIso
```

This supports faster provider availability checks and more accurate dispatch behavior.

---

## Screenshots

Add product screenshots here before publication.

```text
docs/screenshots/customer-home.png
docs/screenshots/create-order.png
docs/screenshots/customer-tracking.png
docs/screenshots/provider-dashboard.png
docs/screenshots/provider-tracking.png
docs/screenshots/admin-dashboard.png
docs/screenshots/admin-analytics.png
```

Example layout:

| Customer | Provider | Admin |
|---|---|---|
| ![Customer Home](docs/screenshots/customer-home.png) | ![Provider Dashboard](docs/screenshots/provider-dashboard.png) | ![Admin Dashboard](docs/screenshots/admin-dashboard.png) |

---

## Known Limitations / Future Improvements

- iOS, macOS, Windows, and Linux Firebase options are not configured yet.
- Some admin and secondary screens may still need full localization coverage.
- No-provider popup text should be moved fully into localization keys.
- Dispatch currently depends on Firestore provider availability fields being fresh.
- Production deployment should include complete Firebase indexes and monitoring.
- Automated integration tests for dispatch, cancellation, and tracking should be expanded.
- A dedicated backend or Cloud Functions layer could further harden dispatch logic.
- Realtime Database security rules should be reviewed and deployed with production constraints.
- Route services depend on external routing APIs and network availability.

---

## License

This project is currently provided for academic and portfolio evaluation purposes.

A production license should be defined before commercial distribution.

---

## Author

Developed as a final graduation project.

**Project:** Auto Rescue  
**Type:** Flutter + Firebase roadside assistance platform  
**Region focus:** Algeria
