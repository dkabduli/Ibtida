//
//  HomePrayerView.swift
//  Ibtida
//
//  Home (Salah Tracker) page - Warm, polished design
//

import SwiftUI

struct HomePrayerView: View {
    @StateObject private var viewModel = HomePrayerViewModel()
    @EnvironmentObject var authService: AuthService
    @Environment(\.colorScheme) var colorScheme
    @State private var selectedPrayer: PrayerType?
    @State private var showStatusSheet = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                WarmBackgroundView()
                mainContent
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear { handleOnAppear() }
            .refreshable { await refreshData() }
            .sheet(isPresented: $showStatusSheet) {
                if let prayer = selectedPrayer {
                    WarmPrayerStatusSheet(
                        prayer: prayer,
                        currentStatus: viewModel.todayPrayers.status(for: prayer),
                        onSelect: { status in
                            Task {
                                await viewModel.updatePrayerStatus(prayer: prayer, status: status)
                            }
                            showStatusSheet = false
                        }
                    )
                    .presentationDetents([.medium])
                    .presentationDragIndicator(.visible)
                }
            }
        }
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
        ScrollView(showsIndicators: false) {
            VStack(spacing: 24) {
                // Error banner (if any)
                if let error = viewModel.errorMessage {
                    ErrorBanner(
                        message: error,
                        onRetry: {
                            viewModel.retry()
                        },
                        onDismiss: {
                            viewModel.errorMessage = nil
                        }
                    )
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                }
                
                // Loading skeleton or content
                if viewModel.isLoading {
                    loadingSkeleton
                } else {
                    // Arabic greeting card
                    greetingCard
                    
                    // Today's Salah section
                    todaysSalahCard
                    
                    // 5-Week Progress Section
                    fiveWeekProgressCard
                    
                    // Progress summary
                    progressSummaryCard
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, viewModel.errorMessage == nil ? 16 : 8)
            .padding(.bottom, 32)
        }
    }
    
    // MARK: - Loading Skeleton
    
    private var loadingSkeleton: some View {
        VStack(spacing: 24) {
            // Greeting skeleton
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.warmSurface(colorScheme).opacity(0.5))
                .frame(height: 120)
                .shimmering()
            
            // Prayer circles skeleton
            HStack(spacing: 8) {
                ForEach(0..<5) { _ in
                    PrayerCircleSkeleton()
                }
            }
            .padding(20)
            .warmCard(elevation: .high)
            
            // Progress summary skeleton
            HStack(spacing: 16) {
                CardSkeleton()
                CardSkeleton()
            }
        }
    }
    
    // MARK: - Sign In Prompt
    
    private var signInPrompt: some View {
        VStack(spacing: 28) {
            ZStack {
                Circle()
                    .fill(Color.mutedGold.opacity(0.15))
                    .frame(width: 100, height: 100)
                
                Image(systemName: "person.crop.circle")
                    .font(.system(size: 50))
                    .foregroundColor(.mutedGold)
            }
            
            VStack(spacing: 12) {
                Text("Welcome to Ibtida")
                    .font(.system(size: 24, weight: .semibold, design: .rounded))
                    .foregroundColor(Color.warmText(colorScheme))
                
                Text("Sign in to track your daily prayers")
                    .font(.system(size: 16))
                    .foregroundColor(Color.warmSecondaryText(colorScheme))
                    .multilineTextAlignment(.center)
            }
        }
        .padding(48)
    }
    
    // MARK: - Greeting Card
    
    private var greetingCard: some View {
        VStack(spacing: 16) {
            // Arabic greeting
            Text("اَلسَلامُ عَلَيْكُم وَرَحْمَةُ اَللهِ وَبَرَكاتُهُ")
                .font(.system(size: 22, weight: .medium, design: .serif))
                .foregroundColor(Color.warmText(colorScheme))
                .multilineTextAlignment(.center)
                .environment(\.layoutDirection, .rightToLeft)
            
            // Divider
            Rectangle()
                .fill(LinearGradient.goldAccent)
                .frame(width: 60, height: 2)
                .cornerRadius(1)
            
            // English greeting
            Text(greetingMessage)
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundColor(Color.warmSecondaryText(colorScheme))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 28)
        .padding(.horizontal, 24)
        .warmCard(elevation: .medium)
        .accessibleCard(label: "Greeting card with Islamic salutation")
    }
    
    private var greetingMessage: String {
        let hour = Calendar.current.component(.hour, from: Date())
        let name = viewModel.userName
        if hour < 12 {
            return "Good morning, \(name)"
        } else if hour < 17 {
            return "Good afternoon, \(name)"
        } else {
            return "Good evening, \(name)"
        }
    }
    
    // MARK: - Today's Salah Card
    
    private var todaysSalahCard: some View {
        VStack(spacing: 20) {
            // Header
            HStack {
                WarmSectionHeader("Today's Ṣalāh", icon: "sun.max.fill", subtitle: formattedDate)
            }
            
            // 5 Prayer circles
            prayerCirclesRow
            
            // Today's progress bar
            todayProgressBar
        }
        .padding(20)
        .warmCard(elevation: .high)
        .accessibleCard(label: "Today's prayer tracking")
    }
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d"
        return formatter.string(from: Date())
    }
    
    private var prayerCirclesRow: some View {
        HStack(spacing: 8) {
            ForEach(PrayerType.allCases) { prayer in
                WarmPrayerCircle(
                    prayer: prayer,
                    status: viewModel.todayPrayers.status(for: prayer),
                    isLoading: viewModel.isSaving,
                    onTap: {
                        HapticFeedback.medium()
                        selectedPrayer = prayer
                        showStatusSheet = true
                    }
                )
            }
        }
    }
    
    private var todayProgressBar: some View {
        let completed = PrayerType.allCases.filter { 
            viewModel.todayPrayers.status(for: $0) != .none 
        }.count
        let progress = Double(completed) / 5.0
        
        return VStack(spacing: 8) {
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.warmBorder(colorScheme))
                        .frame(height: 8)
                    
                    RoundedRectangle(cornerRadius: 6)
                        .fill(LinearGradient.goldAccent)
                        .frame(width: geometry.size.width * progress, height: 8)
                        .animation(.spring(response: 0.4), value: progress)
                }
            }
            .frame(height: 8)
            
            HStack {
                Text("\(completed)/5 logged")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(Color.warmSecondaryText(colorScheme))
                
                Spacer()
                
                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 11))
                        .foregroundColor(.mutedGold)
                    Text("\(viewModel.todayPrayers.totalCreditsForDay) pts today")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(Color.warmText(colorScheme))
                }
            }
        }
    }
    
    // MARK: - 5-Week Progress Card
    
    private var fiveWeekProgressCard: some View {
        VStack(spacing: 20) {
            // Header
            HStack {
                WarmSectionHeader("Last 5 Weeks", icon: "chart.bar.fill", subtitle: "Progress overview")
            }
            
            // 5-Week Progress View
            FiveWeekProgressView(
                prayerLogs: viewModel.prayerLogs,
                onPrayerTap: { date, prayer in
                    // Optional: Could open a detail view or sheet
                    HapticFeedback.light()
                }
            )
        }
        .padding(20)
        .warmCard(elevation: .high)
        .accessibleCard(label: "Last 5 weeks prayer progress")
    }
    
    // MARK: - Progress Summary Card
    
    private var progressSummaryCard: some View {
        HStack(spacing: 16) {
            // Total score
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(Color.mutedGold.opacity(0.15))
                        .frame(width: 48, height: 48)
                    
                    Image(systemName: "star.fill")
                        .font(.system(size: 22))
                        .foregroundColor(.mutedGold)
                }
                
                Text("\(viewModel.totalCredits)")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(Color.warmText(colorScheme))
                
                Text("Total Score")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Color.warmSecondaryText(colorScheme))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .warmCard(elevation: .low)
            .accessibleCard(label: "Total score: \(viewModel.totalCredits) points")
            
            // Streak
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(Color.softTerracotta.opacity(0.15))
                        .frame(width: 48, height: 48)
                    
                    Image(systemName: "flame.fill")
                        .font(.system(size: 22))
                        .foregroundColor(.softTerracotta)
                }
                
                Text("\(viewModel.currentStreak)")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(Color.warmText(colorScheme))
                
                Text("Day Streak")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Color.warmSecondaryText(colorScheme))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .warmCard(elevation: .low)
            .accessibleCard(label: "Current streak: \(viewModel.currentStreak) days")
        }
    }
    
    // MARK: - Actions
    
    private func handleOnAppear() {
        Task {
            await viewModel.loadTodayPrayers()
        }
    }
    
    private func refreshData() async {
        viewModel.refresh()
    }
}

// MARK: - Warm Prayer Circle

struct WarmPrayerCircle: View {
    let prayer: PrayerType
    let status: PrayerStatus
    let isLoading: Bool
    let onTap: () -> Void
    
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                // Circle
                ZStack {
                    Circle()
                        .fill(circleBackground)
                        .frame(width: 52, height: 52)
                    
                    Circle()
                        .strokeBorder(circleBorder, lineWidth: 2.5)
                        .frame(width: 52, height: 52)
                    
                    Image(systemName: statusIcon)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(iconColor)
                }
                
                // Prayer name
                Text(prayer.displayName)
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundColor(Color.warmText(colorScheme))
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(WarmPrayerCircleStyle(status: status))
        .disabled(isLoading)
        .accessiblePrayerButton(prayer: prayer, status: status)
    }
    
    private var circleBackground: Color {
        switch status {
        case .none: return Color.warmSurface(colorScheme)
        case .onTime: return Color.prayerOnTime.opacity(0.15)
        case .late: return Color.prayerLate.opacity(0.15)
        case .qada: return Color.prayerQada.opacity(0.15)
        case .missed: return Color.prayerMissed.opacity(0.15)
        case .prayedAtMasjid: return Color.purple.opacity(0.15)
        case .prayedAtHome: return Color.mint.opacity(0.15)
        case .menstrual: return Color.red.opacity(0.15)
        }
    }
    
    private var circleBorder: Color {
        switch status {
        case .none: return Color.warmBorder(colorScheme)
        case .onTime: return Color.prayerOnTime
        case .late: return Color.prayerLate
        case .qada: return Color.prayerQada
        case .missed: return Color.prayerMissed
        case .prayedAtMasjid: return Color.purple
        case .prayedAtHome: return Color.mint
        case .menstrual: return Color.red.opacity(0.7)
        }
    }
    
    private var statusIcon: String {
        switch status {
        case .none: return prayer.icon
        case .onTime: return "checkmark"
        case .late: return "clock"
        case .qada: return "arrow.counterclockwise"
        case .missed: return "xmark"
        case .prayedAtMasjid: return "building.columns.fill"
        case .prayedAtHome: return "house.fill"
        case .menstrual: return "drop.fill"
        }
    }
    
    private var iconColor: Color {
        switch status {
        case .none: return Color.warmSecondaryText(colorScheme)
        case .onTime: return Color.prayerOnTime
        case .late: return Color.prayerLate
        case .qada: return Color.prayerQada
        case .missed: return Color.prayerMissed
        case .prayedAtMasjid: return Color.purple
        case .prayedAtHome: return Color.mint
        case .menstrual: return Color.red.opacity(0.7)
        }
    }
}

// MARK: - Warm Prayer Status Sheet

struct WarmPrayerStatusSheet: View {
    let prayer: PrayerType
    let currentStatus: PrayerStatus
    let onSelect: (PrayerStatus) -> Void
    
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    
    // Get user gender from ThemeManager
    private var userGender: UserGender? {
        ThemeManager.shared.userGender
    }
    
    // Get gender-specific status options
    private var availableStatuses: [PrayerStatus] {
        if let gender = userGender {
            return gender == .brother 
                ? PrayerStatus.statusesForBrother()
                : PrayerStatus.statusesForSister()
        }
        // Default to brother options if gender not set
        return PrayerStatus.statusesForBrother()
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.warmBackground(colorScheme, gender: userGender).ignoresSafeArea()
                
                VStack(spacing: 24) {
                    // Prayer info
                    VStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(prayer.accentColor.opacity(0.15))
                                .frame(width: 72, height: 72)
                            
                            Image(systemName: prayer.icon)
                                .font(.system(size: 32))
                                .foregroundColor(prayer.accentColor)
                        }
                        
                        VStack(spacing: 4) {
                            Text(prayer.displayName)
                                .font(.system(size: 22, weight: .semibold, design: .rounded))
                                .foregroundColor(Color.warmText(colorScheme))
                            
                            Text(prayer.arabicName)
                                .font(.system(size: 16, weight: .medium, design: .serif))
                                .foregroundColor(Color.warmSecondaryText(colorScheme))
                        }
                    }
                    .padding(.top, 8)
                    
                    // Status options (gender-specific)
                    VStack(spacing: 12) {
                        ForEach(availableStatuses, id: \.self) { status in
                            WarmStatusOptionButton(
                                status: status,
                                isSelected: currentStatus == status,
                                onTap: { onSelect(status) }
                            )
                        }
                        
                        // Clear option
                        if currentStatus != .none {
                            Button(action: { onSelect(.none) }) {
                                HStack {
                                    Image(systemName: "arrow.uturn.backward")
                                    Text("Clear")
                                }
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(Color.warmSecondaryText(colorScheme))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                    
                    Spacer()
                }
            }
            .navigationTitle("Log Prayer")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(.mutedGold)
                }
            }
        }
    }
}

// MARK: - Warm Status Option Button

struct WarmStatusOptionButton: View {
    let status: PrayerStatus
    let isSelected: Bool
    let onTap: () -> Void
    
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Icon
                ZStack {
                    Circle()
                        .fill(statusColor.opacity(0.15))
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: status.icon)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(statusColor)
                }
                
                // Labels
                VStack(alignment: .leading, spacing: 2) {
                    Text(status.displayName)
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundColor(Color.warmText(colorScheme))
                    
                    Text(status.arabicDescription)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(Color.warmSecondaryText(colorScheme))
                }
                
                Spacer()
                
                // Points
                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 11))
                        .foregroundColor(.mutedGold)
                    Text("+\(status.xpValue)")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Color.warmSecondaryText(colorScheme))
                }
                
                // Selection indicator
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 22))
                        .foregroundColor(.mutedGold)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(isSelected ? statusColor.opacity(0.08) : Color.warmCard(colorScheme))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .strokeBorder(isSelected ? statusColor : Color.warmBorder(colorScheme), lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(SmoothButtonStyle())
        .accessibilityLabel("\(status.displayName), \(status.arabicDescription)")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
    
    private var statusColor: Color {
        switch status {
        case .none: return Color.prayerNone
        case .onTime: return Color.prayerOnTime
        case .late: return Color.prayerLate
        case .qada: return Color.prayerQada
        case .missed: return Color.prayerMissed
        case .prayedAtMasjid: return Color.purple
        case .prayedAtHome: return Color.mint
        case .menstrual: return Color.red.opacity(0.7)
        }
    }
}

// MARK: - Preview

#Preview {
    HomePrayerView()
        .environmentObject(AuthService.shared)
}
