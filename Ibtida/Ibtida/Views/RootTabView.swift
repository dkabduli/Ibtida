//
//  RootTabView.swift
//  Ibtida
//
//  Main tab view - navigation hub for the app
//  Tab order: Home (Salah Tracker), Journey, Donations (Requests inside), Dua Wall, Profile
//

import SwiftUI

struct RootTabView: View {
    @EnvironmentObject var authService: AuthService
    @EnvironmentObject var themeManager: ThemeManager
    @State private var selectedTab = 0
    
    /// Tab indices: Home=0, Journey=1, Donate=2, Duas=3, Profile=4, Admin=5 (only when isAdmin)
    private var showAdminTab: Bool { authService.isAdmin }
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Tab 1: Home (Salah Tracker)
            HomePrayerView()
                .environmentObject(authService)
                .tabItem { Label("Home", systemImage: "house.fill") }
                .tag(0)
            
            // Tab 2: Journey
            JourneyView()
                .environmentObject(authService)
                .tabItem { Label("Journey", systemImage: "chart.line.uptrend.xyaxis") }
                .tag(1)
            
            // Tab 3: Donations (My Requests + Charities + Convert Credits)
            DonationsPage()
                .environmentObject(authService)
                .tabItem { Label("Donate", systemImage: "heart.fill") }
                .tag(2)
            
            // Tab 4: Dua Wall
            DuaWallView()
                .tabItem { Label("Duas", systemImage: "hands.sparkles.fill") }
                .tag(3)
            
            // Tab 5: Profile
            ProfileView()
                .tabItem { Label("Profile", systemImage: "person.fill") }
                .tag(4)
            
            // Tab 6: Admin (only when custom claim admin == true)
            if showAdminTab {
                AdminTabView()
                    .environmentObject(authService)
                    .tag(5)
            }
        }
        .accentColor(.accentColor)
        .onChange(of: authService.isAdmin) {
            if !authService.isAdmin && selectedTab == 5 { selectedTab = 0 }
        }
    }
}

// MARK: - Preview

#Preview {
    RootTabView()
}
