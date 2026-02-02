//
//  RootTabView.swift
//  Ibtida
//
//  Main tab view - exactly FIVE tabs: Home, Journey, Reels, Donate, Dua.
//  Profile/Settings (and Admin when isAdmin) are reached via Profile button in each tab's toolbar.
//

import SwiftUI

private let selectedTabKey = "ibtida_selected_tab"

// Tab tags: 0 = Home, 1 = Journey, 2 = Reels, 3 = Donate, 4 = Dua
private let tabCount = 5

struct RootTabView: View {
    @EnvironmentObject var authService: AuthService
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var networkMonitor: NetworkMonitor
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
            
            ReelsTabView()
                .environmentObject(authService)
                .environmentObject(themeManager)
                .environmentObject(networkMonitor)
                .tabItem { Label("Reels", systemImage: "play.rectangle.fill") }
                .tag(2)
            
            DonationsPage()
                .environmentObject(authService)
                .environmentObject(themeManager)
                .tabItem { Label("Donate", systemImage: "heart.fill") }
                .tag(3)
            
            DuaWallView()
                .environmentObject(authService)
                .environmentObject(themeManager)
                .tabItem { Label("Dua", systemImage: "hands.sparkles.fill") }
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
