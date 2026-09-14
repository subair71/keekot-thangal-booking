# Keekot Thangal Visit Booking

A native Flutter Web application for visits to Keekot Thangal Maqam, Chavakkad, Kerala. It implements phone verification, configurable slots, five-minute holds, atomic booking and cancellation, private QR/PDF passes, notifications and staff administration. The supplied mobile design was inspected and rebuilt for responsive web layouts.

**Status:** source and local validation are provided. A production Firebase project, actual venue settings and deployment credentials must be supplied before opening the service. See `docs/validation.md` for the exact checks completed in this delivery and `docs/architecture.md` for implementation details.

## Prerequisites

- Flutter **3.47.4 stable**, Dart **3.13.3** (the SDK used for this delivery).
- Node.js **22** for Firebase Functions, npm, and Java **21+** for Firestore emulators.
- Python 3 for public web configuration generation.
- A Firebase project with billing enabled for phone auth, Functions and scheduled jobs when deploying. Configure quotas and budget alerts appropriate to your expected traffic.
- Firebase CLI is pinned by `functions/package-lock.json`; no global install is required.

Dependencies resolve to mutually compatible stable versions in `pubspec.lock` and `functions/package-lock.json`. Major packages include Riverpod 3.4.3, GoRouter 18.0.1, FlutterFire, Firebase Functions v2 and TypeScript. Newsreader/Plus Jakarta Sans fonts and their OFL licenses are bundled locally.

## Run locally with real Firebase emulators

From the project root:

```bash
flutter pub get --enforce-lockfile
dart run build_runner build
npm ci --prefix functions
npm run build --prefix functions
python3 tool/configure_web.py config/development.json
node functions/node_modules/firebase-tools/lib/bin/firebase.js emulators:start --project demo-keekot-thangal --only auth,firestore,functions
```

In another terminal, seed **only** the emulators:

```bash
FIRESTORE_EMULATOR_HOST=127.0.0.1:8080 FIREBASE_AUTH_EMULATOR_HOST=127.0.0.1:9099 npm run seed --prefix functions
flutter run -d chrome --dart-define-from-file=config/development.json
```

The seed uses capacity **12**, maximum group **6**, a seven-day window and 07:00–19:00 half-hour slots. These are development examples, not approved production capacity. The local admin phone is **+919999999999**; the Auth emulator prints/generated SMS codes are visible in its UI at `http://127.0.0.1:4000`. No SMS is sent and no fixed OTP is stored. Production startup rejects emulator configuration.

To serve the built app through the Hosting emulator:

```bash
bash tool/build_web.sh development
node functions/node_modules/firebase-tools/lib/bin/firebase.js emulators:start --project demo-keekot-thangal --only auth,firestore,functions,hosting
```

Open `http://127.0.0.1:5000`. Reseed after emulator restarts unless you intentionally use Firebase's `--import`/`--export-on-exit` options. Exported emulator data may contain test visitor information; keep it out of Git. FCM itself is not emulated.

## Firebase staging and production setup

1. Create separate staging and production projects. Register a web app in each. Create Firestore in Native mode in the chosen region; Functions are configured for `asia-south1`. If changing Functions region, update `functions/src/index.ts` and `FUNCTIONS_REGION` together.
2. Enable Firebase Phone Authentication, permitted SMS regions (India for this deployment), quotas, and authorized domains. Include the actual `PROJECT_ID.web.app`, custom domain and staging domain. Add localhost only for local testing if needed. FlutterFire's `signInWithPhoneNumber` handles web reCAPTCHA. Use Firebase Console test phone numbers on staging to avoid sending real SMS during automated testing.
3. Register Firebase App Check for the web app with reCAPTCHA v3. Add the same authorized domains and its public site key to `APP_CHECK_SITE_KEY`. Production callable functions enforce App Check. Verify staging tokens before enforcing additional Firestore App Check restrictions in the Firebase Console.
4. Under Project Settings → Cloud Messaging, generate a Web Push certificate/VAPID public key. Enable the FCM Registration API if your project requires it. Set `VAPID_KEY`. HTTPS is required for browser push.
5. Copy `config/staging.example.json` to `config/staging.json` and `config/production.example.json` to `config/production.json`. Fill the web app values from Firebase Console (or FlutterFire CLI output) plus VAPID/App Check keys. These are public web SDK values, not service-account credentials. The files are ignored to avoid accidentally deploying another environment.
6. `python3 tool/configure_web.py config/production.json` creates matching public worker configuration in `web/firebase-config.js`. Run this for the same environment as `--dart-define-from-file`. The build helper does this automatically.
7. Set `APP_ORIGIN=https://YOUR_VERIFIED_DOMAIN` as the Functions environment value in `functions/.env.PROJECT_ID` for notification click links. Use the actual Firebase Hosting origin if there is no custom domain. Environment files are ignored. Use Google Secret Manager for any future backend secrets, never a web configuration file.
8. Authenticate the Firebase CLI using your account (`firebase login`) or authorized Application Default Credentials. Project selection always uses an explicit `--project`; the checked-in default is the safe demo project.

### First administrator and operational settings

Sign in once with the real administrator's phone number. Obtain their Firebase Auth UID from the Console. Use an authorized workstation with `gcloud auth application-default login`, then:

```bash
npm run admin --prefix functions -- YOUR_PROJECT_ID ADMIN_UID admin
```

This preserves unrelated custom claims, sets the role and revokes refresh tokens so the administrator must sign in again. Use role `gate` for entry-only staff or `revoke` to remove both roles. Never assign admin based on a client-editable profile field.

After deploying Functions/rules, sign in and open `/admin/settings`. It is accessible to the authorized administrator even when no booking settings document exists. Enter **actual** capacity and group limits, official HTTPS directions URL, contact phone (optional), booking hours, window, reminders and arrival lead time. Save with bookings paused first; enable bookings when venue approval and staging checks are complete. The emulator seed refuses to write production data.

Use `/admin/slots` to change an individual complete slot, a range or a whole day. Capacity reductions cannot undercut booked/held visitors. Closing slots does not automatically cancel existing bookings; cancel those explicitly in `/admin/bookings`. Search applies to the selected date. Hours/duration cannot change until already-materialized future dates have elapsed; see the architecture guide for the conservative schedule lock. Default capacity affects new slots; use slot management for existing slots.

## Tests and build

```bash
dart run build_runner build
dart format lib test
flutter analyze
flutter test --coverage
npm test --prefix functions
node functions/node_modules/firebase-tools/lib/bin/firebase.js emulators:exec --only firestore,auth --project demo-keekot-thangal 'npm --prefix functions run test:emulator'
bash tool/build_web.sh development
```

`build_runner` 2.16 removed `--delete-conflicting-outputs`; the current supported command above is used. Tests cover slots, India time, date windows, capacity, references, retry safety, concurrency, Firestore ownership restrictions, secure gate validation, OTP states, passes and responsive layouts at 375, 430, 768, 1024, 1280, 1440 and 1920 pixels.

A clean production build once the configuration is filled:

```bash
flutter clean
flutter pub get --enforce-lockfile
dart run build_runner build
dart format lib test
flutter analyze
flutter test
python3 tool/configure_web.py config/production.json
flutter build web --release --dart-define-from-file=config/production.json
```

Crashlytics is not supported on Flutter Web; technical errors are sanitized and platform error hooks are present. Analytics is disabled by default and can be enabled through `ENABLE_ANALYTICS` in the environment configuration. It does not record names, phone numbers or booking tokens.

## Deploy to Firebase

```bash
node functions/node_modules/firebase-tools/lib/bin/firebase.js login
bash tool/build_web.sh production
node functions/node_modules/firebase-tools/lib/bin/firebase.js deploy --project YOUR_PROJECT_ID --only firestore,functions,hosting
```

This deploys Firestore rules/indexes, Functions and the Flutter SPA. Indexes may take time to build. Confirm they are ready in Firestore before testing production queries. Hosting rewrites all application routes to `index.html`, including `/book`, `/my-bookings` and `/admin`. The CLI supplies the actual deployed Hosting URL; this repository does not assert one before deployment.

Verify on staging: phone OTP and reCAPTCHA, App Check acceptance/rejection, simultaneous booking/cancellation, pass PDF download, full-day closures, unauthorized admin access, foreground/background push, reminder scheduling and deep-link refresh. Test real devices for browser push; iOS may require installation to the home screen and supported OS/browser versions. Verify contact details, capacity and visitor instructions with the venue.

## Git and CI/CD

The delivery contains a local Git history. If you create an empty GitHub repository, connect and push it:

```bash
git remote add origin https://github.com/YOUR_USERNAME/keekot-thangal-booking.git
git push -u origin main
```

Authenticate through your normal GitHub workflow before pushing. No remote or account credential is assumed.

GitHub Actions validates Flutter, TypeScript and emulator tests on pull requests/main, then compiles a test-configuration web release. Optional production deployment rebuilds using the actual production config after checks. Configure repository/environment variables: `DEPLOY_FIREBASE=true`, `FIREBASE_PROJECT_ID`, `FIREBASE_WEB_CONFIG` (the public config JSON), `WIF_PROVIDER`, and `DEPLOY_SERVICE_ACCOUNT`. Use a GitHub production environment and narrowly scoped Workload Identity Federation for deployment. Do not store service-account private keys in Git. Ensure the deployment identity has only the roles needed for the selected Firebase resources and function service-account impersonation.

## What the owner must supply

Real Firebase projects/billing/access, web app config, App Check site key, VAPID key, administrator UID, approved capacity/group limits, official location/contact details, final domain/origin and optional Git remote authentication. Live SMS, FCM and deployment cannot be verified without those values.

## References

- [Flutter SDK archive](https://docs.flutter.dev/install/archive)
- [Firebase Flutter phone authentication](https://firebase.google.com/docs/auth/flutter/phone-auth)
- [Receive Firebase messages in Flutter](https://firebase.google.com/docs/cloud-messaging/flutter/receive-messages)
- [Manage Firebase Functions](https://firebase.google.com/docs/functions/manage-functions)

See `docs/design-review.md`, `docs/architecture.md` and `docs/validation.md` for the design decisions, data model, security, concurrency and exact delivery status.
