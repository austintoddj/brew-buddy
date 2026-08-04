//
//  SampleData.swift
//  BrewBuddy
//

import Foundation
import SwiftData

enum SampleData {
    /// Sample tasting locations around the world (for Map demo).
    private struct SampleCheckIn {
        var daysAgo: Int
        var venue: String
        var note: String
        var latitude: Double
        var longitude: Double
    }

    @MainActor
    static func insertIfNeeded(into context: ModelContext) throws {
        let descriptor = FetchDescriptor<Beer>()
        let existing = try context.fetch(descriptor)
        guard existing.isEmpty else { return }
        insertSamples(into: context)
    }

    @MainActor
    static func insertSamples(into context: ModelContext) {
        let samples: [(String, String, String, Double?, Int?, Int, String, Bool, SampleCheckIn?)] = [
            (
                "Pliny the Elder", "Russian River", "Double IPA", 8.0, 100, 5,
                "Hop bomb. Worth every minute in line.", true,
                SampleCheckIn(
                    daysAgo: 2,
                    venue: "Russian River Brewing Co., Santa Rosa, CA",
                    note: "Fresh pour after the drive up.",
                    latitude: 38.4404,
                    longitude: -122.7141
                )
            ),
            (
                "Heady Topper", "The Alchemist", "Double IPA", 8.0, 120, 5,
                "Drink from the can. Unfiltered perfection.", true,
                SampleCheckIn(
                    daysAgo: 14,
                    venue: "The Alchemist, Stowe, VT",
                    note: "Can from the brewery.",
                    latitude: 44.4654,
                    longitude: -72.6874
                )
            ),
            (
                "Guinness Draught", "Guinness", "Stout", 4.2, 45, 4,
                "Classic nitro pour. Creamy and reliable.", false,
                SampleCheckIn(
                    daysAgo: 30,
                    venue: "Guinness Storehouse, Dublin",
                    note: "Gravity Bar view.",
                    latitude: 53.3419,
                    longitude: -6.2867
                )
            ),
            (
                "Pilsner Urquell", "Pilsner Urquell", "Pilsner", 4.4, 40, 4,
                "The original. Crisp, floral, perfect with pizza.", false,
                SampleCheckIn(
                    daysAgo: 45,
                    venue: "Pilsner Urquell Brewery, Plzeň",
                    note: "Unfiltered tank beer tour.",
                    latitude: 49.7467,
                    longitude: 13.3870
                )
            ),
            (
                "Two Hearted Ale", "Bell's", "IPA", 7.0, 55, 5,
                "Centennial hops all the way. House favorite.", true,
                SampleCheckIn(
                    daysAgo: 5,
                    venue: "Bell's Eccentric Café, Kalamazoo, MI",
                    note: "Patio pint.",
                    latitude: 42.2917,
                    longitude: -85.5872
                )
            ),
            (
                "Oberon", "Bell's", "Wheat", 5.8, nil, 4,
                "Summer in a glass. Orange slice optional.", false,
                SampleCheckIn(
                    daysAgo: 60,
                    venue: "Home, Chicago, IL",
                    note: "Backyard opener.",
                    latitude: 41.8781,
                    longitude: -87.6298
                )
            ),
            (
                "Allagash White", "Allagash", "Belgian", 5.2, nil, 4,
                "Witbier done right. Coriander and orange peel.", false,
                SampleCheckIn(
                    daysAgo: 20,
                    venue: "Allagash Brewing Company, Portland, ME",
                    note: "Tasting room flight.",
                    latitude: 43.7026,
                    longitude: -70.3170
                )
            ),
            (
                "Zombie Dust", "3 Floyds", "Pale Ale", 6.2, 50, 5,
                "Citra-forward pale. Crushable.", true,
                SampleCheckIn(
                    daysAgo: 8,
                    venue: "3 Floyds Brewing, Munster, IN",
                    note: "With a soft pretzel.",
                    latitude: 41.5645,
                    longitude: -87.5125
                )
            ),
            (
                "Orval", "Brasserie d'Orval", "Belgian", 6.2, 36, 5,
                "Trappist elegance. Changes in the glass.", true,
                SampleCheckIn(
                    daysAgo: 90,
                    venue: "Café de l'Abbaye, Villers-devant-Orval",
                    note: "Young bottle, cellar cool.",
                    latitude: 49.6397,
                    longitude: 5.3486
                )
            ),
            (
                "Asahi Super Dry", "Asahi", "Lager", 5.0, nil, 3,
                "Crisp karakuchi finish. Sushi night staple.", false,
                SampleCheckIn(
                    daysAgo: 12,
                    venue: "Shinjuku, Tokyo",
                    note: "Izakaya pour.",
                    latitude: 35.6938,
                    longitude: 139.7034
                )
            ),
        ]

        for (index, sample) in samples.enumerated() {
            let beer = Beer(
                name: sample.0,
                brewery: sample.1,
                style: sample.2,
                abv: sample.3,
                ibu: sample.4,
                rating: sample.5,
                notes: sample.6,
                isFavorite: sample.7,
                createdAt: Calendar.current.date(byAdding: .day, value: -index * 3, to: .now) ?? .now,
                updatedAt: .now
            )
            context.insert(beer)

            if let tasting = sample.8 {
                let checkIn = CheckIn(
                    tastedAt: Calendar.current.date(byAdding: .day, value: -tasting.daysAgo, to: .now) ?? .now,
                    venue: tasting.venue,
                    note: tasting.note,
                    latitude: tasting.latitude,
                    longitude: tasting.longitude,
                    beer: beer
                )
                context.insert(checkIn)
            }
        }
    }

    @MainActor
    static func deleteAll(from context: ModelContext) throws {
        // Fetch-and-delete works on iOS 17+; bulk delete(model:) is iOS 18+.
        let checkIns = try context.fetch(FetchDescriptor<CheckIn>())
        for checkIn in checkIns {
            context.delete(checkIn)
        }
        let beers = try context.fetch(FetchDescriptor<Beer>())
        for beer in beers {
            context.delete(beer)
        }
    }
}
