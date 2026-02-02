//
//  ReelsFeedViewModel.swift
//  Ibtida
//
//  Feed state for Reels tab: pagination, interactions, mute preference, loading/error.
//  Strict state machine: idle → loading → (success | empty | error). No blank screens.
//

import Foundation
import SwiftUI

/// Reels feed UI state. Never show a blank screen: always show loading, empty, error, or feed.
enum ReelsLoadState: Equatable {
    case idle
    case loading
    case success
    case empty
    case error(String)
}

@MainActor
final class ReelsFeedViewModel: ObservableObject {
    
    @Published private(set) var reels: [Reel] = []
    @Published private(set) var interactions: [String: ReelInteraction] = [:]
    @Published private(set) var loadState: ReelsLoadState = .idle
    @Published private(set) var isLoadingMore = false
    @Published var isMuted: Bool {
        didSet {
            UserDefaults.standard.set(isMuted, forKey: Self.mutePreferenceKey)
            playerManager.setMuted(isMuted)
        }
    }
    
    let playerManager = PlayerManager()
    
    private static let mutePreferenceKey = "ibtida_reels_muted"
    private let reelService = ReelService.shared
    private let interactionService = ReelInteractionService.shared
    
    init() {
        self.isMuted = UserDefaults.standard.object(forKey: Self.mutePreferenceKey) as? Bool ?? true
    }
    
    /// Loading is true when in .loading state (first page)
    var isLoading: Bool { loadState == .loading }
    
    /// User-facing error message when loadState == .error
    var errorMessage: String? {
        if case .error(let msg) = loadState { return msg }
        return nil
    }
    
    /// Load first page and interactions for current user. Updates loadState; never leaves UI blank.
    func loadFirstPage() async {
        guard loadState != .loading else { return }
        loadState = .loading
        #if DEBUG
        print("🎞️ Reels: fetching…")
        #endif
        defer {}
        
        do {
            let first = try await reelService.fetchFirstPage()
            let ids = first.map(\.id)
            var inter: [String: ReelInteraction] = [:]
            if !ids.isEmpty {
                inter = (try? await interactionService.loadInteractions(reelIds: ids)) ?? [:]
            }
            await MainActor.run {
                reels = first
                interactions = inter
                playerManager.setFeedItems(first.map { ($0.id, $0.videoURL) })
                if !first.isEmpty {
                    playerManager.setCurrentIndex(0)
                    playerManager.setMuted(isMuted)
                    loadState = .success
                    #if DEBUG
                    print("🎞️ Reels: fetched \(first.count)")
                    #endif
                } else {
                    loadState = .empty
                    #if DEBUG
                    print("🎞️ Reels: empty")
                    #endif
                }
            }
        } catch {
            let errorString = String(describing: error)
            let isIndexError = errorString.lowercased().contains("index") || errorString.lowercased().contains("composite")
            let userMessage: String
            #if DEBUG
            if isIndexError {
                userMessage = "Missing Firestore index for reels query. Create it in Firebase console."
                print("❌ Reels: error (index) – \(error)")
            } else {
                userMessage = error.localizedDescription
                print("❌ Reels: error – \(error)")
            }
            #else
            userMessage = error.localizedDescription
            #endif
            await MainActor.run {
                loadState = .error(userMessage)
            }
        }
    }
    
    /// Retry loading first page (e.g. after error)
    func retry() {
        Task { await loadFirstPage() }
    }
    
    /// Load next page when user nears end (e.g. last 2 items)
    func loadNextPageIfNeeded(currentIndex: Int) async {
        guard currentIndex >= reels.count - 2, !isLoadingMore else { return }
        guard let last = reels.last else { return }
        isLoadingMore = true
        defer { isLoadingMore = false }
        
        do {
            let next = try await reelService.fetchNextPage(after: last)
            await MainActor.run {
                reels.append(contentsOf: next)
                playerManager.setFeedItems(reels.map { ($0.id, $0.videoURL) })
            }
            if !next.isEmpty {
                let ids = next.map(\.id)
                let inter = (try? await interactionService.loadInteractions(reelIds: ids)) ?? [:]
                await MainActor.run {
                    for (id, i) in inter { interactions[id] = i }
                }
            }
        } catch {
            AppLog.error("ReelsFeedViewModel: loadNextPage failed \(error)")
        }
    }
    
    /// Called when visible index changes (paging)
    func onVisibleIndexChanged(_ index: Int) {
        playerManager.setCurrentIndex(index)
        Task {
            await loadNextPageIfNeeded(currentIndex: index)
        }
    }
    
    /// Toggle like for reel
    func toggleLike(reelId: String) {
        let current = interactions[reelId]?.liked ?? false
        let new = !current
        interactions[reelId] = ReelInteraction(
            reelId: reelId,
            liked: new,
            saved: interactions[reelId]?.saved ?? false,
            lastWatchedSeconds: interactions[reelId]?.lastWatchedSeconds,
            updatedAt: Date()
        )
        HapticFeedback.light()
        Task {
            do {
                try await interactionService.setLiked(reelId: reelId, liked: new)
            } catch {
                AppLog.error("ReelsFeedViewModel: setLiked failed \(error)")
                await MainActor.run {
                    interactions[reelId]?.liked = current
                }
            }
        }
    }
    
    /// Toggle save for reel
    func toggleSave(reelId: String) {
        let current = interactions[reelId]?.saved ?? false
        let new = !current
        interactions[reelId] = ReelInteraction(
            reelId: reelId,
            liked: interactions[reelId]?.liked ?? false,
            saved: new,
            lastWatchedSeconds: interactions[reelId]?.lastWatchedSeconds,
            updatedAt: Date()
        )
        HapticFeedback.light()
        Task {
            do {
                try await interactionService.setSaved(reelId: reelId, saved: new)
            } catch {
                AppLog.error("ReelsFeedViewModel: setSaved failed \(error)")
                await MainActor.run {
                    interactions[reelId]?.saved = current
                }
            }
        }
    }
    
    /// Update last watched position (e.g. on pause or leave)
    func updateLastWatched(reelId: String, seconds: Double) {
        Task {
            try? await interactionService.setLastWatchedSeconds(reelId: reelId, seconds: seconds)
        }
    }
    
    /// Whether reel is liked
    func isLiked(reelId: String) -> Bool {
        interactions[reelId]?.liked ?? false
    }
    
    /// Whether reel is saved
    func isSaved(reelId: String) -> Bool {
        interactions[reelId]?.saved ?? false
    }
}
