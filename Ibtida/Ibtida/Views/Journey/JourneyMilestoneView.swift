//
//  JourneyMilestoneView.swift
//  Ibtida
//
//  Journey page - Warm, polished design with milestones
//

import SwiftUI

struct JourneyMilestoneView: View {
    @StateObject private var viewModel = JourneyMilestoneViewModel()
    @EnvironmentObject var authService: AuthService
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        NavigationStack {
            ZStack {
                WarmBackgroundView()
                mainContent
            }
            .navigationTitle("Journey")
            .navigationBarTitleDisplayMode(.large)
            .onAppear { handleOnAppear() }
            .refreshable { await refreshData() }
        }
    }
    
    // MARK: - Main Content
    
    @ViewBuilder
    private var mainContent: some View {
        if !authService.isLoggedIn {
            signInPrompt
        } else if viewModel.isLoading {
            loadingView
        } else {
            scrollContent
        }
    }
    
    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.2)
                .tint(.mutedGold)
            
            Text("Loading your journey...")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(Color.warmSecondaryText(colorScheme))
        }
    }
    
    private var signInPrompt: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(Color.mutedGold.opacity(0.15))
                    .frame(width: 72, height: 72)
                
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.system(size: 32))
                    .foregroundColor(.mutedGold)
            }
            
            VStack(spacing: 8) {
                Text("Your Journey Awaits")
                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                    .foregroundColor(Color.warmText(colorScheme))
                
                Text("Sign in to track your progress")
                    .font(.system(size: 14))
                    .foregroundColor(Color.warmSecondaryText(colorScheme))
            }
        }
        .padding(32)
    }
    
    private var scrollContent: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 16) {
                // Total score hero card
                totalScoreHero
                
                // Current milestone card
                currentMilestoneCard
                
                // Progress to next
                progressToNextCard
                
                // Recent activity
                recentActivityCard
                
                // Disclaimer
                disclaimerText
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 24)
        }
    }
    
    // MARK: - Total Score Hero
    
    private var totalScoreHero: some View {
        VStack(spacing: 12) {
            // Icon with glow effect
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color.mutedGold.opacity(0.3), Color.mutedGold.opacity(0.05)],
                            center: .center,
                            startRadius: 16,
                            endRadius: 44
                        )
                    )
                    .frame(width: 72, height: 72)
                
                Circle()
                    .fill(Color.mutedGold.opacity(0.2))
                    .frame(width: 56, height: 56)
                
                Image(systemName: "star.fill")
                    .font(.system(size: 26))
                    .foregroundColor(.mutedGold)
            }
            
            // Score
            VStack(spacing: 4) {
                Text("\(viewModel.totalCredits)")
                    .font(.system(size: 38, weight: .bold, design: .rounded))
                    .foregroundColor(Color.warmText(colorScheme))
                    .minimumScaleFactor(0.7)
                
                Text("Consistency Score")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(Color.warmSecondaryText(colorScheme))
            }
            
            // Streak badge
            if viewModel.currentStreak > 0 {
                HStack(spacing: 6) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.softTerracotta)
                    
                    Text("\(viewModel.currentStreak) day streak")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(Color.warmText(colorScheme))
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(Color.softTerracotta.opacity(0.15))
                )
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .warmCard(elevation: .high)
        .accessibleCard(label: "Total consistency score: \(viewModel.totalCredits)")
    }
    
    // MARK: - Current Milestone Card
    
    private var currentMilestoneCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            WarmSectionHeader("Current Milestone", icon: "flag.fill")
            
            HStack(spacing: 12) {
                // Icon
                ZStack {
                    Circle()
                        .fill(LinearGradient.goldAccent.opacity(0.2))
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: viewModel.currentMilestone.icon)
                        .font(.system(size: 18))
                        .foregroundColor(.mutedGold)
                }
                
                // Info
                VStack(alignment: .leading, spacing: 2) {
                    Text(viewModel.currentMilestone.name)
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundColor(Color.warmText(colorScheme))
                    
                    Text(viewModel.currentMilestone.arabicName)
                        .font(.system(size: 12, weight: .medium, design: .serif))
                        .foregroundColor(Color.warmSecondaryText(colorScheme))
                }
                
                Spacer()
                
                // Achieved badge
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 22))
                    .foregroundColor(.prayerOnTime)
            }
        }
        .padding(16)
        .warmCard(elevation: .medium)
        .accessibleCard(label: "Current milestone: \(viewModel.currentMilestone.name)")
    }
    
    // MARK: - Progress to Next Card
    
    private var progressToNextCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            if let next = viewModel.nextMilestone {
                WarmSectionHeader("Next Milestone", icon: "arrow.up.circle.fill")
                
                // Next milestone info
                HStack {
                    ZStack {
                        Circle()
                            .fill(Color.warmSurface(colorScheme))
                            .frame(width: 44, height: 44)
                        
                        Image(systemName: next.icon)
                            .font(.system(size: 18))
                            .foregroundColor(Color.warmSecondaryText(colorScheme))
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(next.name)
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .foregroundColor(Color.warmText(colorScheme))
                        
                        Text(next.arabicName)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(Color.warmSecondaryText(colorScheme))
                    }
                    
                    Spacer()
                    
                    if let toGo = viewModel.creditsToNext {
                        Text("\(toGo) to go")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(Color.warmSecondaryText(colorScheme))
                    }
                }
                
                // Progress bar
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.warmSurface(colorScheme))
                            .frame(height: 14)
                        
                        RoundedRectangle(cornerRadius: 8)
                            .fill(LinearGradient.goldAccent)
                            .frame(width: geometry.size.width * viewModel.progressToNext, height: 14)
                            .animation(.spring(response: 0.5), value: viewModel.progressToNext)
                    }
                }
                .frame(height: 14)
                
                // Percentage
                Text("\(Int(viewModel.progressToNext * 100))% complete")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(Color.warmSecondaryText(colorScheme))
                
            } else {
                // Max milestone reached
                HStack(spacing: 12) {
                    Image(systemName: "crown.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.mutedGold)
                    
                    Text("You've reached the highest milestone!")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Color.warmText(colorScheme))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
            }
        }
        .padding(20)
        .warmCard(elevation: .medium)
    }
    
    // MARK: - Recent Activity Card
    
    private var recentActivityCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            WarmSectionHeader("Recent Activity", icon: "clock.fill", subtitle: "Last 7 days")
            
            if viewModel.recentDays.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "calendar.badge.plus")
                        .font(.system(size: 32))
                        .foregroundColor(Color.warmSecondaryText(colorScheme).opacity(0.5))
                    
                    Text("No prayer history yet")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(Color.warmSecondaryText(colorScheme))
                    
                    Text("Start tracking today!")
                        .font(.system(size: 14))
                        .foregroundColor(Color.warmSecondaryText(colorScheme).opacity(0.7))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
            } else {
                VStack(spacing: 10) {
                    ForEach(viewModel.recentDays) { day in
                        WarmRecentDayRow(prayerDay: day)
                    }
                }
            }
        }
        .padding(20)
        .warmCard(elevation: .medium)
    }
    
    // MARK: - Disclaimer
    
    private var disclaimerText: some View {
        Text("This score is a personal tracking metric to help you stay consistent. It does not represent actual religious reward from Allah ﷻ.")
            .font(.system(size: 13, weight: .medium))
            .foregroundColor(Color.warmSecondaryText(colorScheme).opacity(0.8))
            .multilineTextAlignment(.center)
            .padding(.horizontal, 20)
    }
    
    // MARK: - Actions
    
    private func handleOnAppear() {
        Task {
            await viewModel.loadData()
        }
    }
    
    private func refreshData() async {
        viewModel.refresh()
    }
}

// MARK: - Warm Recent Day Row

struct WarmRecentDayRow: View {
    let prayerDay: PrayerDay
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        HStack {
            // Date
            VStack(alignment: .leading, spacing: 2) {
                Text(formattedDate)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundColor(Color.warmText(colorScheme))
                
                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 10))
                        .foregroundColor(.mutedGold)
                    
                    Text("\(prayerDay.totalCreditsForDay) pts")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Color.warmSecondaryText(colorScheme))
                }
            }
            
            Spacer()
            
            // Prayer status indicators
            HStack(spacing: 6) {
                ForEach(PrayerType.allCases) { prayer in
                    Circle()
                        .fill(statusColor(for: prayerDay.status(for: prayer)))
                        .frame(width: 10, height: 10)
                }
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.warmSurface(colorScheme))
        )
    }
    
    private var formattedDate: String {
        guard let date = FirestorePaths.date(from: prayerDay.dateString) else {
            return prayerDay.dateString
        }
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE, MMM d"
        let greg = formatter.string(from: date)
        let hijri = HijriCalendarService.hijriDisplayString(for: date, method: ThemeManager.shared.hijriMethod)
        return "\(greg) · \(hijri)"
    }
    
    private func statusColor(for status: PrayerStatus) -> Color {
        switch status {
        case .none: return Color.prayerNone.opacity(0.4)
        case .onTime: return Color.prayerOnTime
        case .late: return Color.prayerLate
        case .qada: return Color.prayerQada
        case .missed: return Color.prayerMissed
        case .prayedAtMasjid: return Color.purple.opacity(0.8)
        case .prayedAtHome: return Color.mint.opacity(0.8)
        case .menstrual: return Color.red.opacity(0.7)
        case .jummah: return Color.mutedGold
        }
    }
}

// MARK: - Preview

#Preview {
    JourneyMilestoneView()
        .environmentObject(AuthService.shared)
}
