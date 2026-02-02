# Behavior Lock Checklist

**Purpose:** This document and in-code comments define behaviors that MUST remain identical across refactors. Do not change user-visible flows, data shapes, or outcomes.

---

## 1. Module / Screen / Service Inventory

| Area | Screens / Entry Points | Key Services | Models |
|------|------------------------|-------------|--------|
| **Auth** | LoginView, GenderOnboardingView, RootView (auth routing) | AuthService, UserProfileFirestoreService | UserProfile |
| **Home (Salah)** | HomePrayerView (prayer bubbles, 5-week grid), HomeView (today/week) | HomePrayerViewModel, PrayerLogFirestoreService, DailyLogFirestoreService, UserProfileFirestoreService | PrayerDay, PrayerLog, DailyLog |
| **Journey** | JourneyView, JourneyMilestoneView, JourneyDayDetailSheet | JourneyViewModel, PrayerLogFirestoreService, UserProfileFirestoreService | JourneyWeekSummary, JourneyDayDetail |
| **Donate** | DonationsPage, DonateView, CategoryCharitiesView, OrganizationIntakeView, CreditConversionView | DonationViewModel, DonationService, UserDonationsFirestoreService, OrganizationIntakeService | Donation, Charity |
| **Duas** | DuaWallView, SubmitDuaView, DuaFilterView | DuaViewModel, DuaFirestoreService, UIStateFirestoreService | Dua |
| **Requests** | RequestsView (inside Donate) | CommunityRequestsViewModel, RequestsView (Firestore in view) | RequestModel |
| **Profile** | ProfileView, DonationsHistoryView, SettingsView, AppSettingsView, DiagnosticsView | UserProfileFirestoreService | UserProfile, Donation |
| **Ramadan** | RamadanTabView, RamadanDaySheet | RamadanViewModel, CalendarConfigManager, RamadanLogFirestoreService | RamadanConfig, RamadanLog |
| **Reels** | ReelsTabView | ReelsFeedViewModel, ReelService, ReelInteractionService, PlayerManager | Reel, ReelInteraction |
| **Admin** | AdminTabView, AdminDashboardView, AdminRequestsView, AdminModerationToolsView, AdminCreditConversionView | Various (Firestore in ViewModels/Views) | Report, CreditConversionRequest |
| **Core** | IbtidaApp, RootTabView | ThemeManager, CalendarConfigManager, FirestoreService, PerformanceCache, DateUtils, CreditRules | — |

---

## 2. Behaviors That Must Remain Identical

### Navigation & flows
- **Tab order:** Home → Journey → [Ramadan if enabled] → Reels → Donate → Duas → Profile → [Admin if admin]
- **Auth flow:** Loading → Logged out (LoginView) OR Logged in → onboarding if gender/onboarding not set → RootTabView.
- **Home prayer flow:** Tap bubble → (if fasting prompt needed) FastingPromptSheet → WarmPrayerStatusSheet → save → sheet dismiss.
- **Journey:** Current week first; last 5 weeks horizontal; tap day → JourneyDayDetailSheet.
- **Sheet presentation:** Sheets must never show blank (e.g. Journey: set `activeDayDetail` before `activeSheetRoute`; Home: `sheetRoute` drives step).

### Button & action outcomes
- Prayer status select → Firestore write (prayerDays + user totals/streak); credits/points per CreditRules.
- Fasting answer → DailyLog save + optional fasting bonus (DailyLogFirestoreService); then continue to prayer status.
- Jumu'ah: brothers on Friday see Jumu'ah instead of Dhuhr; status options per PrayerType.statusesForJummahBrother().
- Donate / credit conversion / organization intake: existing flows and Firestore writes unchanged.
- Dua ameen / submit / filter: existing behavior unchanged.
- Reels: like/save/share and playback rules unchanged.

### Data reads/writes (Firestore)
- **Collections/paths:** Do NOT rename. Use FirestorePaths for all references (users, prayerDays, dailyLogs, duas, daily_duas, requests, reports, donations, ramadanLogs, reels, reelInteractions, app_config, etc.).
- **Document shapes:** No field renames or removals. totalCredits (with legacy "credits" read fallback where already present).
- **Query semantics:** Same filters, orderBy, limit, pagination (e.g. reels: isActive == true, tags array-contains "quran"; Journey: 5 weeks, journeyCalendar).

### Points / credit logic
- CreditRules: fasting bonus, Sunnah bonus, Jumu'ah bonus, streak logic.
- DailyLogFirestoreService: fasting bonus applied in transaction when saving daily log.
- HomePrayerViewModel / PrayerDayFirestoreService: credit and streak updates per existing logic.
- StreakCalculator: streak = consecutive days with ≥3 completed prayers; menstrual days excluded.

### Date / week calculations
- **Day boundary:** DateUtils.dayId() and user timezone; prayers never carry over between days.
- **Week:** Sunday-based (firstWeekday = 1); DateUtils.weekStart, daysInWeek, lastNWeekStarts, dateRangeForLastNWeeks.
- **Journey:** DateUtils.journeyCalendar (America/Toronto) for week bucketing and last 5 weeks.

### Privacy & sensitivity
- Sister "Not applicable 🩸" and menstrual-related fields: never exposed to other users; Firestore rules and UI keep them private.
- User documents and subcollections: read/write only by that user (except admin/global collections per rules).

---

## 3. In-Code Checklist References

Key files include a short comment pointing here:

- **HomePrayerView.swift:** Sheet route and fasting → prayer step flow; no blank sheet.
- **HomePrayerViewModel.swift:** loadTodayPrayers guard/cache; credit/streak writes.
- **JourneyView.swift:** loadIfNeeded single flow; sheet uses activeDayDetail + activeSheetRoute.
- **JourneyViewModel.swift:** JourneyLoadState; current week first, last 5 weeks.
- **IbtidaApp.swift (RootView):** Auth routing; profile load and onboarding gate.
- **DuaWallView.swift:** loadDuas/loadDailyDua; daily dismissal state.
- **DateUtils.swift:** Day/week boundaries and Journey calendar.
- **CreditRules.swift:** Point and bonus constants.
- **FirestorePaths.swift:** Single source for collection/document path strings.
- **RequestsView / RequestsViewModel:** LoadState + single loadTask prevent blank-first-tap and double-fetch; UserRequestsFirestoreService centralizes Firestore for user requests.
- **LoadState.swift:** Shared loading state for list screens (idle, loading, loaded, empty, error); use `showLoadingPlaceholder(loadState, isEmpty)` for placeholder.

When editing these areas, re-check this checklist so behavior stays identical.
