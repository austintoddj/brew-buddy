//
//  BrewBuddyTests.swift
//  BrewBuddyTests
//

import XCTest
import UIKit
@testable import BrewBuddy

final class BrewBuddyTests: XCTestCase {

    func testClampedRatingBounds() {
        XCTAssertEqual(Beer.clampedRating(-3), 0)
        XCTAssertEqual(Beer.clampedRating(0), 0)
        XCTAssertEqual(Beer.clampedRating(3), 3)
        XCTAssertEqual(Beer.clampedRating(5), 5)
        XCTAssertEqual(Beer.clampedRating(99), 5)
    }

    func testBeerInitClampsRating() {
        let beer = Beer(name: "Test", rating: 12)
        XCTAssertEqual(beer.rating, 5)
        XCTAssertEqual(beer.displayName, "Test")
    }

    func testDisplayNameFallback() {
        let beer = Beer(name: "   ")
        XCTAssertEqual(beer.displayName, "Untitled Beer")
    }

    func testCSVEscapeQuotesAndCommas() {
        XCTAssertEqual(ExportService.csvEscape("simple"), "simple")
        XCTAssertEqual(ExportService.csvEscape("hello, world"), "\"hello, world\"")
        XCTAssertEqual(ExportService.csvEscape("say \"hi\""), "\"say \"\"hi\"\"\"")
    }

    func testCSVContainsHeaderAndRow() {
        let beer = Beer(
            name: "Two Hearted",
            brewery: "Bell's",
            style: "IPA",
            abv: 7.0,
            rating: 5,
            notes: "Great",
            isFavorite: true
        )
        let csv = ExportService.csvString(from: [beer])
        XCTAssertTrue(csv.contains("beer_id,name,brewery,style"))
        XCTAssertTrue(csv.contains("Two Hearted"))
        XCTAssertTrue(csv.contains("Bell's") || csv.contains("Bell"))
        XCTAssertTrue(csv.contains("IPA"))
    }

    func testJSONExportDecodes() throws {
        let beer = Beer(name: "Guinness", brewery: "Guinness", style: "Stout", rating: 4)
        let data = try ExportService.jsonData(from: [beer])
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let export = try decoder.decode(ExportService.LibraryExport.self, from: data)
        XCTAssertEqual(export.version, 1)
        XCTAssertEqual(export.beers.count, 1)
        XCTAssertEqual(export.beers.first?.name, "Guinness")
        XCTAssertEqual(export.beers.first?.rating, 4)
    }

    func testStatsSnapshot() {
        let a = Beer(name: "A", style: "IPA", rating: 5, isFavorite: true)
        let b = Beer(name: "B", style: "IPA", rating: 3, isFavorite: false)
        let c = Beer(name: "C", style: "Stout", rating: 0, isFavorite: true)
        let checkIn = CheckIn(tastedAt: .now, venue: "Home", beer: a)
        a.checkIns = [checkIn]

        let snapshot = StatsComputer.snapshot(from: [a, b, c])
        XCTAssertEqual(snapshot.totalBeers, 3)
        XCTAssertEqual(snapshot.favorites, 2)
        XCTAssertEqual(snapshot.ratedCount, 2)
        XCTAssertEqual(snapshot.averageRating!, 4.0, accuracy: 0.001)
        XCTAssertEqual(snapshot.totalCheckIns, 1)
        XCTAssertEqual(snapshot.checkInsThisMonth, 1)
        XCTAssertEqual(snapshot.styleCounts.first?.style, "IPA")
        XCTAssertEqual(snapshot.styleCounts.first?.count, 2)
        XCTAssertEqual(snapshot.styleCounts.count, 2)
        XCTAssertEqual(snapshot.ratingDistribution[5], 1)
        XCTAssertEqual(snapshot.ratingDistribution[3], 1)
    }

    func testCheckInCoordinates() {
        let pinned = CheckIn(
            venue: "Guinness Storehouse",
            latitude: 53.3419,
            longitude: -6.2867
        )
        XCTAssertTrue(pinned.hasCoordinates)
        XCTAssertEqual(pinned.coordinate?.latitude ?? 0, 53.3419, accuracy: 0.0001)
        XCTAssertEqual(pinned.coordinate?.longitude ?? 0, -6.2867, accuracy: 0.0001)

        let freeText = CheckIn(venue: "Home")
        XCTAssertFalse(freeText.hasCoordinates)
        XCTAssertNil(freeText.coordinate)

        let invalid = CheckIn(venue: "X", latitude: 999, longitude: 0)
        XCTAssertFalse(invalid.hasCoordinates)
    }

    /// Regression: selecting a place used to clear lat/lon when venue `onChange` fired after apply.
    func testVenuePinPolicyKeepsCoordinatesWhenLabelMatches() {
        XCTAssertTrue(
            VenuePinPolicy.shouldKeepCoordinates(
                pinnedLabel: "Guinness Storehouse, Dublin",
                venueText: "Guinness Storehouse, Dublin"
            )
        )
        XCTAssertFalse(
            VenuePinPolicy.shouldKeepCoordinates(
                pinnedLabel: "Guinness Storehouse, Dublin",
                venueText: "Guinness Storehouse, Dublin "
            )
        )
        XCTAssertFalse(
            VenuePinPolicy.shouldKeepCoordinates(
                pinnedLabel: "Guinness Storehouse, Dublin",
                venueText: "Home"
            )
        )
        XCTAssertFalse(
            VenuePinPolicy.shouldKeepCoordinates(
                pinnedLabel: nil,
                venueText: "Anything typed"
            )
        )
    }

    func testResolvedPlaceDisplayName() {
        let withSubtitle = PlaceSearchService.ResolvedPlace(
            name: "Guinness Storehouse",
            subtitle: "Dublin, Ireland",
            latitude: 53.34,
            longitude: -6.29
        )
        XCTAssertEqual(withSubtitle.displayName, "Guinness Storehouse, Dublin, Ireland")

        let nameOnly = PlaceSearchService.ResolvedPlace(
            name: "Home Bar",
            subtitle: "",
            latitude: 0,
            longitude: 0
        )
        XCTAssertEqual(nameOnly.displayName, "Home Bar")

        let subtitleContainsName = PlaceSearchService.ResolvedPlace(
            name: "Dublin",
            subtitle: "Dublin, Ireland",
            latitude: 53.35,
            longitude: -6.26
        )
        XCTAssertEqual(subtitleContainsName.displayName, "Dublin, Ireland")
    }

    func testJSONExportIncludesCoordinates() throws {
        let beer = Beer(name: "Guinness", brewery: "Guinness", style: "Stout", rating: 4)
        let checkIn = CheckIn(
            tastedAt: .now,
            venue: "Dublin",
            latitude: 53.35,
            longitude: -6.26,
            beer: beer
        )
        beer.checkIns = [checkIn]

        let data = try ExportService.jsonData(from: [beer])
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let export = try decoder.decode(ExportService.LibraryExport.self, from: data)
        let exported = export.beers.first?.checkIns.first
        XCTAssertEqual(exported?.venue, "Dublin")
        XCTAssertEqual(exported?.latitude ?? 0, 53.35, accuracy: 0.001)
        XCTAssertEqual(exported?.longitude ?? 0, -6.26, accuracy: 0.001)
    }

    func testPhotoCompressorReturnsJPEG() {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 40, height: 40))
        let image = renderer.image { ctx in
            UIColor.orange.setFill()
            ctx.fill(CGRect(x: 0, y: 0, width: 40, height: 40))
        }
        guard let data = image.pngData() else {
            XCTFail("Could not make PNG")
            return
        }
        let compressed = PhotoCompressor.compress(data)
        XCTAssertNotNil(compressed)
        XCTAssertNotNil(UIImage(data: compressed!))
        // JPEG magic bytes
        XCTAssertEqual(compressed![0], 0xFF)
        XCTAssertEqual(compressed![1], 0xD8)
    }

    func testPhotoCompressorDownscalesLargeImages() {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 3000, height: 2000))
        let image = renderer.image { ctx in
            UIColor.brown.setFill()
            ctx.fill(CGRect(x: 0, y: 0, width: 3000, height: 2000))
        }
        guard let data = image.pngData(),
              let compressed = PhotoCompressor.compress(data),
              let out = UIImage(data: compressed) else {
            XCTFail("Compression failed")
            return
        }
        XCTAssertLessThanOrEqual(max(out.size.width, out.size.height), PhotoCompressor.maxDimension + 1)
    }
}
