//
//  DuaRequest.swift
//  Ibtida
//
//  Request model for donation/dua requests
//

import Foundation

struct DuaRequest: Identifiable, Codable, Equatable {
    let id: String
    let userId: String
    let title: String
    let body: String
    let status: RequestStatus
    let createdAt: Date
    var updatedAt: Date
    
    init(
        id: String = UUID().uuidString,
        userId: String,
        title: String,
        body: String,
        status: RequestStatus = .pending,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.userId = userId
        self.title = title
        self.body = body
        self.status = status
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    static func == (lhs: DuaRequest, rhs: DuaRequest) -> Bool {
        lhs.id == rhs.id
    }
}

enum RequestStatus: String, Codable, CaseIterable {
    case pending = "pending"
    case approved = "approved"
    case rejected = "rejected"
    case completed = "completed"
    
    var displayName: String {
        switch self {
        case .pending: return "Pending"
        case .approved: return "Approved"
        case .rejected: return "Rejected"
        case .completed: return "Completed"
        }
    }
    
    var color: String {
        switch self {
        case .pending: return "orange"
        case .approved: return "green"
        case .rejected: return "red"
        case .completed: return "blue"
        }
    }
}
