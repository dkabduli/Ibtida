//
//  ProfileToolbarButton.swift
//  Ibtida
//
//  Reusable Profile/Settings toolbar button (top-right). Opens Profile & Settings.
//  Use in all five main tabs for consistent access.
//

import SwiftUI

struct ProfileToolbarButton: View {
    @EnvironmentObject var authService: AuthService
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        NavigationLink(destination: ProfileView()
            .environmentObject(authService)
            .environmentObject(themeManager)
        ) {
            Image(systemName: "person.circle.fill")
                .font(.system(size: 22, weight: .medium))
        }
        .accessibilityLabel("Profile")
        .accessibilityHint("Opens Profile and Settings")
    }
}

#Preview {
    NavigationStack {
        Text("Tab content")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    ProfileToolbarButton()
                        .environmentObject(AuthService.shared)
                        .environmentObject(ThemeManager.shared)
                }
            }
    }
}
