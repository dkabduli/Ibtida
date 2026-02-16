//
//  RootTabView.swift
//  Ibtida
//
//  Main tab view - exactly FIVE tabs: Home, Journey, Donate, Dua, Profile.
//  Profile/Settings (and Admin when isAdmin) also reachable via toolbar in each tab.
//

import SwiftUI

private let selectedTabKey = "ibtida_selected_tab"

// Tab tags: 0 = Home, 1 = Journey, 2 = Donate, 3 = Dua, 4 = Profile
private let tabCount = 5

struct RootTabView: View {
    @EnvironmentObject var authService: AuthService
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.scenePhase) private var scenePhase
    @ObservedObject private var calendarConfig = CalendarConfigManager.shared
    @State private var selectedTab: Int = (UserDefaults.standard.object(forKey: selectedTabKey) as? Int).flatMap { $0 >= 0 && $0 < tabCount ? $0 : nil } ?? 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            HomePrayerView()
                .environmentObject(authService)
                .environmentObject(themeManager)
                .tabItem { Label("Home", systemImage: "house.fill") }
                .tag(0)
            
            JourneyView()
                .environmentObject(authService)
                .environmentObject(themeManager)
                .tabItem { Label("Journey", systemImage: "chart.line.uptrend.xyaxis") }
                .tag(1)
            
            DonationsPage()
                .environmentObject(authService)
                .environmentObject(themeManager)
                .tabItem { Label("Donate", systemImage: "heart.fill") }
                .tag(2)
            
            DuaWallView()
                .environmentObject(authService)
                .environmentObject(themeManager)
                .tabItem { Label("Dua", systemImage: "hands.sparkles.fill") }
                .tag(3)
            
            ProfileView()
                .environmentObject(authService)
                .environmentObject(themeManager)
                .tabItem { Label("Profile", systemImage: "person.circle.fill") }
                .tag(4)
        }
        .accentColor(.accentColor)
        .onAppear {
            Task { await calendarConfig.fetchIfNeeded() }
            restoreOrClampSelectedTab()
        }
        .onChange(of: selectedTab) { _, newValue in
            UserDefaults.standard.set(newValue, forKey: selectedTabKey)
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                Task { await calendarConfig.refresh() }
            }
        }
    }
    
    private func restoreOrClampSelectedTab() {
        if selectedTab < 0 || selectedTab >= tabCount {
            selectedTab = min(tabCount - 1, max(0, selectedTab))
        }
    }
}

#Preview {
    RootTabView()
        .environmentObject(AuthService.shared)
        .environmentObject(ThemeManager.shared)
}
