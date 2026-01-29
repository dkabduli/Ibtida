//
//  JourneyDateUtilsTests.swift
//  IbtidaTests
//
//  Unit tests for Journey week ordering and date range (DateUtils).
//

import Testing
import Foundation
@testable import Ibtida

struct JourneyDateUtilsTests {

    /// Last 5 week starts: count is 5, index 0 is current week start (Sunday in journey timezone).
    @Test func lastNWeekStarts_returnsFiveWeeks_currentWeekFirst() async throws {
        let calendar = DateUtils.journeyCalendar
        let weekStarts = DateUtils.lastNWeekStarts(5, using: calendar)
        #expect(weekStarts.count == 5)
        let now = Date()
        let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now)
        let expectedCurrentWeekStart = calendar.date(from: components)
        #expect(expectedCurrentWeekStart != nil)
        #expect(calendar.isDate(weekStarts[0], equalTo: expectedCurrentWeekStart!, toGranularity: .day))
        // Index 1 should be one week earlier
        let oneWeekEarlier = calendar.date(byAdding: .weekOfYear, value: -1, to: weekStarts[0])
        #expect(oneWeekEarlier != nil)
        #expect(calendar.isDate(weekStarts[1], equalTo: oneWeekEarlier!, toGranularity: .day))
    }

    /// Date range for last 5 weeks: start is 4 weeks ago week start, end is start of next week after current.
    @Test func dateRangeForLastNWeeks_spansFiveWeeks() async throws {
        let calendar = DateUtils.journeyCalendar
        let (start, end) = DateUtils.dateRangeForLastNWeeks(5, using: calendar)
        let weekStarts = DateUtils.lastNWeekStarts(5, using: calendar)
        #expect(weekStarts.count == 5)
        let oldestWeekStart = weekStarts[4]
        let currentWeekStart = weekStarts[0]
        #expect(calendar.isDate(start, equalTo: oldestWeekStart, toGranularity: .day))
        let expectedEnd = calendar.date(byAdding: .weekOfYear, value: 1, to: currentWeekStart)
        #expect(expectedEnd != nil)
        #expect(calendar.isDate(end, equalTo: expectedEnd!, toGranularity: .day))
    }
}
