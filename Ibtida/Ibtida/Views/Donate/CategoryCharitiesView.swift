//
//  CategoryCharitiesView.swift
//  Ibtida
//
//  Category-specific charity list view with premium dark mode styling
//

import SwiftUI
import SafariServices

struct CategoryCharitiesView: View {
    let category: DonationType
    @StateObject private var viewModel = CategoryCharitiesViewModel()
    @State private var searchText = ""
    @State private var showBookmarkedOnly = false
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        ZStack {
            // Layered background - avoids flat black
            Color(.systemGroupedBackground)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Category header with accent color
                categoryHeader
                
                // Search bar
                searchBar
                
                // Filter toggle
                filterToggle
                
                // Content
                if viewModel.isLoading && !viewModel.hasLoadedOnce {
                    loadingView
                } else if let error = viewModel.errorMessage {
                    errorStateView(error)
                } else if viewModel.filteredCharities.isEmpty {
                    emptyStateView
                } else {
                    charityList
                }
            }
        }
        .navigationTitle(category.title)
        .navigationBarTitleDisplayMode(.large)
        .onAppear {
            viewModel.loadCharities(for: category.id)
        }
        .onChange(of: searchText) { _, newValue in
            viewModel.searchText = newValue
        }
        .onChange(of: showBookmarkedOnly) { _, newValue in
            viewModel.showBookmarkedOnly = newValue
        }
    }
    
    // MARK: - Category Header
    
    private var categoryHeader: some View {
        HStack(spacing: AppSpacing.md) {
            // Icon with category color
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(category.accentColor.opacity(0.15))
                    .frame(width: 48, height: 48)
                
                Image(systemName: category.icon)
                    .font(.system(size: 22, weight: .medium))
                    .foregroundColor(category.accentColor)
            }
            
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text(category.title)
                    .font(AppTypography.bodyBold)
                    .foregroundColor(.primary)
                
                Text("\(viewModel.filteredCharities.count) verified charities")
                    .font(AppTypography.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(AppSpacing.lg)
        .background(
            Rectangle()
                .fill(Color(.secondarySystemBackground))
                .overlay(
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [category.accentColor.opacity(0.08), Color.clear],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                )
        )
    }
    
    // MARK: - Search Bar
    
    private var searchBar: some View {
        HStack(spacing: AppSpacing.sm) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.secondary)
            
            TextField("Search charities...", text: $searchText)
                .font(AppTypography.body)
                .textFieldStyle(.plain)
            
            if !searchText.isEmpty {
                Button(action: { searchText = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(AppSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.tertiarySystemBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color(.separator).opacity(0.3), lineWidth: 1)
                )
        )
        .padding(.horizontal, AppSpacing.lg)
        .padding(.vertical, AppSpacing.md)
    }
    
    // MARK: - Filter Toggle
    
    private var filterToggle: some View {
        HStack {
            Toggle(isOn: $showBookmarkedOnly) {
                HStack(spacing: AppSpacing.sm) {
                    Image(systemName: showBookmarkedOnly ? "bookmark.fill" : "bookmark")
                        .foregroundColor(showBookmarkedOnly ? .accentColor : .secondary)
                    Text("Bookmarked only")
                        .font(AppTypography.subheadline)
                }
            }
            .toggleStyle(SwitchToggleStyle(tint: .accentColor))
        }
        .padding(.horizontal, AppSpacing.lg)
        .padding(.bottom, AppSpacing.md)
    }
    
    // MARK: - Charity List
    
    private var charityList: some View {
        ScrollView {
            LazyVStack(spacing: AppSpacing.md) {
                ForEach(viewModel.filteredCharities) { charity in
                    PremiumCharityCard(charity: charity, categoryColor: category.accentColor)
                }
            }
            .padding(.horizontal, AppSpacing.lg)
            .padding(.vertical, AppSpacing.md)
        }
    }
    
    // MARK: - Loading View
    
    private var loadingView: some View {
        VStack(spacing: AppSpacing.lg) {
            ProgressView()
                .scaleEffect(1.2)
            
            Text("Loading charities...")
                .font(AppTypography.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Empty State View
    
    private var emptyStateView: some View {
        VStack(spacing: AppSpacing.lg) {
            ZStack {
                Circle()
                    .fill(Color(.tertiarySystemBackground))
                    .frame(width: 80, height: 80)
                
                Image(systemName: "heart.slash")
                    .font(.system(size: 36))
                    .foregroundColor(.secondary.opacity(0.6))
            }
            
            VStack(spacing: AppSpacing.sm) {
                Text("No Charities Found")
                    .font(AppTypography.title3)
                    .foregroundColor(.primary)
                
                Text("Try adjusting your search or filters")
                    .font(AppTypography.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(AppSpacing.xxxl)
    }
    
    // MARK: - Error State View
    
    private func errorStateView(_ message: String) -> some View {
        VStack(spacing: AppSpacing.lg) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundColor(.orange)
            
            VStack(spacing: AppSpacing.sm) {
                Text("Something went wrong")
                    .font(AppTypography.title3)
                    .foregroundColor(.primary)
                
                Text(message)
                    .font(AppTypography.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Button(action: {
                viewModel.loadCharities(for: category.id)
            }) {
                Text("Try Again")
                    .font(AppTypography.bodyBold)
                    .padding(.horizontal, AppSpacing.xl)
                    .padding(.vertical, AppSpacing.md)
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            .buttonStyle(SmoothButtonStyle())
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(AppSpacing.xxxl)
    }
}

// MARK: - Premium Charity Card

struct PremiumCharityCard: View {
    let charity: Charity
    let categoryColor: Color
    @State private var showSafari = false
    @State private var showMissingURLAlert = false
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.lg) {
            // Header row
            HStack(alignment: .top, spacing: AppSpacing.md) {
                // Charity info
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    HStack(spacing: AppSpacing.sm) {
                        Text(charity.name)
                            .font(AppTypography.bodyBold)
                            .foregroundColor(.primary)
                            .lineLimit(2)
                        
                        if charity.verified {
                            Image(systemName: "checkmark.seal.fill")
                                .font(.system(size: 16))
                                .foregroundColor(.blue)
                        }
                    }
                    
                    if let city = charity.city {
                        HStack(spacing: AppSpacing.xs) {
                            Image(systemName: "mappin.circle.fill")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                            Text(city)
                                .font(AppTypography.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Spacer()
                
                // Bookmark button placeholder
                Button(action: {
                    HapticFeedback.light()
                }) {
                    Image(systemName: "bookmark")
                        .font(.system(size: 18))
                        .foregroundColor(.secondary)
                }
            }
            
            // Description
            Text(charity.description)
                .font(AppTypography.caption)
                .foregroundColor(.secondary)
                .lineLimit(3)
            
            // Tags
            if !charity.tags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: AppSpacing.sm) {
                        ForEach(charity.tags.prefix(4), id: \.self) { tag in
                            Text(tag)
                                .font(AppTypography.caption)
                                .foregroundColor(categoryColor)
                                .padding(.horizontal, AppSpacing.sm)
                                .padding(.vertical, AppSpacing.xs)
                                .background(
                                    Capsule()
                                        .fill(categoryColor.opacity(0.1))
                                )
                        }
                    }
                }
            }
            
            // Donate button
            Button(action: {
                HapticFeedback.medium()
                if charity.donationURL != nil {
                    showSafari = true
                } else {
                    showMissingURLAlert = true
                }
            }) {
                HStack(spacing: AppSpacing.sm) {
                    Image(systemName: "heart.fill")
                    Text("Donate")
                    Spacer()
                    Image(systemName: "arrow.up.right")
                }
                .font(AppTypography.bodyBold)
                .foregroundColor(.white)
                .padding()
                .background(
                    LinearGradient(
                        colors: [categoryColor, categoryColor.opacity(0.8)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(12)
            }
            .buttonStyle(SmoothButtonStyle())
        }
        .padding(AppSpacing.lg)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            colorScheme == .dark 
                                ? categoryColor.opacity(0.2) 
                                : Color(.separator).opacity(0.3),
                            lineWidth: colorScheme == .dark ? 1 : 0.5
                        )
                )
        )
        .shadow(
            color: colorScheme == .dark 
                ? Color.black.opacity(0.3) 
                : Color.black.opacity(0.06),
            radius: colorScheme == .dark ? 8 : 12,
            x: 0,
            y: colorScheme == .dark ? 2 : 4
        )
        .sheet(isPresented: $showSafari) {
            if let urlString = charity.donationURL, let url = URL(string: urlString) {
                SafariView(url: url)
            }
        }
        .alert("Donation Link Unavailable", isPresented: $showMissingURLAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("The donation link for this charity is not available at this time. Please visit their website directly.")
        }
    }
}

// MARK: - Safari View

struct SafariView: UIViewControllerRepresentable {
    let url: URL
    
    func makeUIViewController(context: Context) -> SFSafariViewController {
        let config = SFSafariViewController.Configuration()
        config.entersReaderIfAvailable = false
        config.barCollapsingEnabled = true
        
        let safariVC = SFSafariViewController(url: url, configuration: config)
        safariVC.preferredControlTintColor = .systemBlue
        return safariVC
    }
    
    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {}
}
