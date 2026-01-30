//
//  SettingsView.swift
//  Ibtida
//
//  Settings screen
//

import SwiftUI
import FirebaseAuth

struct SettingsView: View {
    @EnvironmentObject var authService: AuthService
    @StateObject private var themeManager = ThemeManager.shared
    @State private var showLogoutAlert = false
    
    var body: some View {
        NavigationStack {
            Form {
                // Theme Section
                Section {
                    Picker("Theme", selection: $themeManager.appAppearanceRaw) {
                        // EXPLICIT text-based selection
                        Text("System").tag(AppAppearance.system.rawValue)
                        Text("Light").tag(AppAppearance.light.rawValue)
                        Text("Dark").tag(AppAppearance.dark.rawValue)
                    }
                    .pickerStyle(.segmented)
                    
                    Toggle(isOn: $themeManager.useWarmTheme) {
                        HStack {
                            Image(systemName: "sun.max.fill")
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Warm Theme")
                                    .font(.system(size: 16, weight: .medium))
                                Text("Use warm, earthy colors")
                                    .font(.system(size: 13))
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                } header: {
                    Text("Appearance")
                }
                
                // Account Section
                if let user = authService.user {
                    Section {
                        HStack {
                            Text("Email")
                            Spacer()
                            Text(user.email ?? "")
                                .foregroundColor(.secondary)
                        }
                        
                        Button(role: .destructive, action: {
                            showLogoutAlert = true
                        }) {
                            Text("Sign Out")
                        }
                    } header: {
                        Text("Account")
                    }
                }
                
                // About Section
                Section {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                } header: {
                    Text("About")
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .alert("Sign Out", isPresented: $showLogoutAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Sign Out", role: .destructive) {
                    authService.signOut()
                }
            } message: {
                Text("Are you sure you want to sign out?")
            }
        }
    }
}
