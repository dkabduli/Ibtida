//
//  Dua.swift
//  Ibtida
//
//  Dua model for community duas
//

import Foundation

struct Dua: Identifiable, Codable, Equatable {
    let id: String
    let text: String
    let authorId: String?
    let authorName: String?
    let isAnonymous: Bool
    var ameenCount: Int
    var ameenBy: [String] // Array of user IDs who said ameen
    let tags: [String]
    let createdAt: Date
    
    init(
        id: String = UUID().uuidString,
        text: String,
        authorId: String? = nil,
        authorName: String? = nil,
        isAnonymous: Bool = false,
        ameenCount: Int = 0,
        ameenBy: [String] = [],
        tags: [String] = [],
        createdAt: Date = Date()
    ) {
        self.id = id
        self.text = text
        self.authorId = authorId
        self.authorName = authorName
        self.isAnonymous = isAnonymous
        self.ameenCount = ameenCount
        self.ameenBy = ameenBy
        self.tags = tags
        self.createdAt = createdAt
    }
    
    var displayAuthorName: String {
        if isAnonymous {
            return "Anonymous"
        }
        return authorName ?? "Community Member"
    }
    
    func hasUserSaidAmeen(userId: String) -> Bool {
        return ameenBy.contains(userId)
    }
    
    static func == (lhs: Dua, rhs: Dua) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Dua Filter

enum DuaFilter: String, CaseIterable, Identifiable {
    case all = "All"
    case recent = "Recent"
    case mostPrayedFor = "Most Prayed"
    case myDuas = "My Duas"
    
    var id: String { rawValue }
}
