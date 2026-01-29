//
//  StripeConfig.swift
//  Ibtida
//
//  Single source of truth for Stripe publishable key. Load at app launch.
//  Info.plist key MUST be named exactly: StripePublishableKey
//  Fallback: environment variable STRIPE_PUBLISHABLE_KEY (debug only).
//  Never log full key; only prefix (pk_test_ / pk_live_) for verification.
//

import Foundation

enum StripeConfig {
    /// Exact key name required in Info.plist (target must include the plist).
    private static let infoPlistKey = "StripePublishableKey"
    private static let envKey = "STRIPE_PUBLISHABLE_KEY"

    /// Valid prefixes; key must match one of these or we treat as missing.
    private static let validPrefixes = ["pk_test_", "pk_live_"]

    /// Raw load: Info.plist (StripePublishableKey) first, then env STRIPE_PUBLISHABLE_KEY.
    /// Does not validate prefix; use publishableKey for validated key.
    static func loadPublishableKey() -> String {
        if let key = Bundle.main.object(forInfoDictionaryKey: infoPlistKey) as? String, !key.trimmingCharacters(in: .whitespaces).isEmpty {
            return key.trimmingCharacters(in: .whitespaces)
        }
        if let key = ProcessInfo.processInfo.environment[envKey], !key.trimmingCharacters(in: .whitespaces).isEmpty {
            return key.trimmingCharacters(in: .whitespaces)
        }
        #if DEBUG
        print("❌ Stripe publishable key not set. Set Info.plist key '\(infoPlistKey)' or env \(envKey). Payment will fail.")
        #endif
        return ""
    }

    /// Validated publishable key for Stripe SDK. Use this at app launch.
    /// Returns non-empty only if key starts with "pk_test_" or "pk_live_"; never logs full key.
    static var publishableKey: String {
        let raw = loadPublishableKey()
        guard !raw.isEmpty else { return "" }
        let valid = validPrefixes.contains { raw.hasPrefix($0) }
        if !valid {
            #if DEBUG
            print("❌ Stripe key invalid: must start with pk_test_ or pk_live_ (prefix only, never log full key)")
            #endif
            return ""
        }
        return raw
    }

    /// Safe log: key mode only (pk_test_ / pk_live_). Never log full key.
    static func logKeyMode(_ key: String) {
        guard !key.isEmpty else {
            #if DEBUG
            print("🔑 Stripe key: NOT SET (payment will fail)")
            #endif
            return
        }
        #if DEBUG
        if key.hasPrefix("pk_test_") {
            print("🔑 Stripe key mode: TEST (pk_test_...)")
        } else if key.hasPrefix("pk_live_") {
            print("🔑 Stripe key mode: LIVE (pk_live_...)")
        } else {
            print("🔑 Stripe key: invalid prefix (expected pk_test_ or pk_live_)")
        }
        #endif
    }

    /// Human-readable key mode for diagnostics UI (never full key).
    static func keyModeDescription() -> String {
        let key = loadPublishableKey()
        if key.isEmpty { return "Not set" }
        if key.hasPrefix("pk_test_") { return "TEST (pk_test_...)" }
        if key.hasPrefix("pk_live_") { return "LIVE (pk_live_...)" }
        return "Invalid prefix"
    }

    /// Minimum amount in cents (Stripe / backend)
    static let minAmountCents = 50

    /// Base URL for Firebase Functions (for diagnostics)
    static var functionsBaseURL: String {
        let projectId = "ibtida-b1b7c"
        return "https://us-central1-\(projectId).cloudfunctions.net"
    }
}
