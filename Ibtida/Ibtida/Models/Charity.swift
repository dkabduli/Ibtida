//
//  Charity.swift
//  Ibtida
//
//  Charity model - verified charitable organizations
//

import Foundation

struct Charity: Identifiable, Codable, Hashable {
    let id: String
    let name: String
    let description: String
    let verified: Bool
    let tags: [String]
    let websiteURL: String?
    let donationURL: String? // Direct donation page URL
    let category: String? // "humanitarian", "environmental", "masjid"
    let city: String? // e.g., "Ottawa"
    let logoURL: String?
    let createdAt: Date
    
    init(
        id: String,
        name: String,
        description: String,
        verified: Bool = false,
        tags: [String] = [],
        websiteURL: String? = nil,
        donationURL: String? = nil,
        category: String? = nil,
        city: String? = nil,
        logoURL: String? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.verified = verified
        self.tags = tags
        self.websiteURL = websiteURL
        self.donationURL = donationURL
        self.category = category
        self.city = city
        self.logoURL = logoURL
        self.createdAt = createdAt
    }
}
