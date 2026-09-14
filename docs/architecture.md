# Architecture and operational behavior

The Flutter application uses Riverpod for dependency injection and reactive state, GoRouter for navigation, and feature folders with domain contracts and Firebase data implementations. The backend is TypeScript, Firebase Functions v2, and Firestore. Domains use immutable Dart models and typed TypeScript models; there is no Firebase or Flutter UI dependency in the Dart domain. Riverpod configuration is generated with `build_runner`. Freezed is not needed for these small immutable models.

## Important folders

| Folder | Purpose |
| --- | --- |
| `lib/app` | Initialization, Riverpod wiring, route guards, semantic theme |
| `lib/core` | Configuration, typed failures, time formatting, shared UI |
| `lib/features/authentication` | Phone authentication contract, FlutterFire implementation, OTP UI |
| `lib/features/booking` | Settings, slots, holds, repository, selection and confirmation |
| `lib/features/my_bookings` | Upcoming/history views, digital pass, PDF download |
| `lib/features/notifications` | Private inbox, push permission, device tokens |
| `lib/features/admin` | Staff overview, bookings, closures, settings, entry validation |
| `functions/src` | Authoritative booking service, callable APIs, event handlers and schedulers |
| `functions/test` | Domain, concurrency, authorization and rules tests |
| `test` | Flutter domain and responsive widget tests |
| `tool`, `config`, `.github/workflows` | Configuration generation, builds, environment samples, CI/CD |

## Firestore collections

| Collection | Data and visibility |
| --- | --- |
| `settings/booking` | Public operational settings. Server/admin-function writes only. |
| `visitSlots/{date_HHmm}` | Public schedule, capacity, confirmed occupancy, blocking reason. No visitor data. |
| `slotState/{slotId}` | Private hold map, read only by backend. Expirations are numeric server milliseconds. |
| `slotHolds/{uid_requestId}` | Owner-readable hold; server-only writes. A TTL `purgeAt` enables eventual cleanup. |
| `activeUserHolds/{uid}` | Owner-readable pointer enforcing one active hold per visitor account. |
| `bookings/{randomId}` | Owner/admin readable booking and private bearer QR. No client writes. |
| `passTokens/{sha256}` | Backend-only token-hash lookup. Contains the booking ID, never a phone number. |
| `closures/{yyyy-MM-dd}` | Public whole-day closure and reason; server-only writes. |
| `users/{uid}` | Owner profile; only display name and server timestamp permitted. |
| `users/{uid}/devices/{sha256}` | Backend-only FCM token, registration timestamp, maximum 10 devices. |
| `notifications/{bookingId_kind}` | Owner-readable inbox and delivery state; owner can only mark read. |
| `auditLog/{randomId}` | Staff actions, actor UID and timestamp; admin readable, server-only writes. |

Admin identity comes from signed Firebase Auth custom claims (`admin: true` / `gate: true`). There is no writable `adminUsers` privilege collection or browser storage authority.

## Firebase Functions

| Functions | Authorization and purpose |
| --- | --- |
| `getAvailability` | Public callable with production App Check; computes capacity from current bookings and holds. |
| `getActiveHold`, `createHold`, `releaseHold`, `createBooking`, `cancelBooking` | Verified phone identity; ownership and atomic capacity mutations. |
| `validatePass` | Admin or gate claim; validate or check in an opaque QR token. |
| `adminDashboard`, `adminUpdateSlot`, `adminUpdateSettings`, `adminSetBookingStatus` | Admin claim; reports, capacity, closures, configuration and attendance. |
| `registerDevice`, `unregisterDevice` | Verified phone identity; private push token registration. |
| `sendBookingConfirmation`, `sendPushNotification` | Firestore event handlers; deterministic inbox and independent FCM delivery. |
| `bookingReminderScheduler`, `cleanupExpiredHolds` | One-minute scheduled jobs; reminders, retries, expiry and hold cleanup. |

## Transaction protocol

1. Authentication completes before reserving capacity. Every production callable validates App Check; visitor mutations require a verified Firebase phone identity.
2. `createHold` reads settings, the visitor's active-hold pointer, the selected slot, private slot state and day closure inside a Firestore transaction. It removes expired holds from the calculation, validates date/time and visitor count, and reserves five minutes of capacity. The request ID is stable across retries. A different slot uses a new request ID.
3. `createBooking` rereads the hold, current settings, closure, slot and active holds. The same transaction converts the hold to confirmed occupancy, creates a random-ID booking, creates a SHA-256 pass lookup, and marks the hold converted. A retry returns the original booking ID. The transaction's read set detects concurrent admin closures and capacity changes.
4. Cancellation checks ownership or admin authorization. It changes status and decrements occupancy together. Further cancellations return success without another decrement.
5. The UI polls availability every 20 seconds, using server-computed active holds. Expired holds are excluded immediately, even if cleanup is late. Selection is informational until the backend accepts a hold/confirmation.

One private slot-state document serializes requests for a slot, with maximum configurable capacity 500. This is appropriate for the requested appointment scale; load-test against expected venue traffic before increasing scale. Settings are read in each booking transaction, but the schedule-lock field is only written when the locked-through date advances.

## Schedule changes

All dates and hours use `Asia/Kolkata` and explicit UTC+05:30 conversion. The booking window includes today: seven days means today through today+6. Disabling same-day booking excludes today without extending the final day.

The development seed is 07:00–19:00, 30-minute slots, capacity 12, maximum group size 6, seven-day window. These values are explicitly for testing. No production settings are automatically seeded.

Hours, timezone and duration are locked through the latest date with materialized slots/holds to avoid orphaning existing appointments. After that date elapses, administrators can change them. This conservative lock is not removed by cancellation. Default capacity changes affect newly materialized slots; existing slots are changed through slot management. Existing bookings retain their time and reminder schedule.

Blocking a period stops new confirmations and does not silently cancel existing confirmed visits. Staff must cancel affected bookings separately if entry should be revoked. Whole-day closures must be reopened at day level before individual slots can reopen. Completed/no-show/expired occupancy remains historical and is never reused as future capacity.

## QR passes

Each pass uses 32 cryptographically random bytes encoded as a 43-character base64url bearer token. It contains no name, phone, readable reference or document ID. Its SHA-256 hash is the private lookup key. The original token is stored only on the owner/admin-readable booking so a visitor can reopen/download a pass. Treat the QR like an admission ticket; copied passes are not separate entitlements.

`validatePass` requires gate or admin claims and returns only validity, reference, date/time, visitor count and status. Entry is valid from the configured early-arrival lead time until slot end. Check-in marks the booking completed transactionally, so another scan cannot admit it again. The UI supports text-output scanners or pasted scanned tokens; a camera scanning UI is not included.

## Notification semantics

Firestore booking creation/cancellation events create a deterministic inbox record. Delivery runs independently of booking success. A lease and bounded retries handle transient FCM failures; invalid device tokens are removed. Scheduler retries also recover abandoned leases. Delivery is at least once: the notification tag/deterministic ID reduces visible duplicates, but an interruption after FCM sends can cause a duplicate. Never promise exactly-once push delivery.

Reminders are queued by a one-minute scheduler and use each booking's configured-at-creation lead time. Disabling reminders prevents sends. Past confirmed bookings become expired unless staff checked them in; admins can correct expired bookings to attended/no-show. Push is unavailable in Firebase emulators; inbox event behavior and authoritative booking transactions remain testable there. Real FCM/VAPID, reCAPTCHA/App Check, SMS quotas and mobile browser permissions require a configured staging project and devices.

Notification permission is requested only from an explicit signed-in visitor action after booking or on Notifications. Existing permission restores registration and refresh handling on later signed-in sessions without another permission prompt. Tokens register through authenticated callables. Signing out attempts both server removal and local token deletion; a server removal error does not skip the local deletion attempt or block sign-out. User data is not placed in analytics events or production function error logs. Firebase Crashlytics does not support Flutter Web; no nonfunctional Crashlytics integration is included.

## Web and accessibility

The supplied emblem is used directly, with bundled OFL Newsreader and Plus Jakarta Sans fonts. Desktop has a centered 1280px content area and full navigation; smaller screens use bottom navigation and stacked layouts. Cards/slot grids reflow, 48–52px primary controls support keyboard focus, slots carry semantic status, and errors are announced. The HTML shell provides metadata, a favicon, loading state and SPA routes. Flutter rendering limits content SEO compared with server-rendered HTML; the static shell supplies basic discovery metadata.

Exact phone numbers, map coordinates, gate names, distances and facilities from design mockups were not assumed to be verified. Only official owner-provided location/contact configuration is shown.
