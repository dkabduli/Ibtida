//
//  EmptyStates.swift
//  Ibtida
//
//  Consistent empty state views across the app
//

import SwiftUI

// MARK: - Generic Empty State (with optional action)

struct GenericEmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    let actionTitle: String?
    let action: (() -> Void)?
    
    @Environment(\.colorScheme) var colorScheme
    
    init(
        icon: String,
        title: String,
        message: String,
        actionTitle: String? = nil,
        action: (() -> Void)? = nil
    ) {
        self.icon = icon
        self.title = title
        self.message = message
        self.actionTitle = actionTitle
        self.action = action
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // Icon
            ZStack {
                Circle()
                    .fill(Color.accentGold(colorScheme, gender: nil).opacity(0.1))
                    .frame(width: 80, height: 80)
                
                Image(systemName: icon)
                    .font(.system(size: 32, weight: .medium))
                    .foregroundColor(Color.accentGold(colorScheme, gender: nil))
            }
            
            // Text
            VStack(spacing: 8) {
                Text(title)
                    .font(SemanticTypography.title3)
                    .foregroundColor(Color.textPrimary(colorScheme))
                
                Text(message)
                    .font(SemanticTypography.body)
                    .foregroundColor(Color.textSecondary(colorScheme))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            
            // Action button
            if let actionTitle = actionTitle, let action = action {
                Button(action: action) {
                    Text(actionTitle)
                        .font(SemanticTypography.subheadlineBold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(
                            Capsule()
                                .fill(LinearGradient.goldAccent)
                        )
                }
                .padding(.top, 8)
            }
        }
        .padding(.vertical, 48)
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Specific Empty States

struct EmptyDuasView: View {
    let onCreateDua: (() -> Void)?
    
    var body: some View {
        GenericEmptyStateView(
            icon: "hands.sparkles",
            title: "No duas yet",
            message: "Be the first to share a dua with the community",
            actionTitle: onCreateDua != nil ? "Submit a Dua" : nil,
            action: onCreateDua
        ) 
    }
}

struct EmptyRequestsView: View {
    let onCreateRequest: (() -> Void)?
    
    var body: some View {
        GenericEmptyStateView(
            icon: "heart.fill",
            title: "No requests yet",
            message: "Community requests will appear here",
            actionTitle: onCreateRequest != nil ? "Create Request" : nil,
            action: onCreateRequest
        )
    }
}

struct EmptyDonationsView: View {
    var body: some View {
        GenericEmptyStateView(
            icon: "creditcard.fill",
            title: "No donations yet",
            message: "Your donation history will appear here"
        )
    }
}

struct EmptyJourneyView: View {
    var body: some View {
        GenericEmptyStateView(
            icon: "chart.line.uptrend.xyaxis",
            title: "Start your journey",
            message: "Log your prayers to begin tracking your spiritual progress"
        )
    }
}

#Preview {
    VStack(spacing: 32) {
        EmptyDuasView(onCreateDua: {})
        EmptyRequestsView(onCreateRequest: {})
    }
    .padding()
}
