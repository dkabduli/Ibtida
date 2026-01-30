//
//  DonationsPage.swift
//  Ibtida
//
//  Main Donations page - Warm, polished design
//  Contains Requests as a nested section
//

import SwiftUI
import FirebaseAuth

struct DonationsPage: View {
    @EnvironmentObject var authService: AuthService
    /// User's own donation requests (users/{uid}/requests); no global community feed for regular users.
    @StateObject private var myRequestsViewModel = RequestsViewModel()
    @StateObject private var creditConversionViewModel = CreditConversionViewModel()
    @Environment(\.colorScheme) var colorScheme
    @State private var selectedSection: DonationSection = .overview
    @State private var showCreateRequest = false
    
    enum DonationSection: String, CaseIterable {
        case overview = "Overview"
        case requests = "My Requests"
        case charities = "Charities"
        case creditConversion = "Convert Credits"
        
        var icon: String {
            switch self {
            case .overview: return "heart.fill"
            case .requests: return "hand.raised.fill"
            case .charities: return "building.columns.fill"
            case .creditConversion: return "arrow.triangle.2.circlepath"
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                WarmBackgroundView()
                
                VStack(spacing: 0) {
                    // Section selector
                    sectionSelector
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                    
                    // Content
                    switch selectedSection {
                    case .overview:
                        overviewContent
                    case .requests:
                        requestsContent
                    case .charities:
                        charitiesContent
                    case .creditConversion:
                        creditConversionContent
                    }
                }
            }
            .navigationTitle("Donations")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                myRequestsViewModel.loadRequests()
            }
            .sheet(isPresented: $showCreateRequest) {
                CreateRequestView(viewModel: myRequestsViewModel)
            }
        }
    }
    
    // MARK: - Section Selector
    
    private var sectionSelector: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(DonationSection.allCases, id: \.self) { section in
                        Button(action: {
                            HapticFeedback.light()
                            withAnimation(.spring(response: 0.3)) {
                                selectedSection = section
                                // Scroll to selected section
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    proxy.scrollTo(section, anchor: .center)
                                }
                            }
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: section.icon)
                                    .font(.system(size: 12, weight: .semibold))
                                Text(section.rawValue)
                                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.85)
                            }
                            .foregroundColor(selectedSection == section ? .white : Color.warmText(colorScheme))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .frame(minHeight: 44)
                            .fixedSize(horizontal: true, vertical: false)
                            .background(
                                Capsule()
                                    .fill(selectedSection == section ? LinearGradient.goldAccent : LinearGradient(colors: [Color.warmCard(colorScheme)], startPoint: .leading, endPoint: .trailing))
                            )
                            .overlay(
                                Capsule()
                                    .strokeBorder(selectedSection == section ? Color.clear : Color.warmBorder(colorScheme), lineWidth: 1)
                            )
                        }
                        .buttonStyle(SmoothButtonStyle())
                        .id(section)
                    }
                }
                .padding(.horizontal, 20)
            }
            .onChange(of: selectedSection) { _, newSection in
                // Ensure selected section is visible when changed
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        proxy.scrollTo(newSection, anchor: .center)
                    }
                }
            }
        }
    }
    
    // MARK: - Overview Content
    
    private var overviewContent: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 24) {
                // Islamic charity card
                islamicCharityCard
                
                // Quick actions
                quickActionsSection
                
                // Featured requests
                featuredRequestsSection
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 32)
        }
    }
    
    private var islamicCharityCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                ZStack {
                    Circle()
                        .fill(Color.softTerracotta.opacity(0.15))
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: "heart.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.softTerracotta)
                }
                
                Text("Sadaqah & Charity")
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundColor(Color.warmText(colorScheme))
            }
            
            Text("\"The believer's shade on the Day of Resurrection will be their charity.\"")
                .font(.system(size: 15, weight: .medium, design: .serif))
                .foregroundColor(Color.warmSecondaryText(colorScheme))
                .italic()
            
            Text("— Prophet Muhammad ﷺ")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(Color.mutedGold)
            
            Divider()
                .background(Color.warmBorder(colorScheme))
            
            Text("Support those in need through verified, halal charitable causes.")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Color.warmSecondaryText(colorScheme))
        }
        .padding(20)
        .warmCard(elevation: .high)
        .accessibleCard(label: "Islamic charity information card")
    }
    
    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            WarmSectionHeader("Quick Actions", icon: "bolt.fill")
            
            HStack(spacing: 14) {
                WarmQuickActionButton(
                    icon: "hand.raised.fill",
                    title: "My Requests",
                    color: .softTerracotta
                ) {
                    selectedSection = .requests
                }
                
                WarmQuickActionButton(
                    icon: "building.columns.fill",
                    title: "Charities",
                    color: .softOlive
                ) {
                    selectedSection = .charities
                }
            }
        }
    }
    
    private var featuredRequestsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                WarmSectionHeader("My Requests", icon: "sparkles")
                
                Spacer()
                
                Button("See All") {
                    selectedSection = .requests
                }
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.mutedGold)
            }
            
            if myRequestsViewModel.requests.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "tray")
                        .font(.system(size: 28))
                        .foregroundColor(Color.warmSecondaryText(colorScheme).opacity(0.5))
                    
                    Text("No requests yet")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(Color.warmSecondaryText(colorScheme))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 32)
                .warmCard(elevation: .low)
            } else {
                VStack(spacing: 12) {
                    ForEach(myRequestsViewModel.requests.prefix(3)) { request in
                        RequestCard(request: request)
                    }
                }
            }
        }
    }
    
    // MARK: - Requests Content (user's own requests only)
    
    private var requestsContent: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                if authService.isLoggedIn {
                    Button(action: { showCreateRequest = true }) {
                        HStack(spacing: 10) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 18))
                            Text("Create Request")
                                .font(.system(size: 16, weight: .semibold, design: .rounded))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(LinearGradient.goldAccent)
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .buttonStyle(SmoothButtonStyle())
                } else {
                    signInPromptCard
                }
                
                if myRequestsViewModel.isLoading {
                    ProgressView()
                        .tint(.mutedGold)
                        .padding(40)
                } else if myRequestsViewModel.requests.isEmpty {
                    emptyRequestsView
                } else {
                    ForEach(myRequestsViewModel.requests) { request in
                        RequestCard(request: request)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 32)
        }
        .refreshable {
            myRequestsViewModel.loadRequests()
        }
    }
    
    private var signInPromptCard: some View {
        VStack(spacing: 14) {
            Image(systemName: "person.crop.circle")
                .font(.system(size: 36))
                .foregroundColor(Color.warmSecondaryText(colorScheme).opacity(0.5))
            
            Text("Sign in to create requests")
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(Color.warmSecondaryText(colorScheme))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 28)
        .warmCard(elevation: .low)
    }
    
    private var emptyRequestsView: some View {
        EmptyRequestsView(
            onCreateRequest: {
                HapticFeedback.medium()
                showCreateRequest = true
            }
        )
        .warmCard(elevation: .medium)
    }
    
    // MARK: - Charities Content
    
    private var charitiesContent: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                WarmSectionHeader("Choose a Cause", icon: "heart.circle.fill")
                    .padding(.horizontal, 20)
                
                VStack(spacing: 14) {
                    ForEach(DonationType.allTypes) { category in
                        WarmCharityCategoryCard(category: category)
                    }
                }
                .padding(.horizontal, 20)
            }
            .padding(.bottom, 32)
        }
    }
    
    // MARK: - Credit Conversion Content
    
    private var creditConversionContent: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 24) {
                if authService.isLoggedIn {
                    CreditConversionView(viewModel: creditConversionViewModel)
                } else {
                    signInPromptCard
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 32)
        }
        .onAppear {
            if authService.isLoggedIn {
                creditConversionViewModel.loadUserCredits()
            }
        }
    }
}

// MARK: - Warm Quick Action Button

struct WarmQuickActionButton: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void
    
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.15))
                        .frame(width: 52, height: 52)
                    
                    Image(systemName: icon)
                        .font(.system(size: 22))
                        .foregroundColor(color)
                }
                
                Text(title)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundColor(Color.warmText(colorScheme))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .warmCard(elevation: .low)
        }
        .buttonStyle(SmoothButtonStyle())
    }
}

// MARK: - Warm Request Preview Card

struct WarmRequestPreviewCard: View {
    let request: CommunityRequest
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(request.title)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundColor(Color.warmText(colorScheme))
                    .lineLimit(1)
                
                Spacer()
                
                Text(request.status.displayName)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(statusColor)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(statusColor.opacity(0.12))
                    )
            }
            
            Text(request.description)
                .font(.system(size: 14))
                .foregroundColor(Color.warmSecondaryText(colorScheme))
                .lineLimit(2)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.warmSurface(colorScheme))
        )
    }
    
    private var statusColor: Color {
        switch request.status {
        case .open: return Color.prayerOnTime
        case .funded: return Color.prayerQada
        case .closed: return Color.prayerNone
        case .rejected: return Color.prayerMissed
        }
    }
}

// MARK: - Warm Community Request Card

struct WarmCommunityRequestCard: View {
    let request: CommunityRequest
    let onReport: () -> Void
    
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Header
            HStack {
                Text(request.title)
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                    .foregroundColor(Color.warmText(colorScheme))
                
                Spacer()
                
                Menu {
                    Button(action: onReport) {
                        Label("Report", systemImage: "flag")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 16))
                        .foregroundColor(Color.warmSecondaryText(colorScheme))
                        .padding(8)
                }
            }
            
            // Description
            Text(request.description)
                .font(.system(size: 15))
                .foregroundColor(Color.warmSecondaryText(colorScheme))
            
            // Progress if has goal
            if let goal = request.goalAmount, let raised = request.raisedAmount {
                VStack(spacing: 8) {
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 5)
                                .fill(Color.warmSurface(colorScheme))
                                .frame(height: 10)
                            
                            RoundedRectangle(cornerRadius: 5)
                                .fill(LinearGradient.goldAccent)
                                .frame(width: geometry.size.width * request.progress, height: 10)
                        }
                    }
                    .frame(height: 10)
                    
                    HStack {
                        Text("$\(Int(raised)) raised")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(Color.warmSecondaryText(colorScheme))
                        
                        Spacer()
                        
                        Text("Goal: $\(Int(goal))")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(Color.warmSecondaryText(colorScheme))
                    }
                }
            }
            
            Divider()
                .background(Color.warmBorder(colorScheme))
            
            // Footer
            HStack {
                if let name = request.createdByName {
                    Text("by \(name)")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(Color.warmSecondaryText(colorScheme))
                }
                
                Spacer()
                
                Text(request.createdAt.formatted(date: .abbreviated, time: .omitted))
                    .font(.system(size: 13))
                    .foregroundColor(Color.warmSecondaryText(colorScheme))
            }
        }
        .padding(18)
        .warmCard(elevation: .medium)
    }
}

// MARK: - Warm Charity Category Card

struct WarmCharityCategoryCard: View {
    let category: DonationType
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        NavigationLink(destination: CategoryCharitiesView(category: category)) {
            HStack(spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(category.accentColor.opacity(0.15))
                        .frame(width: 54, height: 54)
                    
                    Image(systemName: category.icon)
                        .font(.system(size: 24))
                        .foregroundColor(category.accentColor)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(category.title)
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundColor(Color.warmText(colorScheme))
                    
                    Text(category.shortDescription)
                        .font(.system(size: 14))
                        .foregroundColor(Color.warmSecondaryText(colorScheme))
                        .lineLimit(1)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Color.warmSecondaryText(colorScheme))
            }
            .padding(16)
            .warmCard(elevation: .low)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Warm Create Request Sheet

struct WarmCreateRequestSheet: View {
    @ObservedObject var viewModel: CommunityRequestsViewModel
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    
    @State private var title = ""
    @State private var description = ""
    @State private var goalAmount = ""
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.warmBackground(colorScheme).ignoresSafeArea()
                
                Form {
                    Section {
                        TextField("Title", text: $title)
                    } header: {
                        Text("Request Title")
                    }
                    .listRowBackground(Color.warmCard(colorScheme))
                    
                    Section {
                        TextEditor(text: $description)
                            .frame(minHeight: 100)
                    } header: {
                        Text("Description")
                    } footer: {
                        Text("Explain what help is needed and why")
                    }
                    .listRowBackground(Color.warmCard(colorScheme))
                    
                    Section {
                        TextField("Amount (optional)", text: $goalAmount)
                            .keyboardType(.decimalPad)
                    } header: {
                        Text("Goal Amount ($)")
                    } footer: {
                        Text("Leave empty if not seeking a specific amount")
                    }
                    .listRowBackground(Color.warmCard(colorScheme))
                    
                    Section {
                        Text("All requests are visible to the community. Please ensure your request is genuine and respectful.")
                            .font(.system(size: 14))
                            .foregroundColor(Color.warmSecondaryText(colorScheme))
                    }
                    .listRowBackground(Color.warmCard(colorScheme))
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Create Request")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(Color.warmSecondaryText(colorScheme))
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Submit") { submitRequest() }
                        .foregroundColor(.mutedGold)
                        .fontWeight(.semibold)
                        .disabled(title.isEmpty || description.isEmpty || viewModel.isCreating)
                }
            }
            .overlay {
                if viewModel.isCreating {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                    ProgressView()
                        .tint(.white)
                }
            }
        }
    }
    
    private func submitRequest() {
        let goal = Double(goalAmount)
        Task {
            let success = await viewModel.createRequest(
                title: title,
                description: description,
                goalAmount: goal
            )
            if success {
                dismiss()
            }
        }
    }
}

// MARK: - Preview

#Preview {
    DonationsPage()
        .environmentObject(AuthService.shared)
}
