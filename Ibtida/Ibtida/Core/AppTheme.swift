//
//  AppTheme.swift
//  Ibtida
//
//  Warm, sleek theme system with dark mode support
//  Inspired by modern faith/wellness apps
//

import SwiftUI

// MARK: - App Appearance Enum
// SINGLE SOURCE OF TRUTH for appearance selection
// Used throughout the app - no other appearance enums should exist

enum AppAppearance: String, CaseIterable, Codable {
    case system = "system"  // Follows iOS device setting (live updates)
    case light = "light"    // Always light mode
    case dark = "dark"      // Always dark mode
}

// MARK: - Warm Color Palette

extension Color {
    // MARK: - Base Warm Colors (Brother Theme)
    
    /// Cream - Light mode primary background
    static let warmCream = Color(red: 0.98, green: 0.96, blue: 0.92)
    
    /// Sand - Light mode secondary background
    static let warmSand = Color(red: 0.95, green: 0.91, blue: 0.85)
    
    /// Soft Olive - Accent for nature/calm
    static let softOlive = Color(red: 0.55, green: 0.60, blue: 0.45)
    
    /// Muted Gold - Accent for highlights/achievements
    static let mutedGold = Color(red: 0.80, green: 0.68, blue: 0.42)
    
    /// Deep Gold - Stronger accent
    static let deepGold = Color(red: 0.72, green: 0.58, blue: 0.30)
    
    /// Warm Brown - Text and icons
    static let warmBrown = Color(red: 0.35, green: 0.28, blue: 0.22)
    
    /// Soft Terracotta - Warm accent
    static let softTerracotta = Color(red: 0.80, green: 0.55, blue: 0.45)
    
    // MARK: - Sister Theme Colors (More feminine - light pink for light mode, dark purple for dark mode)
    
    /// Sister cream - Light pink background (light mode)
    static let sisterCream = Color(red: 0.99, green: 0.95, blue: 0.97)  // Light pink
    
    /// Sister sand - Soft pink surface (light mode)
    static let sisterSand = Color(red: 0.98, green: 0.93, blue: 0.96)  // Soft pink
    
    /// Sister gold - Rose-pink accent (light mode)
    static let sisterGold = Color(red: 0.92, green: 0.75, blue: 0.85)  // Rose-pink
    
    /// Sister deep gold - Deeper rose-pink (light mode)
    static let sisterDeepGold = Color(red: 0.88, green: 0.68, blue: 0.80)
    
    /// Sister rose - Soft pink accent
    static let sisterRose = Color(red: 0.95, green: 0.80, blue: 0.88)
    
    /// Sister lavender - Soft purple accent
    static let sisterLavender = Color(red: 0.88, green: 0.82, blue: 0.92)
    
    // MARK: - Sister Dark Mode Colors (Dark purple with black accents)
    
    /// Sister dark purple - Dark purple background (dark mode)
    static let sisterDarkPurple = Color(red: 0.15, green: 0.10, blue: 0.20)  // Dark purple
    
    /// Sister dark purple surface - Elevated dark purple (dark mode)
    static let sisterDarkPurpleSurface = Color(red: 0.20, green: 0.14, blue: 0.26)  // Darker purple
    
    /// Sister dark purple card - Card background (dark mode)
    static let sisterDarkPurpleCard = Color(red: 0.25, green: 0.18, blue: 0.32)  // Slightly lighter purple
    
    /// Sister dark accent - Black shadow accent (dark mode)
    static let sisterDarkAccent = Color(red: 0.05, green: 0.05, blue: 0.05)  // Near black
    
    // MARK: - Dark Mode Warm Colors
    
    /// Dark mode background - warm charcoal
    static let warmCharcoal = Color(red: 0.12, green: 0.11, blue: 0.10)
    
    /// Dark mode elevated - warm dark brown
    static let warmDarkBrown = Color(red: 0.18, green: 0.16, blue: 0.14)
    
    /// Dark mode card - slightly lighter
    static let warmDarkCard = Color(red: 0.22, green: 0.20, blue: 0.18)
    
    // MARK: - Semantic Colors (Adapt to color scheme and gender)
    
    /// Primary background (gender-aware)
    static func warmBackground(_ scheme: ColorScheme, gender: UserGender? = nil, menstrualMode: Bool = false) -> Color {
        if scheme == .dark {
            // Dark mode: dark purple for sisters, warm charcoal for brothers
            return gender == .sister ? sisterDarkPurple : warmCharcoal
        }
        
        // Light mode: light pink for sisters, warm cream for brothers
        if gender == .sister {
            // Slightly softer when in menstrual mode
            return menstrualMode ? sisterCream.opacity(0.95) : sisterCream
        }
        
        return warmCream
    }
    
    /// Secondary/elevated background (gender-aware)
    static func warmSurface(_ scheme: ColorScheme, gender: UserGender? = nil) -> Color {
        if scheme == .dark {
            // Dark mode: dark purple surface for sisters, warm dark brown for brothers
            return gender == .sister ? sisterDarkPurpleSurface : warmDarkBrown
        }
        
        // Light mode: soft pink surface for sisters, warm sand for brothers
        return gender == .sister ? sisterSand : warmSand
    }
    
    /// Card background (gender-aware)
    static func warmCard(_ scheme: ColorScheme, gender: UserGender? = nil) -> Color {
        if scheme == .dark {
            // Dark mode: dark purple card for sisters, warm dark card for brothers
            return gender == .sister ? sisterDarkPurpleCard : warmDarkCard
        }
        
        // Light mode: white cards for both
        return .white
    }
    
    /// Primary text
    static func warmText(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? Color(white: 0.92) : warmBrown
    }
    
    /// Secondary text
    static func warmSecondaryText(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? Color(white: 0.65) : Color(red: 0.50, green: 0.45, blue: 0.40)
    }
    
    /// Border/divider (gender-aware)
    static func warmBorder(_ scheme: ColorScheme, gender: UserGender? = nil) -> Color {
        if scheme == .dark {
            // Dark mode: black accent for sisters, standard for brothers
            return gender == .sister ? Color.sisterDarkAccent.opacity(0.4) : Color(white: 0.25)
        }
        return Color(red: 0.88, green: 0.85, blue: 0.80)
    }
    
    /// Accent gold (gender-aware)
    static func accentGold(gender: UserGender? = nil) -> Color {
        gender == .sister ? sisterGold : mutedGold
    }
    
    /// Deep accent gold (gender-aware)
    static func deepAccentGold(gender: UserGender? = nil) -> Color {
        gender == .sister ? sisterDeepGold : deepGold
    }
    
    // MARK: - Prayer Status Colors (Warmer variants)
    
    static let prayerOnTime = Color(red: 0.45, green: 0.72, blue: 0.50)
    static let prayerLate = Color(red: 0.90, green: 0.70, blue: 0.35)
    static let prayerQada = Color(red: 0.50, green: 0.65, blue: 0.80)
    static let prayerMissed = Color(red: 0.75, green: 0.45, blue: 0.45)
    static let prayerNone = Color(red: 0.70, green: 0.68, blue: 0.65)
}

// MARK: - Warm Gradients

extension LinearGradient {
    /// Warm cream to sand gradient
    static var warmBackground: LinearGradient {
        LinearGradient(
            colors: [Color.warmCream, Color.warmSand.opacity(0.5)],
            startPoint: .top,
            endPoint: .bottom
        )
    }
    
    /// Dark warm gradient
    static var warmDarkBackground: LinearGradient {
        LinearGradient(
            colors: [Color.warmCharcoal, Color.warmDarkBrown],
            startPoint: .top,
            endPoint: .bottom
        )
    }
    
    /// Gold accent gradient (gender-aware, scheme-aware)
    static func goldAccent(gender: UserGender? = nil, scheme: ColorScheme? = nil) -> LinearGradient {
        if gender == .sister {
            if scheme == .dark {
                // Dark mode: dark purple to black accent gradient
                return LinearGradient(
                    colors: [Color.sisterDarkPurpleCard, Color.sisterDarkAccent],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            } else {
                // Light mode: rose-pink gradient
                return LinearGradient(
                    colors: [Color.sisterGold, Color.sisterRose, Color.sisterDeepGold],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
        }
        
        return LinearGradient(
            colors: [Color.mutedGold, Color.deepGold],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    /// Gold accent gradient (legacy, uses light mode by default)
    /// For scheme-aware gradients, use goldAccent(gender:scheme:) instead
    static var goldAccent: LinearGradient {
        // Default to light mode for legacy calls
        return goldAccent(gender: nil, scheme: .light)
    }
    
    /// Soft olive gradient
    static var oliveAccent: LinearGradient {
        LinearGradient(
            colors: [Color.softOlive.opacity(0.8), Color.softOlive],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    /// Prayer card gradient
    static func prayerCard(_ scheme: ColorScheme) -> LinearGradient {
        if scheme == .dark {
            return LinearGradient(
                colors: [Color.warmDarkCard, Color.warmDarkCard.opacity(0.9)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else {
            return LinearGradient(
                colors: [.white, Color.warmSand.opacity(0.3)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
}

// MARK: - Warm Card Style Modifier

struct WarmCardModifier: ViewModifier {
    @Environment(\.colorScheme) var colorScheme
    var elevation: CardElevation = .medium
    
    enum CardElevation {
        case low, medium, high
        
        var shadowRadius: CGFloat {
            switch self {
            case .low: return 4
            case .medium: return 8
            case .high: return 16
            }
        }
        
        var shadowOpacity: Double {
            switch self {
            case .low: return 0.05
            case .medium: return 0.08
            case .high: return 0.12
            }
        }
    }
    
    func body(content: Content) -> some View {
        let gender = ThemeManager.shared.userGender
        content
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.warmCard(colorScheme, gender: gender))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(Color.warmBorder(colorScheme, gender: gender), lineWidth: 1)
            )
            .shadow(
                color: colorScheme == .dark 
                    ? (gender == .sister 
                       ? Color.sisterDarkAccent.opacity(elevation.shadowOpacity * 3)  // Black shadow for sisters
                       : Color.black.opacity(elevation.shadowOpacity * 2))
                    : Color.warmBrown.opacity(elevation.shadowOpacity),
                radius: elevation.shadowRadius,
                x: 0,
                y: 2
            )
    }
}

extension View {
    func warmCard(elevation: WarmCardModifier.CardElevation = .medium) -> some View {
        modifier(WarmCardModifier(elevation: elevation))
    }
}

// MARK: - Warm Button Style

struct WarmButtonStyle: ButtonStyle {
    @Environment(\.colorScheme) var colorScheme
    var style: Style = .primary
    
    enum Style {
        case primary, secondary, outline
    }
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 16, weight: .semibold, design: .rounded))
            .padding(.horizontal, 24)
            .padding(.vertical, 14)
            .background(background(for: style))
            .foregroundColor(foregroundColor(for: style))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(borderColor(for: style), lineWidth: style == .outline ? 1.5 : 0)
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .opacity(configuration.isPressed ? 0.9 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: configuration.isPressed)
    }
    
    @ViewBuilder
    private func background(for style: Style) -> some View {
        switch style {
        case .primary:
            // Get gender from ThemeManager for gradient
            let gender = ThemeManager.shared.userGender
            LinearGradient.goldAccent(gender: gender, scheme: colorScheme)
        case .secondary:
            Color.warmSurface(colorScheme)
        case .outline:
            Color.clear
        }
    }
    
    private func foregroundColor(for style: Style) -> Color {
        switch style {
        case .primary:
            return .white
        case .secondary:
            return Color.warmText(colorScheme)
        case .outline:
            return Color.mutedGold
        }
    }
    
    private func borderColor(for style: Style) -> Color {
        switch style {
        case .outline:
            return Color.mutedGold
        default:
            return .clear
        }
    }
}

// MARK: - Warm Prayer Circle Style

struct WarmPrayerCircleStyle: ButtonStyle {
    let status: PrayerStatus
    @Environment(\.colorScheme) var colorScheme
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.92 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: configuration.isPressed)
    }
    
    var circleColor: Color {
        switch status {
        case .none: return Color.prayerNone.opacity(0.3)
        case .onTime: return Color.prayerOnTime
        case .late: return Color.prayerLate
        case .qada: return Color.prayerQada
        case .missed: return Color.prayerMissed
        case .prayedAtMasjid: return Color.purple.opacity(0.8)
        case .prayedAtHome: return Color.mint.opacity(0.8)
        case .menstrual: return Color.red.opacity(0.7)
        }
    }
}

// MARK: - Warm Section Header

struct WarmSectionHeader: View {
    let title: String
    let icon: String?
    let subtitle: String?
    
    @Environment(\.colorScheme) var colorScheme
    
    init(_ title: String, icon: String? = nil, subtitle: String? = nil) {
        self.title = title
        self.icon = icon
        self.subtitle = subtitle
    }
    
    var body: some View {
        HStack(spacing: 8) {
            if let icon = icon {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.mutedGold)
            }
            
            Text(title)
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundColor(Color.warmText(colorScheme))
            
            Spacer()
            
            if let subtitle = subtitle {
                Text(subtitle)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(Color.warmSecondaryText(colorScheme))
            }
        }
    }
}

// MARK: - Warm Background View

struct WarmBackgroundView: View {
    @Environment(\.colorScheme) var colorScheme
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        Group {
            if colorScheme == .dark {
                // Dark mode: gender-aware background
                if themeManager.userGender == .sister {
                    // Sister dark mode: dark purple gradient
                    LinearGradient(
                        colors: [Color.sisterDarkPurple, Color.sisterDarkPurpleSurface],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                } else {
                    // Brother dark mode: warm dark gradient
                    LinearGradient.warmDarkBackground
                }
            } else {
                // Light mode: gender-aware background
                if themeManager.userGender == .sister {
                    // Sister light mode: light pink gradient
                    LinearGradient(
                        colors: [
                            Color.sisterCream,
                            Color.sisterSand.opacity(0.6)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                } else {
                    // Brother light mode: warm cream gradient
                    LinearGradient(
                        colors: [
                            Color.warmBackground(colorScheme, gender: themeManager.userGender, menstrualMode: themeManager.menstrualModeEnabled),
                            Color.warmSurface(colorScheme, gender: themeManager.userGender).opacity(0.5)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                }
            }
        }
        .ignoresSafeArea()
    }
}

// MARK: - Accessibility Helpers

extension View {
    func accessiblePrayerButton(prayer: PrayerType, status: PrayerStatus) -> some View {
        self
            .accessibilityLabel("\(prayer.displayName) prayer")
            .accessibilityValue(status.displayName)
            .accessibilityHint("Double tap to change status")
            .accessibilityAddTraits(.isButton)
    }
    
    func accessibleCard(label: String, hint: String? = nil) -> some View {
        self
            .accessibilityElement(children: .combine)
            .accessibilityLabel(label)
            .accessibilityHint(hint ?? "")
    }
}
