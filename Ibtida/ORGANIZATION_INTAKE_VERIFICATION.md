# Organization Intake + Payment — Verification Checklist & Known Limitations

## 1) Findings (brief)

- **Nonprofits**: Rendered in `CategoryCharitiesView` → `PremiumCharityCard`. Org name tap opens intake sheet (no external URL). Secondary "Website" link opens Safari.
- **Backend**: `firebase/functions/index.js` — `health`, `createPaymentIntent` (validates `intakeId`, draft/requires_payment, idempotent), `stripeWebhook` (signature verify, event idempotency, updates `organizationIntakes` + `payments`).
- **Firestore**: `organizationIntakes` (client create draft only; server updates status), `payments` (server-only). Rules in `firebase/firestore.rules`.
- **iOS**: `OrganizationIntakeView` — auth required, preset amount chips + custom, note 500 char, save draft → createPaymentIntent(intakeId) → PaymentSheet → Processing (poll) → Confirmation with receipt id. No client-side payment status write.
- **Stripe**: Publishable key from Info.plist `StripePublishableKey` or env `STRIPE_PUBLISHABLE_KEY`. Secrets in Firebase Secret Manager.

---

## 2) File-by-file change list

| File | Change |
|------|--------|
| `Ibtida/ORGANIZATION_INTAKE_FINDINGS.md` | **New** — Audit findings |
| `Ibtida/ORGANIZATION_INTAKE_VERIFICATION.md` | **New** — This file |
| `firebase/functions/index.js` | **Updated** — createPaymentIntent: intakeId required, validate intake, idempotent, write Firestore. stripeWebhook: organizationIntakes + payments, event idempotency |
| `firebase/firestore.rules` | **New** — organizationIntakes (create draft, read own), payments (deny client) |
| `firebase/firebase.json` | **Updated** — Added firestore.rules |
| `Ibtida/Ibtida/Core/FirestorePaths.swift` | **Updated** — payments collection path |
| `Ibtida/Ibtida/Services/OrganizationIntakeService.swift` | **Updated** — status "draft", currency, removed updatePaymentStatus; added fetchIntakeStatus |
| `Ibtida/Ibtida/Services/FirebaseFunctionsService.swift` | **Updated** — createPaymentIntent(intakeId, amountCents, currency) |
| `Ibtida/Ibtida/Views/Donate/OrganizationIntakeView.swift` | **Updated** — Auth required, preset chips, note limit, draft flow, Processing state, poll status, confirmation with receipt id, no client status write |
| `Ibtida/Ibtida/Views/Donate/CategoryCharitiesView.swift` | **Updated** — Secondary "Website" link, accessibility (VoiceOver, dynamic type, hit area) |
| `Ibtida/Ibtida/Views/Settings/DiagnosticsView.swift` | **Updated** — Ping health, Create PI (test), Open Stripe event deliveries |
| `Ibtida/Ibtida/Info.plist` | **Updated** — StripePublishableKey (empty; set in build or replace) |

---

## 3) Firestore rules (snippet)

Full file: `firebase/firestore.rules`

- **organizationIntakes**: `create` if auth and status draft and userId == auth.uid; `read` if auth and resource.userId == auth.uid; `update`, `delete` false (server updates via Admin SDK).
- **payments**: `read`, `write` false (server-only).
- **users**, **donations**, **charities**: existing-style rules; default deny.

---

## 4) Verification checklist (step-by-step)

### Backend

1. **Lint**  
   `cd firebase/functions && npm run lint`  
   → No errors.

2. **List functions**  
   `cd firebase && firebase functions:list`  
   → Expect: health, createPaymentIntent, stripeWebhook (3 functions).

3. **Health**  
   `curl -s "https://us-central1-ibtida-b1b7c.cloudfunctions.net/health"`  
   → `{"ok":true,"timestamp":"..."}`.

4. **createPaymentIntent (valid intake)**  
   - Create a draft intake in Firestore (e.g. from app or Diagnostics "Create PI (test)").  
   - `curl -s -X POST "https://us-central1-ibtida-b1b7c.cloudfunctions.net/createPaymentIntent" -H "Content-Type: application/json" -d '{"intakeId":"<existing-draft-id>","amountCents":100,"currency":"cad"}'`  
   → `{"clientSecret":"pi_...","paymentIntentId":"pi_..."}`.

5. **createPaymentIntent (invalid)**  
   - Missing intakeId: 400 "intakeId is required".  
   - Non-existent intakeId: 404 "Intake not found".

6. **stripeWebhook (signature)**  
   `curl -s -X POST "https://us-central1-ibtida-b1b7c.cloudfunctions.net/stripeWebhook" -H "Content-Type: application/json" -d '{}'`  
   → 400 (missing stripe-signature expected).

7. **Stripe Dashboard**  
   - Webhooks → Add endpoint: `https://us-central1-ibtida-b1b7c.cloudfunctions.net/stripeWebhook`.  
   - Events: payment_intent.succeeded, payment_intent.payment_failed, payment_intent.canceled.  
   - Copy signing secret → `firebase functions:secrets:set STRIPE_WEBHOOK_SECRET`.  
   - Send test event (e.g. payment_intent.succeeded) → Event deliveries show success.

### iOS

8. **Auth required**  
   Sign out → tap org name → "Sign In Required" alert.

9. **Intake flow**  
   Sign in → tap org name → form (preset $5 $10 $25 $50 Custom, full name, email, amount, note) → Continue → PaymentSheet → complete payment → "Processing..." → Confirmation with Reference ID.

10. **Website link**  
    On charity card, small "Website" link opens Safari (optional).

11. **Diagnostics (dev)**  
    Settings → About → Diagnostics (long press) → Ping health (ok + timestamp) → Create PI (test) (clientSecret...) → Open Stripe event deliveries (opens dashboard).

### Config

12. **Stripe publishable key**  
    Set Info.plist `StripePublishableKey` or env `STRIPE_PUBLISHABLE_KEY` (Xcode scheme).  
13. **Secrets**  
    `firebase functions:secrets:set STRIPE_SECRET_KEY` and `STRIPE_WEBHOOK_SECRET`.

---

## 5) Known limitations / TODOs

- **Guest checkout**: Not implemented (Option A: require auth). To allow guest: backend would need to accept intake without userId and return a one-time receipt token; rules and client would need updates.
- **Stripe key**: Publishable key must be set in Info.plist or env; no Remote Config in this implementation.
- **Firestore rules**: Default-deny at end may block other app collections not listed; add match rules for any other collections you use.
- **npm audit**: If moderate vulnerabilities appear in functions, fix with targeted updates; document if a fix breaks the runtime.
- **CORS**: createPaymentIntent/health use `*`; restrict origin in production if required.
- **Optional fields**: "In honor of", "Anonymous", "Subscribe to updates" toggles not persisted to Firestore in this implementation; add fields and backend if needed.
