//
//  HomeView.swift
//  Ibtida
//
//  Home screen with prayer tracking - fixed loading states
//

import SwiftUI

struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()
    @State private var showPrayerStatusPicker = false
    @State private var selectedPrayer: (date: Date, prayer: PrayerType)?
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: AppSpacing.xl) {
                        // Greeting
                        greetingSection
                        
                        // Tab selector (Today/Week)
                        tabSelector
                        
                        // Prayer tracking
                        if viewModel.selectedTab == .today {
                            todayQuickActions
                        } else {
                            weeklyPrayerTracker
                        }
                    }
                    .padding(.vertical, AppSpacing.lg)
                }
            }
            .navigationTitle("Home")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                Task {
                    await viewModel.loadUserProfile()
                    await viewModel.loadPrayerLogs()
                }
            }
            .sheet(isPresented: $showPrayerStatusPicker) {
                if let selected = selectedPrayer {
                    PrayerStatusPickerSheet(
                        date: selected.date,
                        prayer: selected.prayer,
                        currentStatus: viewModel.prayerLogs.first(where: { $0.date == selected.date && $0.prayerType == selected.prayer })?.status ?? .missed,
                        onSelect: { status in
                            Task {
                                await viewModel.setPrayerStatus(date: selected.date, prayer: selected.prayer, status: status)
                            }
                            showPrayerStatusPicker = false
                        }
                    )
                }
            }
        }
    }
    
    private var greetingSection: some View {
        VStack(spacing: AppSpacing.sm) {
            Text("اَلسَلامُ عَلَيْكُم وَرَحْمَةُ اَللهِ وَبَرَكاتُهُ")
                .font(AppTypography.arabicLarge)
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, AppSpacing.xl)
            
            if let profile = viewModel.userProfile {
                Text("Welcome, \(profile.name)")
                    .font(AppTypography.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppSpacing.lg)
        .cardStyle()
        .padding(.horizontal, AppSpacing.lg)
    }
    
    private var tabSelector: some View {
        HStack(spacing: AppSpacing.md) {
            ForEach(HomeViewModel.TimeRange.allCases, id: \.self) { range in
                Button(action: {
                    HapticFeedback.light()
                    withAnimation(.spring(response: 0.3)) {
                        viewModel.setSelectedTab(range)
                    }
                }) {
                    Text(range.rawValue)
                        .font(AppTypography.bodyBold)
                        .foregroundColor(viewModel.selectedTab == range ? .white : .primary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, AppSpacing.md)
                        .background(
                            Capsule()
                                .fill(viewModel.selectedTab == range ? Color.accentColor : Color(.secondarySystemBackground))
                        )
                }
                .buttonStyle(SmoothButtonStyle())
            }
        }
        .padding(.horizontal, AppSpacing.lg)
    }
    
    private var todayQuickActions: some View {
        VStack(spacing: AppSpacing.xl) {
            // Today's Prayers
            VStack(alignment: .leading, spacing: AppSpacing.md) {
                SectionHeader(title: "Today's Prayers")
                
                if !viewModel.hasLoadedOnce && viewModel.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                        .padding()
                } else {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: AppSpacing.md), count: 3), spacing: AppSpacing.md) {
                        ForEach(PrayerType.allCases) { prayer in
                            PrayerCircle(
                                prayer: prayer,
                                status: viewModel.prayerLogs.first(where: { Calendar.current.isDateInToday($0.date) && $0.prayerType == prayer })?.status ?? .missed,
                                onTap: {
                                    let today = Date()
                                    selectedPrayer = (today, prayer)
                                    showPrayerStatusPicker = true
                                }
                            )
                        }
                    }
                }
            }
            .cardStyle()
            
            // 5-Week Progress Section
            VStack(alignment: .leading, spacing: AppSpacing.md) {
                SectionHeader(title: "Last 5 Weeks")
                
                FiveWeekProgressView(
                    prayerLogs: viewModel.prayerLogs,
                    onPrayerTap: { date, prayer in
                        selectedPrayer = (date, prayer)
                        showPrayerStatusPicker = true
                    }
                )
            }
            .cardStyle()
        }
        .padding(.horizontal, AppSpacing.lg)
    }
    
    private var weeklyPrayerTracker: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            SectionHeader(title: "This Week")
            
            if !viewModel.hasLoadedOnce && viewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding()
            } else {
                // Weekly grid view
                WeeklyPrayerGridView(
                    prayerLogs: viewModel.prayerLogs,
                    onPrayerTap: { date, prayer in
                        selectedPrayer = (date, prayer)
                        showPrayerStatusPicker = true
                    }
                )
            }
        }
        .cardStyle()
        .padding(.horizontal, AppSpacing.lg)
    }
}

struct PrayerCircle: View {
    let prayer: PrayerType
    let status: PrayerStatus
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: AppSpacing.xs) {
                Text(prayer.displayName)
                    .font(AppTypography.captionBold)
                    .foregroundColor(.primary)
                
                Circle()
                    .fill(statusColor)
                    .frame(width: 50, height: 50)
                    .overlay(
                        Circle()
                            .stroke(Color(.separator), lineWidth: 1)
                    )
            }
        }
        .buttonStyle(SmoothButtonStyle())
    }
    
    private var statusColor: Color {
        switch status {
        case .none: return .gray.opacity(0.3)
        case .onTime: return .green
        case .late: return .orange
        case .missed: return .gray
        case .qada: return .blue
        case .prayedAtMasjid: return .purple
        case .prayedAtHome: return .mint
        case .menstrual: return .red.opacity(0.7)
        }
    }
}

struct WeeklyPrayerGridView: View {
    let prayerLogs: [PrayerLog]
    let onPrayerTap: (Date, PrayerType) -> Void
    @State private var showPastDayAlert = false
    
    var body: some View {
        VStack(spacing: AppSpacing.sm) {
            // Header
            HStack {
                Text("Day")
                    .font(AppTypography.captionBold)
                    .frame(maxWidth: .infinity)
                ForEach(PrayerType.allCases) { prayer in
                    Text(prayer.displayName.prefix(1))
                        .font(AppTypography.captionBold)
                        .frame(maxWidth: .infinity)
                }
            }
            
            // Rows
            ForEach(weekDays, id: \.self) { date in
                let isToday = Calendar.current.isDateInToday(date)
                let isPast = date < Calendar.current.startOfDay(for: Date())
                
                HStack {
                    HStack(spacing: AppSpacing.xs) {
                        Text(dayLabel(for: date))
                            .font(isToday ? AppTypography.captionBold : AppTypography.caption)
                            .foregroundColor(isToday ? .accentColor : .primary)
                        
                        if isToday {
                            Circle()
                                .fill(Color.accentColor)
                                .frame(width: 6, height: 6)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    
                    ForEach(PrayerType.allCases) { prayer in
                        let log = prayerLogs.first(where: { Calendar.current.isDate($0.date, inSameDayAs: date) && $0.prayerType == prayer })
                        let status = log?.status ?? .missed
                        
                        Button(action: {
                            if isToday {
                                onPrayerTap(date, prayer)
                            } else if isPast {
                                showPastDayAlert = true
                            }
                            // Future dates do nothing silently
                        }) {
                            Circle()
                                .fill(statusColor(status))
                                .frame(width: 30, height: 30)
                                .opacity(isToday ? 1.0 : 0.6)
                                .overlay(
                                    Circle()
                                        .stroke(isToday ? Color.accentColor.opacity(0.3) : Color.clear, lineWidth: 2)
                                )
                        }
                        .buttonStyle(SmoothButtonStyle())
                        .disabled(!isToday && !isPast) // Disable future days
                    }
                }
            }
        }
        .alert("Past Prayers", isPresented: $showPastDayAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("You can only update today's prayer status. Past prayers are locked.")
        }
    }
    
    private var weekDays: [Date] {
        let calendar = Calendar.current
        let now = Date()
        let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now))!
        
        return (0..<7).compactMap { dayOffset in
            calendar.date(byAdding: .day, value: dayOffset, to: weekStart)
        }
    }
    
    private func dayLabel(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: date)
    }
    
    private func statusColor(_ status: PrayerStatus) -> Color {
        switch status {
        case .none: return .gray.opacity(0.3)
        case .onTime: return .green
        case .late: return .orange
        case .missed: return .gray
        case .qada: return .blue
        case .prayedAtMasjid: return .purple
        case .prayedAtHome: return .mint
        case .menstrual: return .red.opacity(0.7)
        }
    }
}

struct FiveWeekProgressView: View {
    let prayerLogs: [PrayerLog]
    let onPrayerTap: (Date, PrayerType) -> Void
    
    var body: some View {
        VStack(spacing: AppSpacing.md) {
            // Week columns (oldest to newest, left to right - current week is rightmost)
            HStack(spacing: AppSpacing.md) {
                ForEach(weekRanges, id: \.start) { weekRange in
                    VStack(spacing: AppSpacing.sm) {
                        // Week label
                        Text(weekLabel(for: weekRange.start))
                            .font(AppTypography.captionBold)
                            .foregroundColor(.primary)
                            .frame(height: 20)
                        
                        // Prayer circles for this week (5 circles = 5 prayers)
                        VStack(spacing: 6) {
                            ForEach(PrayerType.allCases) { prayer in
                                let averageStatus = averageStatusForWeek(weekRange: weekRange, prayer: prayer)
                                
                                Circle()
                                    .fill(statusColor(averageStatus))
                                    .frame(width: 28, height: 28)
                                    .overlay(
                                        Circle()
                                            .stroke(Color(.separator).opacity(0.3), lineWidth: 0.5)
                                    )
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(.vertical, AppSpacing.sm)
    }
    
    // Get the last 5 weeks (oldest to newest, so current week is rightmost)
    private var weekRanges: [(start: Date, end: Date)] {
        let calendar = Calendar.current
        let now = Date()
        var weeks: [(start: Date, end: Date)] = []
        
        // Get current week start
        let currentWeekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now))!
        
        // Generate last 5 weeks (including current week)
        // Start from 4 weeks ago and go to current week
        for weekOffset in 0..<5 {
            let weekStart = calendar.date(byAdding: .weekOfYear, value: -weekOffset, to: currentWeekStart)!
            let weekEnd = calendar.date(byAdding: .day, value: 7, to: weekStart)!
            weeks.append((start: weekStart, end: weekEnd))
        }
        
        // Reverse so oldest is left, newest (current) is right
        return weeks.reversed()
    }
    
    private func weekLabel(for weekStart: Date) -> String {
        let formatter = DateFormatter()
        let weekEnd = Calendar.current.date(byAdding: .day, value: 6, to: weekStart)!
        
        // If same month, show "MMM d-d", else "MMM d"
        if Calendar.current.isDate(weekStart, equalTo: weekEnd, toGranularity: .month) {
            formatter.dateFormat = "d"
            let endDay = formatter.string(from: weekEnd)
            formatter.dateFormat = "MMM d"
            let start = formatter.string(from: weekStart)
            return "\(start)-\(endDay)"
        } else {
            // Just show the start date for simplicity
            formatter.dateFormat = "MMM d"
            return formatter.string(from: weekStart)
        }
    }
    
    // Calculate dominant status for a week and prayer type
    // Shows the best status achieved for that prayer during the week
    private func averageStatusForWeek(weekRange: (start: Date, end: Date), prayer: PrayerType) -> PrayerStatus {
        let logs = prayerLogs.filter { log in
            log.prayerType == prayer &&
            log.date >= weekRange.start &&
            log.date < weekRange.end
        }
        
        // If no logs, return .none
        guard !logs.isEmpty else { return .none }
        
        // Priority order: onTime > late > qada > prayedAtMasjid/prayedAtHome > menstrual > missed > none
        // Return the best status found in the week
        if logs.contains(where: { $0.status == .onTime }) {
            return .onTime
        } else if logs.contains(where: { $0.status == .late }) {
            return .late
        } else if logs.contains(where: { $0.status == .qada }) {
            return .qada
        } else if logs.contains(where: { $0.status == .prayedAtMasjid || $0.status == .prayedAtHome }) {
            return logs.first(where: { $0.status == .prayedAtMasjid || $0.status == .prayedAtHome })?.status ?? .missed
        } else if logs.contains(where: { $0.status == .menstrual }) {
            return .menstrual
        } else if logs.contains(where: { $0.status == .missed }) {
            return .missed
        } else {
            return .none
        }
    }
    
    private func statusColor(_ status: PrayerStatus) -> Color {
        switch status {
        case .none: return .gray.opacity(0.2)
        case .onTime: return .green
        case .late: return .orange
        case .missed: return .gray.opacity(0.5)
        case .qada: return .blue
        case .prayedAtMasjid: return .purple
        case .prayedAtHome: return .mint
        case .menstrual: return .red.opacity(0.7)
        }
    }
}

struct PrayerStatusPickerSheet: View {
    let date: Date
    let prayer: PrayerType
    let currentStatus: PrayerStatus
    let onSelect: (PrayerStatus) -> Void
    
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            VStack(spacing: AppSpacing.xl) {
                Text("\(prayer.displayName) - \(dayLabel(for: date))")
                    .font(AppTypography.title3)
                    .padding()
                
                VStack(spacing: AppSpacing.md) {
                    ForEach([PrayerStatus.onTime, .late, .missed, .qada], id: \.self) { status in
                        Button(action: {
                            onSelect(status)
                            dismiss()
                        }) {
                            HStack {
                                Circle()
                                    .fill(statusColor(status))
                                    .frame(width: 20, height: 20)
                                
                                Text(status.displayName)
                                    .font(AppTypography.body)
                                
                                Spacer()
                                
                                if status == currentStatus {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.accentColor)
                                }
                            }
                            .padding()
                            .background(Color(.secondarySystemBackground))
                            .cornerRadius(12)
                        }
                        .buttonStyle(SmoothButtonStyle())
                    }
                }
                .padding(.horizontal, AppSpacing.xl)
                
                Spacer()
            }
            .navigationTitle("Prayer Status")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func dayLabel(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }
    
    private func statusColor(_ status: PrayerStatus) -> Color {
        switch status {
        case .none: return .gray.opacity(0.3)
        case .onTime: return .green
        case .late: return .orange
        case .missed: return .gray
        case .qada: return .blue
        case .prayedAtMasjid: return .purple
        case .prayedAtHome: return .mint
        case .menstrual: return .red.opacity(0.7)
        }
    }
}
