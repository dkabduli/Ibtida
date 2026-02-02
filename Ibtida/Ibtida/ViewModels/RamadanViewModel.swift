//
//  RamadanViewModel.swift
//  Ibtida
//
//  ViewModel for Ramadan tab: fasting logs and calendar config.
//

import Foundation
import FirebaseAuth

@MainActor
final class RamadanViewModel: ObservableObject {
    @Published var logsByDate: [String: RamadanLog] = [:]
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let configManager = CalendarConfigManager.shared
    private let logService = RamadanLogFirestoreService.shared
    
    var config: RamadanConfig { configManager.config }
    var isWithinRange: Bool { configManager.isWithinRamadanRange }
    var ramadanDates: [Date] { configManager.ramadanDateRange() }
    var ramadanTotalDays: Int? { configManager.ramadanTotalDays }
    
    var isSister: Bool {
        ThemeManager.shared.userGender == .sister
    }
    
    func ramadanDayNumber(for date: Date) -> Int? {
        configManager.ramadanDayNumber(for: date)
    }
    
    func loadLogsIfNeeded() async {
        guard Auth.auth().currentUser != nil else { return }
        guard config.hasValidRange else { return }
        
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        let dateStrings = ramadanDates.map { DateUtils.dayId(for: $0) }
        do {
            let logs = try await logService.loadLogs(dateStrings: dateStrings)
            var dict: [String: RamadanLog] = [:]
            for log in logs { dict[log.dateString] = log }
            logsByDate = dict
        } catch {
            errorMessage = "Could not load fasting logs"
            logsByDate = [:]
        }
    }
    
    func log(for dateString: String) -> RamadanLog? {
        logsByDate[dateString]
    }
    
    func status(for dateString: String) -> RamadanFastingStatus? {
        log(for: dateString)?.status(isSister: isSister)
    }
    
    func saveLog(_ log: RamadanLog) async {
        do {
            try await logService.saveLog(log, isSister: isSister)
            logsByDate[log.dateString] = log
        } catch {
            errorMessage = "Could not save"
        }
    }
    
    func clearError() {
        errorMessage = nil
    }
}
