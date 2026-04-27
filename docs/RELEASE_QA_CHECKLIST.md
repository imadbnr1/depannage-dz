# Depaniny Final Release QA Checklist

Use this checklist before a graduation demo, APK sharing, or Firebase Hosting deploy.

## Build Health

- [ ] Run `flutter clean`
- [ ] Run `flutter pub get`
- [ ] Run `flutter analyze`
- [ ] Run `flutter build web --release`
- [ ] Run `flutter build apk --release`

## Firebase

- [ ] Deploy Firestore rules with `firebase deploy --only firestore:rules`
- [ ] Deploy Storage rules with `firebase deploy --only storage`
- [ ] Deploy web hosting with `firebase deploy --only hosting`
- [ ] Confirm admin account has `role: admin` in `users/{uid}`
- [ ] Confirm providers cannot approve themselves
- [ ] Confirm blocked users cannot log in

## Customer Flow

- [ ] Create customer account
- [ ] Allow GPS and notifications
- [ ] Create mission with pickup, destination, car type, and car model
- [ ] Confirm estimated price and provider access fee look correct
- [ ] Track provider before pickup
- [ ] Rate provider after completion
- [ ] Refresh browser and confirm rating is not asked again

## Provider Flow

- [ ] Create provider account
- [ ] Confirm provider is pending until admin approval
- [ ] Admin approves provider
- [ ] Provider receives new mission popup
- [ ] Provider accepts mission
- [ ] Provider tracking shows route to customer
- [ ] Hidden dev simulation still works for laptop testing
- [ ] After pickup, route switches to destination
- [ ] Provider rates customer after completion

## Admin Flow

- [ ] Hidden admin login opens
- [ ] Admin dashboard loads counts and recent missions
- [ ] Provider approve/block/unblock works
- [ ] Customer search and block/unblock works
- [ ] Mission filters work
- [ ] Force-cancel mission works
- [ ] Analytics date/time filters work
- [ ] Analytics CSV export downloads on web
- [ ] Activity log records admin actions
- [ ] Notification popup appears for customer/provider

## Public Readiness

- [ ] Legal pages are reachable from login and support
- [ ] Support phone, WhatsApp, email, address, and hours are configured
- [ ] App icon and app name are final
- [ ] APK installs on a real Android phone
- [ ] Firebase Hosting URL works on Chrome
- [ ] Admin uses web URL, customers/providers can use APK or web
