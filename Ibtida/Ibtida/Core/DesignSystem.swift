//
//  DesignSystem.swift
//  Ibtida
//
//  Centralized design system - colors, spacing, typography
//

import SwiftUI
import CoreHaptics

// MARK: - Spacing

enum AppSpacing {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let lg: CGFloat = 16
    static let xl: CGFloat = 20
    static let xxl: CGFloat = 24
    static let xxxl: CGFloat = 32
}

// MARK: - Tab Bar Clearance (shared by Home, Journey, and other tab content)

/// Height to reserve at the bottom so content never clips under the tab bar.
/// Tab bar ~49pt + home indicator ~34pt + small buffer. Apply to the *container* (e.g. ZStack
/// wrapping the ScrollView) so the scroll view's frame ends above the tab bar.
enum TabBarLayout {
    static let clearanceHeight: CGFloat = 96
}

extension View {
    /// Reserves bottom space so scroll content (e.g. last card) is never hidden behind the tab bar.
    /// Use on the ScrollView that contains tab content. Matches Home + Journey layout system.
    func tabBarScrollClearance() -> some View {
        safeAreaInset(edge: .bottom, spacing: 0) {
            Color.clear.frame(height: TabBarLayout.clearanceHeight)
        }
    }
}

// MARK: - Typography

enum AppTypography {
    static let largeTitle = Font.system(size: 34, weight: .bold, design: .rounded)
    static let title1 = Font.system(size: 28, weight: .bold, design: .rounded)
    static let title2 = Font.system(size: 22, weight: .semibold, design: .rounded)
    static let title3 = Font.system(size: 20, weight: .semibold, design: .rounded)
    static let body = Font.system(size: 17, weight: .regular, design: .default)
    static let bodyBold = Font.system(size: 17, weight: .semibold, design: .default)
    static let subheadline = Font.system(size: 15, weight: .regular, design: .default)
    static let subheadlineBold = Font.system(size: 15, weight: .semibold, design: .default)
    static let caption = Font.system(size: 13, weight: .regular, design: .default)
    static let captionBold = Font.system(size: 13, weight: .semibold, design: .default)
    static let arabicLarge = Font.system(size: 22, weight: .medium, design: .serif)
}

// MARK: - Colors

extension Color {
    static let soothingGreen = Color(red: 0.4, green: 0.7, blue: 0.5)
    static let soothingBlue = Color(red: 0.4, green: 0.6, blue: 0.8)
    static let trustGreen = Color(red: 0.2, green: 0.7, blue: 0.4)
}

// MARK: - Haptic Feedback

struct HapticFeedback {
    /// Check if device supports haptics (prevents Simulator warnings)
    private static var supportsHaptics: Bool {
        // Check if running on Simulator
        #if targetEnvironment(simulator)
        return false
        #else
        // Check hardware support on real device
        if #available(iOS 13.0, *) {
            return CHHapticEngine.capabilitiesForHardware().supportsHaptics
        } else {
            // Fallback for older iOS versions
            return true
        }
        #endif
    }
    
    /// Check if device is in silent mode
    /// Respects silent mode for masjid and late hours
    private static var isSilentMode: Bool {
        // Check if device is in silent mode (ringer off)
        // iOS doesn't provide direct API, but we can check audio session
        // For now, we'll be conservative and respect quiet hours (after Isha)
        let hour = Calendar.current.component(.hour, from: Date())
        // After 9 PM (21:00) or before 5 AM (5:00) - quiet hours
        return hour >= 21 || hour < 5
    }
    
    /// Respect silent mode and hardware support - only provide haptics if supported and not silent
    private static func shouldProvideHaptic() -> Bool {
        return supportsHaptics && !isSilentMode
    }
    
    static func light() {
        guard shouldProvideHaptic() else { return }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
    
    static func soft() {
        guard shouldProvideHaptic() else { return }
        // Very light haptic for late prayers
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.prepare()
        generator.impactOccurred(intensity: 0.5)
    }
    
    static func medium() {
        guard shouldProvideHaptic() else { return }
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }
    
    static func success() {
        guard shouldProvideHaptic() else { return }
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }
    
    static func error() {
        guard shouldProvideHaptic() else { return }
        UINotificationFeedbackGenerator().notificationOccurred(.error)
    }
    
    /// Status-specific haptic for prayer logging
    static func forPrayerStatus(_ status: PrayerStatus) {
        switch status {
        case .onTime:
            light() // Gentle for on-time
        case .late:
            soft() // Softer for late
        case .qada:
            light() // Gentle for make-up
        case .missed:
            // No haptic for missed - avoid negative reinforcement
            break
        case .prayedAtMasjid, .prayedAtHome:
            light() // Gentle for location-based
        case .menstrual:
            // No haptic for menstrual - neutral
            break
        case .none:
            break
        }
    }
}

// MARK: - Button Styles

struct SmoothButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .opacity(configuration.isPressed ? 0.88 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.8), value: configuration.isPressed)
    }
}

// MARK: - Card Style Modifier

struct CardStyle: ViewModifier {
    var padding: CGFloat = AppSpacing.lg
    
    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.secondarySystemBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(Color(.systemGray5), lineWidth: 1)
            )
    }
}

extension View {
    func cardStyle(padding: CGFloat = AppSpacing.lg) -> some View {
        modifier(CardStyle(padding: padding))
    }
}

// MARK: - Premium Card Modifier

struct PremiumCardModifier: ViewModifier {
    @Environment(\.colorScheme) var colorScheme
    
    func body(content: Content) -> some View {
        content
            .padding(AppSpacing.xl)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(.secondarySystemBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color(.separator).opacity(colorScheme == .dark ? 0.4 : 0.3), lineWidth: 0.5)
                    )
            )
            .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.15 : 0.06), radius: 10, x: 0, y: 4)
    }
}

extension View {
    func premiumCard() -> some View {
        modifier(PremiumCardModifier())
    }
}

// MARK: - Interactive Card Button Style (renamed to avoid SwiftUI conflict)

struct InteractiveCardButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .opacity(configuration.isPressed ? 0.9 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

// MARK: - Soft Shadow Modifier

struct SoftShadowModifier: ViewModifier {
    var opacity: Double = 0.08
    var radius: CGFloat = 12
    var x: CGFloat = 0
    var y: CGFloat = 4
    
    func body(content: Content) -> some View {
        content
            .shadow(color: Color.black.opacity(opacity), radius: radius, x: x, y: y)
    }
}

extension View {
    func softShadow(opacity: Double = 0.08, radius: CGFloat = 12, x: CGFloat = 0, y: CGFloat = 4) -> some View {
        modifier(SoftShadowModifier(opacity: opacity, radius: radius, x: x, y: y))
    }
}

// MARK: - Section Header

struct SectionHeader: View {
    let title: String
    var action: (() -> Void)? = nil
    var actionTitle: String = "See All"
    
    var body: some View {
        HStack {
            Text(title)
                .font(AppTypography.subheadlineBold)
                .foregroundColor(.secondary)
            
            Spacer()
            
            if let action = action {
                Button(action: action) {
                    Text(actionTitle)
                        .font(AppTypography.caption)
                        .foregroundColor(.accentColor)
                }
            }
        }
    }
}
