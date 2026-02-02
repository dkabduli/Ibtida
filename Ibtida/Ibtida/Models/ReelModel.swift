//
//  ReelModel.swift
//  Ibtida
//
//  Data model for Reels feed. Firestore: reels/{reelId}
//  For now: Quran recitation only (filter by tags contains "quran"); extensible for advice later.
//

import Foundation
import FirebaseFirestore

/// Video delivery type (mp4 now; HLS allowed later)
enum ReelVideoType: String, Codable, CaseIterable {
    case mp4
    case hls
}

/// Reel document from Firestore. Only reels with isActive == true and tags containing "quran" are shown.
struct Reel: Identifiable, Equatable {
    var id: String
    var title: String
    var reciterName: String?
    var surahName: String?
    var tags: [String]
    var videoType: ReelVideoType
    var videoURL: String
    var thumbnailURL: String?
    var durationSeconds: Int?
    var isActive: Bool
    var createdAt: Date
    var sortRank: Int
    
    init(
        id: String,
        title: String,
        reciterName: String? = nil,
        surahName: String? = nil,
        tags: [String] = [],
        videoType: ReelVideoType = .mp4,
        videoURL: String,
        thumbnailURL: String? = nil,
        durationSeconds: Int? = nil,
        isActive: Bool = true,
        createdAt: Date = Date(),
        sortRank: Int = 0
    ) {
        self.id = id
        self.title = title
        self.reciterName = reciterName
        self.surahName = surahName
        self.tags = tags
        self.videoType = videoType
        self.videoURL = videoURL
        self.thumbnailURL = thumbnailURL
        self.durationSeconds = durationSeconds
        self.isActive = isActive
        self.createdAt = createdAt
        self.sortRank = sortRank
    }
    
    /// Whether this reel is in the Quran recitation category (for filtering)
    var isQuranRecitation: Bool {
        tags.contains("quran")
    }
    
    /// Subtitle line: reciter and/or surah
    var subtitle: String? {
        let parts = [reciterName, surahName].compactMap { $0 }.filter { !$0.isEmpty }
        return parts.isEmpty ? nil : parts.joined(separator: " · ")
    }
}

// MARK: - Firestore Parsing

extension Reel {
    /// Parse from Firestore document (documentId + data)
    static func from(documentId: String, data: [String: Any]) -> Reel? {
        guard let title = data["title"] as? String,
              let videoURL = data["videoURL"] as? String,
              (data["isActive"] as? Bool) ?? true else {
            return nil
        }
        let tags = (data["tags"] as? [String]) ?? []
        let videoTypeRaw = (data["videoType"] as? String) ?? "mp4"
        let videoType = ReelVideoType(rawValue: videoTypeRaw) ?? .mp4
        var createdAt = Date()
        if let ts = data["createdAt"] as? Timestamp {
            createdAt = ts.dateValue()
        }
        return Reel(
            id: documentId,
            title: title,
            reciterName: data["reciterName"] as? String,
            surahName: data["surahName"] as? String,
            tags: tags,
            videoType: videoType,
            videoURL: videoURL,
            thumbnailURL: data["thumbnailURL"] as? String,
            durationSeconds: data["durationSeconds"] as? Int,
            isActive: (data["isActive"] as? Bool) ?? true,
            createdAt: createdAt,
            sortRank: (data["sortRank"] as? Int) ?? 0
        )
    }
}

// MARK: - Reel Interaction (per-user, private)

/// User interaction with a reel: users/{uid}/reelInteractions/{reelId}
struct ReelInteraction: Equatable {
    var reelId: String
    var liked: Bool
    var saved: Bool
    var lastWatchedSeconds: Double?
    var updatedAt: Date
    
    init(
        reelId: String,
        liked: Bool = false,
        saved: Bool = false,
        lastWatchedSeconds: Double? = nil,
        updatedAt: Date = Date()
    ) {
        self.reelId = reelId
        self.liked = liked
        self.saved = saved
        self.lastWatchedSeconds = lastWatchedSeconds
        self.updatedAt = updatedAt
    }
}

extension ReelInteraction {
    static func from(data: [String: Any], reelId: String) -> ReelInteraction {
        var updatedAt = Date()
        if let ts = data["updatedAt"] as? Timestamp {
            updatedAt = ts.dateValue()
        }
        return ReelInteraction(
            reelId: reelId,
            liked: (data["liked"] as? Bool) ?? false,
            saved: (data["saved"] as? Bool) ?? false,
            lastWatchedSeconds: data["lastWatchedSeconds"] as? Double,
            updatedAt: updatedAt
        )
    }
}
