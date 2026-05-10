# AGENTS.md

## Project Context

This repository contains a production-style Flutter roadside assistance / towing / dépannage platform developed as a final graduation project.

This is NOT a demo project.

All changes must preserve:

* production readiness
* Firebase security
* realtime dispatch integrity
* customer/provider/admin flows
* multilingual support
* responsive UI
* Flutter Web and Android compatibility

The application uses:

* Flutter
* Firebase Auth
* Cloud Firestore
* Firebase Realtime Database
* Firebase Messaging
* Firebase Hosting
* Firebase Functions when available
* Provider / ChangeNotifier state management
* Flutter Map / OpenStreetMap-based maps

---

## Critical Security Rules

Never commit secrets.

Never commit:

* firebase-admin.json
* service-account JSON files
* .env
* private keys
* API secrets
* webhook secrets
* raw FCM tokens
* credential exports

If a credential was ever committed:

1. revoke/delete the exposed key
2. rotate it
3. remove it from Git history
4. force-push cleaned history only after confirmation

Public Firebase client config may remain public if required by FlutterFire, but Firebase Admin SDK credentials must never be public.

---

## GitHub Safety Rules

Before any public push:

* check `git status --short`
* confirm `.env` is ignored
* confirm `firebase-admin.json` is not tracked
* confirm `.firebase/` cache is not tracked
* confirm `.env.example` contains placeholders only
* do not push generated build files unless intentionally required

Use `.gitignore` for:

* `.env`
* `.env.*`
* `!.env.example`
* `firebase-admin.json`
* `**/firebase-admin.json`
* `service-account*.json`
* `*.p12`
* `*.pem`
* `*.key`
* `.firebase/`
* `build/`
* `.dart_tool/`

---

## Architecture Rules

Do NOT rewrite large systems unnecessarily.

Do NOT replace:

* Provider/ChangeNotifier
* repository structure
* auth architecture
* dispatch architecture
* provider presence system
* localization system

Prefer:

* minimal safe edits
* targeted fixes
* backwards-compatible additions
* production-safe fallbacks

---

## Firebase Rules

Security rules must be production-safe.

Never use:

```js
allow read, write: if true;
```

Rule changes must:

* validate ownership
* validate roles
* validate state transitions
* restrict allowed fields
* avoid broad admin bypasses unless explicitly required and protected

---

## Dispatch System Rules

The dispatch system is business-critical.

Provider dispatch must depend only on Firestore app providers.

Do NOT make dispatch depend on:

* Nominatim
* Overpass
* route APIs
* map proxy
* geocoding
* nearby places
* external POI search

Expected dispatch behavior:

1. load Firestore providers
2. filter eligible providers
3. sort by distance
4. offer mission one provider at a time
5. respect provider timeout
6. retry safely if customer chooses to keep waiting
7. show “Aucun provider disponible” only after true dispatch exhaustion

Eligible provider must be:

* online
* approved
* not busy
* not on active mission
* has valid location
* within dispatch radius if radius is enabled

When debugging dispatch, log only safe diagnostics:

* provider uid
* total providers count
* eligible count
* online/approved/busy flags
* has location
* distance
* exclusion reason

Never log:

* phone
* email
* FCM token
* private user data

---

## Provider Presence Rules

Provider online/offline state uses:

* Firebase Realtime Database presence
* Firestore availability mirror/fallback

Do not break:

* onDisconnect behavior
* offline fallback
* busy-state protection
* active mission protection

A provider on an active mission must not receive another mission.

---

## Tracking and Map Rules

Tracking must:

* update in realtime
* show route/ETA/distance when available
* degrade gracefully on Flutter Web
* never crash because a map API fails

On Flutter Web:

* browser CORS can block direct third-party map/search APIs
* use Firebase Functions proxy when available
* otherwise fallback safely
* straight-line route fallback is acceptable

External map/search failures must never affect provider dispatch.

---

## Firebase Functions Rules

Use Firebase Functions as a backend proxy for web map/search/routing when possible.

Spark/free-plan compatibility:

* do not require Secret Manager unless project is on Blaze
* support `functions.config()` or `process.env`
* fail gracefully if a key is missing
* never expose API keys to Flutter frontend

Cloud Function endpoints may include:

* `mapSearch`
* `reverseGeocode`
* `nearbyPlaces`
* `routeDirections`

Functions must:

* validate input
* apply timeouts
* catch upstream errors
* normalize responses
* return empty/fallback results instead of crashing

---

## UI/UX Rules

Do NOT redesign pages unless explicitly requested.

Preserve:

* current branding
* layout language
* customer/provider/admin flows
* localization behavior

Fixes should:

* remove overflow
* avoid layout jumps
* keep mobile/web responsive
* keep animations lightweight

---

## Marker and Animation Rules

Map markers must:

* use fixed/constrained dimensions
* avoid unconstrained `Column`
* avoid RenderFlex overflow
* keep marker and pulse centered

Searching marker pulse:

* use `Stack(alignment: Alignment.center)`
* place pulse behind marker
* match marker widget width/height with map marker width/height
* avoid offset Transform bugs
* stop animation when status is no longer searching

---

## Localization Rules

The project supports:

* French
* English
* Arabic

Avoid hardcoded strings for new production UI.
Prefer existing localization architecture.

Temporary debug-only text is acceptable during diagnosis but should not remain in final production UI.

---

## FCM Rules

Never print raw FCM tokens.

Allowed logs:

* `FCM token saved`
* `FCM token refreshed`
* `FCM unavailable on web`

Not allowed:

* token value
* raw exception payloads containing sensitive details

On Flutter Web:

* FCM may fail because of service worker/browser push restrictions
* failure must not crash UI

---

## Code Quality Rules

After edits:

* run `dart format`
* run `flutter analyze`
* run `npm run lint` / `npm run build` for functions when changed

Avoid:

* noisy permanent logs
* dead code
* duplicated logic
* unrelated refactors
* repeated failed network retries

---

## Final Response Format

Every coding task response must include:

* root cause
* files changed
* what was fixed
* commands run
* remaining risks/TODOs

For dispatch bugs, also include:

* exact reason provider was excluded
* how eligibility was corrected

For Functions changes, also include:

* setup commands
* deploy commands
* any Blaze-only limitations

---

## Goal

Every change should move the project toward:

* production readiness
* secure Firebase architecture
* stable realtime dispatch
* professional UX
* graduation-project presentation quality
