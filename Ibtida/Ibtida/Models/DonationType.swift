//
//  DonationType.swift
//  Ibtida
//
//  Donation type model - categories for donations
//

import Foundation
import SwiftUI

struct DonationType: Identifiable, Hashable {
    let id: String
    let title: String
    let shortDescription: String
    let fullDescription: String
    let icon: String
    let accentColor: Color
    let suggestedAmounts: [Double]
    
    init(
        id: String,
        title: String,
        shortDescription: String,
        fullDescription: String,
        icon: String,
        accentColor: Color,
        suggestedAmounts: [Double] = [5, 10, 25]
    ) {
        self.id = id
        self.title = title
        self.shortDescription = shortDescription
        self.fullDescription = fullDescription
        self.icon = icon
        self.accentColor = accentColor
        self.suggestedAmounts = suggestedAmounts
    }
}

extension DonationType {
    static let allTypes: [DonationType] = [
        DonationType(
            id: "humanitarian",
            title: "Humanitarian Aid",
            shortDescription: "Support those in need with essential resources and emergency relief",
            fullDescription: "Your donation helps provide food, clean water, shelter, medical care, and emergency relief to communities facing crisis. Every contribution makes a meaningful difference in the lives of those who need it most.",
            icon: "heart.fill",
            accentColor: .red,
            suggestedAmounts: [5, 10, 25, 50, 100]
        ),
        DonationType(
            id: "environmental",
            title: "Environmental Aid",
            shortDescription: "Protect our planet and combat climate change through sustainable initiatives",
            fullDescription: "Support environmental conservation, reforestation, clean energy projects, and climate action initiatives. Your contribution helps preserve our planet for future generations and creates a more sustainable world.",
            icon: "leaf.fill",
            accentColor: .green,
            suggestedAmounts: [10, 25, 50, 100, 250]
        ),
        DonationType(
            id: "masjid",
            title: "Masjid Building",
            shortDescription: "Help build and maintain places of worship and community centers",
            fullDescription: "Contribute to the construction, maintenance, and expansion of masjids and Islamic community centers. Your donation helps create spaces for prayer, education, and community gathering that serve Muslims worldwide.",
            icon: "building.columns.fill",
            accentColor: .blue,
            suggestedAmounts: [25, 50, 100, 250, 500]
        )
    ]
    
    static func withId(_ id: String) -> DonationType? {
        return allTypes.first { $0.id == id }
    }
}
