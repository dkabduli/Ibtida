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
  - **Brothers:** In masjid (jamat), On time, Qada, Missed, Not logged; **Jumu’ah** replaces Dhuhr on Friday (distinct status options)
  - **Sisters:** At home (on time), Qada, Missed, Not applicable 🩸 (streak-safe)
  - Sunnah and Witr (Isha) logged where applicable; status stored as enum raw value in Firestore; legacy values migrated on read (`PrayerStatus.fromFirestore`)
- **Fasting & Hijri** — Optional fasting prompt (Monday/Thursday, White Days); Hijri date display (Civil or Umm al-Qura); daily log and bonus credits via `CreditRules`
- **Last 5 weeks** — Horizontal progress grid: **current week first (left)**, older weeks to the right; “This Week” highlighted
- **Prayer status sheet** — Full-height bottom sheet; first tap opens correctly (no blank screen); **Duas** tab: Ameen and Done buttons spaced (no overlap)
- **Streaks & credits** — Credits per prayer status (see table below); streak calculator; menstrual / “Not applicable 🩸” does not break streak
- **Journey** — Single “Journey” title (nav bar); proportions and padding; milestones by total credits; week progress (5 squares); day detail sheet with gender-aware labels
- **Ramadan tab** (optional) — Shown when server enables via `app_config/calendar_flags` and date range is set; per-day fasting log (brothers: Yes/No; sisters: Yes / No / Not applicable 🩸). See `firebase/RAMADAN_CONFIG.md`
- **Reels tab** — Vertical full-screen Quran recitation videos; feed from Firestore (`reels` where `isActive` and `tags` contains `"quran"`); like/save/share; mute; user interactions in `users/{uid}/reelInteractions`. See `firebase/REELS_MIGRATION.md`
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

- **Regular users:** Home, Journey, [Ramadan if enabled], Reels, Donate, Duas, Profile.
- **Admin users:** Same tabs plus **Admin** when `authService.isAdmin` (Firebase Auth custom claim).

Tab contents:

1. **Home** — Today’s prayers (5 circles; Jumu’ah replaces Dhuhr for brothers on Friday), Last 5 Weeks grid (current week left), progress summary; fasting prompt and Sunnah/Witr where applicable.
2. **Journey** — Milestones, week progress (5 squares), credit summary; single nav title “Journey”; day detail sheet.
3. **Ramadan** (optional) — Visible when server config enables it and date range is set; daily fasting log (brothers/sisters; sisters: Yes / No / Not applicable 🩸).
4. **Reels** — Vertical full-screen Quran recitation short videos (data-driven via Firestore); like, save, share; mute toggle; only reels with tag `"quran"` are shown.
5. **Donate** — Overview, **My Requests**, Charities (by category), Convert Credits; card donation via Stripe (CAD).
6. **Duas** — Community dua wall; submit and view duas; Dua of the Day with Ameen/Done.
7. **Profile** — User info, credits, streak; **Donations** history; theme; settings; About; Diagnostics (dev).
8. **Admin** (if `isAdmin`) — Dashboard, All Requests, Credit Conversion, Moderation.

---

## Tech Stack

- **iOS** — SwiftUI, iOS 17+
- **Backend** — Firebase (Auth, Firestore, Cloud Functions)
- **Payments** — Stripe (PaymentSheet); **CAD** only; test mode via `pk_test_` / Stripe test cards
- **Key paths** — All Firestore paths are centralized in `Core/FirestorePaths.swift`. Main ones: `users/{uid}`, `users/{uid}/donations`, `users/{uid}/requests`, `users/{uid}/prayerDays`, `users/{uid}/prayers`, `users/{uid}/reelInteractions`, `users/{uid}/ramadanLogs`, `users/{uid}/dailyLogs`; `organizationIntakes`, `payments`; global `duas`, `daily_duas`, `charities`, `reels`; `app_config` (e.g. calendar_flags); **admin-only:** `admin/*`, global `requests`, `reports`, `credit_conversion_requests`.

---

## Firestore Rules (Summary)

- **Users** — Read/write only own `users/{userId}` and subcollections (`donations`, `requests`, `prayers`, `prayerDays`, `dailyLogs`, `ramadanLogs`, `reelInteractions`).
- **Donations** — Read-only for user on `users/{uid}/donations`; writes only by backend.
- **Reels** — Read where `isActive == true`; no client write. **reelInteractions** — user read/write only own `users/{uid}/reelInteractions/{reelId}`.
- **app_config** — Read for authenticated users; write only by admin (e.g. Ramadan calendar flags).
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
│   ├── FirestorePaths.swift  (single source for all collection/document paths)
│   ├── BEHAVIOR_LOCK.md      (behaviors that must not change; in-code checklist refs)
│   ├── LoadState.swift       (shared loading state for list screens)
│   ├── StripeConfig.swift, DateUtils.swift, DonationAmountParser.swift
│   ├── DesignSystem.swift, SemanticDesignSystem.swift, AppTheme.swift
│   ├── CreditRules.swift, PrayerStatusColors.swift, HijriCalendar.swift
│   ├── ThemeManager.swift, GentleLanguage.swift, TimeAwareUI.swift, LogLevel.swift
│   └── NetworkErrorHandler.swift, PerformanceCache.swift, AppStrings.swift
├── Models/
│   ├── Charity.swift, Donation.swift, DonationError.swift, DonationType.swift
│   ├── CreditConversionRequest.swift, DailyLog.swift, RamadanConfig.swift, RamadanLog.swift
│   ├── Prayer.swift (PrayerStatus.fromFirestore, gender-specific lists)
│   ├── PrayerModels.swift, UserProfile.swift, RequestModel.swift
│   ├── Dua.swift, DuaRequest.swift, ReelModel.swift
│   └── ...
├── Services/
│   ├── AuthService.swift (isAdmin, refreshAdminClaim)
│   ├── FirestoreService.swift, UserProfileFirestoreService.swift (profile cache 60s, clear on sign-out)
│   ├── UserRequestsFirestoreService.swift (user requests: load/create)
│   ├── PrayerLogFirestoreService.swift, PrayerDayFirestoreService.swift, DailyLogFirestoreService.swift
│   ├── StreakCalculator.swift, CalendarConfigManager.swift, RamadanLogFirestoreService.swift
│   ├── ReelService.swift, ReelInteractionService.swift, PlayerManager.swift
│   ├── FirebaseFunctionsService.swift, UserDonationsFirestoreService.swift
│   ├── OrganizationIntakeService.swift, CharityService.swift, DonationService.swift
│   ├── CreditConversionService.swift, DuaFirestoreService.swift
│   └── LocalStorageService.swift, UIStateFirestoreService.swift
├── ViewModels/
│   ├── HomeViewModel.swift, HomePrayerViewModel.swift
│   ├── JourneyViewModel.swift, JourneyProgressViewModel.swift, JourneyMilestoneViewModel.swift
│   ├── RamadanViewModel.swift, ReelsFeedViewModel.swift
│   ├── DonationViewModel.swift, CreditConversionViewModel.swift, PaymentFlowCoordinator.swift
│   ├── CategoryCharitiesViewModel.swift, CommunityRequestsViewModel.swift (admin-only use)
│   └── DuaViewModel.swift
├── Views/
│   ├── Home/       (HomeView, HomePrayerView — prayer grid, status sheets)
│   ├── Journey/    (JourneyView, JourneyHomeView, JourneyMilestoneView)
│   ├── Ramadan/    (RamadanTabView, RamadanDaySheet — optional tab)
│   ├── Reels/      (ReelsTabView, VideoPlayerView — Quran recitation feed)
│   ├── Donate/     (DonationsPage [My Requests], OrganizationIntakeView, CategoryCharitiesView, CreditConversionView)
│   ├── Dua/        (DuaWallView)
│   ├── Profile/    (ProfileView, DonationsHistoryView)
│   ├── Requests/   (RequestsView — user’s own requests; LoadState + UserRequestsFirestoreService)
│   ├── Admin/      (AdminTabView, AdminDashboardView, AdminRequestsView, AdminCreditConversionView, AdminModerationToolsView)
│   ├── Auth/       (LoginView)
│   ├── Onboarding/ (GenderOnboardingView)
│   ├── Settings/   (SettingsView, AppSettingsView, DiagnosticsView)
│   ├── Components/ (DuaComponents, EmptyStates, ErrorHandling, NetworkStatusBanner)
│   └── RootTabView.swift (tab order; conditional Ramadan & Reels & Admin; persist selected tab)
├── REFACTOR_PLAN.md, QUALITY_GATE_CHECKLIST.md, REELS_CHECKLIST.md
└── Resources/      charities.json; Assets.xcassets

firebase/
├── firestore.rules           (user-only + admin-only + reels read; reelInteractions per user)
├── RAMADAN_CONFIG.md         (how to enable Ramadan tab via app_config/calendar_flags)
├── REELS_MIGRATION.md        (how to add reels documents; composite index)
├── scripts/
│   └── set-admin-claims.js   (set admin custom claim by email; run locally)
└── functions/
    └── index.js              createPaymentIntent (CAD), finalizeDonation, stripeWebhook, health, setAdminRole (callable)
```

---

## Code quality & refinement

- **Firestore paths** — All collection/document strings live in `Core/FirestorePaths.swift`; use these constants instead of literals.
- **Behavior lock** — `Core/BEHAVIOR_LOCK.md` and in-code comments define behaviors that must stay identical across refactors (navigation, sheets, credits, dates, privacy). Check before changing flows or data.
- **Loading state** — List screens use `LoadState` (idle, loading, loaded, empty, error) and `LoadState.showLoadingPlaceholder(loadState, isEmpty)` to avoid blank-first-tap and double-fetch.
- **Services** — Firestore access is centralized in services (e.g. `UserRequestsFirestoreService`, `UserProfileFirestoreService` with optional 60s profile cache). Views/ViewModels orchestrate; services perform reads/writes.
- **Quality gate** — After changes, run through `Ibtida/QUALITY_GATE_CHECKLIST.md` (build, no behavior change, no clipping, no blank first-tap, no fetch loops).

---

## Notes

- **Credits** are for in-app motivation and conversion only; they do not represent religious reward.
- **Donation receipts** are written only by the backend; client never writes to `users/{uid}/donations`.
- **Prayer status** is stored as enum raw value in Firestore; display labels are gender-specific in the UI; legacy strings (e.g. `"later"`, `"made up"`) are mapped on read via `PrayerStatus.fromFirestore`.
- **Last 5 Weeks** order: index 0 = current week (left); data from `DateUtils.lastNWeekStarts(5)`; “This Week” emphasized.
- **Islamic guidelines** — Prayer terminology (e.g. Jama’ah, Qada, “Not applicable 🩸”) and donation flows are aligned with mainstream fiqh; “Not applicable 🩸” does not penalize streaks; donations are transparent (CAD, receipt state, no misleading success until receipt is saved).
- **App icon** — Use the same in-app logo for the iOS App Icon (see `Ibtida/JOURNEY_DEBUG_CHECKLIST.md` for App Icon consistency notes).

### Related docs (in repo)

- **`Ibtida/Core/BEHAVIOR_LOCK.md`** — Behaviors that must remain identical; module inventory; in-code checklist references
- **`Ibtida/REFACTOR_PLAN.md`** — Refinement passes: path centralization, LoadState, services, profile cache; file-by-file rationale
- **`Ibtida/QUALITY_GATE_CHECKLIST.md`** — Post-refactor verification: build, no behavior change, no clipping, no blank first-tap, no fetch loops
- **`Ibtida/REELS_CHECKLIST.md`** — Reels tab QA: iPhone SE, single player, no audio overlap, memory
- **`Ibtida/ADMIN_OVERLAY_TEST_CHECKLIST.md`** — How to set admin, test non-admin vs admin, token refresh, CAD, privacy
- **`Ibtida/JOURNEY_DEBUG_CHECKLIST.md`** — Production QA checklist, App Icon consistency, Islamic guidelines section
- **`firebase/RAMADAN_CONFIG.md`** — Enable Ramadan tab via `app_config/calendar_flags`
- **`firebase/REELS_MIGRATION.md`** — Add reels in Firestore; composite index; user interactions
- **`firebase/functions/README.md`** — Cloud Functions setup

---

*Ibtida — a beginning.*
