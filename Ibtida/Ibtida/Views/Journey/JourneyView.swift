//
//  JourneyView.swift
//  Ibtida
//
//  Journey page - shows user's spiritual progress and stats
//

import SwiftUI
import FirebaseAuth

struct JourneyView: View {
    @State private var userProfile: UserProfile?
    @State private var isLoading = true
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Profile card
                        profileCard
                        
                        // Stats grid
                        statsGrid
                        
                        // Progress section
                        progressSection
                        
                        // Achievements (placeholder)
                        achievementsSection
                    }
                    .padding(16)
                }
            }
            .navigationTitle("Journey")
            .navigationBarTitleDisplayMode(.large)
            .onAppear { loadProfile() }
            .refreshable { loadProfile() }
        }
    }
    
    // MARK: - Profile Card
    
    private var profileCard: some View {
        VStack(spacing: 16) {
            // Avatar
            ZStack {
                Circle()
                    .fill(Color.accentColor.opacity(0.1))
                    .frame(width: 80, height: 80)
                
                Text(userProfile?.name.prefix(1).uppercased() ?? "?")
                    .font(.largeTitle.weight(.semibold))
                    .foregroundColor(.accentColor)
            }
            
            // Name
            Text(userProfile?.name ?? "Loading...")
                .font(.title2.weight(.semibold))
            
            // Email
            Text(userProfile?.email ?? "")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.secondarySystemBackground))
        )
    }
    
    // MARK: - Stats Grid
    
    private var statsGrid: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 16) {
            StatCard(
                title: "Credits",
                value: "\(userProfile?.credits ?? 0)",
                icon: "star.fill",
                color: .yellow
            )
            
            StatCard(
                title: "Streak",
                value: "\(userProfile?.currentStreak ?? 0) days",
                icon: "flame.fill",
                color: .orange
            )
        }
    }
    
    // MARK: - Progress Section
    
    private var progressSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Your Progress")
                .font(.headline)
            
            // Weekly progress
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Weekly Goal")
                        .font(.subheadline)
                    Spacer()
                    Text("25/35 prayers")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                ProgressView(value: 25, total: 35)
                    .tint(.accentColor)
                
                Text("Complete 25 prayers to earn 1 credit")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.tertiarySystemBackground))
            )
            
            // Credits progress
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Credits Balance")
                        .font(.subheadline)
                    Spacer()
                    Text("\(userProfile?.credits ?? 0)/100")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                ProgressView(value: Double(userProfile?.credits ?? 0), total: 100)
                    .tint(.yellow)
                
                Text("100 credits = $1 donation value")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.tertiarySystemBackground))
            )
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.secondarySystemBackground))
        )
    }
    
    // MARK: - Achievements Section
    
    private var achievementsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Achievements")
                .font(.headline)
            
            HStack(spacing: 16) {
                AchievementBadge(
                    icon: "star.fill",
                    title: "First Dua",
                    isUnlocked: true
                )
                
                AchievementBadge(
                    icon: "flame.fill",
                    title: "7 Day Streak",
                    isUnlocked: (userProfile?.currentStreak ?? 0) >= 7
                )
                
                AchievementBadge(
                    icon: "heart.fill",
                    title: "100 Ameen",
                    isUnlocked: false
                )
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.secondarySystemBackground))
        )
    }
    
    // MARK: - Actions
    
    private func loadProfile() {
        guard let uid = AuthService.shared.userUID else {
            userProfile = nil
            isLoading = false
            return
        }
        
        isLoading = true
        
        Task {
            do {
                let profile = try await UserProfileFirestoreService.shared.loadUserProfile(uid: uid)
                await MainActor.run {
                    self.userProfile = profile
                    self.isLoading = false
                }
            } catch {
                #if DEBUG
                print("❌ JourneyView: Failed to load profile from Firestore - \(error)")
                #endif
                await MainActor.run {
                    self.userProfile = nil
                    self.isLoading = false
                }
            }
        }
    }
}

// MARK: - Stat Card

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.1))
                    .frame(width: 50, height: 50)
                
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
            }
            
            Text(value)
                .font(.title2.weight(.semibold))
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemBackground))
        )
    }
}

// MARK: - Achievement Badge

struct AchievementBadge: View {
    let icon: String
    let title: String
    let isUnlocked: Bool
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(isUnlocked ? Color.accentColor.opacity(0.1) : Color(.systemGray5))
                    .frame(width: 50, height: 50)
                
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(isUnlocked ? .accentColor : .secondary)
            }
            
            Text(title)
                .font(.caption2)
                .foregroundColor(isUnlocked ? .primary : .secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .opacity(isUnlocked ? 1 : 0.5)
    }
}

// MARK: - Preview

#Preview {
    JourneyView()
}
