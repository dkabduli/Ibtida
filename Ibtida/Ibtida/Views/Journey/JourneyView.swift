//
//  JourneyView.swift
//  Ibtida
//
//  Journey progress dashboard: header summary, this week, last 5 weeks, milestones.
//

import SwiftUI

struct JourneyView: View {
    @StateObject private var viewModel = JourneyViewModel()
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

    // MARK: - Sign-in prompt

    private var signInPrompt: some View {
        VStack(spacing: 28) {
            ZStack {
                Circle()
                    .fill(Color.mutedGold.opacity(0.15))
                    .frame(width: 100, height: 100)
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.system(size: 45))
                    .foregroundColor(.mutedGold)
            }
            VStack(spacing: 12) {
                Text("Your Journey Awaits")
                    .font(.system(size: 24, weight: .semibold, design: .rounded))
                    .foregroundColor(Color.warmText(colorScheme))
                Text("Sign in to track your progress")
                    .font(.system(size: 16))
                    .foregroundColor(Color.warmSecondaryText(colorScheme))
            }
        }
        .padding(48)
    }

    // MARK: - Skeleton (no blank screen)

    private var skeletonView: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 24) {
                // Section 1 skeleton
                VStack(alignment: .leading, spacing: 12) {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.warmSurface(colorScheme).opacity(0.6))
                        .frame(width: 120, height: 28)
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.warmSurface(colorScheme).opacity(0.5))
                        .frame(width: 180, height: 20)
                    HStack(spacing: 12) {
                        ForEach(0..<3, id: \.self) { _ in
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.warmSurface(colorScheme).opacity(0.5))
                                .frame(height: 64)
                                .frame(maxWidth: .infinity)
                        }
                    }
                }
                .padding(.horizontal, 20)

                // Section 2 skeleton
                VStack(alignment: .leading, spacing: 12) {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.warmSurface(colorScheme).opacity(0.5))
                        .frame(width: 100, height: 22)
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.warmSurface(colorScheme).opacity(0.5))
                        .frame(height: 120)
                }
                .padding(.horizontal, 20)

                // Section 3 skeleton
                VStack(alignment: .leading, spacing: 12) {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.warmSurface(colorScheme).opacity(0.5))
                        .frame(width: 140, height: 22)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(alignment: .top, spacing: 12) {
                            ForEach(0..<3, id: \.self) { _ in
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.warmSurface(colorScheme).opacity(0.5))
                                    .frame(width: 140, height: 100)
                            }
                        }
                        .padding(.leading, 20)
                    }
                }
            }
            .padding(.top, 16)
            .padding(.bottom, 32)
        }
    }

    // MARK: - Scroll content (4 sections)

    private var scrollContent: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 24) {
                section1HeaderSummary
                section2ThisWeek
                section3LastFiveWeeks
                section4Milestones
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 32)
        }
    }

    // MARK: - Section 1: Header Summary

    private var section1HeaderSummary: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Journey")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(Color.warmText(colorScheme))
            Text("Your prayer consistency over time")
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(Color.warmSecondaryText(colorScheme))

            HStack(spacing: 12) {
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
            .padding(.top, 4)
            if let updated = viewModel.lastUpdated {
                Text(relativeTimeString(from: updated))
                    .font(.system(size: 11, weight: .medium))
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
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(color)
            Text(value)
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .foregroundColor(Color.warmText(colorScheme))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(Color.warmSecondaryText(colorScheme))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .padding(.horizontal, 8)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.warmSurface(colorScheme))
        )
    }

    // MARK: - Section 2: This Week

    private var section2ThisWeek: some View {
        VStack(alignment: .leading, spacing: 14) {
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
        .padding(20)
        .warmCard(elevation: .medium)
        .accessibleCard(label: "This week's prayer progress")
    }

    private func hasNoLogsAtAll(week: JourneyWeekSummary) -> Bool {
        viewModel.lastFiveWeeks.allSatisfy { $0.completedCount == 0 }
    }

    private var emptyStateCard: some View {
        VStack(spacing: 16) {
            Image(systemName: "calendar.badge.plus")
                .font(.system(size: 36))
                .foregroundColor(Color.warmSecondaryText(colorScheme).opacity(0.6))
            Text("Your Journey will appear here as you log prayers.")
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(Color.warmSecondaryText(colorScheme))
                .multilineTextAlignment(.center)
            Text("Log today in the Home tab")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.mutedGold)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
    }

    private func weekGrid(week: JourneyWeekSummary) -> some View {
        let dayLabels = ["S", "M", "T", "W", "T", "F", "S"]
        let dayFormatter = DateFormatter()
        dayFormatter.dateFormat = "d"
        dayFormatter.timeZone = TimeZone.current
        return VStack(spacing: 10) {
            HStack(spacing: 0) {
                ForEach(Array(dayLabels.enumerated()), id: \.offset) { _, label in
                    Text(label)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(Color.warmSecondaryText(colorScheme))
                        .frame(maxWidth: .infinity)
                }
            }
            HStack(spacing: 0) {
                ForEach(week.daySummaries) { day in
                    Text(dayFormatter.string(from: day.date))
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(Color.warmText(colorScheme))
                        .frame(maxWidth: .infinity)
                }
            }
            HStack(spacing: 4) {
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
        return VStack(spacing: 4) {
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
        .padding(6)
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

    // MARK: - Section 3: Last 5 Weeks (left-justified horizontal)

    private var section3LastFiveWeeks: some View {
        VStack(alignment: .leading, spacing: 12) {
            WarmSectionHeader("Last 5 Weeks", icon: "calendar.badge.clock")
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(alignment: .top, spacing: 12) {
                    ForEach(viewModel.lastFiveWeeks) { week in
                        lastWeekCard(week: week)
                    }
                }
                .padding(.leading, 16)
                .padding(.trailing, 20)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .accessibleCard(label: "Last 5 weeks progress")
    }

    private func lastWeekCard(week: JourneyWeekSummary) -> some View {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        formatter.timeZone = TimeZone.current
        let startStr = formatter.string(from: week.weekStart)
        let endStr = formatter.string(from: week.weekEnd)
        return VStack(alignment: .leading, spacing: 10) {
            Text("\(startStr)–\(endStr)")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(Color.warmText(colorScheme))
            Text("\(week.completedCount)/\(week.totalCount)")
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundColor(Color.warmSecondaryText(colorScheme))
            HStack(spacing: 2) {
                ForEach(week.daySummaries) { day in
                    Circle()
                        .fill(day.prayersCompleted > 0 ? Color.mutedGold : Color.warmSecondaryText(colorScheme).opacity(0.25))
                        .frame(width: 8, height: 8)
                }
            }
        }
        .frame(width: 120, alignment: .leading)
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.warmSurface(colorScheme))
        )
        .accessibilityLabel("Week \(startStr) to \(endStr), \(week.completedCount) of 35 prayers")
    }

    // MARK: - Section 4: Milestones

    private var section4Milestones: some View {
        VStack(alignment: .leading, spacing: 14) {
            WarmSectionHeader("Milestones", icon: "flag.fill")
            VStack(spacing: 8) {
                ForEach(viewModel.computedMilestones()) { row in
                    HStack(spacing: 12) {
                        Image(systemName: row.achieved ? "checkmark.circle.fill" : "circle")
                            .font(.system(size: 20))
                            .foregroundColor(row.achieved ? .prayerOnTime : Color.warmSecondaryText(colorScheme).opacity(0.6))
                        VStack(alignment: .leading, spacing: 2) {
                            Text(row.title)
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(Color.warmText(colorScheme))
                            Text(row.subtitle)
                                .font(.system(size: 12))
                                .foregroundColor(Color.warmSecondaryText(colorScheme))
                        }
                        Spacer()
                    }
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.warmSurface(colorScheme))
                    )
                }
            }
        }
        .padding(20)
        .warmCard(elevation: .medium)
        .accessibleCard(label: "Journey milestones")
    }

    // MARK: - Error banner

    private func errorBanner(_ message: String) -> some View {
        Text(message)
            .font(.system(size: 14, weight: .medium))
            .foregroundColor(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Capsule().fill(Color.softTerracotta))
            .padding(.top, 8)
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
                                    Text(item.status.displayName)
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

// MARK: - Preview

#Preview {
    JourneyView()
        .environmentObject(AuthService.shared)
}
