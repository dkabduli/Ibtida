# Ibtida App Icon Specification

## Design Requirements

The app icon must match the Welcome/Login screen branding exactly.

### Colors (Light Mode - Brother Theme)
- **Background**: `warmCream` = RGB(250, 245, 235) = #FAF5EB
- **Icon Tint Start**: `mutedGold` = RGB(204, 173, 107) = #CCAD6B
- **Icon Tint End**: `deepGold` = RGB(184, 148, 77) = #B8944D

### Icon Symbol
- **SF Symbol**: `hands.sparkles.fill`
- **Weight**: Medium
- **Size**: ~50% of icon canvas (with proper padding)

### Required Sizes (iOS)
| Size | Scale | Pixels | Usage |
|------|-------|--------|-------|
| 1024x1024 | 1x | 1024px | App Store |
| 60x60 | 3x | 180px | iPhone App Icon |
| 60x60 | 2x | 120px | iPhone App Icon |
| 40x40 | 3x | 120px | Spotlight |
| 40x40 | 2x | 80px | Spotlight |
| 29x29 | 3x | 87px | Settings |
| 29x29 | 2x | 58px | Settings |
| 20x20 | 3x | 60px | Notification |
| 20x20 | 2x | 40px | Notification |

### Design Guidelines
1. **No transparency** - iOS requires opaque icons
2. **Full bleed background** - warmCream fills entire icon
3. **Centered symbol** - hands.sparkles.fill centered with ~20% padding
4. **Gradient direction** - top-to-bottom (mutedGold → deepGold)
5. **Corner radius** - iOS applies automatically, do NOT add manually
6. **Export format** - PNG, RGB color space, no alpha

### Generation Steps
1. Create 1024x1024 canvas with #FAF5EB fill
2. Place hands.sparkles.fill SF Symbol centered
3. Apply linear gradient: #CCAD6B (top) → #B8944D (bottom)
4. Symbol should be ~512px tall (50% of canvas)
5. Export all sizes from the 1024 master

### Tools
- **Recommended**: SF Symbols app + Sketch/Figma
- **Alternative**: Use `SF Symbols` app to export, then composite in image editor
- **Automation**: bakery.app, IconKitchen, or AppIconMaker

### Verification
After adding icons, verify:
1. Icon appears correctly in Simulator Settings
2. Icon shows on Home screen without white edges
3. Icon appears in App Store Connect preview
