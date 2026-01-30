//
//  HomePrayerView.swift
//  Ibtida
//
//  Home (Salah Tracker) page - Warm, polished design
//

import SwiftUI

// MARK: - Prayer sheet route (single source of truth; prevents blank first tap)

private enum HomePrayerSheetRoute: Identifiable {
    case prayerStatus(PrayerType)
    var id: String {
        switch self {
        case .prayerStatus(let p): return "prayer-\(p.rawValue)"
        }
    }
}

struct HomePrayerView: View {
    @StateObject private var viewModel = HomePrayerViewModel()
    @EnvironmentObject var authService: AuthService
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.colorScheme) var colorScheme
    @State private var sheetRoute: HomePrayerSheetRoute?
    
    var body: some View {
        NavigationStack {
            ZStack {
                WarmBackgroundView()
                mainContent
            }
            .tabBarScrollClearance()
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear { handleOnAppear() }
            .refreshable { await refreshData() }
            .sheet(item: $sheetRoute) { route in
                switch route {
                case .prayerStatus(let prayer):
                    WarmPrayerStatusSheet(
                        prayer: prayer,
                        currentStatus: viewModel.todayPrayers.status(for: prayer),
                        isLoading: viewModel.isLoading,
                        onSelect: { status in
                            #if DEBUG
                            print("📥 HomePrayerView: prayer status selected \(prayer.rawValue) -> \(status.rawValue)")
                            #endif
                            Task {
                                await viewModel.updatePrayerStatus(prayer: prayer, status: status)
                            }
                            sheetRoute = nil
                        }
                    )
                    .presentationDetents([.large])
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
                Text(AppStrings.welcomeToApp)
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
            // Arabic greeting with accessibility
            Text("اَلسَلامُ عَلَيْكُم وَرَحْمَةُ اَللهِ وَبَرَكاتُهُ")
                .font(.system(size: 22, weight: .medium, design: .serif))
                .foregroundColor(Color.warmText(colorScheme))
                .multilineTextAlignment(.center)
                .environment(\.layoutDirection, .rightToLeft)
                .accessibleArabicText("اَلسَلامُ عَلَيْكُم وَرَحْمَةُ اَللهِ وَبَرَكاتُهُ", english: "Peace be upon you and the mercy and blessings of Allah")
                .dynamicTypeSize(...DynamicTypeSize.accessibility5) // Support larger text sizes
            
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
            // Header with Jumu'ah highlight for brothers on Fridays
            VStack(spacing: 8) {
                HStack {
                    WarmSectionHeader("Today's Ṣalāh", icon: "sun.max.fill", subtitle: formattedDate)
                }
                
                // Jumu'ah highlight for brothers on Fridays
                if isFriday && themeManager.userGender == .brother {
                    HStack(spacing: 8) {
                        Image(systemName: "building.columns.fill")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.mutedGold)
                        Text("Jumu'ah (Friday Prayer)")
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundColor(.mutedGold)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(Color.mutedGold.opacity(0.15))
                    )
                }
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
    
    private var isFriday: Bool {
        Calendar.current.component(.weekday, from: Date()) == 6 // Friday
    }
    
    private var prayerCirclesRow: some View {
        HStack(spacing: 8) {
            ForEach(PrayerType.allCases) { prayer in
                WarmPrayerCircle(
                    prayer: prayer,
                    status: viewModel.todayPrayers.status(for: prayer),
                    isLoading: viewModel.isSaving,
                    onTap: {
                        #if DEBUG
                        print("📤 HomePrayerView: prayer circle tapped \(prayer.rawValue)")
                        #endif
                        HapticFeedback.forPrayerStatus(viewModel.todayPrayers.status(for: prayer))
                        sheetRoute = .prayerStatus(prayer)
                    }
                )
                .environmentObject(ThemeManager.shared)
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
                Text(GentleLanguage.partialCompletionMessage(completed: completed, total: 5))
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
                todayPrayers: viewModel.todayPrayers, // Pass today's prayers for highlighting
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
    @EnvironmentObject var themeManager: ThemeManager
    @State private var isPulsing = false
    @State private var showCheckAnimation = false
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                // Circle with gentle pulse animation when logged
                ZStack {
                    Circle()
                        .fill(circleBackground)
                        .frame(width: 52, height: 52)
                        .scaleEffect(isPulsing ? 1.05 : 1.0)
                        .opacity(isPulsing ? 0.8 : 1.0)
                    
                    Circle()
                        .strokeBorder(circleBorder, lineWidth: 2.5)
                        .frame(width: 52, height: 52)
                    
                    // Status icon with soft check animation (use effectiveStatus for icon)
                    ZStack {
                        if showCheckAnimation {
                            Image(systemName: "checkmark")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(iconColor)
                                .scaleEffect(showCheckAnimation ? 1.2 : 0.8)
                                .opacity(showCheckAnimation ? 0 : 1)
                        } else {
                            Image(systemName: effectiveStatusIcon)
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(iconColor)
                        }
                    }
                }
                .animation(.easeOut(duration: 0.3), value: showCheckAnimation)
                .animation(.easeInOut(duration: 0.6).repeatCount(2, autoreverses: true), value: isPulsing)
                
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
        .onChange(of: status) { _, newStatus in
            // Trigger gentle pulse and check animation when status changes from .none
            if newStatus != .none {
                triggerPrayerLoggedAnimation()
            }
        }
    }
    
    private func triggerPrayerLoggedAnimation() {
        // Gentle pulse
        isPulsing = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            isPulsing = false
        }
        
        // Soft check animation (only for on-time)
        if status == .onTime {
            showCheckAnimation = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                showCheckAnimation = false
            }
        }
    }
    
    // Check if user is in menstrual mode (sisters only)
    private var isMenstrualMode: Bool {
        themeManager.userGender == .sister && themeManager.menstrualModeEnabled
    }
    
    // For sisters in menstrual mode: show neutral placeholder instead of "missed"
    private var effectiveStatus: PrayerStatus {
        if isMenstrualMode && status == .missed {
            return .menstrual // Show menstrual status instead of missed
        }
        return status
    }
    
    private var circleBackground: Color {
        switch effectiveStatus {
        case .none: return Color.warmSurface(colorScheme)
        case .onTime: return Color.prayerOnTime.opacity(0.15)
        case .late: return Color.prayerLate.opacity(0.15)
        case .qada: return Color.prayerQada.opacity(0.15)
        case .missed: return Color.prayerMissed.opacity(0.15)
        case .prayedAtMasjid: return Color.purple.opacity(0.15)
        case .prayedAtHome: return Color.mint.opacity(0.15)
        case .menstrual: return Color.gray.opacity(0.1) // Neutral, not red
        }
    }
    
    private var circleBorder: Color {
        switch effectiveStatus {
        case .none: return Color.warmBorder(colorScheme)
        case .onTime: return Color.prayerOnTime
        case .late: return Color.prayerLate
        case .qada: return Color.prayerQada
        case .missed: return Color.prayerMissed
        case .prayedAtMasjid: return Color.purple
        case .prayedAtHome: return Color.mint
        case .menstrual: return Color.gray.opacity(0.4) // Neutral border
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
    
    // Icon for effective status (used in display) - shows "N/A" icon for sisters
    private var effectiveStatusIcon: String {
        switch effectiveStatus {
        case .none: return prayer.icon
        case .onTime: return "checkmark"
        case .late: return "clock"
        case .qada: return "arrow.counterclockwise"
        case .missed: return "xmark"
        case .prayedAtMasjid: return "building.columns.fill"
        case .prayedAtHome: return "house.fill"
        case .menstrual: return "minus.circle.fill" // Clear "N/A" icon for sisters
        }
    }
    
    private var iconColor: Color {
        switch effectiveStatus {
        case .none: return Color.warmSecondaryText(colorScheme)
        case .onTime: return Color.prayerOnTime
        case .late: return Color.prayerLate
        case .qada: return Color.prayerQada
        case .missed: return Color.prayerMissed
        case .prayedAtMasjid: return Color.purple
        case .prayedAtHome: return Color.mint
        case .menstrual: return Color.gray.opacity(0.5) // Neutral gray
        }
    }
}

// MARK: - Warm Prayer Status Sheet

struct WarmPrayerStatusSheet: View {
    let prayer: PrayerType
    let currentStatus: PrayerStatus
    var isLoading: Bool = false
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
                    // Prayer info (always visible so sheet is never blank)
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
                                .dynamicTypeSize(...DynamicTypeSize.accessibility3) // Support larger text
                            
                            Text(prayer.arabicName)
                                .font(.system(size: 16, weight: .medium, design: .serif))
                                .foregroundColor(Color.warmSecondaryText(colorScheme))
                                .lineLimit(2)
                                .minimumScaleFactor(0.85)
                                .environment(\.layoutDirection, .rightToLeft) // RTL for Arabic
                                .dynamicTypeSize(...DynamicTypeSize.accessibility3)
                        }
                    }
                    .padding(.top, 8)
                    
                    if isLoading {
                        ProgressView()
                            .scaleEffect(1.2)
                            .tint(.mutedGold)
                            .padding(.vertical, 24)
                        Spacer(minLength: 0)
                    } else {
                        // Status options (gender-specific) - Scrollable to ensure all options visible
                        ScrollView {
                            VStack(spacing: 12) {
                                ForEach(availableStatuses, id: \.self) { status in
                                    WarmStatusOptionButton(
                                        status: status,
                                        isSelected: currentStatus == status,
                                        gender: userGender,
                                        onTap: { onSelect(status) }
                                    )
                                    .dynamicTypeSize(...DynamicTypeSize.accessibility3) // Support larger text
                                }
                                
                                // Clear option (sets .none = "Not logged")
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
                            .padding(.bottom, 24) // Extra padding to ensure last option is visible
                        }
                    }
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
        .presentationDetents([.large]) // Ensure full height, no cutoff
        .presentationDragIndicator(.visible)
    }
}

// MARK: - Warm Status Option Button

struct WarmStatusOptionButton: View {
    let status: PrayerStatus
    let isSelected: Bool
    var gender: UserGender? = nil
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
                
                // Labels - Gender-specific display (enum stored to Firestore)
                VStack(alignment: .leading, spacing: 4) {
                    Text(status.displayName(for: gender))
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundColor(Color.warmText(colorScheme))
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)
                    
                    Text(status.arabicDescription)
                        .font(.system(size: 13, weight: .medium, design: .serif))
                        .foregroundColor(Color.warmSecondaryText(colorScheme))
                        .lineLimit(2)
                        .minimumScaleFactor(0.85)
                        .environment(\.layoutDirection, .rightToLeft)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
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
        .accessibilityLabel("\(status.displayName(for: gender)), \(status.arabicDescription)")
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
