//
//  HijriCalendarTests.swift
//  IbtidaTests
//
//  Unit tests for Hijri calendar conversion and fasting prompt logic.
//

import Testing
import Foundation
@testable import Ibtida

struct HijriCalendarTests {

    /// Hijri components return valid day/month/year for a given date
    @Test func hijriComponents_returnsValidRange() async throws {
        let date = Date(timeIntervalSince1970: 1738195200) // 2025-01-29 00:00 UTC (approx)
        let method = HijriMethod.civil
        let comp = HijriCalendarService.hijriComponents(for: date, method: method)
        #expect(comp.day >= 1 && comp.day <= 30)
        #expect(comp.month >= 1 && comp.month <= 12)
        #expect(comp.year >= 1400 && comp.year <= 1500)
    }

    /// White Day: day 13, 14, 15 have isWhiteDay true (HijriDateComponents)
    @Test func hijriComponents_whiteDayRange() async throws {
        let h = HijriDateComponents(year: 1446, month: 7, day: 14)
        #expect(h.day == 14)
        #expect(h.isWhiteDay == true)
        let h13 = HijriDateComponents(year: 1446, month: 7, day: 13)
        #expect(h13.isWhiteDay == true)
        let h16 = HijriDateComponents(year: 1446, month: 7, day: 16)
        #expect(h16.isWhiteDay == false)
    }

    /// weekday: Monday = 2, Thursday = 5 in Gregorian
    @Test func weekday_mondayAndThursday() async throws {
        // 2025-01-27 Monday, 2025-01-30 Thursday (UTC component; use fixed calendar)
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "America/New_York")!
        var compMon = DateComponents()
        compMon.year = 2025
        compMon.month = 1
        compMon.day = 27
        let monday = cal.date(from: compMon)!
        #expect(HijriCalendarService.weekday(for: monday) == 2)

        var compThu = DateComponents()
        compThu.year = 2025
        compThu.month = 1
        compThu.day = 30
        let thursday = cal.date(from: compThu)!
        #expect(HijriCalendarService.weekday(for: thursday) == 5)
    }

    /// shouldShowFastingPrompt true on Monday
    @Test func shouldShowFastingPrompt_trueOnMonday() async throws {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "America/New_York")!
        let monday = cal.date(from: DateComponents(year: 2025, month: 1, day: 27))!
        #expect(HijriCalendarService.shouldShowFastingPrompt(on: monday, method: .civil) == true)
    }

    /// shouldShowFastingPrompt true on Thursday
    @Test func shouldShowFastingPrompt_trueOnThursday() async throws {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "America/New_York")!
        let thursday = cal.date(from: DateComponents(year: 2025, month: 1, day: 30))!
        #expect(HijriCalendarService.shouldShowFastingPrompt(on: thursday, method: .civil) == true)
    }

    /// hijriDisplayString returns non-empty readable string
    @Test func hijriDisplayString_nonEmpty() async throws {
        let date = Date()
        let s = HijriCalendarService.hijriDisplayString(for: date, method: .civil)
        #expect(!s.isEmpty)
        #expect(s.contains(" "))
    }
}
