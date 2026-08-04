//
//  Beer.swift
//  BrewBuddy
//

import Foundation
import SwiftData

@Model
final class Beer {
    var id: UUID
    var name: String
    var brewery: String
    var style: String
    var abv: Double?
    var ibu: Int?
    /// Overall rating: 0 = unrated, 1...5 stars
    var rating: Int
    var notes: String
    var isFavorite: Bool
    @Attribute(.externalStorage) var photoData: Data?
    var createdAt: Date
    var updatedAt: Date

    @Relationship(deleteRule: .cascade, inverse: \CheckIn.beer)
    var checkIns: [CheckIn]

    init(
        id: UUID = UUID(),
        name: String = "",
        brewery: String = "",
        style: String = "",
        abv: Double? = nil,
        ibu: Int? = nil,
        rating: Int = 0,
        notes: String = "",
        isFavorite: Bool = false,
        photoData: Data? = nil,
        createdAt: Date = .now,
        updatedAt: Date = .now,
        checkIns: [CheckIn] = []
    ) {
        self.id = id
        self.name = name
        self.brewery = brewery
        self.style = style
        self.abv = abv
        self.ibu = ibu
        self.rating = Beer.clampedRating(rating)
        self.notes = notes
        self.isFavorite = isFavorite
        self.photoData = photoData
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.checkIns = checkIns
    }

    static func clampedRating(_ value: Int) -> Int {
        min(max(value, 0), 5)
    }

    var displayName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? "Untitled Beer"
            : name
    }

    var sortedCheckIns: [CheckIn] {
        checkIns.sorted { $0.tastedAt > $1.tastedAt }
    }

    func touch() {
        updatedAt = .now
    }
}

enum BeerStyle {
    static let suggestions: [String] = [
        "IPA",
        "Double IPA",
        "Pale Ale",
        "Lager",
        "Pilsner",
        "Stout",
        "Imperial Stout",
        "Porter",
        "Wheat",
        "Hefeweizen",
        "Sour",
        "Gose",
        "Belgian",
        "Saison",
        "Amber",
        "Red Ale",
        "Brown Ale",
        "Barleywine",
        "Seltzer",
        "Other",
    ]
}
