//
//  ErrorHandling.swift
//  Ibtida
//
//  Reusable error handling components with retry mechanisms
//

import SwiftUI

// MARK: - Error Banner

struct ErrorBanner: View {
    let message: String
    let onRetry: (() -> Void)?
    let onDismiss: (() -> Void)?
    
    @Environment(\.colorScheme) var colorScheme
    
    init(message: String, onRetry: (() -> Void)? = nil, onDismiss: (() -> Void)? = nil) {
        self.message = message
        self.onRetry = onRetry
        self.onDismiss = onDismiss
    }
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.red)
            
            Text(message)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Color.warmText(colorScheme))
                .lineLimit(2)
            
            Spacer()
            
            if let onRetry = onRetry {
                Button(action: {
                    HapticFeedback.light()
                    onRetry()
                }) {
                    Text("Retry")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.mutedGold)
                }
            }
            
            if let onDismiss = onDismiss {
                Button(action: {
                    HapticFeedback.light()
                    onDismiss()
                }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(Color.warmSecondaryText(colorScheme))
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.red.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(Color.red.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

// MARK: - Error State View

struct ErrorStateView: View {
    let title: String
    let message: String
    let onRetry: (() -> Void)?
    
    @Environment(\.colorScheme) var colorScheme
    
    init(title: String = "Something went wrong", message: String, onRetry: (() -> Void)? = nil) {
        self.title = title
        self.message = message
        self.onRetry = onRetry
    }
    
    var body: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(Color.red.opacity(0.15))
                    .frame(width: 80, height: 80)
                
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 36))
                    .foregroundColor(.red)
            }
            
            VStack(spacing: 8) {
                Text(title)
                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                    .foregroundColor(Color.warmText(colorScheme))
                
                Text(message)
                    .font(.system(size: 15))
                    .foregroundColor(Color.warmSecondaryText(colorScheme))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            
            if let onRetry = onRetry {
                Button(action: {
                    HapticFeedback.medium()
                    onRetry()
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.clockwise")
                        Text("Try Again")
                    }
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 14)
                    .background(LinearGradient.goldAccent)
                    .cornerRadius(12)
                }
                .buttonStyle(WarmButtonStyle(style: .primary))
            }
        }
        .padding(40)
        .warmCard(elevation: .medium)
    }
}

// MARK: - Loading Skeleton Views

struct PrayerCircleSkeleton: View {
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(spacing: 8) {
            Circle()
                .fill(Color.warmSurface(colorScheme).opacity(0.5))
                .frame(width: 52, height: 52)
            
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.warmSurface(colorScheme).opacity(0.5))
                .frame(width: 40, height: 12)
        }
        .frame(maxWidth: .infinity)
        .shimmering()
    }
}

struct CardSkeleton: View {
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.warmSurface(colorScheme).opacity(0.5))
                .frame(height: 16)
                .frame(maxWidth: .infinity)
            
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.warmSurface(colorScheme).opacity(0.5))
                .frame(height: 16)
                .frame(maxWidth: 200)
            
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.warmSurface(colorScheme).opacity(0.5))
                .frame(height: 16)
                .frame(maxWidth: 150)
        }
        .padding(16)
        .warmCard(elevation: .low)
        .shimmering()
    }
}

// MARK: - Offline Indicator

struct OfflineIndicator: View {
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "wifi.slash")
                .font(.system(size: 12, weight: .semibold))
            Text("Offline")
                .font(.system(size: 12, weight: .medium))
        }
        .foregroundColor(Color.warmSecondaryText(colorScheme))
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(Color.warmSurface(colorScheme))
        )
    }
}

// MARK: - Retry Button Modifier

extension View {
    func withRetry(onRetry: @escaping () -> Void) -> some View {
        self.modifier(RetryButtonModifier(onRetry: onRetry))
    }
}

struct RetryButtonModifier: ViewModifier {
    let onRetry: () -> Void
    @Environment(\.colorScheme) var colorScheme
    
    func body(content: Content) -> some View {
        content
            .overlay(alignment: .topTrailing) {
                Button(action: {
                    HapticFeedback.light()
                    onRetry()
                }) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.mutedGold)
                        .padding(8)
                        .background(
                            Circle()
                                .fill(Color.warmSurface(colorScheme))
                        )
                }
                .padding(8)
            }
    }
}
