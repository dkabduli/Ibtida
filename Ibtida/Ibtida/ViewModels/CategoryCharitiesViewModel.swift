//
//  CategoryCharitiesViewModel.swift
//  Ibtida
//
//  ViewModel for category-specific charity lists with explicit error logging
//

import Foundation
import Combine

@MainActor
class CategoryCharitiesViewModel: ObservableObject {
    // MARK: - Published Properties
    
    @Published var charities: [Charity] = []
    @Published var filteredCharities: [Charity] = []
    @Published var searchText: String = "" {
        didSet { applyFilters() }
    }
    @Published var showBookmarkedOnly: Bool = false {
        didSet { applyFilters() }
    }
    @Published var isLoading: Bool = false
    @Published var hasLoadedOnce: Bool = false
    @Published var errorMessage: String?
    
    // MARK: - Private Properties
    
    private let charityService = CharityService.shared
    private var cancellables = Set<AnyCancellable>()
    private var currentCategoryId: String?
    
    // MARK: - Initialization
    
    init() {
        // Debounce search for better performance
        $searchText
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                self?.applyFilters()
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Load Charities
    
    func loadCharities(for categoryId: String) {
        // Skip if already loaded for this category
        if hasLoadedOnce && currentCategoryId == categoryId {
            #if DEBUG
            print("⏭️ CategoryCharitiesViewModel: Already loaded charities for \(categoryId), skipping")
            #endif
            return
        }
        
        currentCategoryId = categoryId
        isLoading = true
        errorMessage = nil
        
        #if DEBUG
        print("📖 CategoryCharitiesViewModel: Loading charities for category: \(categoryId)")
        #endif
        
        do {
            var loadedCharities: [Charity]
            
            // Special handling for masjid category - prioritize Ottawa masjids
            if categoryId == "masjid" {
                let ottawaMasjids = try charityService.getOttawaMasjids()
                let allMasjids = try charityService.getCharitiesByCategory("masjid")
                
                // Combine with Ottawa masjids first, then others
                var combined = ottawaMasjids
                let otherMasjids = allMasjids.filter { masjid in
                    !ottawaMasjids.contains { $0.id == masjid.id }
                }
                combined.append(contentsOf: otherMasjids)
                
                loadedCharities = combined
                
                #if DEBUG
                print("✅ CategoryCharitiesViewModel: Loaded \(ottawaMasjids.count) Ottawa masjids + \(otherMasjids.count) other masjids")
                #endif
            } else {
                loadedCharities = try charityService.getCharitiesByCategory(categoryId)
                
                #if DEBUG
                print("✅ CategoryCharitiesViewModel: Loaded \(loadedCharities.count) charities for \(categoryId)")
                #endif
            }
            
            self.charities = loadedCharities
            applyFilters()
            hasLoadedOnce = true
            
        } catch CharityServiceError.fileNotFound {
            self.errorMessage = "Charity data not found. Please try again later."
            self.charities = []
            self.filteredCharities = []
            
            #if DEBUG
            print("❌ CategoryCharitiesViewModel: Charity file not found for category: \(categoryId)")
            #endif
            
        } catch CharityServiceError.decodingError {
            self.errorMessage = "Unable to load charity data. Please try again later."
            self.charities = []
            self.filteredCharities = []
            
            #if DEBUG
            print("❌ CategoryCharitiesViewModel: Decoding error for category: \(categoryId)")
            #endif
            
        } catch {
            self.errorMessage = "Failed to load charities: \(error.localizedDescription)"
            self.charities = []
            self.filteredCharities = []
            
            #if DEBUG
            print("❌ CategoryCharitiesViewModel: Unexpected error loading charities for \(categoryId): \(error)")
            #endif
        }
        
        isLoading = false
    }
    
    // MARK: - Apply Filters
    
    private func applyFilters() {
        var filtered = charities
        
        // Search filter
        if !searchText.isEmpty {
            let query = searchText.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
            filtered = filtered.filter { charity in
                charity.name.lowercased().contains(query) ||
                charity.description.lowercased().contains(query) ||
                charity.tags.contains { $0.lowercased().contains(query) } ||
                (charity.city?.lowercased().contains(query) ?? false)
            }
        }
        
        // Bookmark filter (placeholder - would need persistence)
        // For now, bookmarked only shows nothing since we don't have bookmarks
        if showBookmarkedOnly {
            // filtered = filtered.filter { isBookmarked($0) }
            // Since bookmarks aren't implemented, show empty for now
            filtered = []
        }
        
        filteredCharities = filtered
        
        #if DEBUG
        print("🔍 CategoryCharitiesViewModel: Filtered to \(filtered.count) charities (search: '\(searchText)', bookmarked: \(showBookmarkedOnly))")
        #endif
    }
    
    // MARK: - Refresh
    
    func refresh() {
        hasLoadedOnce = false
        if let categoryId = currentCategoryId {
            loadCharities(for: categoryId)
        }
    }
}
