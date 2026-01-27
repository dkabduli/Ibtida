//
//  ProfileView.swift
//  Ibtida
//
//  Profile/Settings page
//

import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var authService: AuthService
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.colorScheme) var colorScheme
    @State private var userProfile: UserProfile?
    @State private var showSignOutAlert = false
    @State private var isUpdatingMenstrualMode = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                WarmBackgroundView()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Profile Section
                        profileSection
                        
                        // Stats Section
                        statsSection
                        
                        // App Section
                        appSection
                        
                        // Account Section
                        accountSection
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 32)
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.large)
            .onAppear { loadProfile() }
            .alert("Sign Out", isPresented: $showSignOutAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Sign Out", role: .destructive) {
                    authService.signOut()
                }
            } message: {
                Text("Are you sure you want to sign out?")
            }
        }
    }
    
    // MARK: - Profile Section
    
    private var profileSection: some View {
        VStack(spacing: 16) {
            HStack(spacing: 16) {
                // Avatar
                ZStack {
                    Circle()
                        .fill(LinearGradient.goldAccent.opacity(0.2))
                        .frame(width: 70, height: 70)
                    
                    Text(userProfile?.name.prefix(1).uppercased() ?? "?")
                        .font(.system(size: 28, weight: .semibold, design: .rounded))
                        .foregroundColor(.mutedGold)
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    Text(userProfile?.name ?? "Loading...")
                        .font(.system(size: 22, weight: .semibold, design: .rounded))
                        .foregroundColor(Color.warmText(colorScheme))
                    
                    Text(userProfile?.email ?? "")
                        .font(.system(size: 15))
                        .foregroundColor(Color.warmSecondaryText(colorScheme))
                }
                
                Spacer()
            }
        }
        .padding(20)
        .warmCard(elevation: .medium)
    }
    
    // MARK: - Stats Section
    
    private var statsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            WarmSectionHeader("Stats", icon: "chart.bar.fill", subtitle: nil)
            
            HStack(spacing: 12) {
                statCard(
                    icon: "star.fill",
                    title: "Credits",
                    value: "\(userProfile?.credits ?? 0)",
                    color: .mutedGold
                )
                
                statCard(
                    icon: "flame.fill",
                    title: "Streak",
                    value: "\(userProfile?.currentStreak ?? 0) days",
                    color: .softTerracotta
                )
            }
            
            statCard(
                icon: "calendar",
                title: "Member Since",
                value: userProfile?.createdAt.formatted(date: .abbreviated, time: .omitted) ?? "-",
                color: .softOlive,
                fullWidth: true
            )
        }
        .padding(20)
        .warmCard(elevation: .medium)
    }
    
    private func statCard(icon: String, title: String, value: String, color: Color, fullWidth: Bool = false) -> some View {
        VStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 44, height: 44)
                
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(color)
            }
            
            VStack(spacing: 4) {
                Text(value)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(Color.warmText(colorScheme))
                
                Text(title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Color.warmSecondaryText(colorScheme))
            }
        }
        .frame(maxWidth: fullWidth ? .infinity : nil)
        .frame(maxWidth: fullWidth ? .infinity : .infinity)
        .padding(.vertical, 16)
        .warmCard(elevation: .low)
    }
    
    // MARK: - App Section
    
    private var appSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            WarmSectionHeader("App", icon: "app.badge", subtitle: nil)
            
            // Theme Toggle
            themeToggleRow
            
            // Menstrual Mode Toggle (Sisters only)
            if userProfile?.isSister == true {
                menstrualModeToggleRow
            }
            
            VStack(spacing: 12) {
                NavigationLink(destination: AboutView()) {
                    appLinkRow(icon: "info.circle", title: "About", color: .mutedGold)
                }
                
                Link(destination: URL(string: "https://ibtida.app/privacy")!) {
                    appLinkRow(icon: "lock.shield", title: "Privacy Policy", color: .softOlive, showArrow: true)
                }
                
                Link(destination: URL(string: "https://ibtida.app/terms")!) {
                    appLinkRow(icon: "doc.text", title: "Terms of Service", color: .softOlive, showArrow: true)
                }
            }
        }
        .padding(20)
        .warmCard(elevation: .medium)
    }
    
    // MARK: - Theme Toggle
    
    private var themeToggleRow: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(Color.mutedGold.opacity(0.15))
                        .frame(width: 36, height: 36)
                    
                    Image(systemName: "paintbrush.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.mutedGold)
                }
                
                Text("Appearance")
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundColor(Color.warmText(colorScheme))
                
                Spacer()
            }
            
            Picker("Theme", selection: $themeManager.appAppearanceRaw) {
                // EXPLICIT text-based selection - no icon logic, no inversion
                // Tapping "Light" → sets light mode
                // Tapping "Dark" → sets dark mode
                // Tapping "System" → follows iOS device setting
                Text("System").tag(AppAppearance.system.rawValue)
                Text("Light").tag(AppAppearance.light.rawValue)
                Text("Dark").tag(AppAppearance.dark.rawValue)
            }
            .pickerStyle(.segmented)
            .onChange(of: themeManager.appAppearanceRaw) { _ in
                HapticFeedback.light()
                // Refresh happens automatically via ThemeManager's didSet
            }
        }
        .padding(.vertical, 8)
    }
    
    // MARK: - Menstrual Mode Toggle
    
    private var menstrualModeToggleRow: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(Color.softTerracotta.opacity(0.15))
                        .frame(width: 36, height: 36)
                    
                    Image(systemName: "moon.circle.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.softTerracotta)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Menstrual Cycle Mode")
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundColor(Color.warmText(colorScheme))
                    
                    Text("Pause streak tracking (streak-safe)")
                        .font(.system(size: 13))
                        .foregroundColor(Color.warmSecondaryText(colorScheme))
                }
                
                Spacer()
                
                Toggle("", isOn: Binding(
                    get: { userProfile?.menstrualModeEnabled ?? false },
                    set: { newValue in
                        updateMenstrualMode(enabled: newValue)
                    }
                ))
                .disabled(isUpdatingMenstrualMode)
            }
        }
        .padding(.vertical, 8)
    }
    
    private func appLinkRow(icon: String, title: String, color: Color, showArrow: Bool = false) -> some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 36, height: 36)
                
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(color)
            }
            
            Text(title)
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundColor(Color.warmText(colorScheme))
            
            Spacer()
            
            if showArrow {
                Image(systemName: "arrow.up.right")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Color.warmSecondaryText(colorScheme))
            }
        }
        .padding(.vertical, 4)
    }
    
    // MARK: - Account Section
    
    private var accountSection: some View {
        Button(action: { showSignOutAlert = true }) {
            HStack {
                Spacer()
                Text("Sign Out")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(.red)
                Spacer()
            }
            .padding(.vertical, 16)
            .warmCard(elevation: .low)
        }
    }
    
    // MARK: - Helper Methods
    
    private func loadProfile() {
        guard let uid = authService.userUID else {
            userProfile = nil
            return
        }
        
        Task {
            do {
                let profile = try await UserProfileFirestoreService.shared.loadUserProfile(uid: uid)
                await MainActor.run {
                    self.userProfile = profile
                    // Update theme manager
                    themeManager.userGender = profile?.gender
                    themeManager.menstrualModeEnabled = profile?.menstrualModeEnabled ?? false
                }
            } catch {
                #if DEBUG
                print("❌ ProfileView: Failed to load profile from Firestore - \(error)")
                #endif
            }
        }
    }
    
    private func updateMenstrualMode(enabled: Bool) {
        guard let uid = authService.userUID else { return }
        
        isUpdatingMenstrualMode = true
        HapticFeedback.light()
        
        Task {
            do {
                try await UserProfileFirestoreService.shared.updateMenstrualMode(uid: uid, enabled: enabled)
                
                // Reload profile
                let profile = try await UserProfileFirestoreService.shared.loadUserProfile(uid: uid)
                
                await MainActor.run {
                    self.userProfile = profile
                    themeManager.menstrualModeEnabled = enabled
                    isUpdatingMenstrualMode = false
                    HapticFeedback.success()
                }
                
                // Recalculate streak if needed
                if enabled {
                    try await StreakCalculator.shared.recalculateAndUpdateStreak(uid: uid)
                }
                
            } catch {
                await MainActor.run {
                    isUpdatingMenstrualMode = false
                    HapticFeedback.error()
                }
                
                #if DEBUG
                print("❌ ProfileView: Failed to update menstrual mode - \(error)")
                #endif
            }
        }
    }
}

// MARK: - About View

struct AboutView: View {
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        ZStack {
            WarmBackgroundView()
            
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(LinearGradient.goldAccent.opacity(0.2))
                                .frame(width: 100, height: 100)
                            
                            Image(systemName: "hands.sparkles.fill")
                                .font(.system(size: 50))
                                .foregroundColor(.mutedGold)
                        }
                        
                        Text("Ibtida")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundColor(Color.warmText(colorScheme))
                        
                        Text("Version 1.0")
                            .font(.system(size: 16))
                            .foregroundColor(Color.warmSecondaryText(colorScheme))
                    }
                    .padding(.vertical, 32)
                    .warmCard(elevation: .medium)
                    
                    // Description
                    VStack(alignment: .leading, spacing: 12) {
                        Text("About Ibtida")
                            .font(.system(size: 20, weight: .semibold, design: .rounded))
                            .foregroundColor(Color.warmText(colorScheme))
                        
                        Text("Ibtida is a spiritual companion app designed to help you strengthen your connection with Allah through daily duas, prayer tracking, and community support.")
                            .font(.system(size: 16))
                            .foregroundColor(Color.warmText(colorScheme))
                            .lineSpacing(4)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(20)
                    .warmCard(elevation: .medium)
                    
                    // Features
                    VStack(alignment: .leading, spacing: 16) {
                        WarmSectionHeader("Features", icon: "sparkles", subtitle: nil)
                        
                        VStack(spacing: 12) {
                            featureRow(icon: "hands.sparkles", title: "Dua Wall", description: "Share and discover duas")
                            featureRow(icon: "chart.line.uptrend.xyaxis", title: "Journey", description: "Track your spiritual progress")
                            featureRow(icon: "hand.raised", title: "Requests", description: "Ask the community for support")
                        }
                    }
                    .padding(20)
                    .warmCard(elevation: .medium)
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 32)
            }
        }
        .navigationTitle("About")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func featureRow(icon: String, title: String, description: String) -> some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color.mutedGold.opacity(0.15))
                    .frame(width: 40, height: 40)
                
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.mutedGold)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(Color.warmText(colorScheme))
                
                Text(description)
                    .font(.system(size: 14))
                    .foregroundColor(Color.warmSecondaryText(colorScheme))
            }
            
            Spacer()
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Preview

#Preview {
    ProfileView()
        .environmentObject(AuthService.shared)
}
