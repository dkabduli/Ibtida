//
//  DonationError.swift
//  Ibtida
//
//  Shared donation error enum
//

import Foundation

enum DonationError: LocalizedError {
    case userNotLoggedIn
    case invalidAmount
    case insufficientCredits
    
    var errorDescription: String? {
        switch self {
        case .userNotLoggedIn:
            return "You must be logged in to make a donation."
        case .invalidAmount:
            return "Please enter a valid donation amount."
        case .insufficientCredits:
            return "You don't have enough credits for this donation."
        }
    }
}
