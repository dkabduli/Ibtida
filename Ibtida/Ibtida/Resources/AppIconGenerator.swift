//
//  AppIconGenerator.swift
//  Ibtida
//
//  Helper view to generate App Icon from existing logo design
//  Use this in Xcode Preview to export icon images
//

import SwiftUI

/// App Icon view matching the exact logo from WarmLoadingView
struct AppIconView: View {
    let colorScheme: ColorScheme
    
    init(colorScheme: ColorScheme = .light) {
        self.colorScheme = colorScheme
    }
    
    var body: some View {
        ZStack {
            // Background - warm neutral (matches app theme)
            backgroundColor
                .ignoresSafeArea()
            
            VStack(spacing: 28) {
                // Logo icon (matching WarmLoadingView exactly)
                ZStack {
                    // Outer gradient circle (matches WarmLoadingView)
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color.mutedGold.opacity(0.25),
                                    Color.mutedGold.opacity(0.05)
                                ],
                                center: .center,
                                startRadius: 20,
                                endRadius: 60
                            )
                        )
                        .frame(width: 110, height: 110)
                    
                    // Inner circle (matches WarmLoadingView)
                    Circle()
                        .fill(Color.mutedGold.opacity(0.15))
                        .frame(width: 90, height: 90)
                    
                    // Central icon (matches WarmLoadingView)
                    Image(systemName: "hands.sparkles.fill")
                        .font(.system(size: 42, weight: .medium))
                        .foregroundColor(.mutedGold)
                }
                
                // App name (matches WarmLoadingView exactly)
                Text("Ibtida")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(textColor)
                
                // Tagline (matches WarmLoadingView exactly)
                Text("Your Prayer Companion")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(secondaryTextColor)
            }
            .padding(60) // Generous padding to prevent edge clipping (App Store requirement)
        }
        .frame(width: 1024, height: 1024) // Standard App Icon size
    }
    
    private var backgroundColor: Color {
        switch colorScheme {
        case .light:
            return Color.warmCream
        case .dark:
            return Color(red: 0.15, green: 0.15, blue: 0.18) // Dark neutral
        @unknown default:
            return Color.warmCream
        }
    }
    
    private var textColor: Color {
        Color.warmText(colorScheme)
    }
    
    private var secondaryTextColor: Color {
        Color.warmSecondaryText(colorScheme)
    }
}

// MARK: - Preview (for exporting)

#Preview("App Icon - Light") {
    AppIconView(colorScheme: .light)
}

#Preview("App Icon - Dark") {
    AppIconView(colorScheme: .dark)
}
