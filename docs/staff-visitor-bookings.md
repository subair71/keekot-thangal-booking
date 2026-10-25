# Staff bookings with visitor contact details

Admins and enabled Khadims with the `bookings` permission enter a required
**Visitor Phone Number** on the confirmation form. It starts blank and accepts
international numbers with `+` and country code; spaces, parentheses and hyphens
are removed before storage. Ordinary visitors continue booking with the phone
number from their authenticated token.

In Admin → Khadim management, enable **Book visits for visitors** for each
Khadim who should use this flow. Saving permissions invalidates their previous
session; they sign in again with the updated access. This permission does not
grant access to the administrator's full booking list.

## Data and access

- `visitorPhone` contains the normalized visitor contact. `phoneNumberMasked`
  is derived from that contact for compatibility.
- `visitorPhoneVerified` is false for manually entered staff bookings. No guest
  Firebase Auth account is created or linked by matching the entered number.
- `bookingSource` is `staff` or `self`. `bookedByUid`, `bookedByRole`, and
  `bookedByName` are derived from authentication and the current staff record.
- `userId` retains its existing meaning as the booking's access owner (the
  creator). Staff can retrieve the passes they created through My bookings.
  A matching visitor phone does not grant another account access.
- Disabled, deleted, or stale-version Khadim sessions cannot use the callables
  or read their created bookings through the updated Firestore rules.
- In-app/push notices for assisted bookings go to the creator account and say
  that the visit was booked for a visitor. No SMS/WhatsApp is sent to an entered,
  unverified contact. Sharing a downloaded pass remains a separate staff action.

The existing two-bookings-per-phone-per-visit-date limit uses `visitorPhone`,
shared across staff and self bookings. Cancelled bookings still count. Admin
exemptions remain. Staff holds retain the existing per-account ownership,
capacity protection and expiry; their visitor's limit is checked atomically at
confirmation, after the visitor details are entered. Retried confirmations
return the original booking without incrementing capacity or daily counts.

Old bookings without a stored visitor contact display **Not recorded** for
Visitor Phone Number. The old masked account number is retained in storage but
is not guessed to be a visitor's number. Existing daily counters are retained;
where a counter is absent, new records can be counted by visitor phone and old
self-booking records by authenticated ownership. A masked-only legacy record
cannot reliably be attributed to a guest booked by staff.

## Deployment

Deploy the backend and rules before releasing the new Flutter build. Older
staff clients must refresh after deployment because staff confirmation now
requires the visitor phone field. Visitor self-booking requests stay compatible.

Use the production project explicitly; `.firebaserc` deliberately defaults to
an emulator project. After dependency installation and passing validation:

```bash
npm ci --prefix functions
npm test --prefix functions
node functions/node_modules/firebase-tools/lib/bin/firebase.js deploy --project keekot-thangal-booking --only functions,firestore:rules --non-interactive
```

The full functions deployment includes staff management and login functions as
well as the updated booking functions. It requires the existing
`CONTACT_GMAIL_APP_PASSWORD` Secret Manager value
for `submitContact`; do not substitute a fake secret if it is not configured.
For an isolated release of this feature, deploy the following changed functions
and the rules (all functions that use the shared actor resolver are included):

```bash
node functions/node_modules/firebase-tools/lib/bin/firebase.js deploy --project keekot-thangal-booking --only functions:getActiveHold,functions:createHold,functions:releaseHold,functions:createBooking,functions:ensureBookingTokens,functions:cancelBooking,functions:validatePass,functions:adminUpdateSlot,functions:adminSetDateHours,functions:adminUpdateSettings,functions:adminSetBookingStatus,functions:adminDashboard,functions:registerDevice,functions:unregisterDevice,functions:adminSaveKhadim,functions:adminDeleteKhadim,functions:assignmentCandidates,functions:adminAssignKhadim,functions:adminSaveKhadimSchedule,functions:khadimSetAvailability,functions:khadimVisitStatus,functions:sendBookingConfirmation,functions:bookingReminderScheduler,firestore:rules --non-interactive
```

No new composite index or data migration is required. The production web release
must use the existing production Firebase configuration, never the emulator
configuration used in CI.

## Validation and live checks

- Backend unit tests cover normalization, missing/invalid contacts, authenticated
  creator identity, spoofed request fields, role checks, disabled/deleted/stale
  Khadims, and notification recipients.
- Emulator tests cover concurrent confirmations across staff accounts, shared
  limits with self bookings, cancellations, admin exemptions without an account
  phone, retries, different guests using one staff account, and Firestore access.
- Flutter tests cover blank staff contact input, validation, normalized submission,
  unchanged self-booking, role guards, pass display, old records, Excel values,
  and PDF generation with long visitor and creator names.
- After release, verify one admin and one permitted Khadim booking with distinct
  visitor numbers; inspect the confirmation and downloaded PDF, then test an
  ordinary visitor booking. Confirm stored creator UID/role and unchanged staff
  account details. These are live checks, not proof supplied by unit tests.

Validation on the feature branch passed in GitHub Actions with Flutter 3.47.4,
Node 22 and Java 21: Dart code generation, formatting, Flutter analysis, the full
Flutter test suite, the TypeScript build and 28 backend unit tests, and Firebase
emulator transaction/rules tests. Generated admin, Khadim and long-name passes
were rendered and visually inspected: each fits on one page with the entered
visitor number and a separate Booked by field. CI retains pass PDFs, report
exports and responsive UI previews for review.

Firebase deployment and live function inventory remain unverified because no
authenticated deployment access is available. The CI release build uses test
configuration and is not a production deployment. See [PR #60](https://github.com/subair71/keekot-thangal-booking/pull/60)
for the latest build results before release.
