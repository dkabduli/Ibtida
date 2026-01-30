# Ibtida 🕌

Ibtida is a **native iOS app** built with **SwiftUI** that encourages consistent prayer, intentional worship, and charitable giving. Users track daily prayers, build streaks, earn credits, and donate to verified charities — including **card payments in CAD** via Stripe and **donation receipts** stored in their profile. **Admin features** (global requests, credit conversion settings, moderation) are gated by Firebase Auth custom claims and Firestore rules; regular users see only their own data.

**Repo layout:** iOS app in `Ibtida/` (Xcode project); Firebase (Functions, Firestore rules, scripts) in `firebase/`.

---

## Purpose

Ibtida (*“a beginning”*) connects two acts of worship:

- **Prayer (Salah)** — consistency and awareness through daily tracking
- **Charity (Sadaqah)** — giving via credits or card (CAD) to verified organizations

By combining prayer tracking with a credit-based system and real card donations, the app helps turn intention into action and build lasting spiritual habits.

---

## Core Features (Current Build)

- **Auth** — Email/password (Firebase Auth); optional Google Sign-In
- **Onboarding** — Gender selection (brother/sister) once at sign-up; no redundant popup; gender drives prayer options and credit rules
- **Prayer tracking** — Log 5 daily prayers with **gender-specific status options**:
  - **Brothers:** In masjid (jamat), On time, Qada, Missed, Not logged
  - **Sisters:** At home (on time), Qada, Missed, Not applicable 🩸 (streak-safe)
  - Status stored as enum raw value in Firestore; legacy values migrated on read (`PrayerStatus.fromFirestore`)
- **Last 5 weeks** — Horizontal progress grid: **current week first (left)**, older weeks to the right; “This Week” highlighted
- **Prayer status sheet** — Full-height bottom sheet; first tap opens correctly (no blank screen); **Duas** tab: Ameen and Done buttons spaced (no overlap)
- **Streaks & credits** — Credits per prayer status (see table below); streak calculator; menstrual / “Not applicable 🩸” does not break streak
- **Journey** — Single “Journey” title (nav bar); proportions and padding (e.g. 16); milestones by total credits; week progress (5 squares); day detail sheet with gender-aware labels
- **Donate tab** — Overview, **My Requests** (user’s own requests only: `users/{uid}/requests`), **Charities** (by category), **Convert Credits**; card donations via **Stripe PaymentSheet** (CAD only). No global community request feed for regular users.
- **Card donations** — Per-charity intake → **createPaymentIntent** (CAD) → Stripe **PaymentSheet** → **finalizeDonation** → receipt in `users/{uid}/donations`. If finalizeDonation fails after retries, user sees **pending receipt** state (no misleading “Thank You” until receipt is persisted).
- **Donation receipts** — Server-only writes (webhook + finalizeDonation); list and detail in **Profile → Donations**; all amounts and storage in **CAD**
- **Credit conversion** — Convert credits to dollar value (100 credits = $1 default); **CreditConversionView**; user’s conversion requests in Firestore; **admin** can edit rate in Admin → Credit Conversion
- **Dua wall** — Global community duas; ameens; submit anonymous or public
- **Profile** — Name, email, credits, streak, member since; **Donations** history; theme; menstrual mode; About, Privacy, Terms; **Diagnostics** (dev)
- **Admin (when isAdmin)** — **Admin** tab visible; Dashboard (counts), All Requests (global `requests`), Credit Conversion (edit rate in `admin/settings`), Moderation (reports). Enforced by custom claim `admin: true` and Firestore rules.
- **Theme** — Warm design system; light/dark/system; muted gold accent; accessible typography
- **Network & errors** — Network status banner; centralized error handling; gentle language and time-aware UI

---

## Admin Overlay (Security & Privacy)

- **Role** — Admin is determined **only** by Firebase Auth custom claim `{ admin: true }`. No email or client-side flag in the app for who is admin.
- **Setting the first admin** — Use the **local script** (recommended) or deploy the callable and have an existing admin call it:
  1. **Script:** From `firebase/functions`:  
     `GOOGLE_APPLICATION_CREDENTIALS=/path/to/service-account.json node ../scripts/set-admin-claims.js admin@example.com`  
     User must sign out and sign in again for the claim to take effect.
  2. **Callable** — Deploy `setAdminRole`; an existing admin can call it with `{ email: "newadmin@example.com" }`.
- **What admins can do** — See **Admin** tab: Dashboard (overview counts), All Requests (global `requests`), Credit Conversion (edit `admin/settings`), Moderation (reports). All admin reads/writes go through Firestore rules that require `request.auth.token.admin == true`.
- **What regular users cannot do** — No Admin tab; no read/write to global `requests`, `admin/*`, or other users’ data. Donate tab shows only **My Requests** (`users/{uid}/requests`).
- **Testing** — See **`Ibtida/ADMIN_OVERLAY_TEST_CHECKLIST.md`** for step-by-step checks (non-admin vs admin, token refresh, CAD, privacy).

---

## Credits & Scoring

Credits are earned by logging prayer status and are used for motivation and conversion to donations.

| Status              | Credits |
|---------------------|--------|
| On Time             | 10     |
| Late                | 6      |
| Qada (made up)      | 4      |
| Missed              | 0      |
| Brothers – Masjid   | 18     |
| Sisters – Home      | 12     |
| Sisters – Not applicable 🩸 | 0 (no streak break) |

- **Daily max** — 50 credits (5 × 10).
- **New user bonus** — First 14 days get a 1.5× multiplier (see `CreditRules`).
- **Conversion** — 100 credits = $1.00 (default; admin can change in Admin → Credit Conversion).

### Milestones (Journey)

| Milestone   | Arabic  | Credits |
|------------|---------|--------|
| Getting Started | البداية | 0   |
| Consistent | مواظب   | 100  |
| Steady     | ثابت    | 250  |
| Committed  | ملتزم   | 500  |
| Devoted    | متفاني  | 1,000 |
| Elite      | متميز   | 2,500 |
| Master     | خبير    | 5,000 |
| Legend     | أسطورة  | 10,000 |

---

## Donations (Card – CAD)

- **Currency** — **CAD only** (client, Cloud Functions, Stripe, Firestore, UI).
- **Flow** — Choose charity → intake form (name, email, amount ≥ $0.50 CAD) → **createPaymentIntent** (Cloud Function) → Stripe **PaymentSheet** → on success, **finalizeDonation** (Cloud Function) → receipt written to `users/{uid}/donations/{intakeId}`.
- **Receipts** — Server-only writes (webhook `payment_intent.succeeded` + **finalizeDonation**). Schema: `amountCents`, `currency: "cad"`, `createdAt`, `organizationId`, `organizationName`, `intakeId`, `paymentIntentId`, `status`, etc.
- **Pending receipt** — If **finalizeDonation** fails after retries, the app shows a **pending receipt** state (e.g. “Payment received; receipt may take a moment — check Profile → Donations”) instead of a full “Thank You” so the UX stays honest and transparent.
- **Profile → Donations** — Lists receipts (newest first); tap for detail (reference ID, amount in CAD, receipt URL if present).

---

## Navigation

- **Regular users (5 tabs):** Home, Journey, Donate, Duas, Profile.
- **Admin users (6 tabs):** Same five plus **Admin** (Dashboard → All Requests, Credit Conversion, Moderation). Admin tab is shown only when `authService.isAdmin` (from ID token custom claim).

Tab contents:

1. **Home** — Today’s prayers (5 circles), Last 5 Weeks grid (current week left), progress summary.
2. **Journey** — Milestones, week progress (5 squares), credit summary; single nav title “Journey”.
3. **Donate** — Overview, **My Requests**, Charities (by category), Convert Credits; card donation via Stripe (CAD).
4. **Duas** — Community dua wall; submit and view duas; Dua of the Day with Ameen/Done layout fixed.
5. **Profile** — User info, credits, streak; **Donations** history; theme; settings; About; Diagnostics (dev).
6. **Admin** (if `isAdmin`) — Dashboard, All Requests, Credit Conversion, Moderation.

---

## Tech Stack

- **iOS** — SwiftUI, iOS 17+
- **Backend** — Firebase (Auth, Firestore, Cloud Functions)
- **Payments** — Stripe (PaymentSheet); **CAD** only; test mode via `pk_test_` / Stripe test cards
- **Key paths** — `users/{uid}`, `users/{uid}/donations`, `users/{uid}/requests`, `users/{uid}/prayerDays`, `users/{uid}/prayers`; `organizationIntakes`, `payments`; global `duas`, `daily_duas`, `charities`; **admin-only:** `admin/*`, global `requests`, `reports`, `credit_conversion_requests` (user sees own docs only; admin sees all).

---

## Firestore Rules (Summary)

- **Users** — Read/write only own `users/{userId}` and subcollections (`donations`, `requests`, `prayers`, `prayerDays`).
- **Donations** — Read-only for user on `users/{uid}/donations`; writes only by backend.
- **Global requests** — Read/write only if `request.auth.token.admin == true`.
- **Reports** — Any authenticated user can create; only admin can read/delete.
- **credit_conversion_requests** — User can create/read/update/delete only docs where `userId == request.auth.uid`; admin can read all.
- **admin** — Read/write only if `request.auth.token.admin == true`.

Full rules in `firebase/firestore.rules`.

---

## Setup (Developers)

- **Requirements** — Xcode 15+, iOS 17+ target.

1. **Xcode** — Open `Ibtida/Ibtida.xcodeproj`; use the **Ibtida** scheme.
2. **Firebase** — Add `GoogleService-Info.plist`; enable Auth (email/password, optional Google) and Firestore.
3. **Stripe** — In **Info.plist** set `StripePublishableKey` to your **test** key (`pk_test_...`). Backend: Stripe secret and webhook secret (Cloud Functions config/secrets).
4. **Cloud Functions** — Deploy from `firebase/functions`. Deployed functions: **createPaymentIntent** (CAD), **finalizeDonation**, **stripeWebhook**, **health**, **setAdminRole** (callable, admin-only). Set secrets for Stripe.
5. **Firestore rules** — Deploy from `firebase/`: `firebase deploy --only firestore:rules`.
6. **First admin (optional)** — Run from `firebase/functions`:  
   `GOOGLE_APPLICATION_CREDENTIALS=/path/to/service-account.json node ../scripts/set-admin-claims.js your-admin@example.com`  
   Then have that user sign out and sign in again.

### Stripe test (donations)

- Use test card **4242 4242 4242 4242** for success.
- Receipts appear under Profile → Donations after **finalizeDonation** (and/or webhook).

---

## Project Structure (High Level)

```
Ibtida/Ibtida/Ibtida/          # iOS app (Xcode: Ibtida/Ibtida.xcodeproj)
├── IbtidaApp.swift
├── Core/
│   ├── StripeConfig.swift, DateUtils.swift, DonationAmountParser.swift
│   ├── DesignSystem.swift, SemanticDesignSystem.swift, AppTheme.swift
│   ├── CreditRules.swift, PrayerStatusColors.swift
│   ├── ThemeManager.swift, FirestorePaths.swift (includes admin paths)
│   ├── GentleLanguage.swift, TimeAwareUI.swift, LogLevel.swift
│   └── NetworkErrorHandler.swift, PerformanceCache.swift, AppStrings.swift
├── Models/
│   ├── Charity.swift, Donation.swift, DonationError.swift, DonationType.swift
│   ├── CreditConversionRequest.swift
│   ├── Prayer.swift (PrayerStatus.fromFirestore, gender-specific lists)
│   ├── PrayerModels.swift, UserProfile.swift, RequestModel.swift
│   └── Dua.swift, DuaRequest.swift
├── Services/
│   ├── AuthService.swift (isAdmin, refreshAdminClaim)
│   ├── FirebaseFunctionsService.swift, UserDonationsFirestoreService.swift
│   ├── FirestoreService.swift, UserProfileFirestoreService.swift
│   ├── PrayerLogFirestoreService.swift, StreakCalculator.swift
│   ├── OrganizationIntakeService.swift, CharityService.swift, DonationService.swift
│   ├── CreditConversionService.swift, DuaFirestoreService.swift
│   └── LocalStorageService.swift, UIStateFirestoreService.swift
├── ViewModels/
│   ├── PaymentFlowCoordinator.swift, HomeViewModel.swift, HomePrayerViewModel.swift
│   ├── JourneyProgressViewModel.swift, JourneyMilestoneViewModel.swift
│   ├── DonationViewModel.swift, CreditConversionViewModel.swift
│   ├── CategoryCharitiesViewModel.swift, CommunityRequestsViewModel.swift (admin-only use)
│   └── DuaViewModel.swift
├── Views/
│   ├── Home/       (HomeView, HomePrayerView — prayer grid, status sheets)
│   ├── Journey/    (JourneyView, JourneyHomeView, JourneyMilestoneView)
│   ├── Donate/     (DonationsPage [My Requests], OrganizationIntakeView, CategoryCharitiesView, CreditConversionView)
│   ├── Dua/        (DuaWallView)
│   ├── Profile/    (ProfileView, DonationsHistoryView)
│   ├── Requests/   (RequestsView — user’s own requests)
│   ├── Admin/      (AdminTabView, AdminDashboardView, AdminRequestsView, AdminCreditConversionView, AdminModerationToolsView)
│   ├── Auth/       (LoginView)
│   ├── Onboarding/ (GenderOnboardingView)
│   ├── Settings/   (SettingsView, AppSettingsView, DiagnosticsView)
│   ├── Components/ (DuaComponents, EmptyStates, ErrorHandling, NetworkStatusBanner)
│   └── RootTabView.swift (conditional Admin tab when isAdmin)
└── Resources/      charities.json; Assets.xcassets

firebase/
├── firestore.rules           (user-only + admin-only rules)
├── scripts/
│   └── set-admin-claims.js   (set admin custom claim by email; run locally)
└── functions/
    └── index.js              createPaymentIntent (CAD), finalizeDonation, stripeWebhook, health, setAdminRole (callable)
```

---

## Notes

- **Credits** are for in-app motivation and conversion only; they do not represent religious reward.
- **Donation receipts** are written only by the backend; client never writes to `users/{uid}/donations`.
- **Prayer status** is stored as enum raw value in Firestore; display labels are gender-specific in the UI; legacy strings (e.g. `"later"`, `"made up"`) are mapped on read via `PrayerStatus.fromFirestore`.
- **Last 5 Weeks** order: index 0 = current week (left); data from `DateUtils.lastNWeekStarts(5)`; “This Week” emphasized.
- **Islamic guidelines** — Prayer terminology (e.g. Jama’ah, Qada, “Not applicable 🩸”) and donation flows are aligned with mainstream fiqh; “Not applicable 🩸” does not penalize streaks; donations are transparent (CAD, receipt state, no misleading success until receipt is saved).
- **App icon** — Use the same in-app logo for the iOS App Icon (see `Ibtida/JOURNEY_DEBUG_CHECKLIST.md` for App Icon consistency notes).

### Related docs (in repo)

- **`Ibtida/ADMIN_OVERLAY_TEST_CHECKLIST.md`** — How to set admin, test non-admin vs admin, token refresh, CAD, privacy
- **`Ibtida/JOURNEY_DEBUG_CHECKLIST.md`** — Production QA checklist, App Icon consistency, Islamic guidelines section
- **`Ibtida/IMPLEMENTATION_SUMMARY.md`** — Implementation and donation flow details (if present)
- **`firebase/functions/README.md`** — Cloud Functions setup

---

*Ibtida — a beginning.*
