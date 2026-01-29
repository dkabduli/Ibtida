//
//  JourneyViewModel.swift
//  Ibtida
//
//  ViewModel for Journey progress dashboard. State machine, single fetch, no blank flashes.
//

import Foundation
import FirebaseAuth

// MARK: - Load State

enum JourneyLoadState: Equatable {
    case idle
    case loading
    case loaded
    case failed(String)
}

@MainActor
final class JourneyViewModel: ObservableObject {

    // MARK: - Published State
    // State flow: loading → set data → loadState=.loaded, lastUpdated=Date(). Never clear currentWeek/lastFiveWeeks on refresh (keeps old content visible). activeSheetRoute set only after activeDayDetail is set (sheet never blank).

    @Published var loadState: JourneyLoadState = .idle
    @Published var userSummary: JourneyUserSummary = JourneyUserSummary(streakDays: 0, credits: 0)
    /// Current week (Section 2). Never set to nil after load unless signing out.
    @Published var currentWeek: JourneyWeekSummary?
    /// Last 5 weeks; index 0 = current week. Left-justified in UI.
    @Published var lastFiveWeeks: [JourneyWeekSummary] = []
    @Published var activeSheetRoute: JourneySheetRoute?
    @Published var activeDayDetail: JourneyDayDetail?
    @Published var isSheetLoading: Bool = false
    @Published var lastUpdated: Date?

    // MARK: - Dependencies (injectable for tests)

    private let prayerService: PrayerLogFirestoreService
    private let profileService: UserProfileFirestoreService

    private var allLogs: [PrayerLog] = []
    private var loadTask: Task<Void, Never>?

    var errorMessage: String? {
        if case .failed(let message) = loadState { return message }
        return nil
    }

    var isLoading: Bool { loadState == .loading }

    // MARK: - Init

    init(
        prayerService: PrayerLogFirestoreService = .shared,
        profileService: UserProfileFirestoreService = .shared
    ) {
        self.prayerService = prayerService
        self.profileService = profileService
    }

    // MARK: - Current user

    var currentUID: String? { Auth.auth().currentUser?.uid }

    // MARK: - Load (single flow, no races)

    func loadIfNeeded() {
        guard currentUID != nil else { return }
        guard loadTask == nil else { return }

        loadTask = Task { [weak self] in
            await self?.performLoad()
            self?.loadTask = nil
        }
    }

    private func performLoad() async {
        guard let uid = currentUID else { return }

        loadState = .loading
        // Do not clear currentWeek / lastFiveWeeks / userSummary — keeps previous content visible

        let calendar = DateUtils.journeyCalendar
        let weekStarts = DateUtils.lastNWeekStarts(5, using: calendar)
        let (rangeStart, rangeEnd) = DateUtils.dateRangeForLastNWeeks(5, using: calendar)

        #if DEBUG
        let startStr = DateUtils.logString(for: rangeStart)
        let endStr = DateUtils.logString(for: rangeEnd)
        print("📖 Journey: fetch uid=\(uid.prefix(8))… rangeStart=\(startStr) rangeEnd=\(endStr)")
        #endif

        do {
            async let profileResult = try? profileService.loadUserProfile(uid: uid)
            async let logsResult = try? prayerService.fetchPrayerLogsOnce(weekStart: rangeStart, weekEnd: rangeEnd)

            let profile = await profileResult
            let logs = await logsResult ?? []

            self.allLogs = logs
            self.userSummary = JourneyUserSummary(
                streakDays: profile?.currentStreak ?? 0,
                credits: profile?.credits ?? 0
            )

            let weeks = Self.computeWeeks(weekStarts: weekStarts, logs: logs, calendar: calendar)

            self.currentWeek = weeks.first
            self.lastFiveWeeks = weeks
            self.loadState = .loaded
            self.lastUpdated = Date()

            #if DEBUG
            let currentStart = weekStarts.first.map { DateUtils.weekId(for: $0) } ?? "—"
            print("📖 Journey: Loaded \(logs.count) prayer logs (\(startStr) – \(endStr)), computed \(weeks.count) weeks, current week starts \(currentStart)")
            #endif

        } catch {
            loadState = .failed("Couldn't load journey. Pull to refresh.")
            #if DEBUG
            print("❌ Journey: load error - \(error)")
            #endif
        }
    }

    // MARK: - Refresh (keep old content, show refreshing)

    func refresh() {
        loadTask?.cancel()
        loadTask = nil
        loadIfNeeded()
    }

    // MARK: - Day selection (sheet: set content first, then route)

    /// Build detail from in-memory logs, set activeDayDetail, then sheetRoute so sheet is never blank.
    func selectDay(date: Date) {
        let dayId = DateUtils.dayId(for: date)
        let detail = Self.buildDayDetail(dayId: dayId, date: date, logs: allLogs)
        activeDayDetail = detail
        activeSheetRoute = .dayDetail(date: date)
    }

    func dismissSheet() {
        activeSheetRoute = nil
        activeDayDetail = nil
        isSheetLoading = false
    }

    // MARK: - Compute weeks from logs

    private static func computeWeeks(weekStarts: [Date], logs: [PrayerLog], calendar: Calendar) -> [JourneyWeekSummary] {
        var result: [JourneyWeekSummary] = []
        let tz = calendar.timeZone

        func dayId(for date: Date) -> String {
            DateUtils.dayId(for: date, timeZone: tz)
        }

        for weekStart in weekStarts {
            let days = (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: weekStart) }
            guard let weekEnd = days.last else { continue }

            var daySummaries: [JourneyDaySummary] = []
            var completedCount = 0

            for dayDate in days {
                let did = dayId(for: dayDate)
                let dayLogs = logs.filter { dayId(for: $0.date) == did }
                let completed = dayLogs.count
                completedCount += completed
                daySummaries.append(JourneyDaySummary(
                    date: dayDate,
                    dayId: did,
                    prayersCompleted: completed,
                    prayersTotal: JourneyDaySummary.prayersPerDay
                ))
            }

            result.append(JourneyWeekSummary(
                weekStart: weekStart,
                weekEnd: weekEnd,
                weekId: DateUtils.weekId(for: weekStart),
                daySummaries: daySummaries,
                completedCount: completedCount,
                totalCount: JourneyWeekSummary.prayersPerWeek
            ))
        }

        return result
    }

    private static func buildDayDetail(dayId: String, date: Date, logs: [PrayerLog]) -> JourneyDayDetail {
        let tz = DateUtils.journeyTimezone
        func dayIdFor(_ d: Date) -> String { DateUtils.dayId(for: d, timeZone: tz) }
        let dayLogs = logs.filter { dayIdFor($0.date) == dayId }
        let byPrayer = Dictionary(grouping: dayLogs, by: { $0.prayerType })
        let items: [JourneyPrayerItem] = PrayerType.allCases.map { prayer in
            let log = byPrayer[prayer]?.first
            return JourneyPrayerItem(
                id: log?.id ?? prayer.rawValue,
                prayerType: prayer,
                status: log?.status ?? .none,
                timestamp: log?.date
            )
        }
        return JourneyDayDetail(
            date: date,
            dayId: dayId,
            prayerItems: items,
            prayersCompleted: dayLogs.count,
            prayersTotal: JourneyDaySummary.prayersPerDay
        )
    }

    // MARK: - Computed milestones (expanded list)

    func computedMilestones() -> [JourneyMilestoneRow] {
        var rows: [JourneyMilestoneRow] = []
        rows.append(JourneyMilestoneRow(
            id: "first_logged_day",
            title: "First logged prayer day",
            subtitle: "Log at least one prayer in a day",
            achieved: hasAnyLoggedDay()
        ))
        rows.append(JourneyMilestoneRow(
            id: "first_full_day",
            title: "First full day (5/5)",
            subtitle: "Log all 5 prayers in one day",
            achieved: hasAnyFullDay()
        ))
        rows.append(JourneyMilestoneRow(
            id: "streak_3",
            title: "3-day streak",
            subtitle: "Keep your streak for 3 days",
            achieved: userSummary.streakDays >= 3
        ))
        rows.append(JourneyMilestoneRow(
            id: "streak_7",
            title: "7-day streak",
            subtitle: "Keep your streak for 7 days",
            achieved: userSummary.streakDays >= 7
        ))
        rows.append(JourneyMilestoneRow(
            id: "streak_14",
            title: "14-day streak",
            subtitle: "Two weeks of consistency",
            achieved: userSummary.streakDays >= 14
        ))
        rows.append(JourneyMilestoneRow(
            id: "credits_100",
            title: "100 credits",
            subtitle: "Earn 100 consistency credits",
            achieved: userSummary.credits >= 100
        ))
        rows.append(JourneyMilestoneRow(
            id: "credits_250",
            title: "250 credits",
            subtitle: "Earn 250 consistency credits",
            achieved: userSummary.credits >= 250
        ))
        return rows
    }

    private func hasAnyLoggedDay() -> Bool {
        lastFiveWeeks.contains { week in
            week.daySummaries.contains { $0.prayersCompleted > 0 }
        }
    }

    private func hasAnyFullDay() -> Bool {
        lastFiveWeeks.contains { week in
            week.daySummaries.contains { $0.prayersCompleted >= JourneyDaySummary.prayersPerDay }
        }
    }
}

// MARK: - Milestone row (Section 4)

struct JourneyMilestoneRow: Identifiable {
    let id: String
    let title: String
    let subtitle: String
    let achieved: Bool
}
