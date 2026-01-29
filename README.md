# Ibtida 🕌

Ibtida is a **native iOS app** built with **SwiftUI** that encourages consistent prayer, intentional worship, and charitable giving. Users track daily prayers, build streaks, earn credits, and donate to verified charities — including **card payments in CAD** via Stripe and **donation receipts** stored in their profile.

**Repo layout:** iOS app lives in `Ibtida/` (Xcode project); Firebase (Functions, Firestore rules) lives in `firebase/`.

---

## Purpose

Ibtida (*“a beginning”*) connects two acts of worship:

- **Prayer (Salah)** — consistency and awareness through daily tracking
- **Charity (Sadaqah)** — giving via credits or card (CAD) to verified organizations

By combining prayer tracking with a credit-based system and real card donations, the app helps turn intention into action and build lasting spiritual habits.

---

## Core Features (Current Build)

- **Auth** — Email/password (Firebase Auth); optional Google Sign-In
- **Onboarding** — Gender selection (brother/sister) for credit rules and prayer options
- **Prayer tracking** — Log 5 daily prayers with status: On time, Late, Made up (Qada), Missed; gender-specific options (e.g. Prayed at Masjid, Prayed at Home, Menstrual)
- **Last 5 weeks** — Horizontal progress grid: **current week first (left)**, older weeks to the right; “This Week” highlighted
- **Prayer status sheet** — Full-height bottom sheet; first tap opens correctly (no blank screen)
- **Streaks & credits** — Credits per prayer status (see table below); streak calculator; menstrual mode (sisters) does not break streak
- **Journey** — Milestones by total credits (البداية → مواظب → ثابت → … → أسطورة); week progress (5 squares)
- **Donate tab** — Overview, **Community Requests**, **Charities** (by category), **Convert Credits**; card donations via **Stripe PaymentSheet** (CAD only)
- **Card donations** — Per-charity intake form (name, email, amount ≥ $0.50 CAD) → **createPaymentIntent** (Cloud Function) → Stripe **PaymentSheet** → **finalizeDonation** → receipt in `users/{uid}/donations`
- **Donation receipts** — Server-written (webhook + finalizeDonation); list (**DonationsHistoryView**) and detail (**DonationReceiptDetailView**) in **Profile → Donations**
- **Credit conversion** — Convert credits to dollar value (100 credits = $1); **CreditConversionView**; tracked in Firestore
- **Dua wall** — Global community duas; ameens; submit anonymous or public
- **Profile** — Name, email, credits, streak, member since; **Donations** history (list + detail); theme (System / Light / Dark); menstrual mode; About, Privacy, Terms; **Diagnostics** (dev: Stripe key mode, Functions URL)
- **Theme** — Warm design system; light/dark/system; muted gold accent; accessible typography
- **Network & errors** — Network status banner; centralized error handling; optional gentle language and time-aware UI

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
| Sisters – Menstrual| 0 (no streak break) |

- **Daily max** — 50 credits (5 × 10).
- **New user bonus** — First 14 days get a 1.5× multiplier (see `CreditRules`).
- **Conversion** — 100 credits = $1.00 (configurable in app/backend).

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
- **Receipts** — Server-only writes (webhook `payment_intent.succeeded` + callable **finalizeDonation**). Fields: `amountCents`, `currency: "cad"`, `createdAt`, `organizationId`, `organizationName`, `intakeId`, `paymentIntentId`, `status`, etc.
- **Profile → Donations** — Lists receipts (newest first); tap for detail (reference ID, amount in CAD, receipt URL if present).

---

## Navigation (5 Tabs)

1. **Home** — Today’s prayers (5 circles), Last 5 Weeks grid (current week left), progress summary
2. **Journey** — Milestones, week progress (5 squares), credit summary
3. **Donate** — Overview, Community Requests, Charities (by category), Convert Credits; card donation via Stripe (CAD)
4. **Duas** — Community dua wall; submit and view duas
5. **Profile** — User info, credits, streak; **Donations** history; theme; settings; About; Diagnostics (dev)

---

## Tech Stack

- **iOS** — SwiftUI, iOS 17+
- **Backend** — Firebase (Auth, Firestore, Cloud Functions)
- **Payments** — Stripe (PaymentSheet); **CAD** only; test mode via `pk_test_` / Stripe test cards
- **Key paths** — `users/{uid}`, `users/{uid}/donations`, `organizationIntakes`, `payments`; global `duas`, `daily_duas`, `charities` (from JSON + Firestore as needed)

---

## Setup (Developers)

- **Requirements** — Xcode 15+, iOS 17+ target.
1. **Xcode** — Open `Ibtida/Ibtida.xcodeproj`; use the **Ibtida** scheme.
2. **Firebase** — Add `GoogleService-Info.plist`; enable Auth (email/password, optional Google) and Firestore.
3. **Stripe** — In **Info.plist** set `StripePublishableKey` to your **test** key (`pk_test_...`). Alternatively set env `STRIPE_PUBLISHABLE_KEY` in the scheme. Backend uses Stripe secret and webhook secret (Cloud Functions config/secrets).
4. **Cloud Functions** — Deploy from `firebase/functions`; ensure **createPaymentIntent** (CAD only), **finalizeDonation**, **stripeWebhook**, and **health** are deployed; set secrets for Stripe.
5. **Firestore rules** — Users read/write own `users/{uid}`; read-only `users/{uid}/donations`; server writes donations; restrict `organizationIntakes` and `payments` as in your rules.

### Stripe test (donations)

- Use test card **4242 4242 4242 4242** for success.
- Receipts appear under Profile → Donations after **finalizeDonation** (and/or webhook).

---

## Project Structure (High Level)

```
Ibtida/Ibtida/Ibtida/          # iOS app (Xcode project root: Ibtida/Ibtida.xcodeproj)
├── IbtidaApp.swift            # App entry; AppDelegate (Firebase + Stripe key init)
├── Core/
│   ├── StripeConfig.swift     # Stripe publishable key (Info.plist / env)
│   ├── DateUtils.swift        # lastNWeekStarts, date ranges for Journey/Home
│   ├── DonationAmountParser.swift
│   ├── DesignSystem.swift, SemanticDesignSystem.swift, AppTheme.swift
│   ├── CreditRules.swift, PrayerStatusColors.swift
│   ├── ThemeManager.swift, FirestorePaths.swift
│   ├── GentleLanguage.swift, TimeAwareUI.swift, LogLevel.swift
│   └── NetworkErrorHandler.swift, PerformanceCache.swift, AppStrings.swift
├── Models/
│   ├── Charity.swift, Donation.swift (UserDonationReceipt), DonationError.swift, DonationType.swift
│   ├── CreditConversionRequest.swift
│   ├── Prayer.swift, PrayerModels.swift
│   ├── UserProfile.swift, RequestModel.swift
│   └── Dua.swift, DuaRequest.swift
├── Services/
│   ├── AuthService.swift, SessionManager.swift
│   ├── FirebaseFunctionsService.swift (createPaymentIntent, finalizeDonation)
│   ├── FirestoreService.swift, UserProfileFirestoreService.swift
│   ├── UserDonationsFirestoreService.swift, OrganizationIntakeService.swift
│   ├── PrayerLogFirestoreService.swift, StreakCalculator.swift
│   ├── DuaFirestoreService.swift, UIStateFirestoreService.swift
│   ├── CharityService.swift, DonationService.swift, CreditConversionService.swift
│   └── LocalStorageService.swift
├── ViewModels/
│   ├── PaymentFlowCoordinator.swift
│   ├── HomeViewModel.swift, HomePrayerViewModel.swift
│   ├── JourneyProgressViewModel.swift, JourneyMilestoneViewModel.swift
│   ├── DonationViewModel.swift, CreditConversionViewModel.swift
│   ├── CategoryCharitiesViewModel.swift, CommunityRequestsViewModel.swift
│   └── DuaViewModel.swift
├── Views/
│   ├── Home/       (HomeView, HomePrayerView — prayer grid, Last 5 Weeks, status sheets)
│   ├── Journey/    (JourneyView, JourneyHomeView, JourneyMilestoneView)
│   ├── Donate/     (DonateView, DonationsPage, OrganizationIntakeView + PaymentSheetView, CategoryCharitiesView, CreditConversionView)
│   ├── Dua/        (DuaWallView)
│   ├── Profile/    (ProfileView, DonationsHistoryView, DonationReceiptDetailView)
│   ├── Requests/   (RequestsView)
│   ├── Auth/       (LoginView)
│   ├── Onboarding/ (GenderOnboardingView)
│   ├── Settings/   (SettingsView, AppSettingsView, DiagnosticsView)
│   ├── Components/ (DuaComponents, EmptyStates, ErrorHandling, NetworkStatusBanner)
│   └── RootTabView.swift
└── Resources/      charities.json; Assets.xcassets

firebase/
├── firestore.rules
└── functions/
    └── index.js    createPaymentIntent (CAD), finalizeDonation, stripeWebhook, health
```

---

## Notes

- **Credits** are for in-app motivation and conversion only; they do not represent religious reward.
- **Donation receipts** are written only by the backend (webhook + finalizeDonation); client never writes to `users/{uid}/donations`.
- **Last 5 Weeks** order: index 0 = current week (left), then previous weeks; data from `DateUtils.lastNWeekStarts(5)`; current week labeled “This Week” with visual emphasis.
- **Prayer status sheets** use `sheet(item:)` and `.presentationDetents([.large])` for reliable first-tap behavior and full-height presentation.
- **Qibla** is not in the current tab bar; focus is Home, Journey, Donate, Duas, Profile.

### Related docs (in repo)

- `Ibtida/IMPLEMENTATION_SUMMARY.md` — Implementation and donation flow details
- `CREDITS_SYSTEM_REFINEMENT.md` — Credit rules and scoring
- `firebase/functions/README.md` — Cloud Functions setup

---

*Ibtida — a beginning.*
