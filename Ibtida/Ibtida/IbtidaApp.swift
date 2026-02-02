//
//  IbtidaApp.swift
//  Ibtida
//
//  App entry point - handles Firebase configuration, auth routing, Stripe, and theming
//

import SwiftUI
import FirebaseCore
import Stripe

// MARK: - App Delegate

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseApp.configure()

        #if DEBUG
        print("✅ AppDelegate: Firebase configured at app launch")
        #endif

        // Stripe: set publishable key as early as possible (single source: StripeConfig)
        // PaymentSheet requires both StripeAPI.defaultPublishableKey and STPAPIClient.shared.publishableKey
        let stripeKey = StripeConfig.publishableKey
        if !stripeKey.isEmpty {
            StripeAPI.defaultPublishableKey = stripeKey
            STPAPIClient.shared.publishableKey = stripeKey
            #if DEBUG
            if stripeKey.hasPrefix("pk_test_") {
                print("🔑 Stripe: TEST mode (pk_test_...) – PaymentSheet ready")
            } else if stripeKey.hasPrefix("pk_live_") {
                print("🔑 Stripe: LIVE mode (pk_live_...) – PaymentSheet ready")
            }
            #endif
            StripeConfig.logKeyMode(stripeKey)
        } else {
            #if DEBUG
            print("❌ Stripe: publishable key missing or invalid. Set Info.plist key 'StripePublishableKey' to pk_test_... or use env STRIPE_PUBLISHABLE_KEY. Payment will fail.")
            #endif
        }

        return true
    }
}

// MARK: - Main App

@main
struct IbtidaApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var authService = AuthService.shared
    @StateObject private var themeManager = ThemeManager.shared
    @StateObject private var networkMonitor = NetworkMonitor()
    
    init() {
        // Setup auth listener after Firebase is configured
        // This happens after AppDelegate runs
        Task { @MainActor in
            AuthService.shared.setupIfNeeded()
        }
        
        #if DEBUG
        print("✅ IbtidaApp initialized")
        #endif
    }
    
    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(authService)
                .environmentObject(themeManager)
                .environmentObject(networkMonitor)
                // SINGLE POINT OF APPEARANCE CONTROL
                // This is the ONLY place preferredColorScheme is applied
                // Mapping: system → nil (follows iOS), light → .light, dark → .dark
                .preferredColorScheme(themeManager.colorScheme)
                .onChange(of: themeManager.appAppearanceRaw) { _, _ in
                    // Appearance changed - refresh UI
                    themeManager.refreshColorScheme()
                }
        }
    }
}

// MARK: - Root View

// BEHAVIOR LOCK: Auth routing; profile load and onboarding gate. See Core/BEHAVIOR_LOCK.md
struct RootView: View {
    @EnvironmentObject var authService: AuthService
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.colorScheme) var colorScheme
    
    @State private var userProfile: UserProfile?
    @State private var isLoadingProfile = false
    @State private var showOnboarding = false
    
    var body: some View {
        Group {
            if authService.isLoadingAuth {
                // Show loading while auth state is being determined
                WarmLoadingView()
            } else if authService.isLoggedIn {
                // Check if onboarding is needed
                if showOnboarding {
                    GenderOnboardingView()
                        .environmentObject(authService)
                        .onAppear {
                            loadUserProfile()
                        }
                } else if isLoadingProfile {
                    WarmLoadingView()
                } else {
                    // User is logged in and onboarded - show main app
                    RootTabView()
                        .environmentObject(authService)
                        .environmentObject(themeManager)
                }
            } else {
                // User is not logged in - show login
                LoginView()
                    .environmentObject(authService)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: authService.isLoadingAuth)
        .animation(.easeInOut(duration: 0.3), value: authService.isLoggedIn)
        .animation(.easeInOut(duration: 0.3), value: showOnboarding)
        .onChange(of: authService.isLoggedIn) { _, isLoggedIn in
            if isLoggedIn {
                loadUserProfile()
            } else {
                userProfile = nil
                showOnboarding = false
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("OnboardingCompleted"))) { _ in
            loadUserProfile()
        }
    }
    
    private func loadUserProfile() {
        guard authService.isLoggedIn,
              let uid = authService.userUID else {
            showOnboarding = false
            return
        }
        
        isLoadingProfile = true
        
        Task {
            do {
                let profile = try await UserProfileFirestoreService.shared.loadUserProfile(uid: uid)
                
                await MainActor.run {
                    self.userProfile = profile
                    
                    // Update theme manager with user gender
                    themeManager.userGender = profile?.gender
                    themeManager.menstrualModeEnabled = profile?.menstrualModeEnabled ?? false
                    
                    // Load appearance from Firestore (source of truth)
                    Task {
                        await themeManager.loadAppearanceFromFirestore()
                    }
                    
                    // Show onboarding if gender is not set or onboarding not completed
                    showOnboarding = profile?.gender == nil || !(profile?.onboardingCompleted ?? false)
                    
                    isLoadingProfile = false
                }
            } catch {
                await MainActor.run {
                    isLoadingProfile = false
                    // If we can't load profile, assume onboarding needed
                    showOnboarding = true
                }
            }
        }
    }
    
}

// MARK: - Warm Loading View

struct WarmLoadingView: View {
    @State private var isAnimating = false
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        ZStack {
            WarmBackgroundView()
            
            VStack(spacing: 28) {
                // Logo with warm styling
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [Color.mutedGold.opacity(0.25), Color.mutedGold.opacity(0.05)],
                                center: .center,
                                startRadius: 20,
                                endRadius: 60
                            )
                        )
                        .frame(width: 110, height: 110)
                        .scaleEffect(isAnimating ? 1.08 : 1.0)
                    
                    Circle()
                        .fill(Color.mutedGold.opacity(0.15))
                        .frame(width: 90, height: 90)
                    
                    Image(systemName: "hands.sparkles.fill")
                        .font(.system(size: 42))
                        .foregroundColor(.mutedGold)
                }
                .animation(
                    .easeInOut(duration: 1.2).repeatForever(autoreverses: true),
                    value: isAnimating
                )
                
                VStack(spacing: 12) {
                    Text("Ibtida")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(Color.warmText(colorScheme))
                    
                    Text("Your Prayer Companion")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(Color.warmSecondaryText(colorScheme))
                    
                    ProgressView()
                        .tint(.mutedGold)
                        .padding(.top, 8)
                }
            }
        }
        .onAppear {
            isAnimating = true
        }
    }
}

// MARK: - Legacy Loading View (for compatibility)

struct LoadingView: View {
    var body: some View {
        WarmLoadingView()
    }
}

// MARK: - Preview

#Preview("Root View") {
    RootView()
        .environmentObject(AuthService.shared)
        .environmentObject(ThemeManager.shared)
}
