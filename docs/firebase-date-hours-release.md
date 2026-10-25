# Date-specific hours: release audit

Audit started 2026-10-13 against main `c2442496c373f0466d609558db225d3ea091804b`.

## Evidence and limits

- PR #4 merged the callable and date-aware booking service. PR #5 did not change the backend.
- Validation run 38326972056 passed on that main revision: 30 Flutter tests, 11 backend domain tests, and 15 emulator tests (including the parent test). Firebase deployment was skipped, as in run 38308716707.
- An unauthenticated POST with empty data to `https://asia-south1-keekot-thangal-booking.cloudfunctions.net/adminSetDateHours` returned HTTP 404. The same project's `getAvailability` returned HTTP 200 for 2026-10-14. The expected admin endpoint appears unavailable; this does not identify the deployed source revision or conclusively prove absence from Cloud Functions inventory.
- Local Firebase CLI reports no authorized accounts. The available GitHub connector cannot inspect Actions variables/secrets, cloud IAM, or dispatch deployment. Console inspection was interrupted. No authenticated production inventory was obtained.
- No production hours, reservations, holds, or settings were changed. Backend build and all 11 domain tests also passed locally. Emulator evidence above is from CI, not a fresh local emulator run.

## Configuration to verify before release

1. Repository variable `DEPLOY_FIREBASE` must equal the literal `true`. The job-level gate is evaluated before the production environment is attached; keep this switch at repository scope. Its current effective value does not permit deployment, but missing versus false was not independently inspected.
2. Configure `FIREBASE_PROJECT_ID`, `WIF_PROVIDER`, and `DEPLOY_SERVICE_ACCOUNT` at repository or production-environment scope. The expected production project from the Pages workflow is `keekot-thangal-booking`; confirm it against the running web app and cloud inventory.
3. Supply `FIREBASE_WEB_CONFIG` as a secret or variable. This patch aligns CI with Pages' secret-first selection. Previously CI used only the variable, while Pages accepted a secret. The config must be production, disable emulators, match the deploy project, and use `asia-south1`.
4. Verify the WIF provider trusts only the intended repository and production release context, and that the service account can be impersonated by that identity. The workflow already grants `id-token: write` and `contents: read`; these GitHub permissions alone do not grant Google Cloud access.
5. Verify narrowly scoped deployment permissions for the selected Cloud Functions, build/artifact resources, Firestore rules/indexes and Hosting, plus act-as permission on the actual runtime service account. Check runtime Firestore permissions, billing, required APIs, quotas and ready indexes. None of these cloud prerequisites has been confirmed in this audit.
6. Review production environment approval/branch restrictions and existing function environment configuration, especially `APP_ORIGIN` and `ENFORCE_APP_CHECK`. Preserve existing values and access controls. Do not seed production or grant administrator claims to a test visitor.

## Supported release and verification

After review, merge the preflight patch and use the existing `Validate and build` workflow on main once release settings and cloud access are verified. The workflow deploys **Firestore, all functions, and Hosting**, not just this feature; review that full scope before enabling the gate. This patch does not enable the gate, change IAM, merge itself, or deploy.

For an authorized backend-only release, the existing Firebase CLI supports a narrower command after `npm ci --prefix functions` and validation:

```sh
node functions/node_modules/firebase-tools/lib/bin/firebase.js deploy \
  --project keekot-thangal-booking \
  --only functions:adminSetDateHours,functions:getAvailability,functions:createHold,functions:createBooking,functions:adminUpdateSlot,functions:adminUpdateSettings \
  --non-interactive
```

Deploying only `adminSetDateHours` is insufficient: callers using the shared date-aware settings and slot generation must also be updated. Before deploying, obtain authenticated function inventory, record current update times and source/build revisions, and review differences from the actual deployed release. After deployment, record operation success and active revisions for these functions. A 401 from an unauthenticated callable probe demonstrates reachability/authentication rejection, not source parity or functional correctness.

Use an isolated demo emulator or authorized staging project for writes. The existing integration test exercises 08:00–17:00 custom availability, rejects an outside-hours hold, permits an inside-hours hold, rejects hours changes affecting an active hold or confirmed booking, restores default slots and checks a different date remains unchanged. Unit tests cover malformed/reversed hours and incomplete slot periods. For staging callable acceptance, also verify unauthenticated and non-admin rejection through the Firebase callable transport, reset protection when a custom slot falls outside default hours, and concurrent schedule-edit/hold requests.

Production acceptance should inspect function metadata and read-only availability. Do not change a genuine booking, create a real visitor hold, cancel a visitor reservation, or reset real hours for testing. End-to-end production admin writes remain unverified until a separately agreed safe test fixture exists.
