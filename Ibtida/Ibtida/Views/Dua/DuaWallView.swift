//
//  DuaWallView.swift
//  Ibtida
//
//  Dua Wall - community duas with daily dua feature
//  Broken into smaller subviews to avoid compiler type-check timeouts
//

import SwiftUI

struct DuaWallView: View {
    @StateObject private var viewModel = DuaViewModel()
    @State private var showSubmitDua = false
    @State private var showFilterSheet = false
    @State private var isDailyDuaDismissed = false
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            ZStack {
                backgroundColor
                mainContent
            }
            .navigationTitle("Dua Wall")
            .navigationBarTitleDisplayMode(.large)
            .toolbar { toolbarContent }
            .sheet(isPresented: $showSubmitDua) {
                SubmitDuaView(viewModel: viewModel)
            }
            .sheet(isPresented: $showFilterSheet) {
                DuaFilterView(
                    selectedFilter: $viewModel.selectedFilter,
                    selectedTag: $viewModel.selectedTag,
                    allTags: viewModel.allTags
                )
            }
            .onAppear { handleOnAppear() }
            .refreshable { await refreshData() }
        }
    }
    
    // MARK: - Background
    
    @Environment(\.colorScheme) var colorScheme
    
    private var backgroundColor: some View {
        WarmBackgroundView()
    }
    
    // MARK: - Main Content
    
    private var mainContent: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                // Error banner (if any)
                if let error = viewModel.errorMessage {
                    ErrorBanner(
                        message: error,
                        onRetry: {
                            viewModel.retry()
                        },
                        onDismiss: {
                            viewModel.errorMessage = nil
                        }
                    )
                    .padding(.horizontal, 16)
                }
                
                // Dua of the Day section (always visible, not blocking)
                dailyDuaSection
                
                // Filter bar
                filterBar
                
                // Duas list
                duasList
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
    }
    
    // MARK: - Daily Dua Section (Inside Scroll)
    
    @ViewBuilder
    private var dailyDuaSection: some View {
        if let dailyDua = viewModel.dailyDua, !isDailyDuaDismissed {
            DuaOfTheDayCard(
                dua: dailyDua,
                hasUserSaidAmeen: viewModel.hasUserSaidAmeen(for: dailyDua),
                onAmeen: {
                    Task { await viewModel.toggleAmeen(for: dailyDua) }
                },
                onDismiss: {
                    dismissDailyDua()
                }
            )
            .padding(.bottom, 8)
            .transition(.move(edge: .top).combined(with: .opacity))
        }
    }
    
    // MARK: - Filter Bar
    
    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(DuaFilter.allCases) { filter in
                    FilterChip(
                        title: filter.rawValue,
                        isSelected: viewModel.selectedFilter == filter
                    ) {
                        viewModel.setFilter(filter)
                    }
                }
            }
            .padding(.horizontal, 4)
        }
    }
    
    // MARK: - Duas List
    
    @ViewBuilder
    private var duasList: some View {
        if viewModel.isLoading && viewModel.duas.isEmpty && !viewModel.hasLoadedOnce {
            loadingView
        } else if viewModel.filteredDuas.isEmpty && !viewModel.isLoading {
            emptyStateView
        } else {
            duasContent
        }
    }
    
    private var loadingView: some View {
        VStack(spacing: 12) {
            ForEach(0..<3, id: \.self) { _ in
                DuaSkeletonView()
            }
        }
    }
    
    // MARK: - Error State
    
    @ViewBuilder
    private var errorStateView: some View {
        if let error = viewModel.errorMessage, viewModel.duas.isEmpty {
            ErrorStateView(
                message: error,
                onRetry: {
                    viewModel.retry()
                }
            )
            .padding(.horizontal, 16)
            .padding(.vertical, 40)
        }
    }
    
    @ViewBuilder
    private var emptyStateView: some View {
        if viewModel.selectedFilter == .myDuas {
            // My Duas empty state
            VStack(spacing: 20) {
                ZStack {
                    Circle()
                        .fill(Color.mutedGold.opacity(0.15))
                        .frame(width: 80, height: 80)
                    
                    Image(systemName: "person.crop.circle")
                        .font(.system(size: 36))
                        .foregroundColor(.mutedGold)
                }
                
                VStack(spacing: 8) {
                    Text("No Duas Yet")
                        .font(.system(size: 20, weight: .semibold, design: .rounded))
                        .foregroundColor(Color.warmText(colorScheme))
                    
                    Text("You haven't submitted any duas yet. Share your first dua with the community.")
                        .font(.system(size: 15))
                        .foregroundColor(Color.warmSecondaryText(colorScheme))
                        .multilineTextAlignment(.center)
                }
                
                Button(action: {
                    HapticFeedback.medium()
                    showSubmitDua = true
                }) {
                    Label("Submit Your First Dua", systemImage: "plus")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                        .padding(.horizontal, 28)
                        .padding(.vertical, 14)
                        .background(LinearGradient.goldAccent)
                        .cornerRadius(12)
                }
                .buttonStyle(WarmButtonStyle(style: .primary))
            }
            .padding(40)
            .warmCard(elevation: .medium)
        } else {
            // General empty state
            VStack(spacing: 20) {
                ZStack {
                    Circle()
                        .fill(Color.mutedGold.opacity(0.15))
                        .frame(width: 80, height: 80)
                    
                    Image(systemName: "hands.sparkles")
                        .font(.system(size: 36))
                        .foregroundColor(.mutedGold)
                }
                
                VStack(spacing: 8) {
                    Text(viewModel.selectedFilter == .all ? "No Duas Yet" : "No Duas Found")
                        .font(.system(size: 20, weight: .semibold, design: .rounded))
                        .foregroundColor(Color.warmText(colorScheme))
                    
                    Text(viewModel.selectedFilter == .all 
                         ? "Be the first to share a dua with the community"
                         : "Try adjusting your filters or check back later")
                        .font(.system(size: 15))
                        .foregroundColor(Color.warmSecondaryText(colorScheme))
                        .multilineTextAlignment(.center)
                }
                
                if viewModel.selectedFilter == .all {
                    Button(action: {
                        HapticFeedback.medium()
                        showSubmitDua = true
                    }) {
                        Label("Submit Dua", systemImage: "plus")
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .foregroundColor(.white)
                            .padding(.horizontal, 28)
                            .padding(.vertical, 14)
                            .background(LinearGradient.goldAccent)
                            .cornerRadius(12)
                    }
                    .buttonStyle(WarmButtonStyle(style: .primary))
                } else {
                    Button(action: {
                        HapticFeedback.light()
                        viewModel.clearFilters()
                    }) {
                        Text("Clear Filters")
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                            .foregroundColor(.mutedGold)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                            .background(
                                Capsule()
                                    .strokeBorder(Color.mutedGold, lineWidth: 1.5)
                            )
                    }
                }
            }
            .padding(40)
            .warmCard(elevation: .medium)
        }
    }
    
    private var duasContent: some View {
        ForEach(viewModel.filteredDuas) { dua in
            DuaCard(
                dua: dua,
                hasUserSaidAmeen: viewModel.hasUserSaidAmeen(for: dua),
                onAmeen: {
                    Task { await viewModel.toggleAmeen(for: dua) }
                },
                onReport: {
                    viewModel.reportDua(dua)
                }
            )
            .warmCard(elevation: .low)
        }
    }
    
    // MARK: - Toolbar
    
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            Button(action: { showFilterSheet = true }) {
                Image(systemName: "line.3.horizontal.decrease.circle")
            }
        }
        
        ToolbarItem(placement: .navigationBarTrailing) {
            Button(action: { showSubmitDua = true }) {
                Image(systemName: "plus")
            }
        }
    }
    
    // MARK: - Actions
    
    private func handleOnAppear() {
        // Setup auth if needed (safe to call multiple times)
        AuthService.shared.setupIfNeeded()
        
        // Only load if logged in
        guard AuthService.shared.isLoggedIn else {
            #if DEBUG
            print("⚠️ DuaWallView: User not logged in, skipping data load")
            #endif
            return
        }
        
        // Load data
        Task {
            await viewModel.loadDuas()
            await viewModel.loadDailyDua()
            
            // Check if daily dua was dismissed today
            checkDailyDuaDismissal()
        }
    }
    
    private func refreshData() async {
        guard AuthService.shared.isLoggedIn else { return }
        await viewModel.loadDuas()
        await viewModel.loadDailyDua()
    }
    
    private func checkDailyDuaDismissal() {
        guard let uid = AuthService.shared.userUID else {
            // Not logged in - show the dua
            isDailyDuaDismissed = false
            return
        }
        
        let today = formatDate(Date())
        
        Task {
            do {
                let dismissed = try await UIStateFirestoreService.shared.isDailyDuaDismissed(uid: uid, date: today)
                await MainActor.run {
                    isDailyDuaDismissed = dismissed
                }
            } catch {
                // On error, default to showing the dua (Firestore is source of truth)
                #if DEBUG
                print("⚠️ DuaWallView: Error checking dismissal, showing dua - \(error)")
                #endif
                await MainActor.run {
                    isDailyDuaDismissed = false
                }
            }
        }
    }
    
    private func dismissDailyDua() {
        guard let uid = AuthService.shared.userUID else {
            // Not logged in - just hide locally
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                isDailyDuaDismissed = true
            }
            HapticFeedback.light()
            return
        }
        
        let today = formatDate(Date())
        
        // Optimistic update
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            isDailyDuaDismissed = true
        }
        HapticFeedback.light()
        
        // Persist to Firestore (source of truth)
        Task {
            do {
                try await UIStateFirestoreService.shared.setDailyDuaDismissed(uid: uid, date: today, reason: "user_dismissed")
            } catch {
                // Rollback on error
                await MainActor.run {
                    isDailyDuaDismissed = false
                }
                #if DEBUG
                print("❌ DuaWallView: Failed to save dismissal to Firestore - \(error)")
                #endif
            }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}

// MARK: - Preview

#Preview {
    DuaWallView()
}
