# Premium visitor care and khadim assignment review

Branch: `feature/premium-design-khadim-assignment`. Do not merge or deploy without approval.

## Routes

| Route | Access |
| --- | --- |
| `/`, `/book`, `/information`, `/contact` | Public information and slot selection |
| `/login` | Visitor SMS login |
| `/admin/login` | Administrator SMS login; admin claim required |
| `/khadim/login` | Existing phone/password staff login |
| `/admin/assignments` | Admin-only assignment list and assign/reassign/remove dialog |
| `/admin/availability` | Admin-only date schedules, working ranges, breaks, absence windows, capacity |
| `/khadim` | Own assigned visits, Today/Upcoming, start/complete |
| `/khadim/availability` | Own schedule visibility and availability changes |
| `/booking/:id`, `/pass/:id`, `/my-bookings` | Owner or administrator; assigned khadim where authorized |

`/auth` and `/khadim-login` redirect to canonical login routes. Login preserves the intended local route. Route guards are backed by callable authorization and Firestore Rules. Public visitor content and SEO content remain intact; robots exclusions and initial-route noindex cover private paths.

## Data and consistency

- `bookings/{id}.assignment`: khadimId, public displayName, service status, monotonic revision, conflict, scheduled start/end. Legacy bookings default to unassigned.
- `khadimSchedules/{uid}_{YYYY-MM-DD}`: explicit date, hours, breaks, unavailable windows, availability toggle, capacity (default 1), updater and timestamp. No schedule means off duty.
- `assignmentHistory`: append-only server audit with actor, timestamp, reason and before/after values for assignment changes.
- `assignmentLocks/global`: transaction serialization for assignment, schedule and service operations. Transactions query current booking documents rather than a second reservation ledger. Cancellation immediately releases capacity because eligibility excludes cancelled bookings.
- Overlaps use half-open intervals. Capacity counts maximum simultaneous workload, not total visits during the booking window.
- Revision checks reject stale/repeated assignment submissions without duplicate writes. Admins must supply a reason to replace/remove an active assignee.
- Schedule changes with conflicts require acknowledgement, retain assignees and flag affected bookings.
- Booking date/time changes trigger transactional revalidation. Compatible assignments retain the same khadim; incompatible ones are flagged. Start checks scheduled times again, protecting against trigger delay.
- QR check-in and service completion remain separate. Checked-in visits may continue service.
- Notification documents reuse the existing notification delivery trigger. Push delivery requires registered devices and remains unverified in production.

The app already fixes its booking timezone to Asia/Kolkata. The new workflow uses the same local date and +05:30 conversion, independent of the browser timezone.

## Deployment after approval only

Deploy Functions, Firestore Rules, and the web application together. New exports: `assignmentCandidates`, `adminAssignKhadim`, `adminSaveKhadimSchedule`, `khadimSetAvailability`, `khadimVisitStatus`, `reconcileAssignment`.

New queries use only single-field equality indexes (Firestore defaults); existing composite indexes remain in `firestore.indexes.json`. No production bookings or staff schedules were seeded or changed during development.

Existing hosting must rewrite direct SPA paths to index.html (Firebase already does). Preserve Amplify/GitHub Pages existing rewrite support. Firebase hosting configuration now includes private-path X-Robots-Tag headers. Mirror these headers in Amplify if that host serves this branch.

## Operational considerations

- All khadims need explicit schedules before receiving assignments. Existing permission flags no longer grant a khadim global booking reads or the admin booking dashboard.
- The admin list currently listens to the booking collection and filters locally. For a high-volume deployment, replace with paginated date-scoped queries before substantial growth.
- The global transaction lock favors correctness and predictable contention for this deployment; high-throughput sites should shard by staff/date while maintaining reassignment lock ordering.
- Schedule editing uses validated HH:mm ranges, comma-separated for split shifts and multiple breaks.
- A preview fixture is isolated through Riverpod repository overrides. It uses DEMO labels and invalid demonstration QR content, with no Firebase connection.

## Validation

See the final delivery summary for exact executed test counts and limitations. Run:

```
flutter pub get --enforce-lockfile
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test --dart-define=CAPTURE_QA=true
npm test --prefix functions
node functions/node_modules/firebase-tools/lib/bin/firebase.js emulators:exec --only firestore,auth --project demo-keekot-thangal 'npm --prefix functions run test:emulator'
flutter build web --release --dart-define-from-file=config/development.json
```

`test/assignment_preview_test.dart` renders actual mobile/desktop widgets and captures PNGs for homepage, booking, all login pages, assignment list, availability, assign/reassign dialogs, khadim dashboard and visitor pass. These are renderer output, not generated mockups.

### Executed checks (22 October 2026)

- Flutter static analysis: no issues.
- Full Flutter suite: 86 tests passed, including 32 isolated preview cases.
- Node/TypeScript unit tests: 22 passed.
- Firestore/Auth emulator integration suite: 25 passed, including concurrent assignments, cancellation, status transitions, changed visit times, permission denial, and real-time snapshots received by visitor, admin and assigned khadim clients.
- Flutter release web build with isolated demo/emulator configuration: succeeded.
- Actual Flutter renderer screenshots: mobile 390px and desktop 1440px, with Malayalam examples. Existing responsive coverage also checks 375–1920px.

Not exercised against production: SMS delivery, App Check, real FCM device delivery, deployed callable URLs, and live-host browser refresh/back/forward. Production was deliberately not deployed or used for test data. No hosted interactive preview URL was created. Screenshot fixtures do not simulate backend writes; backend persistence and race behavior were tested separately in the Firebase emulators.
