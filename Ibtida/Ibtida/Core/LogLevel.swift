//
//  LogLevel.swift
//  Ibtida
//
//  Centralized logging with level control to reduce console noise
//

import Foundation

/// Log levels for controlling debug output
enum LogLevel: String, CaseIterable {
    case none = "none"
    case errors = "errors"      // Only errors
    case network = "network"     // Network operations
    case state = "state"         // State changes
    case verbose = "verbose"     // Everything
    
    /// Current log level (set via environment variable or UserDefaults)
    static var current: LogLevel {
        #if DEBUG
        if let levelString = ProcessInfo.processInfo.environment["IBTIDA_LOG_LEVEL"],
           let level = LogLevel(rawValue: levelString) {
            return level
        }
        // Default to 'errors' in DEBUG to reduce noise
        return .errors
        #else
        return .none
        #endif
    }
    
    /// Check if a log level should be printed
    static func shouldLog(_ level: LogLevel) -> Bool {
        #if DEBUG
        let current = LogLevel.current
        switch current {
        case .none:
            return false
        case .errors:
            return level == .errors
        case .network:
            return level == .errors || level == .network
        case .state:
            return level == .errors || level == .network || level == .state
        case .verbose:
            return true
        }
        #else
        return false
        #endif
    }
}

/// Convenience logging functions
enum AppLog {
    static func error(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        #if DEBUG
        if LogLevel.shouldLog(.errors) {
            let fileName = (file as NSString).lastPathComponent
            print("❌ [\(fileName):\(line)] \(message)")
        }
        #endif
    }
    
    static func network(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        #if DEBUG
        if LogLevel.shouldLog(.network) {
            let fileName = (file as NSString).lastPathComponent
            print("🌐 [\(fileName)] \(message)")
        }
        #endif
    }
    
    static func state(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        #if DEBUG
        if LogLevel.shouldLog(.state) {
            let fileName = (file as NSString).lastPathComponent
            print("🔄 [\(fileName)] \(message)")
        }
        #endif
    }
    
    static func verbose(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        #if DEBUG
        if LogLevel.shouldLog(.verbose) {
            let fileName = (file as NSString).lastPathComponent
            print("📝 [\(fileName)] \(message)")
        }
        #endif
    }
    
    static func success(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        #if DEBUG
        if LogLevel.shouldLog(.errors) {
            let fileName = (file as NSString).lastPathComponent
            print("✅ [\(fileName)] \(message)")
        }
        #endif
    }
}
