# Refactor Plan – Production-Quality Refinement (Behavior-Preserving)

This document describes the refinement pass applied to the Ibtida codebase. **No user-visible behavior, flows, data structures, or UI design was changed.** All changes are internal: maintainability, consistency, and safety.

---

## 1. Top Technical Debts Addressed

| # | Debt | Fix | Behavior preserved |
|---|------|-----|---------------------|
| 1 | Magic strings for Firestore collections ("users", "prayerDays", "credit_conversion_requests") scattered across services and views | Centralized all references to `FirestorePaths`; added `creditConversionRequests` constant | Same collection/document paths; same queries and writes |
| 2 | No single checklist for “do not change” behaviors | Added `Core/BEHAVIOR_LOCK.md` and in-code comments in key files | N/A (documentation only) |
| 3 | Inconsistent Firestore path usage (some files used literals, others FirestorePaths) | Replaced every literal `"users"`, `"prayerDays"`, `"credit_conversion_requests"` with `FirestorePaths.*` | Same Firestore reads/writes |
| 4 | Risk of future refactors breaking critical flows (sheet presentation, load-once, credits) | Documented navigation, sheet, credit, and date rules in BEHAVIOR_LOCK.md; added short comments at flow boundaries | N/A (documentation only) |
| 5 | ThemeManager and StreakCalculator using raw "users" / "prayerDays" | Switched to `FirestorePaths.users` and `FirestorePaths.prayerDays` | Same Firestore operations |
| 6 | Admin/Donation/Requests Firestore usage not aligned with FirestorePaths | DonationService, UIStateFirestoreService, DonationViewModel, JourneyProgressViewModel, RequestsView, AdminDashboardView, CreditConversionService now use FirestorePaths | Same collections and semantics |
| 7 | AuthService and FirestoreService using "users" literal | Use `FirestorePaths.users` | Same user document references |
| 8 | UserProfileFirestoreService and PrayerLogFirestoreService mixing literals | Use `FirestorePaths.users` (and keep existing subcollection names) | Same document shapes and reads/writes |
| 9 | No single place documenting “what must stay the same” | BEHAVIOR_LOCK.md + in-code checklist references | N/A |
| 10 | Credit conversion and admin dashboard using literal collection names | Use `FirestorePaths.creditConversionRequests` and existing `FirestorePaths.requests` | Same admin/credit conversion behavior |

---

## 2. Files Modified (and Why)

### Core

| File | Change | Behavior preserved |
|------|--------|---------------------|
| `Core/FirestorePaths.swift` | Added `creditConversionRequests`; added BEHAVIOR LOCK comment | New constant equals `"credit_conversion_requests"`; no path changes |
| `Core/BEHAVIOR_LOCK.md` | **New.** Inventory + behaviors that must remain identical | N/A |
| `Core/ThemeManager.swift` | `db.collection("users")` → `db.collection(FirestorePaths.users)` | Same user document reads/writes |
| `Core/DateUtils.swift` | Added BEHAVIOR LOCK comment | No logic change |
| `Core/CreditRules.swift` | Added BEHAVIOR LOCK comment | No value or logic change |

### Services

| File | Change | Behavior preserved |
|------|--------|---------------------|
| `Services/FirestoreService.swift` | `"users"` → `FirestorePaths.users` in `userDocument` / `userCollection` | Same references |
| `Services/StreakCalculator.swift` | `"users"` / `"prayerDays"` → `FirestorePaths.users` / `FirestorePaths.prayerDays` | Same query and update |
| `Services/UserProfileFirestoreService.swift` | `"users"` → `FirestorePaths.users` | Same user document access |
| `Services/PrayerLogFirestoreService.swift` | `"users"` → `FirestorePaths.users` | Same collection path |
| `Services/AuthService.swift` | `"users"` → `FirestorePaths.users` (ensureUserProfileExists, signUp) | Same user document create/update |
| `Services/DonationService.swift` | `"users"` → `FirestorePaths.users` | Same user subcollections |
| `Services/UIStateFirestoreService.swift` | `"users"` → `FirestorePaths.users` | Same user uiState path |
| `Services/CreditConversionService.swift` | `"credit_conversion_requests"` → `FirestorePaths.creditConversionRequests` | Same collection |

### ViewModels

| File | Change | Behavior preserved |
|------|--------|---------------------|
| `ViewModels/HomePrayerViewModel.swift` | Added BEHAVIOR LOCK comment | No logic change |
| `ViewModels/JourneyViewModel.swift` | Added BEHAVIOR LOCK comment | No logic change |
| `ViewModels/DonationViewModel.swift` | `"users"` → `FirestorePaths.users` | Same donations/requests paths |
| `ViewModels/JourneyProgressViewModel.swift` | `"users"` → `FirestorePaths.users` | Same user/prayerDays access |

### Views

| File | Change | Behavior preserved |
|------|--------|---------------------|
| `Views/Home/HomePrayerView.swift` | Added BEHAVIOR LOCK comment | No flow or UI change |
| `Views/Journey/JourneyView.swift` | Added BEHAVIOR LOCK comment on onAppear | No load or sheet change |
| `Views/Dua/DuaWallView.swift` | Added BEHAVIOR LOCK comment | No load or dismissal logic change |
| `Views/Requests/RequestsView.swift` | `"users"` → `FirestorePaths.users` in RequestsViewModel | Same user requests subcollection |
| `Views/Admin/AdminDashboardView.swift` | `"credit_conversion_requests"` → `FirestorePaths.creditConversionRequests` | Same admin counts |
| `IbtidaApp.swift` | Added BEHAVIOR LOCK comment on RootView | No auth or profile flow change |

### New / Docs

| File | Purpose |
|------|--------|
| `Core/BEHAVIOR_LOCK.md` | Single place for “must not change” behaviors and module inventory |
| `REFACTOR_PLAN.md` | This plan and file-by-file rationale |
| `QUALITY_GATE_CHECKLIST.md` | Post-refactor verification checklist |

---

## 3. What Was Not Changed (By Design)

- **Navigation and tab order:** Unchanged.
- **Auth and onboarding flow:** Unchanged.
- **Prayer logging (Home):** Fasting prompt → prayer status → Firestore write; credits/streak logic unchanged.
- **Journey:** Current week first, last 5 weeks, sheet presentation (activeDayDetail before activeSheetRoute) unchanged.
- **Donate / Duas / Profile / Ramadan / Reels / Admin:** No flow or feature changes.
- **Firestore:** No collection or document renames; no new or removed fields; no query semantics changed.
- **CreditRules and points:** No value or formula changes.
- **DateUtils and week/day logic:** No logic or calendar changes.
- **UI layout, text, and screens:** No visual or copy changes.

---

## 4. Architecture Notes (Existing, Preserved)

- **Views:** SwiftUI only; no direct Firestore in views except RequestsView (ViewModel in same file uses FirestorePaths now).
- **ViewModels:** State and orchestration; call services. Some still hold a `db` reference and use FirestorePaths for path strings (behavior unchanged).
- **Services:** Firestore, Auth, Stripe, etc. All Firestore path strings now go through FirestorePaths where applicable.
- **Models:** Unchanged; document shapes and Codable usage as before.

No new services or repositories were added; only path centralization and documentation were added.

---

## 5. Second Refinement Pass (State, Services, Paths, Cache)

| # | Debt | Fix | Behavior preserved |
|---|------|-----|---------------------|
| 1 | Requests: Firestore in ViewModel, ad-hoc isLoading/errorMessage, possible double-fetch on appear | Added `LoadState` enum; created `UserRequestsFirestoreService`; refactored `RequestsViewModel` to use service + `loadState` + `loadTask` cancel | Same UI: loading placeholder when loading+empty, empty state when empty, list when loaded; same create + reload |
| 2 | User subcollection literals ("prayers", "uiState", "credit_conversions", "donation_intents", "receipts") | Added `FirestorePaths.prayers`, `uiState`, `creditConversions`, `donationIntents`, `receipts`; replaced in PrayerLogFirestoreService, UIStateFirestoreService, DonationService | Same collection paths and document shapes |
| 3 | Profile over-fetch when switching tabs | In-memory profile cache in `UserProfileFirestoreService` (TTL 60s); `clearProfileCache()` on sign-out | Same data; fewer network calls within 60s; cache cleared so next user gets fresh data |
| 4 | No shared loading-state pattern for list screens | Added `Core/LoadState.swift` (idle, loading, loaded, empty, error) and `showLoadingPlaceholder(loadState, isEmpty)` | Same placeholder/empty/content logic; single source for state |

### Files Modified (Second Pass)

| File | Change | Behavior preserved |
|------|--------|---------------------|
| `Core/LoadState.swift` | **New.** Shared `LoadState` enum and `showLoadingPlaceholder` | N/A |
| `Core/FirestorePaths.swift` | Added `prayers`, `uiState`, `creditConversions`, `donationIntents`, `receipts` | Same path strings |
| `Services/UserRequestsFirestoreService.swift` | **New.** `loadRequests(uid)`, `createRequest(uid, title, body)` | Same query and document shape as former ViewModel logic |
| `Services/UserProfileFirestoreService.swift` | In-memory cache (TTL 60s), `clearProfileCache()`; use cache in `loadUserProfile` | Same returned data; cache cleared on sign-out |
| `Services/AuthService.swift` | Call `UserProfileFirestoreService.shared.clearProfileCache()` in `signOut()` | Same sign-out; cache cleared for next user |
| `Services/PrayerLogFirestoreService.swift` | `"prayers"` → `FirestorePaths.prayers` | Same collection path |
| `Services/UIStateFirestoreService.swift` | `"uiState"` → `FirestorePaths.uiState` | Same collection path |
| `Services/DonationService.swift` | `"credit_conversions"`, `"donation_intents"`, `"donations"`, `"receipts"` → FirestorePaths | Same collection paths |
| `Views/Requests/RequestsView.swift` | Removed Firebase imports; ViewModel uses `UserRequestsFirestoreService` + `LoadState` + `loadTask`; View uses `LoadState.showLoadingPlaceholder`; error dismiss calls `clearError()` | Same loading/empty/list/error UI; same create and reload |
