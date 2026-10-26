
## Admin QR verification

Open **Administration → Scan visitor pass** (`/admin/gate`) with an admin or gate-staff account. Choose **Scan visitor pass**, allow camera access, and point the rear camera at the QR on the on-screen or PDF visitor pass. Scanning a valid pass immediately records attendance (`completed`), check-in time, staff UID, and an audit entry. The dialog closes after one code to prevent repeated camera submissions. Open it again for the next visitor.

Verification uses the existing server-side `validatePass` callable and configured arrival window. Unknown, cancelled, expired, premature, and previously used passes are rejected. Simultaneous scans can confirm a pass only once. A booking's QR covers its entire visitor group; this is not per-person admission.

Camera access requires HTTPS (or localhost) and browser permission. If unavailable, paste the QR token and choose **Verify and confirm visit**. **Check pass** verifies without recording attendance. A network failure never displays successful confirmation; retry verification to find out whether an interrupted request recorded attendance.

Deploy the updated Firebase functions alongside the web release to enable detailed rejection reasons and `checkedInBy` attribution. Before production use, test camera permissions and a real pass on Android Chrome and iPhone Safari, plus cancelled, wrong-time and already-used passes. Automated tests cover server admission rules and the manual verification UI; they cannot exercise a physical camera here.

## Booking confirmation notifications

Each successful booking now creates its confirmation notice in the same Firestore transaction. Retrying a booking or receiving the existing booking trigger again does not create another notice. Users can read the confirmation under Notifications even when browser push is unavailable. The existing `sendPushNotification` trigger delivers the notice to registered devices; it must be deployed together with the updated booking function.

Visitors should select **Enable notifications** on the confirmation screen before selecting **Confirm booking** and allow the browser permission request. Push requires a supported browser, valid VAPID configuration and permission. On iPhone, use the installed Home Screen app. Enabling after a booking does not resend a previously undeliverable confirmation; it enables future notifications.

The messaging worker and config import resolve relative to the app base path, including GitHub Pages. Push links open the root document with a validated booking route, avoiding a Pages nested-route 404. `APP_ORIGIN` can be the complete deployed base URL, including a subdirectory; if unset, notification links use the production GitHub Pages URL. Keep it correct for staging deployments.

Validation: backend tests cover notice ownership/content and root/subdirectory links; emulator tests cover atomic creation, retry deduplication and suppression after cancellation. Real-device permission, foreground alert, background push and notification-tap behavior still need a production smoke test after web and Firebase deployment.

## Request verification and abuse limits

All booking/staff callable functions now require Firebase App Check outside the
Functions emulator. `ENFORCE_APP_CHECK=false` no longer disables protection.
The client already initializes App Check before starting the application. Missing
or invalid attestation must be rejected before database access or booking logic;
a caller-supplied app ID, account ID, or IP in the request body is never trusted.
Callable payloads must be JSON objects no larger than 16 KiB.

After attestation, Firestore transactions enforce these shared fixed-window
budgets. Both the authenticated account and source-IP budget must permit a call.
Limits also apply to staff; staff authorization is still checked separately.

| Action | Per account / minute | Per source IP / minute |
| --- | ---: | ---: |
| Availability polling | 60 | 300 |
| Read active hold | 60 | 600 |
| Create/release hold (shared budget) | 20 | 300 |
| Confirm booking, including retries | 20 | 300 |
| Verify/check in pass | 120 | 600 |
| Register/unregister push device (shared budget) | 20 | 300 |
| Admin/Khadim login (shared budget) | 60 when signed in | 60 |
| Remaining authenticated callables (shared budget) | 120 | 1200 |

Login also retains its existing five attempts per username/phone and thirty per
IP over fifteen minutes. Contact submission retains its separate App Check and
five-per-IP/hour plus one-hundred/day limits. Firebase phone OTP uses Firebase
Authentication directly: these callable limits do not replace its SMS-region,
reCAPTCHA, quota and billing controls.

Counters live in server-only `requestRateLimits` documents. Document identifiers
hash the transport IP/account UID; they contain no raw identifiers, visitor
payloads, or tokens. These IDs remain pseudonymous, not anonymous. Deploy the
`purgeAt` TTL policy in `firestore.indexes.json` to remove expired counters after
24 hours; enforcement uses server time and does not depend on prompt TTL deletion.
A counter-store failure rejects the operation. Throttled responses include a
safe message and `retryAfterSeconds`; the interface must not label throttling as
a full time slot. Review limits against real venue traffic, especially visitors
sharing Wi-Fi/NAT, before increasing them.

Public pass links still allow a single document read by its unguessable token,
but collection listings and queries are denied, including for signed-in clients.
Forwarded links remain bearer links: anyone holding one can read that pass. This
change does not add expiry, redact pass fields, or synchronize pass status.

### Release checks

1. Verify the existing web App Check app/site key and allowed hosting domains in
   the correct Firebase project. Use registered App Check debug tokens only in
   staging; never ship them in web assets or repository configuration.
2. Deploy the reviewed callable code, Firestore rules and indexes together using
   the authorized deployment account. Inventory existing functions first; every
   callable exported by `functions/src/index.ts` uses the changed wrapper.
3. With bookings paused or a dedicated staging project, confirm normal visitor,
   admin and Khadim flows obtain valid App Check tokens. Verify missing/invalid
   App Check requests fail, login limits still work, and exceeding an action
   budget returns `resource-exhausted` without creating another hold/booking.
4. Confirm a known public pass link opens while collection queries fail. Check
   Firestore App Check enforcement separately in the console: callable App Check
   does not itself enable enforcement for direct Firestore SDK access.
5. Check quota/latency dashboards and TTL status after rollout. App Check and
   rate limits reduce abuse; they are not a guarantee against all automated use.

Run backend unit tests and the Firestore/Auth emulator suite before deployment.
Unit tests call `.run()` with synthetic verified context and make no real App
Check attestation claim; deployed negative/positive token checks are a release
requirement. Existing booking idempotency and daily phone limits remain enforced.
