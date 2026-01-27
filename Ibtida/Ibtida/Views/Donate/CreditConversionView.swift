//
//  CreditConversionView.swift
//  Ibtida
//
//  Credit Conversion UI - Convert credits to donations
//

import SwiftUI
import FirebaseAuth

struct CreditConversionView: View {
    @ObservedObject var viewModel: CreditConversionViewModel
    @Environment(\.colorScheme) var colorScheme
    @State private var showCharityPicker = false
    
    var body: some View {
        VStack(spacing: 24) {
            // Header Card
            headerCard
            
            // Conversion Form
            conversionFormCard
            
            // Conversion History
            conversionHistoryCard
        }
    }
    
    // MARK: - Header Card
    
    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                ZStack {
                    Circle()
                        .fill(Color.mutedGold.opacity(0.15))
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .font(.system(size: 20))
                        .foregroundColor(.mutedGold)
                }
                
                Text("Convert Credits to Donation")
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundColor(Color.warmText(colorScheme))
            }
            
            Text("Convert your prayer credits into real donations. Admin will process your request and add the receipt to your account.")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Color.warmSecondaryText(colorScheme))
            
            HStack(spacing: 4) {
                Text("Conversion Rate:")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(Color.warmSecondaryText(colorScheme))
                Text("\(Int(CreditConversionViewModel.conversionRate)) credits = $1.00")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.mutedGold)
            }
            
            Divider()
                .background(Color.warmBorder(colorScheme))
            
            // Available Credits
            HStack {
                Text("Available Credits:")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(Color.warmSecondaryText(colorScheme))
                
                Spacer()
                
                Text("\(viewModel.totalCredits)")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.mutedGold)
            }
        }
        .padding(20)
        .warmCard(elevation: .high)
    }
    
    // MARK: - Conversion Form Card
    
    private var conversionFormCard: some View {
        VStack(alignment: .leading, spacing: 20) {
            WarmSectionHeader("Conversion Form", icon: "doc.text.fill")
            
            // Credits Input
            VStack(alignment: .leading, spacing: 8) {
                Text("Credits to Convert")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Color.warmText(colorScheme))
                
                TextField("Enter amount", text: $viewModel.creditsToConvert)
                    .keyboardType(.numberPad)
                    .padding(14)
                    .background(Color.warmSurface(colorScheme))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(Color.warmBorder(colorScheme), lineWidth: 1)
                    )
                
                if let credits = Int(viewModel.creditsToConvert), credits > 0 {
                    HStack {
                        Text("= $\(String(format: "%.2f", viewModel.dollarAmount))")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.mutedGold)
                        
                        Spacer()
                        
                        Text("\(viewModel.creditsRemaining) credits remaining")
                            .font(.system(size: 13))
                            .foregroundColor(Color.warmSecondaryText(colorScheme))
                    }
                }
                
                if let credits = Int(viewModel.creditsToConvert), credits > viewModel.totalCredits {
                    Text("Insufficient credits")
                        .font(.system(size: 13))
                        .foregroundColor(.red)
                }
            }
            
            // Charity Selection (Optional)
            VStack(alignment: .leading, spacing: 8) {
                Text("Charity (Optional)")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Color.warmText(colorScheme))
                
                Button(action: { showCharityPicker = true }) {
                    HStack {
                        Text(viewModel.selectedCharityName ?? "Select a charity")
                            .font(.system(size: 15))
                            .foregroundColor(viewModel.selectedCharityName != nil ? Color.warmText(colorScheme) : Color.warmSecondaryText(colorScheme))
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12))
                            .foregroundColor(Color.warmSecondaryText(colorScheme))
                    }
                    .padding(14)
                    .background(Color.warmSurface(colorScheme))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(Color.warmBorder(colorScheme), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
            }
            
            // Message (Optional)
            VStack(alignment: .leading, spacing: 8) {
                Text("Message to Admin (Optional)")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Color.warmText(colorScheme))
                
                TextEditor(text: $viewModel.message)
                    .frame(minHeight: 80)
                    .padding(8)
                    .background(Color.warmSurface(colorScheme))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(Color.warmBorder(colorScheme), lineWidth: 1)
                    )
            }
            
            // Error/Success Messages
            if let error = viewModel.errorMessage {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.red)
                    Text(error)
                        .font(.system(size: 14))
                        .foregroundColor(.red)
                }
                .padding(12)
                .background(Color.red.opacity(0.1))
                .cornerRadius(8)
            }
            
            if let success = viewModel.successMessage {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text(success)
                        .font(.system(size: 14))
                        .foregroundColor(.green)
                }
                .padding(12)
                .background(Color.green.opacity(0.1))
                .cornerRadius(8)
            }
            
            // Submit Button
            Button(action: {
                Task {
                    let success = await viewModel.submitConversionRequest()
                    if success {
                        HapticFeedback.success()
                    } else {
                        HapticFeedback.error()
                    }
                }
            }) {
                HStack {
                    if viewModel.isSubmitting {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Image(systemName: "paperplane.fill")
                        Text("Submit Conversion Request")
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    viewModel.canSubmit ? LinearGradient.goldAccent : LinearGradient(colors: [Color.gray.opacity(0.3)], startPoint: .leading, endPoint: .trailing)
                )
                .foregroundColor(.white)
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .buttonStyle(SmoothButtonStyle())
            .disabled(!viewModel.canSubmit || viewModel.isSubmitting)
        }
        .padding(20)
        .warmCard(elevation: .high)
        .sheet(isPresented: $showCharityPicker) {
            CharityPickerView(
                selectedCharityId: $viewModel.selectedCharityId,
                selectedCharityName: $viewModel.selectedCharityName
            )
        }
    }
    
    // MARK: - Conversion History Card
    
    private var conversionHistoryCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            WarmSectionHeader("Conversion History", icon: "clock.fill")
            
            if viewModel.isLoading {
                ProgressView()
                    .tint(.mutedGold)
                    .frame(maxWidth: .infinity)
                    .padding(40)
            } else if viewModel.conversionRequests.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "tray")
                        .font(.system(size: 28))
                        .foregroundColor(Color.warmSecondaryText(colorScheme).opacity(0.5))
                    
                    Text("No conversions yet")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(Color.warmSecondaryText(colorScheme))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 32)
            } else {
                VStack(spacing: 12) {
                    ForEach(viewModel.conversionRequests) { request in
                        ConversionRequestCard(request: request)
                    }
                }
            }
        }
        .padding(20)
        .warmCard(elevation: .medium)
    }
}

// MARK: - Conversion Request Card

struct ConversionRequestCard: View {
    let request: CreditConversionRequest
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(request.creditsToConvert) credits")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundColor(Color.warmText(colorScheme))
                    
                    Text("= $\(String(format: "%.2f", request.dollarAmount))")
                        .font(.system(size: 14))
                        .foregroundColor(.mutedGold)
                }
                
                Spacer()
                
                Text(request.status.displayName)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(statusColor)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(statusColor.opacity(0.15))
                    )
            }
            
            if let charityName = request.charityName {
                HStack {
                    Image(systemName: "building.columns.fill")
                        .font(.system(size: 12))
                        .foregroundColor(Color.warmSecondaryText(colorScheme))
                    Text(charityName)
                        .font(.system(size: 14))
                        .foregroundColor(Color.warmSecondaryText(colorScheme))
                }
            }
            
            Text(request.createdAt.formatted(date: .abbreviated, time: .shortened))
                .font(.system(size: 12))
                .foregroundColor(Color.warmSecondaryText(colorScheme))
        }
        .padding(14)
        .background(Color.warmSurface(colorScheme))
        .cornerRadius(12)
    }
    
    private var statusColor: Color {
        switch request.status {
        case .pending: return .orange
        case .processing: return .blue
        case .completed: return .green
        case .rejected: return .red
        }
    }
}

// MARK: - Charity Picker View

struct CharityPickerView: View {
    @Binding var selectedCharityId: String?
    @Binding var selectedCharityName: String?
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    private let charityService = CharityService.shared
    @State private var charities: [Charity] = []
    @State private var isLoading = true
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.warmBackground(colorScheme).ignoresSafeArea()
                
                if isLoading {
                    ProgressView()
                        .tint(.mutedGold)
                } else if charities.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "building.columns")
                            .font(.system(size: 32))
                            .foregroundColor(Color.warmSecondaryText(colorScheme).opacity(0.5))
                        Text("No charities available")
                            .font(.system(size: 15))
                            .foregroundColor(Color.warmSecondaryText(colorScheme))
                    }
                } else {
                    List {
                        Button(action: {
                            selectedCharityId = nil
                            selectedCharityName = nil
                            dismiss()
                        }) {
                            HStack {
                                Text("No specific charity")
                                    .foregroundColor(Color.warmText(colorScheme))
                                Spacer()
                                if selectedCharityId == nil {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.mutedGold)
                                }
                            }
                        }
                        .listRowBackground(Color.warmCard(colorScheme))
                        
                        ForEach(charities) { charity in
                            Button(action: {
                                selectedCharityId = charity.id
                                selectedCharityName = charity.name
                                dismiss()
                            }) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(charity.name)
                                            .font(.system(size: 15, weight: .semibold))
                                            .foregroundColor(Color.warmText(colorScheme))
                                        if !charity.description.isEmpty {
                                            Text(charity.description)
                                                .font(.system(size: 13))
                                                .foregroundColor(Color.warmSecondaryText(colorScheme))
                                                .lineLimit(2)
                                        }
                                    }
                                    
                                    Spacer()
                                    
                                    if selectedCharityId == charity.id {
                                        Image(systemName: "checkmark")
                                            .foregroundColor(.mutedGold)
                                    }
                                }
                            }
                            .listRowBackground(Color.warmCard(colorScheme))
                        }
                    }
                    .scrollContentBackground(.hidden)
                }
            }
            .navigationTitle("Select Charity")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(.mutedGold)
                }
            }
            .onAppear {
                loadCharities()
            }
        }
    }
    
    private func loadCharities() {
        isLoading = true
        do {
            charities = try charityService.loadCharities()
        } catch {
            #if DEBUG
            print("❌ CharityPickerView: Error loading charities - \(error)")
            #endif
        }
        isLoading = false
    }
}
