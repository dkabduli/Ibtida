//
//  CreditRulesTests.swift
//  IbtidaTests
//
//  Unit tests for Sunnah & fasting credit constants (no duplicate awards).
//

import Testing
import Foundation
@testable import Ibtida

struct CreditRulesTests {

    /// Fasting Mon/Thu bonus is a positive constant
    @Test func fastingMonThuBonus_positive() async throws {
        #expect(CreditRules.fastingMonThuBonus > 0)
    }

    /// Fasting White Day bonus is a positive constant
    @Test func fastingWhiteDayBonus_positive() async throws {
        #expect(CreditRules.fastingWhiteDayBonus > 0)
    }

    /// Sunnah prayer bonus is a positive constant
    @Test func sunnahPrayerBonus_positive() async throws {
        #expect(CreditRules.sunnahPrayerBonus > 0)
    }

    /// Base prayer credits exist for performed statuses
    @Test func baseCreditValues_exist() async throws {
        #expect(CreditRules.onTimeCredit > 0)
        #expect(CreditRules.prayedAtMasjidCredit >= CreditRules.onTimeCredit)
    }

    /// Jumu'ah (Friday prayer) has highest credit for brothers on that day
    @Test func jummahCredit_highestForBrothers() async throws {
        #expect(CreditRules.jummahCredit > 0)
        #expect(CreditRules.jummahCredit >= CreditRules.prayedAtMasjidCredit)
    }
}
