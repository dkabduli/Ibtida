# Admin Overlay – Test Checklist

## How admin is set (do not hardcode in app)

**Q: Do I give the admin email or set that in Firebase?**  
We set admin in Firebase via custom claims. The email is used only once to look up the user when setting the claim (server-side). At runtime the app never checks email for admin; it only reads the `admin` custom claim from the ID token.

### Option 1 (preferred): Local script

1. In Firebase Console → Project Settings → Service accounts, generate a new private key (JSON).
2. Set `GOOGLE_APPLICATION_CREDENTIALS` to the path of that JSON.
3. From `firebase/scripts`:  
   `node set-admin-claims.js <admin@example.com>`
4. User must sign out and sign in again (or force refresh ID token) for the claim to take effect.

### Option 2: Callable Cloud Function

1. Deploy `setAdminRole` (already in `firebase/functions/index.js`).
2. The first admin must be set via Option 1 (script) or Firebase Console (see below).
3. From then on, an existing admin can call `setAdminRole` with `data: { email: "newadmin@example.com" }` (e.g. from a small admin-only screen or script).

### Firebase Console (one-off)

1. Firebase Console → Authentication → Users.
2. Find the user (by email). There is no UI to set custom claims here; use Option 1 or a one-off Cloud Function run with Admin SDK to set `setCustomUserClaims(uid, { admin: true })`.

---

## Test checklist

### 1. Non-admin user

- [ ] Sign in as a **non-admin** user.
- [ ] **Expected:** No Admin tab in the tab bar. Only Home, Journey, Donate, Duas, Profile.
- [ ] Donate → “My Requests”: only that user’s own requests (from `users/{uid}/requests`). No global community feed.
- [ ] Attempt direct read of global `requests` (e.g. via a temporary debug button that does `db.collection("requests").getDocuments()`) → **Expected:** Permission denied.
- [ ] Attempt read of `admin/settings` → **Expected:** Permission denied.

### 2. Admin user

- [ ] Set admin claim for a test user (Option 1 script or Option 2 after first admin exists).
- [ ] That user signs out and signs in again (or app calls `refreshAdminClaim(forceRefresh: true)` and UI updates).
- [ ] **Expected:** Admin tab visible (e.g. “Admin” with shield icon).
- [ ] Open Admin → Dashboard: overview counts load (global requests, conversion requests).
- [ ] Open Admin → All Requests: list of all documents in global `requests` (if any).
- [ ] Open Admin → Credit Conversion: can read/write `admin/settings` (creditConversion).
- [ ] Open Admin → Moderation: can read `reports` collection.

### 3. Token refresh after claim change

- [ ] With admin user signed in, remove admin claim (e.g. run a script that sets `setCustomUserClaims(uid, {})`).
- [ ] In app: trigger token refresh (sign out/in or call `refreshAdminClaim(forceRefresh: true)`).
- [ ] **Expected:** Admin tab disappears; direct read of admin collection fails with permission denied.

### 4. CAD everywhere

- [ ] Donation flow: UI shows amounts in CAD; Firestore donation docs have `currency: "cad"` and `amountCents`.
- [ ] Stripe PaymentIntent created with `currency: "cad"`.
- [ ] Finalize donation / webhook: receipt written with `currency: "cad"`.

### 5. Privacy and data scope

- [ ] Regular user never sees another user’s donation receipts or requests.
- [ ] Donations page shows only “My Requests” (user’s own `users/{uid}/requests`).
- [ ] Profile → Donations shows only that user’s receipts (`users/{uid}/donations`).

---

## Files touched (summary)

| Area | Files |
|------|--------|
| Auth | `AuthService.swift`: `isAdmin`, `refreshAdminClaim()`, call on login |
| Firestore | `FirestorePaths.swift`: admin paths; `firestore.rules`: user-only + admin-only rules |
| Donations page | `DonationsPage.swift`: My Requests only, `RequestsViewModel`, no global `CommunityRequestsViewModel` |
| Admin UI | `Views/Admin/`: `AdminDashboardView`, `AdminRequestsView`, `AdminCreditConversionView`, `AdminModerationToolsView`, `AdminTabView` |
| Tabs | `RootTabView.swift`: Admin tab only when `authService.isAdmin` |
| Functions | `firebase/functions/index.js`: `setAdminRole` callable (admin-only) |
| Script | `firebase/scripts/set-admin-claims.js`: set `admin: true` by email (run locally) |
