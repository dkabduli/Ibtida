//
//  DonateView.swift
//  Ibtida
//
//  Premium donation page with tabs: Charities / History / Receipts / Requests
//

import SwiftUI
import FirebaseAuth
import SafariServices

struct DonateView: View {
    @EnvironmentObject var authService: AuthService
    @StateObject private var viewModel = DonationViewModel()
    @State private var selectedTab: DonationTab = .charities
    @State private var selectedCategory: DonationType?
    @State private var showMatchDonationSafari = false
    
    enum DonationTab: String, CaseIterable {
        case charities = "Charities"
        case history = "History"
        case receipts = "Receipts"
        case requests = "Requests"
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Tab selector
                    tabSelector
                        .padding(.horizontal, AppSpacing.lg)
                        .padding(.vertical, AppSpacing.md)
                    
                    // Tab content
                    TabView(selection: $selectedTab) {
                        charitiesTab
                            .tag(DonationTab.charities)
                        
                        historyTab
                            .tag(DonationTab.history)
                        
                        receiptsTab
                            .tag(DonationTab.receipts)
                        
                        requestsTab
                            .tag(DonationTab.requests)
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                }
            }
            .navigationTitle("Donate")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                Task {
                    await viewModel.loadUserProfile()
                    await viewModel.loadDonationHistory()
                    await viewModel.loadReceipts()
                }
            }
            .navigationDestination(item: $selectedCategory) { category in
                CategoryCharitiesView(category: category)
            }
            .onChange(of: viewModel.shouldOpenDonationURL) { _, url in
                if url != nil {
                    showMatchDonationSafari = true
                }
            }
            .sheet(isPresented: $showMatchDonationSafari, onDismiss: {
                viewModel.shouldOpenDonationURL = nil
            }) {
                if let url = viewModel.shouldOpenDonationURL {
                    SafariView(url: url)
                }
            }
        }
    }
    
    // MARK: - Tab Selector
    
    private var tabSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AppSpacing.sm) {
                ForEach(DonationTab.allCases, id: \.self) { tab in
                    Button(action: {
                        HapticFeedback.light()
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            selectedTab = tab
                        }
                    }) {
                        Text(tab.rawValue)
                            .font(AppTypography.subheadlineBold)
                            .foregroundColor(selectedTab == tab ? .white : .primary)
                            .padding(.horizontal, AppSpacing.lg)
                            .padding(.vertical, AppSpacing.sm)
                            .background(
                                Capsule()
                                    .fill(selectedTab == tab ? Color.accentColor : Color(.secondarySystemBackground))
                                    .overlay(
                                        Capsule()
                                            .stroke(Color(.separator).opacity(0.3), lineWidth: selectedTab == tab ? 0 : 1)
                                    )
                            )
                    }
                    .buttonStyle(SmoothButtonStyle())
                }
            }
            .padding(.horizontal, AppSpacing.xs)
        }
    }
    
    // MARK: - Charities Tab
    
    private var charitiesTab: some View {
        ScrollView {
            VStack(spacing: AppSpacing.xl) {
                // Credit Conversion Section
                creditConversionSection
                    .padding(.horizontal, AppSpacing.lg)
                
                // Match Donation Section
                matchDonationSection
                    .padding(.horizontal, AppSpacing.lg)
                
                // Choose a Cause Section
                causesSection
                    .padding(.horizontal, AppSpacing.lg)
            }
            .padding(.vertical, AppSpacing.lg)
        }
    }
    
    // MARK: - Credit Conversion Section
    
    private var creditConversionSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            HStack {
                Image(systemName: "creditcard.fill")
                    .foregroundColor(.accentColor)
                Text("Your Credits")
                    .font(AppTypography.title3)
                    .foregroundColor(.primary)
            }
            
            if let profile = viewModel.userProfile {
                VStack(spacing: AppSpacing.lg) {
                    // Current balance with premium styling
                    HStack {
                        VStack(alignment: .leading, spacing: AppSpacing.xs) {
                            Text("Current Balance")
                                .font(AppTypography.caption)
                                .foregroundColor(.secondary)
                            Text("\(profile.credits)")
                                .font(AppTypography.largeTitle)
                                .foregroundColor(.primary)
                            + Text(" credits")
                                .font(AppTypography.subheadline)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        
                        // Visual credit indicator
                        ZStack {
                            Circle()
                                .fill(Color.accentColor.opacity(0.1))
                                .frame(width: 60, height: 60)
                            Image(systemName: "star.fill")
                                .font(.system(size: 28))
                                .foregroundColor(.accentColor)
                        }
                    }
                    
                    Divider()
                        .background(Color(.separator))
                    
                    // Conversion rate info
                    HStack {
                        Image(systemName: "arrow.left.arrow.right")
                            .foregroundColor(.secondary)
                        Text("100 credits = $1.00")
                            .font(AppTypography.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                    
                    // Conversion slider
                    if profile.credits > 0 {
                        VStack(alignment: .leading, spacing: AppSpacing.sm) {
                            Text("Convert Credits")
                                .font(AppTypography.subheadlineBold)
                            
                            HStack {
                                Slider(
                                    value: Binding(
                                        get: { Double(viewModel.creditsToConvert) },
                                        set: { viewModel.creditsToConvert = Int($0) }
                                    ),
                                    in: 0...Double(max(profile.credits, 1)),
                                    step: 10
                                )
                                .accentColor(.accentColor)
                                
                                Text("\(viewModel.creditsToConvert)")
                                    .font(AppTypography.bodyBold)
                                    .foregroundColor(.primary)
                                    .frame(width: 60, alignment: .trailing)
                            }
                            
                            HStack {
                                Text("Dollar Value:")
                                    .font(AppTypography.caption)
                                    .foregroundColor(.secondary)
                                Text("$\(String(format: "%.2f", viewModel.convertedDollarValue))")
                                    .font(AppTypography.bodyBold)
                                    .foregroundColor(.trustGreen)
                            }
                        }
                        
                        // Convert button
                        Button(action: {
                            HapticFeedback.medium()
                            Task {
                                await viewModel.convertCredits()
                            }
                        }) {
                            HStack {
                                if viewModel.isConverting {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .scaleEffect(0.8)
                                } else {
                                    Image(systemName: "arrow.triangle.2.circlepath")
                                    Text("Convert Credits")
                                }
                            }
                            .font(AppTypography.bodyBold)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(viewModel.canConvert ? Color.accentColor : Color(.tertiarySystemBackground))
                            .foregroundColor(viewModel.canConvert ? .white : .secondary)
                            .cornerRadius(12)
                        }
                        .disabled(!viewModel.canConvert || viewModel.isConverting)
                        .buttonStyle(SmoothButtonStyle())
                    }
                }
            } else {
                HStack {
                    ProgressView()
                    Text("Loading...")
                        .font(AppTypography.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding()
            }
        }
        .premiumCard()
    }
    
    // MARK: - Match Donation Section
    
    private var matchDonationSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            HStack {
                Image(systemName: "heart.circle.fill")
                    .foregroundColor(.pink)
                Text("Match Your Donation")
                    .font(AppTypography.title3)
                    .foregroundColor(.primary)
            }
            
            if let profile = viewModel.userProfile, viewModel.creditsToConvert > 0 {
                VStack(spacing: AppSpacing.lg) {
                    Text("Double the impact by matching your credit donation")
                        .font(AppTypography.subheadline)
                        .foregroundColor(.secondary)
                    
                    // Multiplier buttons
                    HStack(spacing: AppSpacing.md) {
                        ForEach([1.0, 2.0, 3.0], id: \.self) { multiplier in
                            MultiplierButton(
                                multiplier: multiplier,
                                isSelected: viewModel.matchMultiplier == multiplier,
                                onTap: {
                                    HapticFeedback.light()
                                    viewModel.matchMultiplier = multiplier
                                }
                            )
                        }
                    }
                    
                    // Match amount display
                    HStack {
                        VStack(alignment: .leading, spacing: AppSpacing.xs) {
                            Text("Total Donation Value")
                                .font(AppTypography.caption)
                                .foregroundColor(.secondary)
                            Text("$\(String(format: "%.2f", viewModel.matchDollarValue))")
                                .font(AppTypography.title2)
                                .foregroundColor(.trustGreen)
                        }
                        Spacer()
                        Text("\(Int(viewModel.matchMultiplier))x")
                            .font(AppTypography.largeTitle)
                            .foregroundColor(.accentColor.opacity(0.3))
                    }
                    
                    // Open donation button
                    Button(action: {
                        HapticFeedback.medium()
                        Task {
                            await viewModel.openMatchDonation()
                        }
                    }) {
                        HStack {
                            Image(systemName: "arrow.up.right.square")
                            Text("Open Matching Donation")
                        }
                        .font(AppTypography.bodyBold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            LinearGradient(
                                colors: [Color.accentColor, Color.accentColor.opacity(0.8)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .buttonStyle(SmoothButtonStyle())
                }
            } else {
                VStack(spacing: AppSpacing.md) {
                    Image(systemName: "heart.text.square")
                        .font(.system(size: 40))
                        .foregroundColor(.secondary.opacity(0.5))
                    
                    Text("Select credits to convert above to unlock matching donations")
                        .font(AppTypography.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding()
            }
        }
        .premiumCard()
    }
    
    // MARK: - Causes Section
    
    private var causesSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text("Choose a Cause")
                    .font(AppTypography.title2)
                    .foregroundColor(.primary)
                
                Text("Select a category to find verified charities")
                    .font(AppTypography.subheadline)
                    .foregroundColor(.secondary)
            }
            
            VStack(spacing: AppSpacing.md) {
                ForEach(DonationType.allTypes) { category in
                    PremiumCategoryCard(category: category) {
                        HapticFeedback.light()
                        selectedCategory = category
                    }
                }
            }
        }
        .padding(AppSpacing.xl)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.secondarySystemBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color(.separator).opacity(0.3), lineWidth: 0.5)
                )
        )
        .softShadow()
    }
    
    // MARK: - History Tab
    
    private var historyTab: some View {
        ScrollView {
            VStack(spacing: AppSpacing.lg) {
                if viewModel.donationHistory.isEmpty {
                    EmptyStateView(
                        icon: "clock.arrow.circlepath",
                        title: "No Donation History",
                        message: "Your donation activity will appear here"
                    )
                    .padding(.top, AppSpacing.xxxl)
                } else {
                    ForEach(viewModel.donationHistory) { donation in
                        DonationHistoryCard(donation: donation)
                    }
                }
            }
            .padding(AppSpacing.lg)
        }
    }
    
    // MARK: - Receipts Tab
    
    private var receiptsTab: some View {
        ScrollView {
            VStack(spacing: AppSpacing.lg) {
                if viewModel.receipts.isEmpty {
                    EmptyStateView(
                        icon: "doc.text",
                        title: "No Receipts",
                        message: "Donation receipts will appear here after you donate"
                    )
                    .padding(.top, AppSpacing.xxxl)
                } else {
                    ForEach(viewModel.receipts) { receipt in
                        ReceiptCard(receipt: receipt)
                    }
                }
            }
            .padding(AppSpacing.lg)
        }
    }
    
    // MARK: - Requests Tab
    
    private var requestsTab: some View {
        ScrollView {
            VStack(spacing: AppSpacing.lg) {
                // Info card
                VStack(alignment: .leading, spacing: AppSpacing.md) {
                    HStack {
                        Image(systemName: "hand.raised.fill")
                            .foregroundColor(.orange)
                        Text("Donation Requests")
                            .font(AppTypography.title3)
                    }
                    
                    Text("Request donations on behalf of someone in need. All requests are reviewed before being published.")
                        .font(AppTypography.subheadline)
                        .foregroundColor(.secondary)
                    
                    Button(action: {
                        viewModel.showCreateRequest = true
                    }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("Create Request")
                        }
                        .font(AppTypography.bodyBold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .buttonStyle(SmoothButtonStyle())
                }
                .premiumCard()
                
                if viewModel.donationRequests.isEmpty {
                    EmptyStateView(
                        icon: "person.2.fill",
                        title: "No Active Requests",
                        message: "Donation requests from the community will appear here"
                    )
                } else {
                    ForEach(viewModel.donationRequests) { request in
                        DonationRequestCard(request: request)
                    }
                }
            }
            .padding(AppSpacing.lg)
        }
        .sheet(isPresented: $viewModel.showCreateRequest) {
            CreateDonationRequestView(viewModel: viewModel)
        }
    }
}

// MARK: - Premium Category Card

struct PremiumCategoryCard: View {
    let category: DonationType
    let onTap: () -> Void
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: AppSpacing.lg) {
                // Icon with colored background - premium styling
                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(
                            LinearGradient(
                                colors: [
                                    category.accentColor.opacity(colorScheme == .dark ? 0.2 : 0.15),
                                    category.accentColor.opacity(colorScheme == .dark ? 0.1 : 0.08)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 60, height: 60)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(category.accentColor.opacity(0.2), lineWidth: 1)
                        )
                    
                    Image(systemName: category.icon)
                        .font(.system(size: 28, weight: .medium))
                        .foregroundColor(category.accentColor)
                        .symbolEffect(.pulse.byLayer, options: .repeat(1))
                }
                
                // Text content with better hierarchy
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    Text(category.title)
                        .font(AppTypography.bodyBold)
                        .foregroundColor(.primary)
                    
                    Text(category.shortDescription)
                        .font(AppTypography.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
                
                Spacer(minLength: AppSpacing.sm)
                
                // Chevron with subtle animation
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(category.accentColor.opacity(0.6))
            }
            .padding(AppSpacing.lg)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(Color(.tertiarySystemBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(
                                colorScheme == .dark
                                    ? category.accentColor.opacity(0.35)
                                    : category.accentColor.opacity(0.25),
                                lineWidth: colorScheme == .dark ? 1.5 : 1
                            )
                    )
            )
            .shadow(
                color: colorScheme == .dark
                    ? category.accentColor.opacity(0.08)
                    : Color.black.opacity(0.04),
                radius: 8,
                x: 0,
                y: 2
            )
        }
        .buttonStyle(InteractiveCardButtonStyle())
    }
}

// MARK: - Multiplier Button

struct MultiplierButton: View {
    let multiplier: Double
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: AppSpacing.xs) {
                Text("\(Int(multiplier))x")
                    .font(AppTypography.title3)
                Text("Match")
                    .font(AppTypography.caption)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, AppSpacing.md)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.accentColor : Color(.tertiarySystemBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? Color.clear : Color(.separator).opacity(0.3), lineWidth: 1)
                    )
            )
            .foregroundColor(isSelected ? .white : .primary)
        }
        .buttonStyle(SmoothButtonStyle())
    }
}

// MARK: - Empty State View

struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    
    var body: some View {
        VStack(spacing: AppSpacing.lg) {
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundColor(.secondary.opacity(0.4))
            
            VStack(spacing: AppSpacing.xs) {
                Text(title)
                    .font(AppTypography.title3)
                    .foregroundColor(.primary)
                
                Text(message)
                    .font(AppTypography.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(AppSpacing.xxxl)
    }
}

// MARK: - Donation History Card

struct DonationHistoryCard: View {
    let donation: Donation
    
    var body: some View {
        HStack(spacing: AppSpacing.lg) {
            ZStack {
                Circle()
                    .fill(Color.trustGreen.opacity(0.1))
                    .frame(width: 44, height: 44)
                Image(systemName: "heart.fill")
                    .foregroundColor(.trustGreen)
            }
            
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text("Donation")
                    .font(AppTypography.bodyBold)
                Text(donation.createdAt.formatted(date: .abbreviated, time: .shortened))
                    .font(AppTypography.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text("$\(String(format: "%.2f", donation.amount))")
                .font(AppTypography.bodyBold)
                .foregroundColor(.trustGreen)
        }
        .padding(AppSpacing.lg)
        .cardStyle(padding: 0)
    }
}

// MARK: - Receipt Card

struct ReceiptCard: View {
    let receipt: Receipt
    
    var body: some View {
        HStack(spacing: AppSpacing.lg) {
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.1))
                    .frame(width: 44, height: 44)
                Image(systemName: "doc.text.fill")
                    .foregroundColor(.blue)
            }
            
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text(receipt.charityName)
                    .font(AppTypography.bodyBold)
                Text(receipt.createdAt.formatted(date: .abbreviated, time: .omitted))
                    .font(AppTypography.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: AppSpacing.xs) {
                Text("$\(String(format: "%.2f", receipt.amount))")
                    .font(AppTypography.bodyBold)
                Text("Receipt")
                    .font(AppTypography.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(AppSpacing.lg)
        .cardStyle(padding: 0)
    }
}

// MARK: - Donation Request Models

struct DonationRequest: Identifiable, Codable {
    let id: String
    let userId: String
    let title: String
    let description: String
    let targetAmount: Double
    let raisedAmount: Double
    let status: String // "pending", "approved", "rejected"
    let createdAt: Date
}

// MARK: - Donation Request Card

struct DonationRequestCard: View {
    let request: DonationRequest
    
    var progress: Double {
        guard request.targetAmount > 0 else { return 0 }
        return min(request.raisedAmount / request.targetAmount, 1.0)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            HStack {
                Text(request.title)
                    .font(AppTypography.bodyBold)
                Spacer()
                Text(request.status.capitalized)
                    .font(AppTypography.caption)
                    .foregroundColor(request.status == "approved" ? .green : .orange)
                    .padding(.horizontal, AppSpacing.sm)
                    .padding(.vertical, AppSpacing.xs)
                    .background(
                        Capsule()
                            .fill(request.status == "approved" ? Color.green.opacity(0.1) : Color.orange.opacity(0.1))
                    )
            }
            
            Text(request.description)
                .font(AppTypography.caption)
                .foregroundColor(.secondary)
                .lineLimit(2)
            
            // Progress bar
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color(.tertiarySystemBackground))
                            .frame(height: 8)
                        
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.trustGreen)
                            .frame(width: geometry.size.width * progress, height: 8)
                    }
                }
                .frame(height: 8)
                
                HStack {
                    Text("$\(String(format: "%.0f", request.raisedAmount)) raised")
                        .font(AppTypography.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("Goal: $\(String(format: "%.0f", request.targetAmount))")
                        .font(AppTypography.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(AppSpacing.lg)
        .cardStyle(padding: 0)
    }
}

// MARK: - Create Donation Request View

struct CreateDonationRequestView: View {
    @ObservedObject var viewModel: DonationViewModel
    @Environment(\.dismiss) var dismiss
    
    @State private var title = ""
    @State private var description = ""
    @State private var targetAmount = ""
    @State private var isSubmitting = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Title", text: $title)
                } header: {
                    Text("Request Title")
                }
                
                Section {
                    TextEditor(text: $description)
                        .frame(minHeight: 100)
                } header: {
                    Text("Description")
                } footer: {
                    Text("Explain why this donation is needed")
                }
                
                Section {
                    TextField("Amount", text: $targetAmount)
                        .keyboardType(.decimalPad)
                } header: {
                    Text("Target Amount ($)")
                }
                
                Section {
                    Text("All requests are reviewed by moderators before being published. This helps ensure the integrity of our community.")
                        .font(AppTypography.caption)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Create Request")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Submit") {
                        submitRequest()
                    }
                    .disabled(title.isEmpty || description.isEmpty || targetAmount.isEmpty || isSubmitting)
                }
            }
        }
    }
    
    private func submitRequest() {
        isSubmitting = true
        // In a real app, this would submit to Firestore
        Task {
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            dismiss()
        }
    }
}
