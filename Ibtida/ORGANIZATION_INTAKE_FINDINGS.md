# Organization Intake + Payment — Audit Findings

## 1) Where things are

| Area | Location |
|------|----------|
| **Nonprofits rendered** | `CategoryCharitiesView.swift` → `PremiumCharityCard` (charity list rows); `DonationsPage.swift` → `WarmCharityCategoryCard` (category → `CategoryCharitiesView`) |
| **External links** | `CategoryCharitiesView.swift`: org name tap opens **intake sheet** (no Safari on row tap). `SafariView` exists but only used from intake “View organization website”. `DonateView.swift`: Safari for “match donation” URL. Profile/Settings: `Link()` for privacy/terms. |
| **Firebase** | `IbtidaApp.swift` → `FirebaseApp.configure()`; Firestore/Auth used in `AuthService`, `DonationService`, `OrganizationIntakeService`, ViewModels. |
| **Stripe** | iOS: `OrganizationIntakeView.swift` → `PaymentSheetView`; publishable key from `getStripePublishableKey()` (env/placeholder). Backend: `firebase/functions/index.js` → `createPaymentIntent`, `stripeWebhook`. |
| **Cloud Functions** | `firebase/functions/index.js`: `health` (GET, ok + timestamp), `createPaymentIntent` (POST, amount/currency/metadata → clientSecret), `stripeWebhook` (raw body, signature verify → writes to `donations`). |

## 2) Data & auth

- **Nonprofit model** (`Charity.swift`): `id`, `name`, `description`, `verified`, `tags`, `websiteURL`, `donationURL`, `category`, `city`, `logoURL`, `createdAt`.
- **User / auth** : `AuthService`: `user`, `isLoggedIn`, `userEmail`, `userUID`. App gates main UI on `authService.isLoggedIn`; no guest donation flow today.
- **Intake model** (current): `OrganizationIntakeService` + `OrganizationIntake`: `id`, `orgId`, `orgName`, `fullName`, `email`, `phone`, `amountCents`, `note`, `userId`, `paymentStatus`, `paymentIntentId`, `createdAt`. No `status` enum, no `payments` collection, no server-authoritative flow.

## 3) Gaps vs target

- **Backend** : `createPaymentIntent` does not validate `intakeId`, does not read/update Firestore intake, no idempotency. Webhook writes to `donations` only, not `organizationIntakes` or `payments`; no event idempotency; no status transitions.
- **Firestore** : No rules file in repo for `organizationIntakes` or `payments`. Client can write any fields (e.g. `paymentStatus: "succeeded"`).
- **iOS** : Intake form lacks preset amount chips, “in honor of”, “anonymous”, “subscribe”; no Processing state (wait for webhook); confirmation screen has no receipt/reference id; client updates `paymentStatus` on success (must be server-only). Stripe key is placeholder/env.
- **Auth** : Donation requires login (`OrganizationIntakeService.saveIntake` throws if no user). No explicit “Sign in to donate” prompt before intake.
- **Diagnostics** : `DiagnosticsView` exists (Settings → About) but has no “Ping health”, “Create PI (test)”, or Stripe event link.

## 4) Summary

- **Nonprofit list** : Org name opens intake sheet; no external URL on row tap. Add secondary “Website” link and accessibility.
- **Backend** : Implement intake-aware `createPaymentIntent` (validate intakeId, draft/requires_payment, idempotency, write `paymentIntentId` + status to Firestore). Implement webhook to update `organizationIntakes` + `payments`, with event idempotency.
- **Firestore** : Add rules so clients can create/update intake only with allowed fields and cannot set payment outcome; only Functions can set `paymentIntentId` and success/failure.
- **iOS** : Full intake form (chips, custom amount, optional fields), ViewModel, Processing state, confirmation with receipt id; remove client-side payment success write; require auth with clear prompt; Stripe key from config/plist.
- **Verification** : Firestore rules, Diagnostics (health, Create PI, Stripe link), curl + Stripe Dashboard test events.
