
## Admin QR verification

Open **Administration → Scan visitor pass** (`/admin/gate`) with an admin or gate-staff account. Choose **Scan visitor pass**, allow camera access, and point the rear camera at the QR on the on-screen or PDF visitor pass. Scanning a valid pass immediately records attendance (`completed`), check-in time, staff UID, and an audit entry. The dialog closes after one code to prevent repeated camera submissions. Open it again for the next visitor.

Verification uses the existing server-side `validatePass` callable and configured arrival window. Unknown, cancelled, expired, premature, and previously used passes are rejected. Simultaneous scans can confirm a pass only once. A booking's QR covers its entire visitor group; this is not per-person admission.

Camera access requires HTTPS (or localhost) and browser permission. If unavailable, paste the QR token and choose **Verify and confirm visit**. **Check pass** verifies without recording attendance. A network failure never displays successful confirmation; retry verification to find out whether an interrupted request recorded attendance.

Deploy the updated Firebase functions alongside the web release to enable detailed rejection reasons and `checkedInBy` attribution. Before production use, test camera permissions and a real pass on Android Chrome and iPhone Safari, plus cancelled, wrong-time and already-used passes. Automated tests cover server admission rules and the manual verification UI; they cannot exercise a physical camera here.
