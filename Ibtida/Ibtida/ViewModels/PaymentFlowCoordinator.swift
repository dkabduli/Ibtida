//
//  PaymentFlowCoordinator.swift
//  Ibtida
//
//  Coordinates payment: validate amount (>= 50¢), call createPaymentIntent once,
//  present PaymentSheet once per clientSecret, handle success/cancel/failure.
//  Prevents double-present and Alert + Sheet at same time.
//
//  Stripe TEST mode – card checklist:
//  - 4242 4242 4242 4242 → success
//  - 4000 0000 0000 9995 → insufficient funds (failure)
//  - 4000 0000 0000 0002 → declined
//  - Any future expiry, any CVC. See: https://stripe.com/docs/testing
//  In Stripe Dashboard: Payments → test mode to see PaymentIntents.
//

import Foundation

@MainActor
final class PaymentFlowCoordinator: ObservableObject {
    /// ClientSecret from createPaymentIntent; nil until we have one
    @Published private(set) var clientSecret: String?
    /// PaymentIntent id from createPaymentIntent response (for finalizeDonation after .completed)
    @Published private(set) var paymentIntentId: String?
    /// True when we should show the PaymentSheet (one present per clientSecret)
    @Published var shouldPresentSheet = false
    /// True while createPaymentIntent is in flight
    @Published private(set) var isCreatingIntent = false
    /// Error to show in Alert (only after sheet is dismissed)
    @Published var errorMessage: String?
    /// Lock: avoid presenting twice for same clientSecret
    private var hasPresentedForCurrentSecret = false

    private let functionsService = FirebaseFunctionsService.shared

    /// Start payment: validate, create intent once, then set clientSecret and shouldPresentSheet.
    /// Call from Continue button; amountCents must be >= 50. Currency is always CAD (enforced server-side).
    func startPayment(intakeId: String, amountCents: Int) async {
        guard amountCents >= StripeConfig.minAmountCents else {
            errorMessage = "Minimum amount is $0.50 (50¢)"
            return
        }
        isCreatingIntent = true
        errorMessage = nil
        clientSecret = nil
        paymentIntentId = nil
        shouldPresentSheet = false
        hasPresentedForCurrentSecret = false

        #if DEBUG
        // Stripe diagnostics at donation start
        let key = StripeConfig.publishableKey
        if key.isEmpty {
            print("❌ Stripe diagnostics: publishable key NOT SET – PaymentSheet will fail. Set Info.plist StripePublishableKey.")
        } else {
            print("🔑 Stripe diagnostics: key set (\(key.hasPrefix("pk_test_") ? "TEST" : "LIVE")), baseURL=\(StripeConfig.functionsBaseURL)")
        }
        print("📤 PaymentFlow: createPaymentIntent intakeId=\(intakeId), amountCents=\(amountCents), currency enforced: cad")
        #endif

        do {
            let response = try await functionsService.createPaymentIntent(
                intakeId: intakeId,
                amountCents: amountCents
            )
            clientSecret = response.clientSecret
            paymentIntentId = response.paymentIntentId
                ?? FirebaseFunctionsService.parsePaymentIntentId(from: response.clientSecret)
            isCreatingIntent = false
            if response.clientSecret.isEmpty {
                errorMessage = "No client secret returned"
                return
            }
            #if DEBUG
            print("📥 Stripe diagnostics: clientSecret prefix=\(response.clientSecret.prefix(24))..., paymentIntentId=\(paymentIntentId ?? "nil")")
            #endif
            shouldPresentSheet = true
        } catch {
            isCreatingIntent = false
            errorMessage = error.localizedDescription
            #if DEBUG
            print("❌ PaymentFlow: createPaymentIntent failed \(error.localizedDescription)")
            #endif
        }
    }

    /// Call when PaymentSheet is presented (so we only present once per clientSecret)
    func markSheetPresented() {
        hasPresentedForCurrentSecret = true
    }

    /// Should we allow presenting? Only if we have a secret and haven't presented yet for it.
    var canPresentSheet: Bool {
        guard let secret = clientSecret, !secret.isEmpty else { return false }
        return !hasPresentedForCurrentSecret
    }

    /// Call when sheet is dismissed (success, cancel, or failure). Clears present state; error shown via errorMessage.
    func onSheetDismissed() {
        shouldPresentSheet = false
    }

    /// On success: clear sheet state; caller can set success UI.
    func onSuccess() {
        shouldPresentSheet = false
        errorMessage = nil
    }

    /// On failure: dismiss sheet first, then set error so Alert shows after sheet is gone.
    func onFailure(_ error: Error) {
        shouldPresentSheet = false
        errorMessage = "Payment failed: \(error.localizedDescription)"
    }

    /// On cancel: just dismiss sheet.
    func onCancel() {
        shouldPresentSheet = false
        errorMessage = nil
    }
}
