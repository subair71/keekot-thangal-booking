# Khadim accounts

Admins open **Settings → Manage Khadim accounts** to create or edit a name,
phone number, six-digit numeric password, enabled status, and section access.
Ten-digit Indian numbers are normalized to +91; other numbers need a country
code. Leading zeroes in passwords are preserved. An empty password while editing
keeps the existing password. Accounts cannot grant admin/account-management rights.

Khadims select **Khadim login** on the sign-in screen. Permissions cover overview,
bookings and reports, slots/closures/date hours, booking settings, and pass scanning.
The bookings permission includes cancellation and attendance updates. Settings
permission covers all existing booking settings. Existing admin and gate SMS
sign-in remains available. Khadims retain the normal two-bookings-per-phone limit.

Passwords use salted scrypt hashes in a server-only collection. Login has atomic
15-minute limits of five attempts per phone and thirty per source IP. No password
is returned by any read API. Changes increment the account version: old sessions
are rejected by callable functions and booking-read rules, and the client signs
out when its account listener sees a change. Admins share credentials themselves.

## Deployment

Deploy all Functions and Firestore rules together before publishing the client:

```sh
npm ci --prefix functions
node functions/node_modules/firebase-tools/lib/bin/firebase.js deploy --project keekot-thangal-booking --only functions,firestore:rules
```

This updates existing protected callables and adds `adminSaveKhadim` and
`khadimLogin`. The runtime service account must be able to sign Firebase custom
tokens (IAM Service Account Token Creator on the signing service account, if not
already configured). Verify on staging: create a limited account, sign in with a
leading-zero password, exercise each permitted section, deny other sections,
change permissions, reset password, disable account and test old-session denial.

Local checks: Flutter analysis/tests and TypeScript build/unit tests. Firestore
emulator tests include allowed booking reads, denial of staff list/secret reads,
client escalation prevention, version revocation, disabled accounts and gate-only
read denial. Run those in CI (local environment has Java 17 and no emulator binary).
