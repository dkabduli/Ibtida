//
//  DonationAmountParser.swift
//  Ibtida
//
//  Parses donation amount string to cents (integer). Sanitizes $, spaces, commas.
//
//  Test cases (parseToCents):
//    "5" -> 500
//    "5.00" -> 500
//    "$5" -> 500
//    "0.49" -> 49 (valid parse; below min 50)
//    "0.50" -> 50
//    "" -> nil
//    "abc" -> nil
//

import Foundation

enum DonationAmountParser {
    /// Minimum cents allowed (Stripe / backend)
    static let minCents = 50

    /// Sanitize input: remove $, spaces, commas
    static func sanitize(_ input: String) -> String {
        input
            .replacingOccurrences(of: "$", with: "")
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: ",", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Parse dollars string to cents (Int). Uses round to nearest cent.
    /// Returns nil if invalid. "5", "5.00", "$5" -> 500; "0.50" -> 50; "0.49" -> 49 (valid but below min).
    static func parseToCents(_ input: String) -> Int? {
        let cleaned = sanitize(input)
        guard !cleaned.isEmpty else { return nil }
        guard let value = Double(cleaned), value.isFinite, value >= 0 else { return nil }
        let cents = Int(round(value * 100))
        return cents
    }

    /// Parse and validate: returns cents only if >= minCents
    static func parseAndValidate(_ input: String) -> (cents: Int, error: String?)? {
        guard let cents = parseToCents(input) else {
            return nil
        }
        if cents < minCents {
            return (cents, "Minimum amount is $\(String(format: "%.2f", Double(minCents) / 100))")
        }
        return (cents, nil)
    }
}
