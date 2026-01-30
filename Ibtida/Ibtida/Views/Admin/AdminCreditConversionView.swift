//
//  AdminCreditConversionView.swift
//  Ibtida
//
//  Admin-only: edit credit conversion rate (admin/settings/creditConversion). Regular users cannot read/write.
//

import SwiftUI
import FirebaseFirestore

struct AdminCreditConversionView: View {
    @StateObject private var viewModel = AdminCreditConversionViewModel()
    
    var body: some View {
        Form {
            Section {
                if viewModel.isLoading {
                    ProgressView()
                } else {
                    HStack {
                        Text("Credits per $1 (CAD)")
                        Spacer()
                        TextField("100", text: $viewModel.creditsPerDollarString)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                    }
                }
            } header: {
                Text("Conversion rate")
            } footer: {
                Text("Displayed to users as \"X credits = $1.00\". Stored in admin/settings/creditConversion.")
            }
            
            Section {
                Button("Save") {
                    Task { await viewModel.save() }
                }
                .disabled(viewModel.isSaving || !viewModel.isValid)
            }
            
            if let message = viewModel.message {
                Section {
                    Text(message)
                        .foregroundColor(viewModel.isError ? .red : .secondary)
                }
            }
        }
        .navigationTitle("Credit Conversion")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            Task { await viewModel.load() }
        }
    }
}

@MainActor
class AdminCreditConversionViewModel: ObservableObject {
    @Published var creditsPerDollarString = "100"
    @Published var isLoading = false
    @Published var isSaving = false
    @Published var message: String?
    @Published var isError = false
    
    private let db = Firestore.firestore()
    private var settingsRef: DocumentReference {
        db.collection(FirestorePaths.admin).document(FirestorePaths.adminSettings)
    }
    // Stored as admin/settings document with nested map: creditConversion: { creditsPerDollar, currency, updatedAt }
    
    var isValid: Bool {
        guard let n = Int(creditsPerDollarString), n > 0 else { return false }
        return true
    }
    
    func load() async {
        isLoading = true
        message = nil
        defer { isLoading = false }
        
        do {
            let snap = try await settingsRef.getDocument()
            let data = snap.data()
            let conversion = data?["creditConversion"] as? [String: Any]
            if let credits = conversion?["creditsPerDollar"] as? Int {
                creditsPerDollarString = "\(credits)"
            } else {
                creditsPerDollarString = "100"
            }
        } catch {
            #if DEBUG
            print("❌ AdminCreditConversion: load failed - \(error)")
            #endif
            message = "Failed to load: \(error.localizedDescription)"
            isError = true
        }
    }
    
    func save() async {
        guard let credits = Int(creditsPerDollarString), credits > 0 else {
            message = "Enter a positive number."
            isError = true
            return
        }
        
        isSaving = true
        message = nil
        isError = false
        defer { isSaving = false }
        
        do {
            try await settingsRef.setData([
                "creditConversion": [
                    "creditsPerDollar": credits,
                    "currency": "cad",
                    "updatedAt": FieldValue.serverTimestamp(),
                ],
            ], merge: true)
            message = "Saved. \(credits) credits = $1.00 CAD."
            isError = false
        } catch {
            message = "Failed to save: \(error.localizedDescription)"
            isError = true
        }
    }
}
