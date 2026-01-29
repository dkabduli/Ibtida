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
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Tab 1: Home (Salah Tracker) - 5 prayer squares
            HomePrayerView()
                .environmentObject(authService)
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
                .tag(0)
            
            // Tab 2: Journey (Progress dashboard: streak, credits, this week, last 5 weeks)
            JourneyView()
                .environmentObject(authService)
                .tabItem {
                    Label("Journey", systemImage: "chart.line.uptrend.xyaxis")
                }
                .tag(1)
            
            // Tab 3: Donations (contains Requests inside)
            DonationsPage()
                .environmentObject(authService)
                .tabItem {
                    Label("Donate", systemImage: "heart.fill")
                }
                .tag(2)
            
            // Tab 4: Dua Wall
            DuaWallView()
                .tabItem {
                    Label("Duas", systemImage: "hands.sparkles.fill")
                }
                .tag(3)
            
            // Tab 5: Profile
            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.fill")
                }
                .tag(4)
        }
        .accentColor(.accentColor)
    }
}

// MARK: - Preview

#Preview {
    RootTabView()
}
