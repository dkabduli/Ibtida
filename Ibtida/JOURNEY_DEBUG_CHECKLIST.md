# Production QA Checklist & Acceptance Tests

## Manual QA checklist (10+ steps)

1. **Journey — No blank screen**
   - Open app → sign in → tap Journey tab.
   - **Expected**: Skeleton appears immediately; then content (header, This Week, Last 5 Weeks, Milestones). No white empty view, no "loads after second tap".
   - **Logs (DEBUG)**: `📖 Journey: fetch uid=… rangeStart=… rangeEnd=…` → `📖 Journey: loaded logs count=…` → `📖 Journey: Loaded N prayer logs (…), computed 5 weeks, current week starts …`

2. **Journey — Current week first + left-justified**
   - On Journey, look at "Last 5 Weeks" horizontal row.
   - **Expected**: Leftmost card is the current week. Row is left-aligned; no center-snapping.

3. **Journey — Day sheet never blank**
   - Tap any day in "This Week" 7-day grid.
   - **Expected**: Sheet opens immediately with day title and 5 prayers (or "Not logged"). No blank sheet flash.

4. **Journey — Subtitle and trust**
   - **Expected**: Title "Journey", subtitle "Your prayer consistency over time", "Last updated: Just now" (or Xs ago) below summary cards.

5. **Prayer status sheet (Home) — No blank first tap**
   - On Home, tap a prayer circle.
   - **Expected**: Sheet opens with prayer name + icon; either status list or loader. No blank sheet. Large detent; full list visible.

6. **Journey — Pull to refresh**
   - On Journey, pull down to refresh.
   - **Expected**: Old content stays visible until new data applies; one fetch per refresh.

7. **Journey — Fresh user (0 logs)**
   - Sign in with account that has no prayer logs.
   - **Expected**: Streak 0, Credits 0, 0/35; empty-state card "Your Journey will appear here…"; no crash, no blank.

8. **Donation — Currency CAD**
   - Start a donation (Organization Intake); check logs.
   - **Expected**: `🧾 Donations: currency enforced cad | createPaymentIntent amountCents=…`

9. **Donation — Success only when receipt persisted**
   - Complete a donation with test card (4242…); wait for finalizeDonation.
   - **Expected**: Full "Thank You!" success view only when receipt is saved (Profile → Donations shows receipt). If finalizeDonation fails after retries, "Payment Received" pending view (no green success) with "Receipt may take a moment—check Profile → Donations."

10. **Donation — Pending receipt state**
    - If finalizeDonation fails (e.g. network off after payment), or simulate failure.
    - **Expected**: "Payment Received" view with clock icon and message; no "Thank You!" green checkmark. Done button dismisses.

11. **Logging — Intent-focused**
    - **Expected**: Journey logs include range and "computed 5 weeks, current week starts …"; finalizeDonation logs "receipt written to users/{uid}/donations" on success; donation flow logs "currency enforced cad."

---

## Acceptance tests

- **Journey loads with no data**: Fresh user → Journey tab → header, 0/35, empty-state card, 5 week cards, milestones; no blank screen.
- **First tap always opens sheet**: Journey → tap any day → sheet opens with content (or "Not logged"); Home → tap prayer → sheet opens with prayer + list or loader. No second-tap needed.
- **Current week always leftmost**: Journey → Last 5 Weeks; first card is current week; left-justified.
- **Donation receipt appears after success**: Complete donation → finalizeDonation succeeds → full "Thank You!" and receipt in Profile → Donations. If finalizeDonation fails → "Payment Received" pending view only (no fake success).
- **Currency always CAD**: Donation amounts and Stripe flow use CAD; logs show "currency enforced cad."

---

## Unit tests (Journey)

- **DateUtils week ordering**: `lastNWeekStarts(5, using: journeyCalendar)` returns 5 dates; index 0 is current week start.
- **DateUtils date range**: `dateRangeForLastNWeeks(5, using: journeyCalendar)` spans 5 full weeks; end = start of next week after current.

See `IbtidaTests/JourneyDateUtilsTests.swift`.

---

## App Icon consistency

- **Goal**: Use the same logo image as shown in-app for the iOS App Icon so the icon and in-app branding match.
- **Steps**: Export the in-app logo at 1024×1024 (and any other sizes required by the Asset Catalog). In Xcode: **Assets.xcassets → AppIcon** → drag the exported images into the appropriate slots (iOS universal 1024×1024, dark/tinted if used). Ensure no stretching, correct safe margin, and transparent background handled if needed.
- **Note**: The Asset Catalog does not contain image files by default; you must add the logo assets. Keep the in-app logo and App Icon visually consistent (same colors and proportions).

---

## Islamic guidelines / fiqh alignment

- **Prayer logging**: Terminology uses mainstream terms (e.g. Jama’ah context for masjid, Qada, “Not applicable 🩸” for hayd). “Not applicable 🩸” is excluded from streaks and progress so it does not penalize sisters.
- **Donations**: Flows make clear that funds go to Ibtida and then to chosen organizations; emphasis on niyyah, amanah, and transparency; no riba/interest or gambling-like framing.
- **Tone**: Modest visuals, respectful copy, no music/autoplay, no gamification that trivializes worship. Where fiqh opinions differ, the app presents options neutrally.
