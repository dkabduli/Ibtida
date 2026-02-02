//
//  AppSettingsView.swift
//  Ibtida
//
//  App settings including dark mode toggle
//

import SwiftUI

struct AppSettingsView: View {
    @StateObject private var themeManager = ThemeManager.shared
    @EnvironmentObject var authService: AuthService
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.warmBackground(colorScheme).ignoresSafeArea()
                
                List {
                    appearanceSection
                    islamicCalendarSection
                    accountSection
                    aboutSection
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(.mutedGold)
                }
            }
        }
    }
    
    // MARK: - Appearance Section
    
    private var appearanceSection: some View {
        Section {
            // Appearance picker - EXPLICIT text-based selection
            // Icons are decorative only. Text labels control behavior.
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "paintbrush.fill")
                        .foregroundColor(.mutedGold)
                    Text("Appearance")
                        .font(.system(size: 16, weight: .semibold))
                }
                
                Picker("Appearance", selection: $themeManager.appAppearanceRaw) {
                    // Text labels are the selectors - explicit, no inversion
                    Text("System").tag(AppAppearance.system.rawValue)
                    Text("Light").tag(AppAppearance.light.rawValue)
                    Text("Dark").tag(AppAppearance.dark.rawValue)
                }
                .pickerStyle(.segmented)
                .onChange(of: themeManager.appAppearanceRaw) { _, _ in
                    HapticFeedback.light()
                    // Appearance change triggers refresh automatically via didSet
                }
            }
            .padding(.vertical, 8)
            .listRowBackground(Color.warmCard(colorScheme))
            
            // Warm theme toggle
            Toggle(isOn: $themeManager.useWarmTheme) {
                HStack {
                    Image(systemName: "sun.max.fill")
                        .foregroundColor(.softTerracotta)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Warm Theme")
                            .font(.system(size: 16, weight: .medium))
                        Text("Use warm, earthy colors")
                            .font(.system(size: 13))
                            .foregroundColor(Color.warmSecondaryText(colorScheme))
                    }
                }
            }
            .tint(.mutedGold)
            .listRowBackground(Color.warmCard(colorScheme))
        } header: {
            Text("APPEARANCE")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(Color.warmSecondaryText(colorScheme))
        }
    }
    
    // MARK: - Islamic Calendar Section
    
    private var islamicCalendarSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "moon.stars.fill")
                        .foregroundColor(.mutedGold)
                    Text("Hijri calendar")
                        .font(.system(size: 16, weight: .semibold))
                }
                Picker("Calculation method", selection: $themeManager.hijriMethodRaw) {
                    ForEach(HijriMethod.allCases, id: \.rawValue) { method in
                        Text(method.displayName).tag(method.rawValue)
                    }
                }
                .pickerStyle(.menu)
            }
            .padding(.vertical, 8)
            .listRowBackground(Color.warmCard(colorScheme))
        } header: {
            Text("ISLAMIC CALENDAR")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(Color.warmSecondaryText(colorScheme))
        } footer: {
            Text("Dates may vary by region (moon sighting). Islamic Civil is astronomical; Umm al-Qura is used in Saudi Arabia.")
                .font(.system(size: 12))
        }
    }
    
    // MARK: - Account Section
    
    private var accountSection: some View {
        Section {
            if authService.isLoggedIn {
                // User info
                HStack(spacing: 14) {
                    ZStack {
                        Circle()
                            .fill(Color.mutedGold.opacity(0.15))
                            .frame(width: 50, height: 50)
                        
                        Image(systemName: "person.fill")
                            .font(.system(size: 22))
                            .foregroundColor(.mutedGold)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(authService.currentUser?.displayName ?? "User")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(Color.warmText(colorScheme))
                        
                        Text(authService.currentUser?.email ?? "")
                            .font(.system(size: 14))
                            .foregroundColor(Color.warmSecondaryText(colorScheme))
                    }
                }
                .padding(.vertical, 4)
                .listRowBackground(Color.warmCard(colorScheme))
                
                // Sign out button
                Button(action: signOut) {
                    HStack {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                            .foregroundColor(.prayerMissed)
                        Text("Sign Out")
                            .foregroundColor(.prayerMissed)
                    }
                }
                .listRowBackground(Color.warmCard(colorScheme))
            } else {
                Text("Not signed in")
                    .foregroundColor(Color.warmSecondaryText(colorScheme))
                    .listRowBackground(Color.warmCard(colorScheme))
            }
        } header: {
            Text("ACCOUNT")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(Color.warmSecondaryText(colorScheme))
        }
    }
    
    // MARK: - About Section
    
    @State private var showDiagnostics = false
    @State private var diagnosticsTapCount = 0
    
    private var aboutSection: some View {
        Section {
            HStack {
                Text("Version")
                Spacer()
                Text("1.0.0")
                    .foregroundColor(Color.warmSecondaryText(colorScheme))
            }
            .listRowBackground(Color.warmCard(colorScheme))
            .onTapGesture {
                diagnosticsTapCount += 1
                if diagnosticsTapCount >= 5 {
                    showDiagnostics = true
                    diagnosticsTapCount = 0
                    HapticFeedback.medium()
                }
            }
            
            Link(destination: URL(string: "https://example.com/privacy")!) {
                HStack {
                    Text("Privacy Policy")
                        .foregroundColor(Color.warmText(colorScheme))
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(Color.warmSecondaryText(colorScheme))
                }
            }
            .listRowBackground(Color.warmCard(colorScheme))
            
            Link(destination: URL(string: "https://example.com/terms")!) {
                HStack {
                    Text("Terms of Service")
                        .foregroundColor(Color.warmText(colorScheme))
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(Color.warmSecondaryText(colorScheme))
                }
            }
            .listRowBackground(Color.warmCard(colorScheme))
        } header: {
            Text("ABOUT")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(Color.warmSecondaryText(colorScheme))
        } footer: {
            Text(AppStrings.yourIslamicPrayerCompanion)
                .font(.system(size: 12))
                .foregroundColor(Color.warmSecondaryText(colorScheme))
                .frame(maxWidth: .infinity)
                .padding(.top, 16)
        }
        .sheet(isPresented: $showDiagnostics) {
            DiagnosticsView()
        }
    }
    
    // MARK: - Actions
    
    private func signOut() {
        authService.signOut()
        dismiss()
    }
}

// MARK: - Preview

#Preview {
    AppSettingsView()
        .environmentObject(AuthService.shared)
}
