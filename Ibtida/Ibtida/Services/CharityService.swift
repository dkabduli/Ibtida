//
//  CharityService.swift
//  Ibtida
//
//  Charity service - loads charities from local JSON with Firestore fallback
//

import Foundation

enum CharityServiceError: Error {
    case fileNotFound
    case decodingError
}

class CharityService {
    static let shared = CharityService()
    
    private var cachedCharities: [Charity]?
    
    private init() {}
    
    /// Load charities from local JSON file
    func loadCharities() throws -> [Charity] {
        if let cached = cachedCharities {
            return cached
        }
        
        guard let url = Bundle.main.url(forResource: "charities", withExtension: "json") else {
            throw CharityServiceError.fileNotFound
        }
        
        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        do {
            let charities = try decoder.decode([Charity].self, from: data)
            cachedCharities = charities
            return charities
        } catch {
            throw CharityServiceError.decodingError
        }
    }
    
    /// Get charity by ID
    func getCharity(by id: String) throws -> Charity? {
        let charities = try loadCharities()
        return charities.first { $0.id == id }
    }
    
    /// Search charities by name or description
    func searchCharities(query: String) throws -> [Charity] {
        let charities = try loadCharities()
        
        guard !query.isEmpty else {
            return charities
        }
        
        let lowerQuery = query.lowercased()
        
        return charities.filter { charity in
            charity.name.lowercased().contains(lowerQuery) ||
            charity.description.lowercased().contains(lowerQuery) ||
            charity.tags.contains { $0.lowercased().contains(lowerQuery) }
        }
    }
    
    /// Get verified charities only
    func getVerifiedCharities() throws -> [Charity] {
        let charities = try loadCharities()
        return charities.filter { $0.verified }
    }
    
    /// Get charities by category
    func getCharitiesByCategory(_ category: String) throws -> [Charity] {
        let charities = try loadCharities()
        return charities.filter { charity in
            charity.verified && (charity.category?.lowercased() == category.lowercased() || charity.tags.contains { $0.lowercased() == category.lowercased() })
        }
    }
    
    /// Get Ottawa masjids
    func getOttawaMasjids() throws -> [Charity] {
        let charities = try loadCharities()
        return charities.filter { charity in
            charity.verified &&
            (charity.category?.lowercased() == "masjid" || charity.tags.contains("masjid")) &&
            (charity.city?.lowercased() == "ottawa" || charity.tags.contains("ottawa"))
        }
    }
}
