//
//  JourneyView.swift
//  Ibtida
//
//  Journey progress dashboard: header summary, this week, last 5 weeks, milestones.
//  Layout and typography aligned with Home (DesignSystem, AppSpacing, WarmSectionHeader).
//

import SwiftUI

// MARK: - Journey Layout (matches Home horizontal padding and spacing)

private enum JourneyLayout {
    /// Horizontal padding for content; slightly more than Home so boxes don't feel cut off
    static let horizontalPadding: CGFloat = 24
    /// Vertical spacing between sections; matches HomePrayerView VStack spacing (24)
    static let sectionSpacing: CGFloat = 24
    /// Internal card padding; slightly reduced so cards fit comfortably
    static let cardPadding: CGFloat = 18
    /// Summary bubble grid: same column count as Home prayer circles (3)
    static let summaryColumnCount = 3
    /// Grid spacing; DesignSystem AppSpacing.md (12)
    static let gridSpacing: CGFloat = AppSpacing.md
    /// Max width per summary bubble; kept smaller so 3 fit on screen without clipping
    static let summaryBubbleMaxWidth: CGFloat = 140
    /// Min width per summary bubble on small phones
    static let summaryBubbleMinWidth: CGFloat = 76
    /// Last-5-weeks card width (horizontal scroller); slightly smaller to fit page
    static let weekCardWidth: CGFloat = 128
    /// Bottom padding inside scroll content (matches Home .padding(.bottom, 32))
    static let bottomInset: CGFloat = 32
}

struct JourneyView: View {
    @StateObject private var viewModel = JourneyViewModel(prayerService: PrayerLogFirestoreService.shared, profileService: UserProfileFirestoreService.shared)
    @EnvironmentObject var authService: AuthService
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        NavigationStack {
            ZStack {
                WarmBackgroundView()
                mainContent
            }
            .tabBarScrollClearance()
            .navigationTitle("Journey")
            .navigationBarTitleDisplayMode(.large)
            .onAppear { viewModel.loadIfNeeded() }
            .refreshable { viewModel.refresh() }
            .sheet(item: $viewModel.activeSheetRoute) { _ in
                if let detail = viewModel.activeDayDetail {
                    JourneyDayDetailSheet(detail: detail, onDismiss: { viewModel.dismissSheet() })
                }
            }
            .overlay(alignment: .top) {
                if let message = viewModel.errorMessage {
                    errorBanner(message)
                }
            }
        }
    }

    // MARK: - Main Content

    @ViewBuilder
    private var mainContent: some View {
        if !authService.isLoggedIn {
            signInPrompt
        } else if viewModel.loadState == .loading && viewModel.currentWeek == nil {
            skeletonView
        } else {
            scrollContent
        }
    }

    // MARK: - Sign-in prompt (matches HomePrayerView signInPrompt styling)

    private var signInPrompt: some View {
        VStack(spacing: 28) {
            ZStack {
                Circle()
                    .fill(Color.mutedGold.opacity(0.15))
                    .frame(width: 100, height: 100)
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.system(size: 50))
                    .foregroundColor(.mutedGold)
            }
            VStack(spacing: 12) {
                Text("Your Journey Awaits")
                    .font(AppTypography.title2)
                    .foregroundColor(Color.warmText(colorScheme))
                Text("Sign in to track your progress")
                    .font(AppTypography.subheadline)
                    .foregroundColor(Color.warmSecondaryText(colorScheme))
                    .multilineTextAlignment(.center)
            }
        }
        .padding(48)
    }

    // MARK: - Skeleton (same layout as main content; matches Home spacing and proportions)

    private var skeletonView: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: JourneyLayout.sectionSpacing) {
                // Header placeholder: subtitle + 3 summary bubbles
                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.warmSurface(colorScheme).opacity(0.5))
                        .frame(width: 220, height: 16)
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: JourneyLayout.gridSpacing), count: JourneyLayout.summaryColumnCount), spacing: JourneyLayout.gridSpacing) {
                        ForEach(0..<3, id: \.self) { _ in
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.warmSurface(colorScheme).opacity(0.5))
                                .frame(minWidth: JourneyLayout.summaryBubbleMinWidth, maxWidth: JourneyLayout.summaryBubbleMaxWidth)
                                .frame(minHeight: 56)
                        }
                    }
                }
                // Current week card placeholder
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.warmSurface(colorScheme).opacity(0.5))
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: 100)
                // Last 5 weeks placeholder
                VStack(alignment: .leading, spacing: AppSpacing.md) {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.warmSurface(colorScheme).opacity(0.5))
                        .frame(width: 120, height: 18)
                    ScrollView(.horizontal, showsIndicators: false) {
                        LazyHStack(alignment: .top, spacing: JourneyLayout.gridSpacing) {
                            ForEach(0..<3, id: \.self) { _ in
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.warmSurface(colorScheme).opacity(0.5))
                                    .frame(minWidth: JourneyLayout.weekCardWidth, maxWidth: JourneyLayout.weekCardWidth, minHeight: 80)
                            }
                        }
                        .padding(.trailing, JourneyLayout.horizontalPadding)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                Color.clear.frame(height: 1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, JourneyLayout.horizontalPadding)
            .padding(.top, AppSpacing.lg)
            .padding(.bottom, JourneyLayout.bottomInset)
        }
    }

    // MARK: - Scroll content (single root ScrollView; same spacing as Home)

    private var scrollContent: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: JourneyLayout.sectionSpacing) {
                HeaderSection
                CurrentWeekProgressCard
                Last5WeeksScroller
                MilestonesSection
                BottomPaddingSpacer
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, JourneyLayout.horizontalPadding)
            .padding(.top, AppSpacing.lg)
            .padding(.bottom, JourneyLayout.bottomInset)
        }
    }

    // MARK: - BottomPaddingSpacer (ensures last content clears tab bar when scrolled)
    private var BottomPaddingSpacer: some View {
        Color.clear.frame(height: 1)
    }

    // MARK: - HeaderSection (subtitle + summary grid; title in nav bar; same typography as Home)
    private var HeaderSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("Your prayer consistency over time")
                .font(AppTypography.subheadline)
                .foregroundColor(Color.warmSecondaryText(colorScheme))
                .fixedSize(horizontal: false, vertical: true)
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: JourneyLayout.gridSpacing), count: JourneyLayout.summaryColumnCount), spacing: JourneyLayout.gridSpacing) {
                compactCard(
                    icon: "flame.fill",
                    value: "\(viewModel.userSummary.streakDays)",
                    label: "Streak",
                    color: .softTerracotta
                )
                compactCard(
                    icon: "star.fill",
                    value: "\(viewModel.userSummary.credits)",
                    label: "Credits",
                    color: .mutedGold
                )
                if let week = viewModel.currentWeek {
                    compactCard(
                        icon: "checkmark.circle.fill",
                        value: "\(week.completedCount)/\(week.totalCount)",
                        label: "This week",
                        color: .prayerOnTime
                    )
                } else {
                    compactCard(
                        icon: "checkmark.circle.fill",
                        value: "0/35",
                        label: "This week",
                        color: .prayerOnTime
                    )
                }
            }
            .padding(.top, AppSpacing.xs)
            if let updated = viewModel.lastUpdated {
                Text(relativeTimeString(from: updated))
                    .font(AppTypography.caption)
                    .foregroundColor(Color.warmSecondaryText(colorScheme).opacity(0.8))
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Journey summary: \(viewModel.userSummary.streakDays) day streak, \(viewModel.userSummary.credits) credits")
    }

    private func relativeTimeString(from date: Date) -> String {
        let s = Int(-date.timeIntervalSinceNow)
        if s < 10 { return "Last updated: Just now" }
        if s < 60 { return "Last updated: \(s)s ago" }
        let m = s / 60
        if m < 60 { return "Last updated: \(m) min ago" }
        let h = m / 60
        if h < 24 { return "Last updated: \(h) hr ago" }
        return "Last updated: \(h / 24) day ago"
    }

    private func compactCard(icon: String, value: String, label: String, color: Color) -> some View {
        VStack(spacing: AppSpacing.xs) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(color)
            Text(value)
                .font(AppTypography.title3)
                .foregroundColor(Color.warmText(colorScheme))
                .lineLimit(1)
                .minimumScaleFactor(0.65)
            Text(label)
                .font(AppTypography.caption)
                .foregroundColor(Color.warmSecondaryText(colorScheme))
        }
        .frame(minWidth: JourneyLayout.summaryBubbleMinWidth, maxWidth: JourneyLayout.summaryBubbleMaxWidth)
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppSpacing.sm + 2)
        .padding(.horizontal, AppSpacing.sm)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.warmSurface(colorScheme))
        )
    }

    // MARK: - CurrentWeekProgressCard (same card padding as Home; WarmSectionHeader)

    private var CurrentWeekProgressCard: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            WarmSectionHeader("This Week", icon: "calendar")
            if let week = viewModel.currentWeek {
                if hasNoLogsAtAll(week: week) {
                    emptyStateCard
                } else {
                    weekGrid(week: week)
                }
            } else {
                emptyWeekPlaceholder
            }
        }
        .padding(JourneyLayout.cardPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .warmCard(elevation: .medium)
        .accessibleCard(label: "This week's prayer progress")
    }

    private func hasNoLogsAtAll(week: JourneyWeekSummary) -> Bool {
        viewModel.lastFiveWeeks.allSatisfy { $0.completedCount == 0 }
    }

    private var emptyStateCard: some View {
        VStack(spacing: AppSpacing.lg) {
            Image(systemName: "calendar.badge.plus")
                .font(.system(size: 36))
                .foregroundColor(Color.warmSecondaryText(colorScheme).opacity(0.6))
            Text("Your Journey will appear here as you log prayers.")
                .font(AppTypography.subheadline)
                .foregroundColor(Color.warmSecondaryText(colorScheme))
                .multilineTextAlignment(.center)
            Text("Log today in the Home tab")
                .font(AppTypography.subheadlineBold)
                .foregroundColor(.mutedGold)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppSpacing.xxl)
    }

    private func weekGrid(week: JourneyWeekSummary) -> some View {
        let dayLabels = ["S", "M", "T", "W", "T", "F", "S"]
        let dayFormatter = DateFormatter()
        dayFormatter.dateFormat = "d"
        dayFormatter.timeZone = TimeZone.current
        return VStack(spacing: AppSpacing.sm) {
            HStack(spacing: 0) {
                ForEach(Array(dayLabels.enumerated()), id: \.offset) { _, label in
                    Text(label)
                        .font(AppTypography.captionBold)
                        .foregroundColor(Color.warmSecondaryText(colorScheme))
                        .frame(maxWidth: .infinity)
                }
            }
            HStack(spacing: 0) {
                ForEach(week.daySummaries) { day in
                    Text(dayFormatter.string(from: day.date))
                        .font(AppTypography.caption)
                        .foregroundColor(Color.warmText(colorScheme))
                        .frame(maxWidth: .infinity)
                }
            }
            HStack(spacing: AppSpacing.xs) {
                ForEach(week.daySummaries) { day in
                    Button {
                        viewModel.selectDay(date: day.date)
                    } label: {
                        dayCell(day: day)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func dayCell(day: JourneyDaySummary) -> some View {
        let isToday = Calendar.current.isDateInToday(day.date)
        return VStack(spacing: AppSpacing.xs) {
            HStack(spacing: 2) {
                ForEach(0..<5, id: \.self) { i in
                    Circle()
                        .fill(i < day.prayersCompleted ? dotColor(for: day) : Color.warmSecondaryText(colorScheme).opacity(0.2))
                        .frame(width: 6, height: 6)
                }
            }
        }
        .frame(height: 36)
        .frame(maxWidth: .infinity)
        .padding(AppSpacing.xs + 2)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isToday ? Color.mutedGold.opacity(0.15) : Color.clear)
        )
        .accessibilityLabel("\(shortDayLabel(day.date)) \(dayFormatterForDay().string(from: day.date)): \(day.prayersCompleted) of 5 prayers complete")
        .accessibilityHint("Double tap to see day detail")
    }

    private func dayFormatterForDay() -> DateFormatter {
        let f = DateFormatter()
        f.dateFormat = "d"
        f.timeZone = TimeZone.current
        return f
    }

    private func dotColor(for day: JourneyDaySummary) -> Color {
        if day.prayersCompleted >= day.prayersTotal { return .prayerOnTime }
        return Color.mutedGold.opacity(0.9)
    }

    private var emptyWeekPlaceholder: some View {
        HStack(spacing: 4) {
            ForEach(0..<7, id: \.self) { _ in
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.warmSecondaryText(colorScheme).opacity(0.2))
                    .frame(height: 8)
                    .frame(maxWidth: .infinity)
            }
        }
        .frame(height: 44)
        .padding(4)
    }

    private func shortDayLabel(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "EEE"
        f.timeZone = TimeZone.current
        return f.string(from: date)
    }

    // MARK: - Last5WeeksScroller (horizontal, left-justified; same spacing as Home FiveWeekProgressView)

    private var Last5WeeksScroller: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            WarmSectionHeader("Last 5 Weeks", icon: "chart.bar.fill", subtitle: "Progress overview")
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(alignment: .top, spacing: JourneyLayout.gridSpacing) {
                    ForEach(viewModel.lastFiveWeeks) { week in
                        lastWeekCard(week: week)
                    }
                }
                .padding(.trailing, JourneyLayout.horizontalPadding)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibleCard(label: "Last 5 weeks progress")
    }

    private func lastWeekCard(week: JourneyWeekSummary) -> some View {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        formatter.timeZone = TimeZone.current
        let startStr = formatter.string(from: week.weekStart)
        let endStr = formatter.string(from: week.weekEnd)
        let isCurrentWeek = viewModel.currentWeek?.weekStart == week.weekStart
        return VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("\(startStr)–\(endStr)")
                .font(AppTypography.captionBold)
                .foregroundColor(Color.warmText(colorScheme))
            Text("\(week.completedCount)/\(week.totalCount)")
                .font(AppTypography.bodyBold)
                .foregroundColor(Color.warmSecondaryText(colorScheme))
            HStack(spacing: 2) {
                ForEach(week.daySummaries) { day in
                    Circle()
                        .fill(day.prayersCompleted > 0 ? Color.mutedGold : Color.warmSecondaryText(colorScheme).opacity(0.25))
                        .frame(width: 8, height: 8)
                }
            }
        }
        .frame(width: JourneyLayout.weekCardWidth, alignment: .leading)
        .padding(AppSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isCurrentWeek ? Color.mutedGold.opacity(0.12) : Color.warmSurface(colorScheme))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isCurrentWeek ? Color.mutedGold.opacity(0.4) : Color.clear, lineWidth: 1.5)
        )
        .accessibilityLabel("Week \(startStr) to \(endStr), \(week.completedCount) of 35 prayers\(isCurrentWeek ? ", current week" : "")")
    }

    // MARK: - MilestonesSection (same card padding and typography as Home)

    private var MilestonesSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            WarmSectionHeader("Milestones", icon: "flag.fill")
            VStack(spacing: AppSpacing.sm) {
                ForEach(viewModel.computedMilestones()) { row in
                    HStack(alignment: .top, spacing: JourneyLayout.gridSpacing) {
                        Image(systemName: row.achieved ? "checkmark.circle.fill" : "circle")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(row.achieved ? .prayerOnTime : Color.warmSecondaryText(colorScheme).opacity(0.6))
                        VStack(alignment: .leading, spacing: 2) {
                            Text(row.title)
                                .font(AppTypography.subheadlineBold)
                                .foregroundColor(Color.warmText(colorScheme))
                                .fixedSize(horizontal: false, vertical: true)
                            Text(row.subtitle)
                                .font(AppTypography.caption)
                                .foregroundColor(Color.warmSecondaryText(colorScheme))
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        Spacer(minLength: 0)
                    }
                    .padding(JourneyLayout.gridSpacing)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.warmSurface(colorScheme))
                    )
                }
            }
        }
        .padding(JourneyLayout.cardPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .warmCard(elevation: .medium)
        .accessibleCard(label: "Journey milestones")
    }

    // MARK: - Error banner (matches Home error styling)

    private func errorBanner(_ message: String) -> some View {
        Text(message)
            .font(AppTypography.subheadline)
            .foregroundColor(.white)
            .padding(.horizontal, AppSpacing.lg)
            .padding(.vertical, AppSpacing.sm + 2)
            .background(Capsule().fill(Color.softTerracotta))
            .padding(.top, AppSpacing.sm)
    }
}

// MARK: - Day Detail Sheet (never blank; data set before presentation)

struct JourneyDayDetailSheet: View {
    let detail: JourneyDayDetail
    let onDismiss: () -> Void
    @Environment(\.colorScheme) var colorScheme

    private static var timeFormatter: DateFormatter {
        let f = DateFormatter()
        f.dateFormat = "h:mm a"
        f.timeZone = TimeZone.current
        return f
    }

    private static var dayFormatter: DateFormatter {
        let f = DateFormatter()
        f.dateFormat = "EEEE, MMM d"
        f.timeZone = TimeZone.current
        return f
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(detail.prayerItems) { item in
                        HStack(spacing: 12) {
                            Image(systemName: item.status.icon)
                                .foregroundColor(item.status.color)
                                .frame(width: 28)
                            Text(item.prayerType.displayName)
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(Color.warmText(colorScheme))
                            Spacer()
                            if item.status != .none {
                                VStack(alignment: .trailing, spacing: 2) {
                                    Text(item.status.displayName(for: ThemeManager.shared.userGender))
                                        .font(.system(size: 14))
                                        .foregroundColor(Color.warmSecondaryText(colorScheme))
                                    if let ts = item.timestamp {
                                        Text(Self.timeFormatter.string(from: ts))
                                            .font(.system(size: 12))
                                            .foregroundColor(Color.warmSecondaryText(colorScheme).opacity(0.8))
                                    }
                                }
                            } else {
                                Text("Not logged")
                                    .font(.system(size: 14))
                                    .foregroundColor(Color.warmSecondaryText(colorScheme).opacity(0.7))
                            }
                        }
                        .padding(.vertical, 4)
                    }
                } header: {
                    Text("\(detail.prayersCompleted)/\(detail.prayersTotal) prayers")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(Color.warmSecondaryText(colorScheme))
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle(Self.dayFormatter.string(from: detail.date))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { onDismiss() }
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }
}

// MARK: - Previews (small / large device + Dynamic Type)

#Preview("Journey (default)") {
    JourneyView()
        .environmentObject(AuthService.shared)
}

#Preview("Journey (use Canvas device picker for SE / Pro Max)") {
    JourneyView()
        .environmentObject(AuthService.shared)
}

#Preview("Journey (Dynamic Type large)") {
    JourneyView()
        .environmentObject(AuthService.shared)
        .environment(\.sizeCategory, .accessibilityLarge)
}
