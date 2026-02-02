//
//  PlayerManager.swift
//  Ibtida
//
//  Manages AVPlayer lifecycle for Reels: current index, prefetch adjacent (1 ahead, 1 behind), cleanup to avoid leaks and audio overlap.
//

import Foundation
import AVFoundation
import Combine

/// Manages a single reel's player and playback state. Main thread only.
@MainActor
final class PlayerManager: ObservableObject {
    
    /// Current visible index in the feed
    @Published private(set) var currentIndex: Int = 0
    
    /// Active players keyed by index. Only currentIndex and currentIndex ± 1 are kept.
    private var players: [Int: AVPlayer] = [:]
    private let lock = NSLock()
    
    /// Max number of players to keep (current + 1 ahead + 1 behind = 3)
    private let maxPlayers = 3
    
    /// Reel IDs for the feed (ordered). Used to resolve URL for index.
    private var reelIdsAndURLs: [(id: String, url: String)] = []
    
    #if DEBUG
    /// DEBUG: number of active players (for on-screen verification)
    @Published private(set) var activePlayerCount: Int = 0
    #endif
    
    init() {}
    
    /// Update the feed items (id + videoURL). Call when feed loads or paginates.
    func setFeedItems(_ items: [(id: String, url: String)]) {
        reelIdsAndURLs = items
        prunePlayersOutsideWindow()
    }
    
    /// Set current visible index (e.g. from paging). Plays current, pauses others, prefetches adjacent.
    func setCurrentIndex(_ index: Int) {
        guard index >= 0 && index < reelIdsAndURLs.count else {
            currentIndex = min(max(0, index), reelIdsAndURLs.count - 1)
            return
        }
        currentIndex = index
        playPlayer(at: index)
        pauseAllExcept(index)
        prefetchAdjacent(to: index)
        prunePlayersOutsideWindow()
        #if DEBUG
        activePlayerCount = players.count
        #endif
    }
    
    /// Get the AVPlayer for the given index (may be nil if pruned)
    func player(for index: Int) -> AVPlayer? {
        lock.lock()
        defer { lock.unlock() }
        return players[index]
    }
    
    /// Get or create player for index (used by UI to bind video layer)
    func getOrCreatePlayer(for index: Int) -> AVPlayer? {
        guard index >= 0 && index < reelIdsAndURLs.count else { return nil }
        let item = reelIdsAndURLs[index]
        guard let url = URL(string: item.url), url.scheme?.lowercased() == "https" else {
            AppLog.error("ReelService: invalid video URL for index \(index)")
            return nil
        }
        lock.lock()
        if let existing = players[index] {
            lock.unlock()
            return existing
        }
        let player = AVPlayer(url: url)
        player.isMuted = true // Start muted; UI toggles
        players[index] = player
        lock.unlock()
        prunePlayersOutsideWindow()
        #if DEBUG
        activePlayerCount = players.count
        #endif
        return player
    }
    
    /// Mute/unmute current player only
    func setMuted(_ muted: Bool) {
        lock.lock()
        let current = players[currentIndex]
        lock.unlock()
        current?.isMuted = muted
    }
    
    /// Pause all and release all players (e.g. when leaving Reels tab)
    func releaseAll() {
        lock.lock()
        for (_, p) in players {
            p.pause()
        }
        players.removeAll()
        lock.unlock()
        #if DEBUG
        activePlayerCount = 0
        #endif
    }
    
    /// Toggle play/pause for current index
    func togglePlayPause() {
        lock.lock()
        let current = players[currentIndex]
        lock.unlock()
        guard let p = current else { return }
        if p.timeControlStatus == .playing {
            p.pause()
        } else {
            p.play()
        }
    }
    
    /// Seek current player to 0 and play (e.g. tap to restart)
    func restartCurrent() {
        lock.lock()
        let current = players[currentIndex]
        lock.unlock()
        current?.seek(to: .zero)
        current?.play()
    }
    
    // MARK: - Private
    
    private func playPlayer(at index: Int) {
        guard index >= 0 && index < reelIdsAndURLs.count else { return }
        let p = getOrCreatePlayer(for: index)
        p?.play()
    }
    
    private func pauseAllExcept(_ index: Int) {
        lock.lock()
        let copy = players
        lock.unlock()
        for (i, p) in copy where i != index {
            p.pause()
        }
    }
    
    private func prefetchAdjacent(to index: Int) {
        // Preload player for index-1 and index+1 (don't auto-play)
        _ = getOrCreatePlayer(for: index - 1)
        _ = getOrCreatePlayer(for: index + 1)
    }
    
    /// Keep only currentIndex and currentIndex ± 1
    private func prunePlayersOutsideWindow() {
        lock.lock()
        let keep = Set([currentIndex - 1, currentIndex, currentIndex + 1].filter { $0 >= 0 })
        let toRemove = players.keys.filter { !keep.contains($0) }
        for i in toRemove {
            players[i]?.pause()
            players.removeValue(forKey: i)
        }
        let count = players.count
        lock.unlock()
        #if DEBUG
        activePlayerCount = count
        #endif
    }
}
