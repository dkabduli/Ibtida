//
//  JourneyHomeView.swift
//  Ibtida
//
//  First tab - Journey Home with 5 squares, week progress, month progress
//  Broken into small subviews to avoid compiler type-check issues
//

import SwiftUI

struct JourneyHomeView: View {
    @StateObject private var viewModel = JourneyProgressViewModel()
    @EnvironmentObject var authService: AuthService
    
    var body: some View {
        NavigationStack {
            ZStack {
                backgroundLayer
                mainContent
            }
            .navigationTitle("Home")
            .navigationBarTitleDisplayMode(.large)
            .onAppear { handleOnAppear() }
            .refreshable { await refreshData() }
        }
    }
    
    // MARK: - Background
    
    private var backgroundLayer: some View {
        Color(.systemGroupedBackground)
            .ignoresSafeArea()
    }
    
    // MARK: - Main Content
    
    @ViewBuilder
    private var mainContent: some View {
        if !authService.isLoggedIn {
            signInPrompt
        } else {
            scrollContent
        }
    }
    
    private var scrollContent: some View {
        ScrollView {
            VStack(spacing: AppSpacing.xl) {
                // Greeting
                greetingSection
                
                // 5 Squares Row
                fiveSquaresSection
                
                // Current Week Section
                currentWeekSection
                
                // Month Progress Tab
                monthProgressSection
                
                // Quick Stats
                quickStatsSection
            }
            .padding(AppSpacing.lg)
        }
    }
    
    // MARK: - Sign In Prompt
    
    private var signInPrompt: some View {
        VStack(spacing: 24) {
            Image(systemName: "person.crop.circle.badge.questionmark")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            Text("Sign In Required")
                .font(.title2.weight(.semibold))
            
            Text("Please sign in to track your journey")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(40)
    }
    
    // MARK: - Greeting Section
    
    private var greetingSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("اَلسَلامُ عَلَيْكُم")
                .font(.system(size: 28, weight: .semibold, design: .serif))
                .foregroundColor(.primary)
            
            Text(greetingMessage)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.bottom, 8)
    }
    
    private var greetingMessage: String {
        let hour = Calendar.current.component(.hour, from: Date())
        if hour < 12 {
            return "Good morning, \(viewModel.userProfile?.name ?? "Friend")"
        } else if hour < 17 {
            return "Good afternoon, \(viewModel.userProfile?.name ?? "Friend")"
        } else {
            return "Good evening, \(viewModel.userProfile?.name ?? "Friend")"
        }
    }
    
    // MARK: - Actions
    
    private func handleOnAppear() {
        viewModel.loadAllData()
    }
    
    private func refreshData() async {
        viewModel.loadAllData()
    }
}

// MARK: - Five Squares Section

private extension JourneyHomeView {
    var fiveSquaresSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text("Daily Progress")
                .font(AppTypography.subheadlineBold)
                .foregroundColor(.secondary)
            
            FiveSquaresRow(
                slots: viewModel.weekProgress?.slots ?? [false, false, false, false, false],
                isLoading: viewModel.isLoadingWeek,
                onToggle: { index in
                    Task {
                        await viewModel.toggleSlot(index: index)
                    }
                }
            )
        }
    }
}

// MARK: - Current Week Section

private extension JourneyHomeView {
    var currentWeekSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            HStack {
                Text("Current Week")
                    .font(AppTypography.title3)
                
                Spacer()
                
                Text(viewModel.weekDateRange)
                    .font(AppTypography.caption)
                    .foregroundColor(.secondary)
            }
            
            CurrentWeekCard(
                weekProgress: viewModel.weekProgress,
                isLoading: viewModel.isLoadingWeek
            )
        }
    }
}

// MARK: - Month Progress Section

private extension JourneyHomeView {
    var monthProgressSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text("Monthly Progress")
                .font(AppTypography.subheadlineBold)
                .foregroundColor(.secondary)
            
            MonthProgressCard(
                monthProgress: viewModel.monthProgress,
                isLoading: viewModel.isLoadingMonth
            )
        }
    }
}

// MARK: - Quick Stats Section

private extension JourneyHomeView {
    var quickStatsSection: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: AppSpacing.md) {
            QuickStatCard(
                title: "Credits",
                value: "\(viewModel.userProfile?.credits ?? 0)",
                icon: "star.fill",
                color: .yellow
            )
            
            QuickStatCard(
                title: "Streak",
                value: "\(viewModel.userProfile?.currentStreak ?? 0) days",
                icon: "flame.fill",
                color: .orange
            )
        }
    }
}

// MARK: - Five Squares Row Component

struct FiveSquaresRow: View {
    let slots: [Bool]
    let isLoading: Bool
    let onToggle: (Int) -> Void
    
    var body: some View {
        HStack(spacing: AppSpacing.sm) {
            ForEach(0..<5, id: \.self) { index in
                ProgressSquare(
                    isCompleted: index < slots.count ? slots[index] : false,
                    isLoading: isLoading,
                    dayLabel: dayLabel(for: index),
                    onTap: {
                        onToggle(index)
                    }
                )
            }
        }
    }
    
    private func dayLabel(for index: Int) -> String {
        let days = ["S", "M", "T", "W", "T"]
        return days[index]
    }
}

// MARK: - Progress Square Component

struct ProgressSquare: View {
    let isCompleted: Bool
    let isLoading: Bool
    let dayLabel: String
    let onTap: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            onTap()
        }) {
            squareContent
        }
        .buttonStyle(SquareButtonStyle())
        .disabled(isLoading)
    }
    
    private var squareContent: some View {
        VStack(spacing: 6) {
            // Circle button
            ZStack {
                Circle()
                    .fill(isCompleted ? Color.accentColor : Color(.tertiarySystemBackground))
                    .frame(width: 36, height: 36)
                
                Circle()
                    .strokeBorder(
                        isCompleted ? Color.accentColor : Color(.systemGray4),
                        lineWidth: 2
                    )
                    .frame(width: 36, height: 36)
                
                if isCompleted {
                    Image(systemName: "checkmark")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                }
                
                if isLoading {
                    ProgressView()
                        .scaleEffect(0.6)
                }
            }
            
            // Day label
            Text(dayLabel)
                .font(AppTypography.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(
                    isCompleted ? Color.accentColor.opacity(0.3) : Color(.systemGray5),
                    lineWidth: 1
                )
        )
    }
}

// MARK: - Square Button Style

struct SquareButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

// MARK: - Current Week Card

struct CurrentWeekCard: View {
    let weekProgress: WeekProgress?
    let isLoading: Bool
    
    var body: some View {
        VStack(spacing: AppSpacing.lg) {
            // Progress bar
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                HStack {
                    Text("Progress")
                        .font(AppTypography.subheadline)
                    
                    Spacer()
                    
                    Text("\(weekProgress?.completedCount ?? 0)/\(weekProgress?.totalSlots ?? 5)")
                        .font(AppTypography.subheadlineBold)
                        .foregroundColor(.accentColor)
                }
                
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        // Background
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color(.tertiarySystemBackground))
                            .frame(height: 12)
                        
                        // Progress
                        RoundedRectangle(cornerRadius: 6)
                            .fill(
                                LinearGradient(
                                    colors: [Color.accentColor, Color.accentColor.opacity(0.8)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: progressWidth(geometry: geometry), height: 12)
                            .animation(.spring(response: 0.4), value: weekProgress?.completedCount)
                    }
                }
                .frame(height: 12)
            }
            
            // Status message
            statusMessage
        }
        .padding(AppSpacing.lg)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(Color(.systemGray5), lineWidth: 1)
        )
    }
    
    private func progressWidth(geometry: GeometryProxy) -> CGFloat {
        guard let progress = weekProgress else { return 0 }
        let ratio = CGFloat(progress.completedCount) / CGFloat(max(progress.totalSlots, 1))
        return geometry.size.width * ratio
    }
    
    @ViewBuilder
    private var statusMessage: some View {
        let completed = weekProgress?.completedCount ?? 0
        
        HStack(spacing: AppSpacing.sm) {
            Image(systemName: statusIcon(for: completed))
                .foregroundColor(statusColor(for: completed))
            
            Text(statusText(for: completed))
                .font(AppTypography.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private func statusIcon(for completed: Int) -> String {
        switch completed {
        case 0: return "circle.dashed"
        case 1...2: return "circle.lefthalf.filled"
        case 3...4: return "circle.inset.filled"
        case 5: return "checkmark.circle.fill"
        default: return "circle"
        }
    }
    
    private func statusColor(for completed: Int) -> Color {
        switch completed {
        case 0: return .secondary
        case 1...2: return .orange
        case 3...4: return .blue
        case 5: return .green
        default: return .secondary
        }
    }
    
    private func statusText(for completed: Int) -> String {
        switch completed {
        case 0: return "Tap a circle to track your progress"
        case 1...2: return "Keep going! You're making progress"
        case 3...4: return "Almost there! Just a few more to go"
        case 5: return "Amazing! You completed this week!"
        default: return ""
        }
    }
}

// MARK: - Month Progress Card

struct MonthProgressCard: View {
    let monthProgress: MonthProgress?
    let isLoading: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            // Month name
            HStack {
                Image(systemName: "calendar")
                    .foregroundColor(.accentColor)
                
                Text(monthProgress?.monthName ?? "Loading...")
                    .font(AppTypography.bodyBold)
                
                Spacer()
                
                Text("\(monthProgress?.completedDays ?? 0)/\(monthProgress?.totalDays ?? 31)")
                    .font(AppTypography.caption)
                    .foregroundColor(.secondary)
            }
            
            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(.tertiarySystemBackground))
                        .frame(height: 8)
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.trustGreen)
                        .frame(width: monthProgressWidth(geometry: geometry), height: 8)
                        .animation(.spring(response: 0.4), value: monthProgress?.completedDays)
                }
            }
            .frame(height: 8)
            
            // Percentage
            if let progress = monthProgress {
                let percentage = Int(progress.progressPercentage * 100)
                Text("\(percentage)% of the month completed")
                    .font(AppTypography.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(AppSpacing.lg)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(Color(.systemGray5), lineWidth: 1)
        )
    }
    
    private func monthProgressWidth(geometry: GeometryProxy) -> CGFloat {
        guard let progress = monthProgress else { return 0 }
        return geometry.size.width * CGFloat(progress.progressPercentage)
    }
}

// MARK: - Quick Stat Card

struct QuickStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: AppSpacing.md) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 44, height: 44)
                
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(color)
            }
            
            Text(value)
                .font(AppTypography.title3)
            
            Text(title)
                .font(AppTypography.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(AppSpacing.lg)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(Color(.systemGray5), lineWidth: 1)
        )
    }
}

// MARK: - Preview

#Preview {
    JourneyHomeView()
        .environmentObject(AuthService.shared)
}
