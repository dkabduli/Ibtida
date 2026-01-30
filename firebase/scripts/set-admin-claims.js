/**
 * Set Firebase Auth custom claim { admin: true } for a user by email.
 * Run locally with a service account key; never ship this or call from the app for initial setup.
 *
 * Prerequisites:
 *   1. Firebase project with Auth and a user account.
 *   2. Service account key JSON (Firebase Console → Project Settings → Service accounts → Generate new private key).
 *   3. Run from firebase/functions so firebase-admin is available, or npm install firebase-admin in firebase/scripts.
 *
 * Usage:
 *   export GOOGLE_APPLICATION_CREDENTIALS=/path/to/your-service-account-key.json
 *   cd firebase/functions && node ../scripts/set-admin-claims.js <email>
 *
 * Example:
 *   export GOOGLE_APPLICATION_CREDENTIALS=./my-project-key.json
 *   cd firebase/functions && node ../scripts/set-admin-claims.js admin@example.com
 *
 * After running, the user must sign out and sign in again (or refresh ID token) for the claim to take effect.
 */

const admin = require("firebase-admin");
const email = process.argv[2];

if (!email || !email.includes("@")) {
  console.error("Usage: node set-admin-claims.js <email>");
  console.error("Example: node set-admin-claims.js admin@example.com");
  process.exit(1);
}

if (!admin.apps.length) {
  try {
    admin.initializeApp({ projectId: process.env.GCLOUD_PROJECT || process.env.GCP_PROJECT });
  } catch (e) {
    console.error("Initialize Firebase Admin (e.g. set GOOGLE_APPLICATION_CREDENTIALS):", e.message);
    process.exit(1);
  }
}

async function main() {
  let userRecord;
  try {
    userRecord = await admin.auth().getUserByEmail(email);
  } catch (e) {
    console.error("No user found with email:", email, e.message);
    process.exit(1);
  }

  await admin.auth().setCustomUserClaims(userRecord.uid, { admin: true });
  console.log("Admin claim set for:", userRecord.email, "uid:", userRecord.uid);
  console.log("User must sign out and sign in again for the change to take effect.");
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
