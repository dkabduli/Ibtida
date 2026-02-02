//
//  ReelService.swift
//  Ibtida
//
//  Firestore fetching for reels feed. Pagination via startAfterDocument.
//  Only reels where isActive == true and tags array-contains "quran".
//
//  COMPOSITE INDEX (create in Firebase Console → Firestore → Indexes if you see "index" error):
//  Collection: reels
//  Fields: isActive (Ascending), tags (Array-contains), sortRank (Ascending), createdAt (Descending)
//  Query scope: Collection
//
//  SEEDING: Reels are read-only from client. To add sample reels, use Firebase Console or Admin SDK.
//  Required document shape: title (string), videoURL (string), isActive (bool), tags (array, include "quran"),
//  sortRank (number), createdAt (timestamp). Optional: reciterName, surahName, videoType, thumbnailURL, durationSeconds.
//

import Foundation
import FirebaseFirestore

/// Firestore field for tags array (for query)
private let tagsField = "tags"
/// Quran filter: only show reels with this tag
private let quranTag = "quran"

@MainActor
class ReelService {
    static let shared = ReelService()
    /// Page size for reels feed (used for pagination)
    static let pageSize = 10
    
    private let db = Firestore.firestore()
    
    private init() {}
    
    /// Fetch first page of Quran recitation reels (isActive == true, tags array-contains "quran").
    /// Ordered by sortRank ascending, then createdAt descending.
    func fetchFirstPage() async throws -> [Reel] {
        let query = db.collection(FirestorePaths.reels)
            .whereField("isActive", isEqualTo: true)
            .whereField(tagsField, arrayContains: quranTag)
            .order(by: "sortRank", descending: false)
            .order(by: "createdAt", descending: true)
            .limit(to: Self.pageSize)
        
        let snapshot = try await query.getDocuments()
        return snapshot.documents.compactMap { doc in
            Reel.from(documentId: doc.documentID, data: doc.data())
        }
    }
    
    /// Fetch next page after the last document. Pass the last Reel's id and its sortRank + createdAt for cursor.
    func fetchNextPage(after lastReel: Reel) async throws -> [Reel] {
        let lastSnapshot = try await db.collection(FirestorePaths.reels)
            .document(lastReel.id)
            .getDocument()
        guard lastSnapshot.exists else { return [] }
        
        let query = db.collection(FirestorePaths.reels)
            .whereField("isActive", isEqualTo: true)
            .whereField(tagsField, arrayContains: quranTag)
            .order(by: "sortRank", descending: false)
            .order(by: "createdAt", descending: true)
            .start(afterDocument: lastSnapshot)
            .limit(to: Self.pageSize)
        
        let snapshot = try await query.getDocuments()
        return snapshot.documents.compactMap { doc in
            Reel.from(documentId: doc.documentID, data: doc.data())
        }
    }
}
