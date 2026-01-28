# App Icon Setup Instructions

## Overview
This guide explains how to generate and set up the App Icon using the existing Ibtida logo design.

## Step 1: Generate Icon Images

### Option A: Using Xcode Preview (Recommended)

1. Open `Resources/AppIconGenerator.swift` in Xcode
2. Open the Preview panel (⌘⌥↩ or Editor → Canvas)
3. You'll see two previews:
   - "App Icon - Light" (for light mode)
   - "App Icon - Dark" (for dark mode)

4. For each preview:
   - Right-click on the preview
   - Select "Save Image As..."
   - Save as PNG with these names:
     - `AppIcon-1024-Light.png` (light mode, 1024x1024)
     - `AppIcon-1024-Dark.png` (dark mode, 1024x1024)

### Option B: Using Screenshot Tool

1. Run the app in Simulator
2. Create a view that displays `AppIconView(colorScheme: .light)` and `AppIconView(colorScheme: .dark)`
3. Use screenshot tools to capture at 1024x1024 resolution
4. Save as PNG files

### Option C: Export from Design Tool

If you have access to design tools (Figma, Sketch, etc.):
1. Recreate the logo design from `WarmLoadingView` in `IbtidaApp.swift`
2. Export at 1024x1024 for both light and dark variants
3. Ensure:
   - Background is solid (warmCream for light, dark neutral for dark)
   - Logo is centered with 40pt padding
   - Text is readable at all sizes

## Step 2: Place Icon Files

1. Navigate to: `Ibtida/Ibtida/Assets.xcassets/AppIcon.appiconset/`
2. Place the generated PNG files:
   - `AppIcon-1024-Light.png` (1024x1024, light mode)
   - `AppIcon-1024-Dark.png` (1024x1024, dark mode)

## Step 3: Update Contents.json

The `Contents.json` file has been updated to reference:
- Universal iOS icon (1024x1024) - use light mode version
- Dark appearance variant (1024x1024) - use dark mode version
- Tinted appearance variant (1024x1024) - use light mode version (iOS will apply tint)

## Step 4: Verify in Xcode

1. Open Xcode
2. Select the project in Navigator
3. Select the "Ibtida" target
4. Go to "General" tab
5. Under "App Icons and Launch Images", verify:
   - "App Icons Source" points to `AppIcon`
   - All required sizes show the icon (not placeholder)

## Step 5: Test on Device

1. Build and run on a physical device
2. Verify icon appears correctly:
   - On Home Screen
   - In App Switcher
   - In Settings app

## Design Specifications

### Logo Elements (from WarmLoadingView):
- **Icon**: `hands.sparkles.fill` (42pt, mutedGold color)
- **Outer Circle**: Radial gradient (mutedGold, opacity 0.25 → 0.05)
- **Inner Circle**: Solid mutedGold (opacity 0.15)
- **App Name**: "Ibtida" (32pt, bold, rounded font, warmText color)
- **Tagline**: "Your Prayer Companion" (15pt, medium, warmSecondaryText color)

### Colors:
- **Light Mode Background**: `warmCream` (RGB: 0.98, 0.96, 0.92)
- **Dark Mode Background**: Dark neutral (RGB: 0.15, 0.15, 0.18)
- **Gold Accent**: `mutedGold` (RGB: 0.80, 0.68, 0.42)
- **Text (Light)**: `warmText` (warmBrown: 0.35, 0.28, 0.22)
- **Text (Dark)**: `warmText` (light color for dark mode)

### Layout:
- **Canvas Size**: 1024x1024 points
- **Padding**: 40 points on all sides
- **Spacing**: 16 points between icon and text
- **Centered**: All elements centered vertically and horizontally

## App Store Guidelines Compliance

✅ **No Transparency**: Background is solid color
✅ **No Text Cut-off**: 40pt padding ensures safe area
✅ **No Edge Clipping**: All elements within safe bounds
✅ **Centered**: Logo is visually balanced
✅ **Square Format**: 1024x1024 (iOS handles rounded corners)

## Troubleshooting

### Icon Not Appearing:
- Clean build folder (⌘⇧K)
- Delete derived data
- Rebuild project

### Icon Looks Blurry:
- Ensure PNG is exactly 1024x1024 pixels (not points)
- Use PNG format (not JPEG)
- Check that image is not being scaled

### Wrong Colors:
- Verify you're using the correct color scheme variant
- Check that `AppIconGenerator.swift` uses the same colors as `WarmLoadingView`

## Notes

- The icon generator view (`AppIconGenerator.swift`) matches the exact design from `WarmLoadingView` in `IbtidaApp.swift`
- All typography, colors, and spacing are preserved
- The icon will automatically adapt to light/dark mode based on the variant used
- iOS will automatically apply rounded corners and shadows
