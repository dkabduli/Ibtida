//
//  TimeAwareUI.swift
//  Ibtida
//
//  Time-aware UI adjustments for spiritual context
//

import Foundation
import SwiftUI

/// Time-aware UI adjustments
enum TimeAwareUI {
    
    // MARK: - Time of Day Detection
    
    static func currentTimeOfDay() -> TimeOfDay {
        let hour = Calendar.current.component(.hour, from: Date())
        
        switch hour {
        case 5..<12:
            return .morning
        case 12..<17:
            return .afternoon
        case 17..<20:
            return .evening
        case 20..<22:
            return .night
        default:
            return .lateNight
        }
    }
    
    enum TimeOfDay {
        case morning
        case afternoon
        case evening
        case night
        case lateNight
        
        var warmthLevel: Double {
            switch self {
            case .morning:
                return 1.0 // Full warmth
            case .afternoon:
                return 0.95
            case .evening:
                return 0.85
            case .night:
                return 0.75 // Calmer
            case .lateNight:
                return 0.65 // Deepest, calmest
            }
        }
        
        var shouldReduceStimulation: Bool {
            return self == .lateNight || self == .night
        }
    }
    
    // MARK: - Color Adjustments
    
    static func adjustedWarmColor(_ baseColor: Color, for timeOfDay: TimeOfDay) -> Color {
        // Slightly adjust warmth based on time
        // Morning: brighter, Night: calmer
        return baseColor.opacity(timeOfDay.warmthLevel)
    }
}
