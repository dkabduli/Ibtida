//
//  RamadanLog.swift
//  Ibtida
//
//  Per-day Ramadan fasting log. users/{uid}/ramadanLogs/{YYYY-MM-DD}
//

import Foundation

/// Fasting status for a single day (Brothers: Yes/No; Sisters: Yes/No/Not applicable 🩸)
enum RamadanFastingStatus: Equatable {
    case fasted
    case notFasted
    case sisterNotApplicable
    
    var displayLabel: String {
        switch self {
        case .fasted: return "Fasted ✅"
        case .notFasted: return "Not fasted ❌"
        case .sisterNotApplicable: return "Not applicable 🩸"
        }
    }
}

struct RamadanLog: Identifiable, Equatable {
    var id: String { dateString }
    let dateString: String // yyyy-MM-dd
    /// true = fasted, false = did not fast, nil = not logged (or sister not applicable)
    var didFast: Bool?
    /// Sisters only: true when day is not applicable (menstruation)
    var sisterNotApplicable: Bool?
    var updatedAt: Date
    var timezone: String
    
    init(
        dateString: String,
        didFast: Bool? = nil,
        sisterNotApplicable: Bool? = nil,
        updatedAt: Date = Date(),
        timezone: String = TimeZone.current.identifier
    ) {
        self.dateString = dateString
        self.didFast = didFast
        self.sisterNotApplicable = sisterNotApplicable
        self.updatedAt = updatedAt
        self.timezone = timezone
    }
    
    /// Resolved status for display (Brothers: fasted/notFasted/unlogged; Sisters: + sisterNotApplicable)
    func status(isSister: Bool) -> RamadanFastingStatus? {
        if isSister && sisterNotApplicable == true { return .sisterNotApplicable }
        if let d = didFast { return d ? .fasted : .notFasted }
        return nil
    }
}
