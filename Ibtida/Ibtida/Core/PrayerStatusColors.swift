//
//  PrayerStatusColors.swift
//  Ibtida
//
//  Centralized color mapping for prayer statuses
//  Ensures consistent colors across Today's Salah and Last 5 Weeks grid
//

import SwiftUI

/// Centralized color mapping for prayer statuses
enum PrayerStatusColors {
    
    /// Get color for a prayer status (consistent across app)
    static func color(for status: PrayerStatus) -> Color {
        switch status {
        case .none: return .gray.opacity(0.3)
        case .onTime: return .green
        case .late: return .orange
        case .qada: return .blue
        case .missed: return .red
        case .prayedAtMasjid: return .purple
        case .prayedAtHome: return .mint
        case .menstrual: return .gray.opacity(0.5) // Neutral gray for "Not Applicable" (sisters)
        }
    }
    
    /// Summary status for a day (prioritizes worst status)
    enum SummaryStatus {
        case allOnTime
        case hasLate
        case hasQada
        case hasMissed
        case hasMenstrual
        case none
    }
    
    /// Calculate summary status for a day
    static func summaryStatus(for prayerDay: PrayerDay) -> SummaryStatus {
        let statuses = [
            prayerDay.fajrStatus,
            prayerDay.dhuhrStatus,
            prayerDay.asrStatus,
            prayerDay.maghribStatus,
            prayerDay.ishaStatus
        ]
        
        // Priority: missed > menstrual > late > qada > onTime
        if statuses.contains(.missed) {
            return .hasMissed
        } else if statuses.contains(.menstrual) {
            return .hasMenstrual
        } else if statuses.contains(.late) {
            return .hasLate
        } else if statuses.contains(.qada) {
            return .hasQada
        } else if statuses.allSatisfy({ $0 == .onTime || $0 == .prayedAtMasjid || $0 == .prayedAtHome }) {
            return .allOnTime
        } else {
            return .none
        }
    }
    
    /// Get summary color for a day (matches Today's Salah theme)
    static func summaryColor(for prayerDay: PrayerDay) -> Color {
        switch summaryStatus(for: prayerDay) {
        case .allOnTime:
            return .green
        case .hasLate:
            return .orange
        case .hasQada:
            return .blue
        case .hasMissed:
            return .red
        case .hasMenstrual:
            return .gray.opacity(0.5) // Neutral for sisters
        case .none:
            return .gray.opacity(0.3)
        }
    }
    
    /// Get summary color from prayer logs for a specific day
    static func summaryColor(for logs: [PrayerLog], dayId: String) -> Color {
        let dayLogs = logs.filter { DateUtils.dayId(for: $0.date) == dayId }
        
        guard !dayLogs.isEmpty else {
            return .gray.opacity(0.3)
        }
        
        let statuses = dayLogs.map { $0.status }
        
        // Priority: missed > menstrual > late > qada > onTime
        if statuses.contains(.missed) {
            return .red
        } else if statuses.contains(.menstrual) {
            return .gray.opacity(0.5)
        } else if statuses.contains(.late) {
            return .orange
        } else if statuses.contains(.qada) {
            return .blue
        } else if statuses.allSatisfy({ $0 == .onTime || $0 == .prayedAtMasjid || $0 == .prayedAtHome }) {
            return .green
        } else {
            return .gray.opacity(0.3)
        }
    }
}
