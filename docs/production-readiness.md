# Production readiness audit — 9 October 2026

## Evidence and conclusion

Audited main `ed368c47b82d0e8b36e94f6203be787944a8e776`, including the high-resolution logo update. The existing design and all logo/splash assets are unchanged by this audit.

- [Latest validation run](https://github.com/subair71/keekot-thangal-booking/actions/runs/37502751536): Flutter formatting, analysis, tests and emulator-config release build passed; TypeScript build and six unit tests passed; 14 reported emulator tests passed (parent plus 13 scenarios). **Firebase deploy job was skipped.**
- [Latest Pages run](https://github.com/subair71/keekot-thangal-booking/actions/runs/37502751547): production-config Flutter web build and Pages publish succeeded. It did not deploy Functions, Firestore rules/indexes, configure Auth, or verify real bookings.
- `docs/validation.md` describes the September 13 delivery and remains historical evidence, not current production certification.

Live availability is reachable, but the complete visitor booking flow is not certified production-ready. Deployment configuration names `keekot-thangal-booking` and `asia-south1`, but configuration is not deployment evidence. A read-only call to the live `getAvailability` endpoint returned HTTP 200 for 10 October 2026: 48 quarter-hour slots from 07:00–19:00, each with capacity 1 and no occupancy in the response. This confirms a reachable deployed availability function/settings, not successful reservations. These live values differ from the September half-hour/capacity-12 emulator examples; venue approval is required. The unauthenticated call succeeded without an App Check header, so that endpoint did not enforce App Check for this request. No authenticated Firebase project inventory or live SMS/booking/admin session was available during this audit.

| Function | Repository evidence | Required live verification |
| --- | --- | --- |
| Phone OTP | E.164 validation, six-digit code validation, Firebase web phone auth, timeouts, auth-stream roles | Phone provider enabled, India SMS policy, billing/quota, authorized hosting domain, real reCAPTCHA/SMS, wrong/expired codes and reload/session behavior |
| Availability | Configurable slots, date window, closures, occupancy and unexpired holds; live endpoint returned HTTP 200 with 48 fifteen-minute slots/capacity 1 | Verify venue-approved settings, browser access/App Check, correct IST dates, deployed rules/indexes, live refresh and concurrency |
| Reservations | Five-minute holds, one active hold per UID, transactional capacity, closure recheck, retry-safe confirmation, visitor address and per-visitor tokens | Matching frontend/backend versions; all callable functions; real authenticated confirmation, lost-response retry, group tokens and ownership |
| Cancellation | Owner/admin authorization, status/time checks, idempotent capacity restoration | Live cancellation once and repeated, restored availability, other user denied, cancelled pass rejected |
| Administrator | Custom claims; protected callables/rules; settings, closures, capacity safeguards, status changes, daily exports and gate validation | Actual admin/gate UIDs and fresh tokens; all admin functions; ready indexes; ordinary users denied; reports and check-in on real devices |
| Reminders/push | Firestore triggers, deterministic notices, retry handling, expiry scheduler and token cleanup | Both scheduled jobs, Eventarc triggers, FCM/VAPID, browser permissions/service worker, production logs |
| App Check | Web reCAPTCHA v3 configured; callable enforcement conditional | Register correct web app/site domains; verify valid tokens, set `ENFORCE_APP_CHECK=true`, redeploy, reject missing/invalid tokens; separately configure Firestore enforcement |

## Repository changes from this audit

- Pages publication now runs Flutter formatting/analyzer/tests and backend unit/emulator tests in its own build job. A failed check prevents artifact publication/deployment. Flutter is pinned to the same 3.47.4 SDK as validation instead of floating stable.
- Push destination/icon URLs preserve the application's base path in `APP_ORIGIN`. Unit tests cover root hosting, Pages subpaths, trailing slashes and invalid base URLs.
- Corrected the README's claim that callable App Check was automatically enforced. Existing opt-in behavior is preserved to avoid unexpectedly locking out current clients.

Local TypeScript build and seven unit tests passed after the changes. `git diff --check` passed. Flutter SDK is absent locally; Java 17 prevents the emulator suite from starting (Java 21 required). The October 6 CI results above validate the prior main commit; the new branch must pass CI before merge. No production writes, SMS sends, backend deployment or booking transactions were performed by this audit.

## Hosting decision before launch

The current worker registration in `web/index.html` uses `/firebase-messaging-sw.js` with a root scope. Its worker imports `/firebase-config.js`. FlutterFire Messaging also uses a domain-root worker by default. These root paths are incompatible with a project site at `/keekot-thangal-booking/`; changing only one path is insufficient. GitHub Pages' copied `404.html` also serves deep links as HTTP 404, unlike Firebase Hosting's SPA rewrite.

Use Firebase Hosting or a verified custom domain serving this app at `/` for the simplest reliable push/deep-link deployment. Existing `firebase.json` supports root SPA hosting. Rebuild with base href `/`; do not deploy the Pages-subpath build to Firebase Hosting. If retaining project-path Pages hosting, implement and test a custom service-worker registration passed through the Messaging web integration, relative worker imports, and complete deep-link handling before claiming push support. The link fix in this audit alone does not solve worker registration.

## Exact launch steps

1. In Firebase Console select **keekot-thangal-booking**. Confirm authorized access, billing, Native Firestore, web app ID matching configuration, backend location and production ownership. Keep `settings/booking.bookingEnabled=false` until acceptance tests pass. Do not run the emulator seed against production.
2. Enable Phone Authentication and India SMS region. Add the actual hosting **hostname** to Auth authorized domains and reCAPTCHA/App Check domains (for current Pages: `subair71.github.io`, without the repository path). Confirm SMS quotas/budget and test phone numbers on a separate staging project. Test a real India phone on production before launch.
3. Register App Check reCAPTCHA v3 for the configured web app/site key. Verify tokens on staging first. Set backend environment values in ignored `functions/.env.keekot-thangal-booking`:

   ```dotenv
   APP_ORIGIN=https://keekot-thangal-booking.web.app
   ENFORCE_APP_CHECK=true
   ```

   Use the final verified root-hosted URL if different. Redeployment is required for the flag; enabling the client SDK alone does not enforce it. Configure Firestore App Check enforcement separately after checking its metrics.
4. Fill ignored `config/production.json` from the same Firebase web app, including `USE_EMULATORS=false`, `ENVIRONMENT=production`, `FUNCTIONS_REGION=asia-south1`, verified App Check key and Web Push/VAPID key. Set notification environment and config consistently. Do not put service-account private keys in these files.
5. From an authorized workstation with Flutter 3.47.4, Node 22, Java 21 and Firebase access:

   ```bash
   npm ci --prefix functions
   npm test --prefix functions
   node functions/node_modules/firebase-tools/lib/bin/firebase.js emulators:exec --only firestore,auth --project demo-keekot-thangal 'npm --prefix functions run test:emulator'
   flutter pub get --enforce-lockfile
   dart run build_runner build
   flutter analyze
   flutter test --coverage
   python3 tool/configure_web.py config/production.json
   flutter build web --release --base-href=/ --dart-define-from-file=config/production.json
   node functions/node_modules/firebase-tools/lib/bin/firebase.js login
   node functions/node_modules/firebase-tools/lib/bin/firebase.js deploy --project keekot-thangal-booking --only firestore,functions,hosting
   node functions/node_modules/firebase-tools/lib/bin/firebase.js functions:list --project keekot-thangal-booking
   ```

   Deploy all resources, not just `createBooking`. Required exports: `getAvailability`, `getActiveHold`, `createHold`, `releaseHold`, `createBooking`, `ensureBookingTokens`, `cancelBooking`, `validatePass`, `adminUpdateSlot`, `adminUpdateSettings`, `adminSetBookingStatus`, `adminDashboard`, `registerDevice`, `unregisterDevice`, `sendBookingConfirmation`, `sendPushNotification`, `bookingReminderScheduler`, `cleanupExpiredHolds`. The design-branch workflow deploys only `createBooking` and cannot establish full readiness.
6. Wait for all checked-in Firestore composite indexes to become ready. Check both one-minute scheduler jobs, Eventarc triggers, IAM/service identities and logs. Verify hold TTL policy; expired holds are excluded from capacity even without cleanup, but scheduler cleanup still needs validation. Enable FCM/Web Push as needed and verify the service worker at the final site's root.
7. Sign in with the real admin phone, obtain its UID, then use authorized Application Default Credentials:

   ```bash
   npm run admin --prefix functions -- keekot-thangal-booking ADMIN_UID admin
   ```

   Sign out and back in. For entry-only staff use role `gate`. Open `/admin/settings`; save venue-approved hours, capacity, group limit, window, directions/contact, reminder and arrival settings with booking paused. Existing slots retain their capacities; update them with `/admin/slots` where necessary. Whole-day closure does not automatically cancel existing bookings.
8. On a matching staging deployment with bookings enabled, test two phones/accounts and an ordinary-user/admin/gate account. Verify:
   - Real OTP receipt/sign-in, wrong/expired code, denied permissions and session restoration.
   - IST day boundaries, same-day cutoff, date window, blocked days/slots and availability refresh.
   - Concurrent holds exhausting a small approved test capacity without overselling; expiry after five minutes without relying on the scheduler; release and resume.
   - Confirm name/address/group count; retry the same hold after an interrupted response and confirm one booking/one capacity increment; unique token ranges; private pass and PDF.
   - Owner cancellation/retry restores capacity exactly once; another user cannot read/cancel; cancelled passes cannot check in.
   - Admin settings/closure/capacity updates, dashboard queries, daily exports, role denial, allowed-time gate entry and replay rejection.
   - Valid App Check calls succeed; missing/invalid tokens fail. Browser foreground/background push, reminder delivery/retries and sign-out device removal.
   - Direct refresh of `/book`, `/my-bookings`, `/booking/ID`, `/admin/settings` and notification clicks at the final host, on mobile/desktop. Verify required language characters in PDFs.
9. Record time, release SHA, backend inventory, index readiness, scheduler runs and acceptance results without exposing visitor data. Run a minimal controlled production booking/cancellation with approved test visitors. Remove staging-only/test Auth numbers from production where inappropriate. Set `bookingEnabled=true` only after venue sign-off; monitor callable errors, SMS abuse/quota, index failures, scheduler/FCM failures and capacity reconciliation. Set budget/error alerts and a Firestore backup policy.

For CI backend deployment instead of a workstation, configure production environment variables `DEPLOY_FIREBASE=true`, `FIREBASE_PROJECT_ID=keekot-thangal-booking`, `FIREBASE_WEB_CONFIG`, `WIF_PROVIDER`, `DEPLOY_SERVICE_ACCOUNT`; verify least-privilege Workload Identity Federation and confirm the **deploy** job actually executes. Merely setting these values or passing the Pages job is not evidence of deployment.
