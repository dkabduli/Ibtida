# Elite Refinement Pass — Summary

**Date:** 2026-02-16  
**Scope:** Top-to-bottom structural, architectural, UI/UX, performance, and reliability refinement. No feature additions. No behavior changes to Islamic logic or prayer rules.

---

## 1️⃣ Structural Improvements

### Architecture & Dependency Boundaries
- **FirestorePaths centralization:** All Firestore collection references now use `FirestorePaths`:
  - `DonationViewModel`: `"donations"` → `FirestorePaths.donations`, `"receipts"` → `FirestorePaths.receipts`, `"donation_requests"` → `FirestorePaths.donationRequests`
  - `JourneyProgressViewModel`: `"journey"` → `FirestorePaths.journey`
  - `DuaFirestoreService`: Replaced local `duasCollection` / `dailyDuasCollection` with `FirestorePaths.duas` and `FirestorePaths.dailyDuas`
- **New FirestorePaths constants:**
  - `donationRequests` — for global donation requests collection
  - `journey` — for user journey progress subcollection

### Dead Code Removal
- **WarmCreateRequestSheet** — Entire struct (~90 lines) removed from `DonationsPage.swift`. It was never used; `CreateRequestView` (with `RequestsViewModel`) is used for My Requests.
- No other dead files removed (HomeView, JourneyHomeView retained per BEHAVIOR_LOCK; may be used for future flows).

### Naming & Consistency
- BEHAVIOR_LOCK.md updated: Requests section now correctly lists `RequestsViewModel` and `UserRequestsFirestoreService` for My Requests; `CommunityRequestsViewModel` for Admin-only.

---

## 2️⃣ Removed Dead Code

| Item | Location | Reason |
|------|----------|--------|
| WarmCreateRequestSheet | DonationsPage.swift | Unused; CreateRequestView is used instead |

---

## 3️⃣ Performance Improvements

- **Logging:** Replaced raw `print` + `#if DEBUG` in `CommunityRequestsViewModel` with `AppLog` (error, network, verbose) to reduce console noise and allow LogLevel control.
- **Firestore path consistency:** All path strings now come from `FirestorePaths`, reducing typos and drift.
- **DuaFirestoreService:** Simplified collection path handling; removed redundant local constants.

---

## 4️⃣ UI Consistency Changes

- **DonationsPage:** Added `.tabBarScrollClearance()` so content clears the tab bar when scrolled (matches Home, Journey, Profile).
- **Journey:** Already uses `JourneyLayout`, `AppSpacing`, `ContentLayout`; layout refinements from previous pass retained.
- **Design system:** Existing `AppSpacing`, `ContentLayout`, `AppTypography` unchanged; no magic numbers introduced.

---

## 5️⃣ Remaining Architectural Risks

| Risk | Mitigation |
|------|------------|
| **Views/ViewModels with direct Firestore** | `HomePrayerViewModel`, `AdminDashboardView`, `AdminModerationToolsView`, `AdminCreditConversionView`, `DonationViewModel`, `JourneyProgressViewModel`, `CommunityRequestsViewModel` still hold `db` and perform Firestore reads. Full migration to Services would be a larger refactor. |
| **AppIcon-1024.png missing** | `Assets.xcassets/AppIcon.appiconset/Contents.json` references `AppIcon-1024.png`, but the file is not present. Run `GenerateAppIcon.swift` or add a 1024×1024 PNG to avoid App Icon warnings. |
| **donation_requests collection** | Used by `DonationViewModel`; not defined in `firestore.rules`. If this collection exists, add rules. If deprecated, remove usage. |
| **HomeView vs HomePrayerView** | `RootTabView` uses `HomePrayerView` only. `HomeView` exists but is unused. Consider removing or documenting as legacy. |
| **JourneyHomeView** | Only referenced in its own Preview. May be legacy; consider removing if JourneyView is the sole Journey entry. |

---

## 6️⃣ Domain Logic Verification

- **Brothers:** In masjid (jamat), On time, Qada, Missed, Not logged ✓  
- **Sisters:** At home (on time), Qada, Missed, Not applicable 🩸 ✓  
- **Jumu'ah:** Brothers on Friday — In masjid (Jumu'ah), Missed, Not logged ✓  
- **Gender onboarding:** Single prompt via `GenderOnboardingView`; no duplicate flows found.  
- **Prayer model:** `PrayerStatus` and `PrayerStatus.displayName(for: gender)` verified correct.

---

## 7️⃣ Tab Structure

- **5 tabs:** Home, Journey, Donate, Dua, Profile ✓  
- No Reels tab. No duplicate routes.  
- Profile accessible via toolbar and as tab 4.

---

## 8️⃣ Files Modified

| File | Changes |
|------|---------|
| `Core/FirestorePaths.swift` | Added `donationRequests`, `journey` |
| `ViewModels/DonationViewModel.swift` | FirestorePaths for donations, receipts, donation_requests |
| `ViewModels/JourneyProgressViewModel.swift` | FirestorePaths.journey |
| `ViewModels/CommunityRequestsViewModel.swift` | AppLog instead of print |
| `Services/DuaFirestoreService.swift` | FirestorePaths.duas, FirestorePaths.dailyDuas; TODO → NOTE |
| `Views/Donate/DonationsPage.swift` | Removed WarmCreateRequestSheet; added tabBarScrollClearance |
| `Core/BEHAVIOR_LOCK.md` | Updated Requests row |

---

**No features added. No Islamic logic changed. No Firestore schema altered. Refinement only.**
