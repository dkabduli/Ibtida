# Quality Gate Checklist (Post-Refactor)

Use this after the behavior-preserving refinement pass to confirm nothing regressed.

---

## Build & basics

- [ ] **App builds** – `xcodebuild -scheme Ibtida -destination 'platform=iOS Simulator,name=iPhone 16' build` (or equivalent) succeeds with no compile errors.
- [ ] **No new warnings** – Refactor did not introduce new compiler warnings (existing ones may remain).

---

## Behavior (no user-visible changes)

- [ ] **No behavior changes** – Same navigation (tabs, sheets, back), same button outcomes (prayer status, fasting, donate, duas, profile, admin).
- [ ] **No new features** – No new tabs, screens, settings, or toggles.
- [ ] **Firestore unchanged** – Same collections, document IDs, and field names; no new or removed fields in any document shape.

---

## Layout & UX

- [ ] **No clipping on iPhone SE** – Run on iPhone SE (or equivalent small device) simulator; no text/buttons/cards cut off; safe area and padding respected.
- [ ] **Journey layout** – Current week first, last 5 weeks scroll; day detail sheet opens with content (no blank sheet).
- [ ] **Home layout** – Prayer bubbles and 5-week grid fit on screen; greeting and sections visible.

---

## State & loading

- [ ] **No blank states on first tap** – Home prayer bubble tap shows fasting sheet or prayer status sheet (with content); Journey day tap shows day detail (with content); no empty sheet or white screen on first interaction.
- [ ] **No redundant fetch loops** – Loading prayer data or Journey data does not trigger repeated network calls in a loop (observe in Network inspector or logs if needed).
- [ ] **Stable memory** – No obvious leaks (e.g. Reels tab: after scrolling many reels and leaving tab, active player count returns to 0; no unbounded growth in debug tools).

---

## Data & safety

- [ ] **Sensitive data private** – Sister “Not applicable 🩸” and menstrual-related fields remain user-only; not exposed to other users or public APIs.
- [ ] **Firestore rules** – Rules were not weakened; any tightening was done only where it does not break existing authenticated flows.

---

## Refactor-specific

- [ ] **FirestorePaths in use** – All Firestore collection references use `FirestorePaths` (no literal `"users"`, `"prayerDays"`, `"credit_conversion_requests"` in service/viewmodel code for those collections).
- [ ] **BEHAVIOR_LOCK.md** – Exists under `Core/` and is referenced from key files (HomePrayerView, JourneyView, RootView, DateUtils, CreditRules, FirestorePaths).
- [ ] **No workarounds** – No `DispatchQueue.main.asyncAfter` or fixed delays added to “make it work”; no brute-force fixes.

---

## Sign-off

- [ ] **Refactor plan reviewed** – `REFACTOR_PLAN.md` matches the actual code changes.
- [ ] **Quality gate passed** – All applicable items above checked before release or merge.
