
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
