# Contact form email setup

The public `/contact` page sends enquiries to **keekkottbungalowonline@gmail.com** through the Firebase callable `submitContact` in `asia-south1`. Links are available in the home footer, account menu and visitor information page. The form supports English and Malayalam.

## Required before releasing the form

1. The owner of `keekkottbungalowonline@gmail.com` must enable Google 2-Step Verification and create a Google app password. Do not use the normal account password. Do not paste the app password into chat, source code or GitHub variables.
2. From an authenticated Firebase CLI on the owner's computer, store the app password using the interactive secret prompt:

   ```sh
   firebase functions:secrets:set CONTACT_GMAIL_APP_PASSWORD --project keekot-thangal-booking
   ```

3. Build and deploy the new function:

   ```sh
   npm ci --prefix functions
   npm test --prefix functions
   firebase deploy --only functions:submitContact --project keekot-thangal-booking
   ```

4. Confirm Firebase App Check accepts requests from the production website. This public callable always enforces App Check outside the emulator. The existing web App Check setup must allow the GitHub Pages domain. No visitor login is required.
5. Deploy the website. Submit one clearly labelled test enquiry and confirm receipt in the target inbox and that Reply addresses the visitor. Check spam if needed. Server acceptance does not guarantee inbox placement.

The Gmail account must support app passwords. If account policy disables them, use an OAuth or transactional-email integration instead; do not disable account security.

## Behavior and limits

- Required: name, email, subject and message. Phone is optional.
- Recipient and sender are fixed on the server. A visitor cannot choose another recipient. The visitor email is used only for Reply-To.
- Messages are sent as plain text. Header line breaks and control characters are rejected.
- No message bodies are stored in Firestore or logs. Rate counters in `contactRateLimits` use an HMAC of the request IP, with five attempts per IP per hour and 100 attempts across the site per day. Firestore's existing deny-all rule blocks client access to these counters.
- Success appears only after Gmail accepts the message. On failure, the form retains its values and provides a direct email option. A network interruption after acceptance can make delivery uncertain; retrying may send a duplicate.
- Local automated tests validate recipient locking, reply-to, invalid input, header injection and Malayalam input. No live email is sent by tests.
- Gmail SMTP credentials are read only by the function from Secret Manager. Never include them in Flutter config.

References: https://nodemailer.com/guides/using-gmail and https://firebase.google.com/docs/functions/config-env.
