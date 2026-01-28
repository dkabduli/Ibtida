# QA Checklist - Ibtida App

## Pre-Release Testing Checklist

### ✅ Authentication & Onboarding
- [ ] First launch shows login screen
- [ ] Sign up creates account and shows gender selection
- [ ] Sign in with existing account works
- [ ] Google Sign In works (if enabled)
- [ ] Sign out clears all data and returns to login
- [ ] Gender selection persists and affects theme
- [ ] Onboarding only shows once per user

### ✅ Home / Prayer Tracking
- [ ] Today's Salah shows 5 prayer circles
- [ ] Tapping prayer circle opens status sheet
- [ ] Status sheet shows all options (including "Not applicable" for sisters)
- [ ] Status sheet is fully visible (no cutoff)
- [ ] Arabic and English text don't overlap
- [ ] Selecting status updates circle immediately
- [ ] Status persists after app restart
- [ ] Day boundary works correctly (prayer on Jan 26 doesn't appear on Jan 27)
- [ ] Sisters "Not applicable" shows minus.circle.fill icon
- [ ] Menstrual mode doesn't break streak
- [ ] Progress bar updates correctly
- [ ] Credits update correctly

### ✅ Last 5 Weeks Grid
- [ ] Shows 5 week columns
- [ ] Each week shows 35 circles (7 days × 5 prayers)
- [ ] Today's circle has glow effect
- [ ] Today's circle color matches Today's Salah status
- [ ] Week bucketing is correct (Jan 27 in week starting Jan 25)
- [ ] All 7 days of each week are visible
- [ ] Circles are properly spaced and sized
- [ ] Grid fills card space nicely
- [ ] Works in both light and dark mode

### ✅ Dua Wall
- [ ] Dua of the Day appears at top
- [ ] Dua of the Day has solid background (not transparent)
- [ ] Dua of the Day can be dismissed with X
- [ ] Dua of the Day resets at midnight
- [ ] Daily dua selected at 2 AM (or shows empty state before 2 AM)
- [ ] Ameen button works and prevents double-counting
- [ ] Ameen count animates smoothly
- [ ] Ameen button locks for 400ms after tap
- [ ] Undo works within 5 seconds
- [ ] Duas list shows only last 24 hours
- [ ] Empty state shows when no duas
- [ ] Filter chips work correctly
- [ ] Submit dua works

### ✅ Donations
- [ ] Charity categories display correctly
- [ ] Charity cards are tappable
- [ ] Donation flow works
- [ ] Credit conversion works
- [ ] Requests list shows empty state when empty
- [ ] Create request works
- [ ] Donation history shows (if implemented)

### ✅ Profile & Settings
- [ ] Profile shows user name and email
- [ ] Appearance toggle works:
  - [ ] Light → forces light mode
  - [ ] Dark → forces dark mode
  - [ ] System → follows iOS setting
- [ ] Appearance preference persists after restart
- [ ] Warm theme toggle works
- [ ] Menstrual mode toggle works (sisters only)
- [ ] Logout works and clears all data

### ✅ Theme & Appearance
- [ ] Light mode looks correct
- [ ] Dark mode looks correct
- [ ] System mode follows iOS setting
- [ ] Warm theme applies consistently
- [ ] Sister theme variant shows (if gender is sister)
- [ ] All cards have consistent styling
- [ ] All buttons have consistent styling
- [ ] No transparency issues (solid backgrounds)

### ✅ Network & Offline
- [ ] App works offline (shows cached data)
- [ ] Network error shows friendly message
- [ ] Retry button works
- [ ] No infinite loading spinners
- [ ] UI doesn't block on network errors
- [ ] Automatic retry with backoff works

### ✅ Performance
- [ ] App launches quickly
- [ ] Scrolling is smooth
- [ ] No jank or stuttering
- [ ] No excessive memory usage
- [ ] Cache works (instant load on second open)
- [ ] No duplicate loads

### ✅ Edge Cases
- [ ] App handles day change while open
- [ ] App handles timezone change
- [ ] App handles device clock change
- [ ] Rapid taps don't cause issues
- [ ] Empty data doesn't crash
- [ ] Missing Firestore fields don't crash
- [ ] Large text sizes work (Dynamic Type)
- [ ] Small screens (iPhone SE) work
- [ ] Large screens (iPhone Pro Max) work
- [ ] VoiceOver works (accessibility)

### ✅ Data Consistency
- [ ] No duplicate dictionary keys
- [ ] Firestore writes use merge: true
- [ ] Server timestamps used correctly
- [ ] DayId is timezone-aware everywhere
- [ ] Week bucketing is consistent
- [ ] Credits calculate correctly
- [ ] Streak calculates correctly

### ✅ Code Quality
- [ ] No compiler errors
- [ ] No linter warnings
- [ ] No force unwraps (safe unwrapping)
- [ ] No duplicate code
- [ ] Logging is clean (not excessive)
- [ ] All listeners are cleaned up
- [ ] All tasks are cancelled properly

## Test Scenarios

### Scenario 1: First Launch
1. Delete app and reinstall
2. Launch app
3. Should show login screen
4. Sign up with new account
5. Should show gender selection
6. Select gender
7. Should show main app

### Scenario 2: Day Rollover
1. Open app on Jan 26
2. Log a prayer
3. Wait for midnight (or change device time)
4. App should show Jan 27
5. Jan 26 prayer should NOT appear in Today's Salah
6. Jan 26 prayer should appear in correct week column

### Scenario 3: Network Failure
1. Turn on airplane mode
2. Open app
3. Should show cached data or empty state
4. Should show network error banner
5. Should allow navigation
6. Turn off airplane mode
7. Should retry automatically
8. Data should load

### Scenario 4: Sisters Menstrual Mode
1. Sign in as sister
2. Enable menstrual mode
3. Mark prayer as "Not applicable"
4. Should show minus.circle.fill icon
5. Should NOT break streak
6. Should show neutral gray color (not red)

### Scenario 5: Appearance Toggle
1. Go to Settings
2. Select "Light"
3. App should force light mode
4. Select "Dark"
5. App should force dark mode
6. Select "System"
7. App should follow iOS setting
8. Restart app
9. Preference should persist

### Scenario 6: Dua of the Day
1. Open Dua Wall
2. Dua of the Day should appear
3. Tap Ameen
4. Count should increment immediately
5. Button should lock for 400ms
6. Undo should appear for 5 seconds
7. Tap X to dismiss
8. Should not reappear until next day

## Known Issues / Notes

- [ ] List any known issues here
- [ ] Document any workarounds
- [ ] Note any platform-specific behaviors

## Performance Benchmarks

- [ ] App launch time: < 2 seconds
- [ ] Prayer status update: < 500ms
- [ ] Dua load time: < 1 second
- [ ] Week grid render: < 100ms
- [ ] Memory usage: < 100MB (typical)

## Accessibility

- [ ] VoiceOver works for all interactive elements
- [ ] Dynamic Type supported (up to accessibility sizes)
- [ ] High contrast mode works
- [ ] Color contrast meets WCAG AA
- [ ] All buttons have accessibility labels
