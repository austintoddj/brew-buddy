//
//  CheckIn.swift
//  BrewBuddy
//

import Foundation
import SwiftData
import CoreLocation

@Model
final class CheckIn {
    var id: UUID
    var tastedAt: Date
    var venue: String?
    var note: String?
    /// WGS84 latitude when the tasting was pinned to a place (optional).
    var latitude: Double?
    /// WGS84 longitude when the tasting was pinned to a place (optional).
    var longitude: Double?
    @Attribute(.externalStorage) var photoData: Data?
    var beer: Beer?

    init(
        id: UUID = UUID(),
        tastedAt: Date = .now,
        venue: String? = nil,
        note: String? = nil,
        latitude: Double? = nil,
        longitude: Double? = nil,
        photoData: Data? = nil,
        beer: Beer? = nil
    ) {
        self.id = id
        self.tastedAt = tastedAt
        self.venue = venue
        self.note = note
        self.latitude = latitude
        self.longitude = longitude
        self.photoData = photoData
        self.beer = beer
    }

    var displayVenue: String {
        let trimmed = venue?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return trimmed.isEmpty ? "Somewhere" : trimmed
    }

    var hasCoordinates: Bool {
        guard let latitude, let longitude else { return false }
        return (-90...90).contains(latitude) && (-180...180).contains(longitude)
    }

    var coordinate: CLLocationCoordinate2D? {
        guard hasCoordinates, let latitude, let longitude else { return nil }
        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}
