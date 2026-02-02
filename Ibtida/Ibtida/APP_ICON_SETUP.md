# App Icon – Match Welcome Page Logo

The app icon should match the logo on the Welcome/Loading screen (warm cream background, gold `hands.sparkles.fill` symbol).

## 1. Generate the 1024×1024 icon

From the **Ibtida** project folder (the one that contains `Ibtida.xcodeproj`), run:

```bash
swift Ibtida/GenerateAppIcon.swift
```

This creates `AppIcon-1024.png` in `Ibtida/Ibtida/Assets.xcassets/AppIcon.appiconset/` (warm cream background + gold symbol, same as WarmLoadingView).

## 2. Use it in Xcode

- **Assets.xcassets** → **AppIcon** should already reference `AppIcon-1024.png` (Contents.json is set).
- If the image was created in a different location, drag `AppIcon-1024.png` into the AppIcon set in Xcode.

## 3. See it on device

- **Clean build:** Product → Clean Build Folder (Cmd+Shift+K), then build and run.
- **Build number** was bumped (CFBundleVersion = 2) so the system is more likely to refresh the icon when you install on a physical iPhone.

## 4. Target check

- Target → **General** → **App Icons and Launch Screen** → App Icon source should be **AppIcon** (default).
