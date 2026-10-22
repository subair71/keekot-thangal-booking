# Administrator username/password login

`/admin/login` uses the `adminLogin` callable in asia-south1. Visitor phone verification remains unchanged. Deploy the function before releasing the updated UI.

To provision an administrator, use a trusted terminal authenticated with Firebase Application Default Credentials authorized to manage Auth users and Firestore in the production project:

```bash
npm ci --prefix functions
npm run build --prefix functions
read -r -s -p 'Administrator password: ' ADMIN_ACCOUNT_PASSWORD
printf '\n'
printf '%s' "$ADMIN_ACCOUNT_PASSWORD" | node functions/lib/scripts/admin-account.js keekot-thangal-booking keekkottbungalow
unset ADMIN_ACCOUNT_PASSWORD
```

The script creates a Firebase Auth user with an admin custom claim and stores only a salted scrypt hash in a server-only Firestore collection. It refuses to overwrite an existing username. Never put the password in source code, workflow inputs, command arguments, or logs.

After deploying, verify login at `/admin/login`, access to administrator pages, rejection of incorrect credentials, and unchanged visitor SMS login. Account provisioning and live verification require privileged production access and are not performed by the code change alone.
