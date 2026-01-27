//
//  RequestModel.swift
//  Ibtida
//
//  Model for community donation requests
//

import Foundation

/// Status for community donation requests
enum CommunityRequestStatus: String, Codable, CaseIterable {
    case open = "open"
    case funded = "funded"
    case closed = "closed"
    case rejected = "rejected"
    
    var displayName: String {
        switch self {
        case .open: return "Open"
        case .funded: return "Funded"
        case .closed: return "Closed"
        case .rejected: return "Rejected"
        }
    }
    
    var color: String {
        switch self {
        case .open: return "green"
        case .funded: return "blue"
        case .closed: return "gray"
        case .rejected: return "red"
        }
    }
}

/// Community donation request
struct CommunityRequest: Identifiable, Codable {
    let id: String
    let title: String
    let description: String
    let createdByUid: String
    let createdByName: String?
    let status: CommunityRequestStatus
    let goalAmount: Double?
    let raisedAmount: Double?
    let tags: [String]
    let createdAt: Date
    let updatedAt: Date
    
    init(
        id: String = UUID().uuidString,
        title: String,
        description: String,
        createdByUid: String,
        createdByName: String? = nil,
        status: CommunityRequestStatus = .open,
        goalAmount: Double? = nil,
        raisedAmount: Double? = nil,
        tags: [String] = [],
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.createdByUid = createdByUid
        self.createdByName = createdByName
        self.status = status
        self.goalAmount = goalAmount
        self.raisedAmount = raisedAmount
        self.tags = tags
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    /// Progress towards goal (0.0 to 1.0)
    var progress: Double {
        guard let goal = goalAmount, goal > 0, let raised = raisedAmount else {
            return 0
        }
        return min(1.0, raised / goal)
    }
}

/// Report model for moderation
struct Report: Identifiable, Codable {
    let id: String
    let type: ReportType
    let targetId: String
    let reason: String?
    let reporterUid: String
    let createdAt: Date
    
    init(
        id: String = UUID().uuidString,
        type: ReportType,
        targetId: String,
        reason: String? = nil,
        reporterUid: String,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.type = type
        self.targetId = targetId
        self.reason = reason
        self.reporterUid = reporterUid
        self.createdAt = createdAt
    }
}

/// Type of content being reported
enum ReportType: String, Codable {
    case request = "request"
    case dua = "dua"
}
