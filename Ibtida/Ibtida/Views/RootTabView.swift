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
    @StateObject private var duaViewModel = DuaViewModel()
    @State private var selectedTab = 0
    @State private var showDailyDuaPopup = false
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        ZStack {
            TabView(selection: $selectedTab) {
            // Tab 1: Home (Salah Tracker) - 5 prayer squares
            HomePrayerView()
                .environmentObject(authService)
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
                .tag(0)
            
            // Tab 2: Journey (Credits + Milestones)
            JourneyMilestoneView()
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
                .environmentObject(duaViewModel)
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
            
            // Dua of the Day Popup Overlay
            dailyDuaPopupOverlay
        }
        .onAppear {
            handleOnAppear()
        }
    }
    
    // MARK: - Daily Dua Popup Overlay
    
    @ViewBuilder
    private var dailyDuaPopupOverlay: some View {
        if showDailyDuaPopup, let dailyDua = duaViewModel.dailyDua {
            ZStack {
                // Background overlay - tap to dismiss
                Color.black.opacity(0.5)
                    .ignoresSafeArea()
                    .contentShape(Rectangle())
                    .onTapGesture {
                        HapticFeedback.light()
                        dismissDailyDua(reason: "background")
                    }
                
                // Daily Dua Card
                DailyDuaCard(
                    dua: dailyDua,
                    hasUserSaidAmeen: duaViewModel.hasUserSaidAmeen(for: dailyDua),
                    onAmeen: {
                        Task {
                            await duaViewModel.toggleAmeen(for: dailyDua)
                            // Dismiss after Ameen is toggled
                            await MainActor.run {
                                dismissDailyDua(reason: "ameen")
                            }
                        }
                    },
                    onDismiss: { 
                        dismissDailyDua(reason: "x")
                    }
                )
                .padding(24)
                .transition(.scale.combined(with: .opacity))
                .allowsHitTesting(true)
            }
            .zIndex(1000)
            .animation(.spring(response: 0.3), value: showDailyDuaPopup)
        }
    }
    
    // MARK: - Actions
    
    private func handleOnAppear() {
        guard authService.isLoggedIn else { return }
        
        Task {
            // Load daily dua
            await duaViewModel.loadDailyDua()
            
            // Wait a bit for UI to settle, then check if we should show the popup
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
            
            // Check if we should show the popup
            checkAndShowDailyDua()
        }
    }
    
    private func checkAndShowDailyDua() {
        // Only show if user is still logged in
        guard authService.isLoggedIn,
              let uid = authService.userUID else { return }
        
        let today = formatDate(Date())
        
        Task {
            // Check Firestore for dismissal state
            do {
                let isDismissed = try await UIStateFirestoreService.shared.isDailyDuaDismissed(uid: uid, date: today)
                
                // Also check in-memory fallback (for non-logged-in or network issues)
                let lastShown = LocalStorageService.shared.getLastDuaPopupDate()
                
                // Show popup if:
                // 1. Not dismissed in Firestore for today
                // 2. Not shown today (in-memory fallback)
                // 3. Daily dua exists
                // 4. Popup is not already showing
                if !isDismissed,
                   lastShown != today,
                   let dailyDua = duaViewModel.dailyDua,
                   !showDailyDuaPopup {
                    await MainActor.run {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            showDailyDuaPopup = true
                        }
                        // Set in-memory fallback
                        LocalStorageService.shared.setLastDuaPopupDate(today)
                        
                        // Haptic feedback for popup
                        HapticFeedback.light()
                    }
                }
            } catch {
                // Fallback to in-memory check if Firestore fails
                #if DEBUG
                print("⚠️ RootTabView: Could not check Firestore dismissal, using in-memory fallback")
                #endif
                
                let lastShown = LocalStorageService.shared.getLastDuaPopupDate()
                if lastShown != today,
                   let dailyDua = duaViewModel.dailyDua,
                   !showDailyDuaPopup {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        showDailyDuaPopup = true
                    }
                    LocalStorageService.shared.setLastDuaPopupDate(today)
                    HapticFeedback.light()
                }
            }
        }
    }
    
    private func dismissDailyDua(reason: String = "x") {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            showDailyDuaPopup = false
        }
        
        // Save dismissal to Firestore
        guard authService.isLoggedIn,
              let uid = authService.userUID else {
            // If not logged in, just use in-memory
            let today = formatDate(Date())
            LocalStorageService.shared.setLastDuaPopupDate(today)
            return
        }
        
        let today = formatDate(Date())
        
        Task {
            do {
                try await UIStateFirestoreService.shared.setDailyDuaDismissed(uid: uid, date: today, reason: reason)
            } catch {
                #if DEBUG
                print("⚠️ RootTabView: Could not save dismissal to Firestore - \(error)")
                #endif
                // Fallback to in-memory
                LocalStorageService.shared.setLastDuaPopupDate(today)
            }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}

// MARK: - Preview

#Preview {
    RootTabView()
}
