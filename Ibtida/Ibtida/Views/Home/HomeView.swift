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
                    todayPrayers: nil, // HomeView doesn't have todayPrayers - will use logs only
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
    let todayPrayers: PrayerDay? // Today's prayer day for highlighting
    let onPrayerTap: (Date, PrayerType) -> Void
    
    // Get today's dayId (timezone-aware)
    private var todayDayId: String {
        DateUtils.dayId()
    }
    
    var body: some View {
        // 5 weeks side-by-side (horizontal) - oldest to newest (current week rightmost)
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: layout.interWeekSpacing) {
                ForEach(Array(weekStarts.enumerated()), id: \.offset) { weekIndex, weekStart in
                    WeekColumn(
                        weekStart: weekStart,
                        weekDays: daysInWeek(containing: weekStart),
                        prayerLogs: prayerLogs,
                        todayPrayers: todayPrayers,
                        todayDayId: todayDayId,
                        layout: layout
                    )
                }
            }
            .padding(.horizontal, layout.horizontalPadding)
        }
        .padding(.vertical, layout.verticalPadding)
    }
    
    // MARK: - Layout Calculation
    
    struct WeekLayout {
        let circleSize: CGFloat
        let circleSpacing: CGFloat
        let rowSpacing: CGFloat
        let interWeekSpacing: CGFloat
        let horizontalPadding: CGFloat
        let verticalPadding: CGFloat
        let weekColumnWidth: CGFloat
        let labelHeight: CGFloat
    }
    
    // Optimized layout: smaller circles, better spacing, fills container properly
    private var layout: WeekLayout {
        // Smaller circles for better visual density and fill
        let circleSize: CGFloat = 12 // Reduced from 16 for better spacing
        let circleSpacing: CGFloat = 4 // Reduced from 5 for tighter but even spacing
        let rowSpacing: CGFloat = 3 // Tighter row spacing for compact grid
        let interWeekSpacing: CGFloat = AppSpacing.md // 12 - good separation between weeks
        let horizontalPadding: CGFloat = AppSpacing.sm // 8 - reduced padding
        let verticalPadding: CGFloat = AppSpacing.xs // 4 - minimal vertical padding
        let labelHeight: CGFloat = 20 // Reduced label height
        
        // Calculate week column width based on circle size and spacing
        // (7 circles * 12) + (6 gaps * 4) = 84 + 24 = 108
        let calculatedWidth = (CGFloat(7) * circleSize) + (CGFloat(6) * circleSpacing)
        let weekColumnWidth = max(calculatedWidth, 110) // Minimum 110 for comfortable spacing
        
        return WeekLayout(
            circleSize: circleSize,
            circleSpacing: circleSpacing,
            rowSpacing: rowSpacing,
            interWeekSpacing: interWeekSpacing,
            horizontalPadding: horizontalPadding,
            verticalPadding: verticalPadding,
            weekColumnWidth: weekColumnWidth,
            labelHeight: labelHeight
        )
    }
    
    // Get the last 5 week starts (Sunday-based, oldest to newest)
    private var weekStarts: [Date] {
        let weekStarts = DateUtils.lastNWeekStarts(5)
        
        // Logs moved to verbose to reduce noise (only log on first render or errors)
        #if DEBUG
        // Only log if there's an issue (week doesn't have 7 days)
        for weekStart in weekStarts {
            let days = DateUtils.daysInWeek(containing: weekStart)
            if days.count != 7 {
                print("⚠️ FiveWeekProgressView: Expected 7 days, got \(days.count) for week starting \(DateUtils.logString(for: weekStart))")
            }
        }
        #endif
        
        return weekStarts
    }
    
    private func weekStartLabel(for weekStart: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        formatter.timeZone = TimeZone.current
        return formatter.string(from: weekStart)
    }
    
    // Get all 7 days of the week (Sunday through Saturday)
    private func daysInWeek(containing weekStart: Date) -> [Date] {
        return DateUtils.daysInWeek(containing: weekStart)
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
        // Use centralized color mapping for consistency
        return PrayerStatusColors.color(for: status)
    }
}

// MARK: - Helper Views for Week Grid

struct WeekColumn: View {
    let weekStart: Date
    let weekDays: [Date]
    let prayerLogs: [PrayerLog]
    let todayPrayers: PrayerDay?
    let todayDayId: String
    let layout: FiveWeekProgressView.WeekLayout
    
    var body: some View {
        VStack(spacing: 6) {
            // Week start date label
            Text(weekStartLabel(for: weekStart))
                .font(AppTypography.captionBold)
                .foregroundColor(.primary)
                .frame(height: layout.labelHeight)
            
            // 35 circles: 7 days x 5 prayers
            VStack(spacing: layout.rowSpacing) {
                // 5 rows (prayers)
                ForEach(PrayerType.allCases, id: \.self) { prayer in
                    PrayerWeekRow(
                        weekDays: weekDays,
                        weekStart: weekStart,
                        prayer: prayer,
                        prayerLogs: prayerLogs,
                        todayPrayers: todayPrayers,
                        todayDayId: todayDayId,
                        layout: layout
                    )
                }
            }
        }
        .frame(width: layout.weekColumnWidth)
    }
    
    private func weekStartLabel(for weekStart: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        formatter.timeZone = TimeZone.current
        return formatter.string(from: weekStart)
    }
}

struct PrayerWeekRow: View {
    let weekDays: [Date]
    let weekStart: Date
    let prayer: PrayerType
    let prayerLogs: [PrayerLog]
    let todayPrayers: PrayerDay?
    let todayDayId: String
    let layout: FiveWeekProgressView.WeekLayout
    
    var body: some View {
        HStack(spacing: layout.circleSpacing) {
            // 7 columns (days)
            ForEach(Array(weekDays.enumerated()), id: \.offset) { dayIndex, day in
                PrayerDayCircle(
                    day: day,
                    dayIndex: dayIndex,
                    prayer: prayer,
                    weekStart: weekStart,
                    prayerLogs: prayerLogs,
                    todayPrayers: todayPrayers,
                    todayDayId: todayDayId,
                    layout: layout
                )
            }
        }
    }
}

struct PrayerDayCircle: View {
    let day: Date
    let dayIndex: Int
    let prayer: PrayerType
    let weekStart: Date
    let prayerLogs: [PrayerLog]
    let todayPrayers: PrayerDay?
    let todayDayId: String
    let layout: FiveWeekProgressView.WeekLayout
    
    private var dayId: String {
        DateUtils.dayId(for: day)
    }
    
    private var isToday: Bool {
        dayId == todayDayId
    }
    
    private var status: PrayerStatus {
        if isToday, let today = todayPrayers {
            return today.status(for: prayer)
        } else {
            let log = prayerLogs.first(where: { log in
                let logDayId = DateUtils.dayId(for: log.date)
                let logWeekStart = DateUtils.weekStart(for: log.date)
                return logDayId == dayId && 
                       log.prayerType == prayer &&
                       logWeekStart == weekStart
            })
            return log?.status ?? .none
        }
    }
    
    private var circleColor: Color {
        PrayerStatusColors.color(for: status)
    }
    
    private var circleSize: CGFloat {
        isToday ? layout.circleSize * 1.15 : layout.circleSize
    }
    
    var body: some View {
        Circle()
            .fill(circleColor)
            .frame(width: circleSize, height: circleSize)
            .overlay(
                Circle()
                    .stroke(
                        isToday ? circleColor.opacity(0.8) : Color(.separator).opacity(0.2),
                        lineWidth: isToday ? 2 : 0.5
                    )
            )
            .shadow(
                color: isToday ? circleColor.opacity(0.7) : Color.clear,
                radius: isToday ? 5 : 0,
                x: 0,
                y: isToday ? 2 : 0
            )
            .scaleEffect(isToday ? 1.1 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: status)
            .animation(.easeInOut(duration: 0.2), value: isToday)
            .id("\(prayer.rawValue)-\(dayIndex)")
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
