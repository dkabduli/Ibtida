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
    /// Jumu'ah (Friday prayer) – distinct prayer; replaces Dhuhr for brothers on Friday only
    case jumuah = "jumuah"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .fajr: return "Fajr"
        case .dhuhr: return "Dhuhr"
        case .asr: return "Asr"
        case .maghrib: return "Maghrib"
        case .isha: return "Isha"
        case .jumuah: return "Jumu'ah"
        }
    }
    
    var arabicName: String {
        switch self {
        case .fajr: return "الفجر"
        case .dhuhr: return "الظهر"
        case .asr: return "العصر"
        case .maghrib: return "المغرب"
        case .isha: return "العشاء"
        case .jumuah: return "الجُمعة"
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
        case .jumuah: return "building.columns.fill"
        }
    }
    
    var accentColor: Color {
        switch self {
        case .fajr: return .orange
        case .dhuhr: return .yellow
        case .asr: return .blue
        case .maghrib: return .pink
        case .isha: return .indigo
        case .jumuah: return Color.mutedGold
        }
    }
    
    /// Five prayers to display for a given day and gender. Brothers on Friday: Jumu'ah replaces Dhuhr; otherwise standard five.
    static func prayersToDisplay(for date: Date, gender: UserGender?) -> [PrayerType] {
        let isFriday = Calendar.current.component(.weekday, from: date) == 6
        if isFriday && gender == .brother {
            return [.fajr, .jumuah, .asr, .maghrib, .isha]
        }
        return [.fajr, .dhuhr, .asr, .maghrib, .isha]
    }
    
    /// Standard five (no Jumu'ah substitution) for iteration where day/gender context is not needed
    static var standardFive: [PrayerType] {
        [.fajr, .dhuhr, .asr, .maghrib, .isha]
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
    /// Jumu'ah (Friday prayer) – brothers only, Dhuhr slot on Friday; highest reward for that day
    case jummah = "jummah"
    
    var id: String { rawValue }
    
    /// Default display name (use displayName(for: gender) for gender-specific labels).
    var displayName: String {
        displayName(for: nil)
    }

    /// Gender-specific display label for prayer logging. Store enum raw value to Firestore; change wording here without breaking history.
    /// Brothers: In masjid (jamat), On time, Qada, Missed, Not logged.
    /// Sisters: At home (on time), Qada, Missed, Not applicable 🩸. "Not logged" for default/empty.
    /// Legacy "late" maps to "On time" for brothers for migration.
    func displayName(for gender: UserGender?) -> String {
        switch self {
        case .none: return "Not logged"
        case .onTime: return "On time"
        case .late: return gender == .brother ? "On time" : "Later" // Legacy: map to On time for brother
        case .qada: return "Qada"
        case .missed: return "Missed"
        case .prayedAtMasjid: return "In masjid (jamat)"
        case .prayedAtHome: return "At home (on time)"
        case .menstrual: return "Not applicable 🩸"
        case .jummah: return "In masjid (Jumu'ah)"
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
        case .jummah: return "الجُمعة"
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
        case .jummah: return Color.mutedGold  // Jumu'ah: highest reward, gold
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
        case .jummah: return "building.columns.fill"  // Masjid / Jumu'ah
        }
    }
    
    // MARK: - Gender-Specific Status Lists (only these options shown in picker)
    /// Brothers: In masjid (jamat), On time, Qada, Missed, Not logged. Stored as enum raw value in Firestore.
    static func statusesForBrother() -> [PrayerStatus] {
        return [.prayedAtMasjid, .onTime, .qada, .missed, .none]
    }
    /// Brothers logging Jumu'ah (Friday only): In masjid (Jumu'ah), Missed, Not logged. No Qada for Jumu'ah.
    static func statusesForJummahBrother() -> [PrayerStatus] {
        return [.jummah, .missed, .none]
    }
    /// Sisters: At home (on time), Qada, Missed, Not applicable 🩸. Not applicable 🩸 does not penalize streaks.
    static func statusesForSister() -> [PrayerStatus] {
        return [.prayedAtHome, .qada, .missed, .menstrual]
    }
    
    /// Statuses that count as "performed" (Sunnah toggle and bonus apply)
    static let performedStatuses: Set<PrayerStatus> = [.onTime, .late, .qada, .prayedAtMasjid, .prayedAtHome, .jummah]

    /// Parse status from Firestore with best-effort migration for legacy/unknown values. Do not crash on unknown strings.
    static func fromFirestore(_ raw: String) -> PrayerStatus {
        if let status = PrayerStatus(rawValue: raw) { return status }
        switch raw.lowercased() {
        case "later": return .late
        case "made up", "madeup": return .qada
        case "jumu'ah", "jumua", "jumah": return .jummah
        default: return .none
        }
    }
}

// MARK: - Sister Jumu'ah Status (Friday optional for sisters only)

/// Sisters on Friday: optional Jumu'ah tracking. Does not replace Dhuhr; no Qada; no double-count.
enum SisterJumuahStatus: String, CaseIterable, Identifiable, Codable {
    case prayed = "prayed"
    case didNotPray = "didNotPray"
    case notApplicable = "notApplicable"  // menstrual
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .prayed: return "Jumu'ah prayed"
        case .didNotPray: return "Did not pray Jumu'ah"
        case .notApplicable: return "Not applicable 🩸"
        }
    }
    
    static func fromFirestore(_ raw: String?) -> SisterJumuahStatus? {
        guard let raw = raw else { return nil }
        return SisterJumuahStatus(rawValue: raw)
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
