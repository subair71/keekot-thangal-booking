# Delivery validation

Validation date: 13 September 2026. This delivery is source code and a compiled web release using **development emulator configuration**. It is not a deployed production service.

## Completed checks

| Check | Result |
| --- | --- |
| Flutter clean and locked dependency restore | Passed; Flutter 3.47.4 stable / Dart 3.13.3. |
| Riverpod code generation | Passed; generated provider source is committed. |
| Dart formatting | Passed for `lib` and `test`. |
| Flutter analyzer | Passed with no issues. |
| Flutter domain, widget and PDF tests | 22 passed. |
| Responsive layouts | Tested at 375, 430, 768, 1024, 1280, 1440 and 1920 pixels. |
| TypeScript Functions build and unit tests | Build passed; 6 domain tests passed. |
| Firestore/Auth emulator integration suite | 10 reported tests passed: one parent and nine integration scenarios. |
| Flutter release web build | Passed with development configuration; output is `build/web`. |
| PDF visual inspection | Long-name pass rendered to PNG; name, dates, QR and footer fit on one A5 page. |

Flutter tests cover 24 non-overlapping half-hour slots, IST conversion, booking dates, capacity, safe auth return paths, home/navigation at seven widths, slot selection/confirmation at seven widths, OTP consent/code-entry states, empty/confirmed bookings, the mobile pass and PDF generation. Actual application fonts are loaded during widget testing. `CAPTURE_QA=true` writes review renders under `build/qa`; these use test repositories, not live venue availability. Coverage output is available when running `flutter test --coverage`; no claim of complete coverage is made.

Backend tests cover date validation, slot generation, capacity accounting, configuration validation and secure references/tokens. Emulator tests verify 12 simultaneous reservation attempts competing for three places, idempotent confirmation, ownership and repeated cancellation, expired holds without the scheduler, suppression of delayed confirmation notices after cancellation, closure rechecks, capacity reduction protection, gate/time/replay validation and Firestore client access restrictions. Expected permission-denied log messages are assertions of successful rule enforcement.

The Functions tests ran with the environment's Node 24.19.0 and Java 21. Functions deployment targets Node 22, and CI selects Node 22. Real staging validation remains required for the hosted runtime and Firebase project settings.

## Issues found and corrected

- Updated FlutterFire API calls and resolved analyzer findings.
- Fixed a compact-header overflow with explicit logo typography.
- Replaced availability polling with a controller/timer that stops immediately on provider disposal.
- Made shared cards Material surfaces so checkbox/list-tile ink feedback stays visible.
- Rechecked account ownership before displaying cached passes and reset pass streams when authentication changes.
- Prevented delayed confirmation notifications from being queued for cancelled bookings.
- Restored push token registration after prior permission and separated local token cleanup from server removal failure during sign-out.
- Bundled the Cupertino icon font referenced by adaptive framework widgets.
- Included visitor names in PDF passes and corrected the long-name footer layout.

## What was not executed against production

Firebase CLI account inspection returned **no authorized accounts**. No real Firebase project configuration, domain, approved venue capacity or administrator account was supplied. Deployment prerequisites were checked; a deploy command was not sent to an unconfigured/demo project. No deployed URL exists for this delivery.

Live SMS/reCAPTCHA, production App Check enforcement, browser FCM foreground/background delivery, real scheduled jobs, final-domain routing and device-specific permission behavior need a staging project. Automated tests and Flutter-rendered screenshots were inspected; no live-browser end-to-end session against a real Firebase project was performed. A camera QR scanner is not included; the gate UI accepts text-output scanners/pasted opaque tokens. PDF names were verified with Latin text; test the venue's required scripts and add suitable fonts/shaping support before claiming broader language support.

Git is initialized locally with meaningful commits. There is no remote, so no push was attempted. `git log --oneline` shows the included history. The README contains exact commands for adding a remote, production configuration, administrator claims, the release build and `firebase deploy --only firestore,functions,hosting`.

## Owner-provided production values

Provide Firebase staging/production projects and authorized deployment access; web app configuration; App Check site key; VAPID public key; final domain and `APP_ORIGIN`; administrator UID; approved slot capacity, group limit and hours; official directions/contact information; and a Git remote if a push is wanted. Configure billing, authorized phone-auth domains/SMS regions, indexes, quotas and production monitoring in the project before accepting visits.

The architecture, collections, complete exported Function list, security model, concurrency strategy and notification behavior are documented in `architecture.md`. Design interpretation is in `design-review.md`; setup and operational commands are in the root README.
