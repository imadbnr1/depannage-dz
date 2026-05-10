# AGENTS.md

## Project Context

This repository contains a production-style Flutter roadside assistance / towing / dépannage platform developed as a final graduation project.

This is NOT a demo project.

All code changes must preserve:

* production readiness
* realtime stability
* Firebase security
* existing architecture
* provider/customer/admin flows
* multilingual support
* responsive UI behavior
* realtime dispatch integrity

The application uses:

* Flutter
* Firebase Auth
* Cloud Firestore
* Firebase Realtime Database
* Firebase Messaging
* Google Maps
* Provider state management

---

# Core Engineering Rules

## 1. Never Rewrite Large Systems Unnecessarily

Do NOT rewrite:

* dispatch system
* authentication flow
* provider presence system
* Firestore architecture
* routing/navigation architecture
* state management architecture

Prefer:

* minimal safe edits
* targeted fixes
* additive improvements
* backward-compatible changes

---

## 2. Preserve Existing Architecture

Respect the existing structure:

* repositories
* services
* Provider/ChangeNotifier state management
* models
* localization system
* feature folders

Avoid introducing:

* Riverpod
* Bloc
* GetX
* new architecture patterns
  unless explicitly requested.

---

## 3. Production-Safe Firebase Rules

Security is critical.

Never:

* loosen Firestore rules broadly
* use allow read, write: if true
* expose admin-only operations
* expose provider private data
* allow arbitrary request mutation

All rule changes must:

* follow least-privilege principle
* restrict fields precisely
* validate ownership
* validate request state transitions

---

# Dispatch System Rules

The dispatch system is business-critical.

Important concepts:

* eligibleProvidersSortedByDistance
* dispatch chains
* provider offer timeout
* provider busy-state handling
* fallback dispatch
* retry dispatch
* no-provider popup logic

Never:

* create infinite dispatch loops
* instantly show "no provider available"
* bypass provider timeout logic
* dispatch to busy providers
* dispatch to offline providers

Expected behavior:

1. Build dispatch chain
2. Offer mission sequentially
3. Respect timeout window
4. Retry safely if requested
5. Show no-provider popup ONLY after true exhaustion

---

# Provider Presence Rules

Provider online/offline state uses:

* Firebase Realtime Database
* Firestore sync fallback

Never:

* break disconnect handling
* remove onDisconnect behavior
* mark providers online incorrectly
* allow busy providers to receive new missions

Provider session integrity is critical.

---

# Tracking & Navigation Rules

Tracking pages must:

* support realtime updates
* avoid heavy rebuilds
* support ETA/distance
* gracefully degrade on Flutter Web
* avoid crashes when route APIs fail

On Flutter Web:

* fallback route rendering is acceptable
* straight polyline fallback is acceptable
* UI must never crash due to CORS

---

# UI/UX Rules

Do NOT redesign pages unless explicitly requested.

Keep:

* existing branding
* visual hierarchy
* navigation flow
* localization behavior

Fixes should:

* avoid overflows
* avoid layout jumps
* remain responsive
* preserve performance

Animations:

* lightweight only
* avoid rebuilding full map/widgets every frame
* prefer AnimationController + AnimatedBuilder

---

# Marker & Map Rules

Custom map markers must:

* have constrained dimensions
* avoid RenderFlex overflow
* avoid unconstrained Column usage
* remain performant

Searching state may use:

* pulse animation
* radar ring
* opacity/scale animation

---

# Localization Rules

The project supports:

* French
* English
* Arabic

Never hardcode new UI strings unless unavoidable.

Prefer:

* localization keys
* existing translation architecture

---

# Repository Safety Rules

Before public Git pushes:

Sensitive files must NEVER be committed:

* firebase-admin.json
* service-account JSON files
* .env
* API secrets
* private tokens
* webhook secrets

Public Firebase client config may remain public if required by FlutterFire.

---

# Code Quality Rules

Required after modifications:

* dart format
* flutter analyze when practical

Avoid:

* dead code
* noisy debug logs
* duplicated logic
* massive unrelated refactors

---

# Modification Strategy

Before editing:

1. Read AGENTS.md
2. Read repomix-flutter.txt
3. Inspect affected architecture
4. Minimize scope
5. Preserve compatibility

Final responses should include:

* root cause
* files changed
* what was fixed
* commands run
* remaining risks/TODOs

---

# Performance Rules

Avoid:

* unnecessary rebuilds
* polling loops
* memory leaks
* repeated failed API retries
* excessive Firestore writes

Prefer:

* cached state
* throttled updates
* lightweight animations
* graceful fallback behavior

---

# Deployment Rules

Code must remain compatible with:

* Flutter Web
* Android

Do not introduce:

* platform-breaking imports
* unsupported web plugins
* incompatible native-only logic without guards

---

# Goal

Every change should move the project toward:

* production readiness
* stability
* maintainability
* professional UX
* secure Firebase architecture
* graduation-project presentation quality
