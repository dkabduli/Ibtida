//
//  SemanticDesignSystem.swift
//  Ibtida
//
//  Unified semantic design system - colors, typography, spacing, shadows
//  Single source of truth for all design tokens
//

import SwiftUI

// MARK: - Semantic Color Tokens

extension Color {
    // MARK: - Background Colors (Semantic)
    
    /// Primary background - main app background
    static func bgPrimary(_ scheme: ColorScheme, gender: UserGender? = nil) -> Color {
        Color.warmBackground(scheme, gender: gender)
    }
    
    /// Card background - elevated surfaces
    static func cardBg(_ scheme: ColorScheme, gender: UserGender? = nil) -> Color {
        Color.warmCard(scheme, gender: gender)
    }
    
    /// Surface background - secondary elevated surfaces
    static func surfaceBg(_ scheme: ColorScheme, gender: UserGender? = nil) -> Color {
        Color.warmSurface(scheme, gender: gender)
    }
    
    // MARK: - Text Colors (Semantic)
    
    /// Primary text - main content
    static func textPrimary(_ scheme: ColorScheme) -> Color {
        Color.warmText(scheme)
    }
    
    /// Secondary text - supporting content
    static func textSecondary(_ scheme: ColorScheme) -> Color {
        Color.warmSecondaryText(scheme)
    }
    
    /// Tertiary text - subtle content
    static func textTertiary(_ scheme: ColorScheme) -> Color {
        scheme == .dark 
            ? Color(white: 0.45)
            : Color(red: 0.60, green: 0.55, blue: 0.50)
    }
    
    // MARK: - Accent Colors (Semantic)
    
    /// Primary accent - gold/rose (gender-aware)
    static func accentGold(_ scheme: ColorScheme, gender: UserGender? = nil) -> Color {
        if gender == .sister {
            return scheme == .dark ? Color.sisterGold : Color.sisterGold
        }
        return Color.mutedGold
    }
    
    /// Success color - green
    static let successGreen = Color(red: 0.20, green: 0.70, blue: 0.40)
    
    /// Warning color - amber/orange
    static let warningAmber = Color(red: 1.0, green: 0.65, blue: 0.0)
    
    /// Error color - red (gentle, not harsh)
    static let errorRed = Color(red: 0.85, green: 0.30, blue: 0.30)
    
    /// Info color - blue
    static let infoBlue = Color(red: 0.20, green: 0.60, blue: 0.85)
    
    // MARK: - Border Colors (Semantic)
    
    /// Border/divider color
    static func borderColor(_ scheme: ColorScheme, gender: UserGender? = nil) -> Color {
        Color.warmBorder(scheme, gender: gender)
    }
}

// MARK: - Semantic Typography (Dynamic Type Friendly)

enum SemanticTypography {
    // MARK: - Headings
    
    /// Large title - app titles, hero text
    static var largeTitle: Font {
        .system(size: 34, weight: .bold, design: .rounded)
    }
    
    /// Title 1 - section headers
    static var title1: Font {
        .system(size: 28, weight: .bold, design: .rounded)
    }
    
    /// Title 2 - card titles
    static var title2: Font {
        .system(size: 22, weight: .semibold, design: .rounded)
    }
    
    /// Title 3 - subsection headers
    static var title3: Font {
        .system(size: 20, weight: .semibold, design: .rounded)
    }
    
    // MARK: - Body Text
    
    /// Body - main content
    static var body: Font {
        .system(size: 17, weight: .regular, design: .default)
    }
    
    /// Body Bold - emphasized content
    static var bodyBold: Font {
        .system(size: 17, weight: .semibold, design: .default)
    }
    
    /// Subheadline - secondary content
    static var subheadline: Font {
        .system(size: 15, weight: .regular, design: .default)
    }
    
    /// Subheadline Bold - emphasized secondary
    static var subheadlineBold: Font {
        .system(size: 15, weight: .semibold, design: .default)
    }
    
    // MARK: - Supporting Text
    
    /// Caption - small supporting text
    static var caption: Font {
        .system(size: 13, weight: .regular, design: .default)
    }
    
    /// Caption Bold - emphasized small text
    static var captionBold: Font {
        .system(size: 13, weight: .semibold, design: .default)
    }
    
    /// Footnote - smallest text
    static var footnote: Font {
        .system(size: 12, weight: .regular, design: .default)
    }
    
    // MARK: - Special
    
    /// Arabic text - serif design
    static var arabic: Font {
        .system(size: 18, weight: .medium, design: .serif)
    }
    
    /// Arabic Large - prominent Arabic
    static var arabicLarge: Font {
        .system(size: 22, weight: .medium, design: .serif)
    }
}

// MARK: - Semantic Spacing (Consistent)

enum SemanticSpacing {
    static let xs: CGFloat = 4   // Tight spacing
    static let sm: CGFloat = 8    // Small spacing
    static let md: CGFloat = 12   // Medium spacing
    static let lg: CGFloat = 16   // Large spacing
    static let xl: CGFloat = 20   // Extra large
    static let xxl: CGFloat = 24  // 2x large
    static let xxxl: CGFloat = 32 // 3x large
}

// MARK: - Semantic Corner Radius

enum SemanticRadius {
    static let small: CGFloat = 8   // Buttons, chips
    static let medium: CGFloat = 12  // Small cards
    static let large: CGFloat = 16   // Standard cards
    static let xlarge: CGFloat = 20  // Large cards
    static let round: CGFloat = 999  // Fully rounded
}

// MARK: - Semantic Shadows

enum SemanticShadow {
    /// Small shadow - subtle elevation
    static func small(_ scheme: ColorScheme, gender: UserGender? = nil) -> (color: Color, radius: CGFloat, x: CGFloat, y: CGFloat) {
        if scheme == .dark {
            let shadowColor = gender == .sister 
                ? Color.sisterDarkAccent.opacity(0.3)
                : Color.black.opacity(0.4)
            return (shadowColor, 4, 0, 2)
        }
        return (Color.warmBrown.opacity(0.1), 4, 0, 2)
    }
    
    /// Medium shadow - standard elevation
    static func medium(_ scheme: ColorScheme, gender: UserGender? = nil) -> (color: Color, radius: CGFloat, x: CGFloat, y: CGFloat) {
        if scheme == .dark {
            let shadowColor = gender == .sister 
                ? Color.sisterDarkAccent.opacity(0.4)
                : Color.black.opacity(0.5)
            return (shadowColor, 8, 0, 4)
        }
        return (Color.warmBrown.opacity(0.15), 8, 0, 4)
    }
    
    /// Large shadow - high elevation
    static func large(_ scheme: ColorScheme, gender: UserGender? = nil) -> (color: Color, radius: CGFloat, x: CGFloat, y: CGFloat) {
        if scheme == .dark {
            let shadowColor = gender == .sister 
                ? Color.sisterDarkAccent.opacity(0.5)
                : Color.black.opacity(0.6)
            return (shadowColor, 16, 0, 8)
        }
        return (Color.warmBrown.opacity(0.2), 16, 0, 8)
    }
    
    /// Glow effect - for highlights (dark mode)
    static func glow(_ color: Color, radius: CGFloat = 8) -> (color: Color, radius: CGFloat, x: CGFloat, y: CGFloat) {
        return (color.opacity(0.6), radius, 0, 0)
    }
}

// MARK: - Card Elevation

enum CardElevation {
    case low, medium, high
}

// MARK: - View Modifiers for Consistent Styling

extension View {
    /// Apply semantic card style
    func semanticCard(
        scheme: ColorScheme,
        gender: UserGender? = nil,
        elevation: CardElevation = .medium
    ) -> some View {
        let shadow = elevation == .high 
            ? SemanticShadow.large(scheme, gender: gender)
            : elevation == .medium
            ? SemanticShadow.medium(scheme, gender: gender)
            : SemanticShadow.small(scheme, gender: gender)
        
        return self
            .background(
                RoundedRectangle(cornerRadius: SemanticRadius.large)
                    .fill(Color.cardBg(scheme, gender: gender))
            )
            .overlay(
                RoundedRectangle(cornerRadius: SemanticRadius.large)
                    .strokeBorder(Color.borderColor(scheme, gender: gender), lineWidth: 1)
            )
            .shadow(
                color: shadow.color,
                radius: shadow.radius,
                x: shadow.x,
                y: shadow.y
            )
    }
}
