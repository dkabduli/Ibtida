# Reels Tab – Confirmation Checklist

## Performance & QA (addressed in implementation)

- **iPhone SE simulator**
  - Overlays use `ContentLayout.horizontalPadding`, `TabBarLayout.clearanceHeight`, and `AppSpacing` so layout scales; no fixed sizes that clip on small screens.
  - Buttons are full-size tap targets; titles use `AppTypography.bodyBold` / `caption` and `lineLimit(2)` so they stay readable.
- **Larger device**
  - Feed uses full screen; no fixed gaps. Rotated TabView fills `GeometryReader` and is clipped to screen bounds.
- **Single reel plays at a time**
  - `PlayerManager.setCurrentIndex` calls `playPlayer(at:)` for the current index and `pauseAllExcept(index)` for others.
- **No audio overlap**
  - Only the current index is played; adjacent players are prefetched but not played until they become current.
- **Memory**
  - `PlayerManager` keeps at most 3 players (current ± 1). `prunePlayersOutsideWindow()` runs on index change and after getOrCreatePlayer. `releaseAll()` is called in `ReelsTabView.onDisappear`.
- **DEBUG player count**
  - In DEBUG, `ReelsTabView` shows an on-screen badge: `Players: \(viewModel.playerManager.activePlayerCount)` so you can confirm cleanup when scrolling 30+ reels.

## Manual verification (recommended)

1. Run on iPhone SE (or equivalent) simulator: open Reels, confirm no overlay cutoffs and buttons are tappable.
2. Run on a larger simulator: confirm no awkward gaps and smooth vertical paging.
3. Scroll through many reels: confirm only one plays at a time, no overlapping audio, and DEBUG badge stays ≤ 3 (or 0 when tab is not visible).
4. Add reels in Firestore per `firebase/REELS_MIGRATION.md`, then confirm feed loads and pagination works.
