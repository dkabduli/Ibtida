//
//  Prayer.swift
//  Ibtida
//
//  Prayer tracking models with Islamic terminology
//

import Foundation
import SwiftUI

// MARK: - Prayer Type (5 Daily Prayers)

enum PrayerType: String, CaseIterable, Identifiable, Codable {
    case fajr = "fajr"
    case dhuhr = "dhuhr"
    case asr = "asr"
    case maghrib = "maghrib"
    case isha = "isha"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .fajr: return "Fajr"
        case .dhuhr: return "Dhuhr"
        case .asr: return "Asr"
        case .maghrib: return "Maghrib"
        case .isha: return "Isha"
        }
    }
    
    var arabicName: String {
        switch self {
        case .fajr: return "الفجر"
        case .dhuhr: return "الظهر"
        case .asr: return "العصر"
        case .maghrib: return "المغرب"
        case .isha: return "العشاء"
        }
    }
    
    var fullDisplayName: String {
        "\(displayName) (\(arabicName))"
    }
    
    var icon: String {
        switch self {
        case .fajr: return "sunrise.fill"
        case .dhuhr: return "sun.max.fill"
        case .asr: return "sun.haze.fill"
        case .maghrib: return "sunset.fill"
        case .isha: return "moon.stars.fill"
        }
    }
    
    var accentColor: Color {
        switch self {
        case .fajr: return .orange
        case .dhuhr: return .yellow
        case .asr: return .blue
        case .maghrib: return .pink
        case .isha: return .indigo
        }
    }
}

// MARK: - Prayer Status

enum PrayerStatus: String, CaseIterable, Identifiable, Codable {
    case none = "none"          // Not yet logged
    case onTime = "onTime"      // Prayed on time
    case late = "late"          // Prayed late but within time
    case qada = "qada"          // Made up (قضاء)
    case missed = "missed"      // Missed entirely
    case prayedAtMasjid = "prayedAtMasjid"  // Prayed at masjid (brothers only)
    case prayedAtHome = "prayedAtHome"      // Prayed at home (sisters only)
    case menstrual = "menstrual"            // Menstrual period (sisters only)
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .none: return "Not yet logged"
        case .onTime: return "On time"
        case .late: return "Later"
        case .qada: return "Made up"
        case .missed: return "Not logged" // Gentle: avoids "missed" or "failed"
        case .prayedAtMasjid: return "At masjid"
        case .prayedAtHome: return "At home"
        case .menstrual: return "Not applicable" // Respectful, neutral
        }
    }
    
    var arabicDescription: String {
        switch self {
        case .none: return "لم يُسجَّل"
        case .onTime: return "أدّيتُها في وقتها"
        case .late: return "متأخر"
        case .qada: return "قضاء"
        case .missed: return "فاتتني"
        case .prayedAtMasjid: return "في المسجد"
        case .prayedAtHome: return "في البيت"
        case .menstrual: return "الحيض"
        }
    }
    
    var fullDisplayName: String {
        "\(displayName) (\(arabicDescription))"
    }
    
    var xpValue: Int {
        // Use CreditRules for consistency (base values only, bonuses applied separately)
        return CreditRules.baseCreditValue(for: self)
    }
    
    var color: Color {
        switch self {
        case .none: return .gray
        case .onTime: return .green
        case .late: return .orange
        case .qada: return .blue
        case .missed: return .red
        case .prayedAtMasjid: return .purple  // Distinct color for masjid
        case .prayedAtHome: return .mint  // Soft color for home prayer
        case .menstrual: return .red.opacity(0.7)  // Soft red for menstrual period
        }
    }
    
    var icon: String {
        switch self {
        case .none: return "circle"
        case .onTime: return "checkmark.circle.fill"
        case .late: return "clock.fill"
        case .qada: return "arrow.counterclockwise.circle.fill"
        case .missed: return "xmark.circle.fill"
        case .prayedAtMasjid: return "building.columns.fill"
        case .prayedAtHome: return "house.fill"
        case .menstrual: return "drop.fill"  // Menstrual icon
        }
    }
    
    // MARK: - Gender-Specific Status Lists
    
    static func statusesForBrother() -> [PrayerStatus] {
        return [.onTime, .late, .qada, .prayedAtMasjid, .missed]
    }
    
    static func statusesForSister() -> [PrayerStatus] {
        return [.onTime, .late, .qada, .prayedAtHome, .menstrual, .missed]
    }
}

// MARK: - Prayer Log

struct PrayerLog: Identifiable, Codable, Equatable {
    let id: String
    let date: Date
    let prayerType: PrayerType
    var status: PrayerStatus
    
    init(
        id: String = UUID().uuidString,
        date: Date = Date(),
        prayerType: PrayerType,
        status: PrayerStatus = .none
    ) {
        self.id = id
        self.date = date
        self.prayerType = prayerType
        self.status = status
    }
    
    static func == (lhs: PrayerLog, rhs: PrayerLog) -> Bool {
        lhs.id == rhs.id
    }
}
