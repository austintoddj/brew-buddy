//
//  PlaceSearchService.swift
//  BrewBuddy
//

import Foundation
import MapKit
import Combine

/// Apple Maps place autocomplete via `MKLocalSearchCompleter`.
@MainActor
final class PlaceSearchService: NSObject, ObservableObject {
    struct ResolvedPlace: Equatable {
        var name: String
        var subtitle: String
        var latitude: Double
        var longitude: Double

        var coordinate: CLLocationCoordinate2D {
            CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        }

        /// Best single-line venue label for storage.
        var displayName: String {
            if subtitle.isEmpty { return name }
            // Prefer "Name, City" style without duplicating the name.
            if subtitle.localizedCaseInsensitiveContains(name) {
                return subtitle
            }
            return "\(name), \(subtitle)"
        }
    }

    @Published private(set) var completions: [MKLocalSearchCompletion] = []
    @Published private(set) var isSearching = false

    private let completer = MKLocalSearchCompleter()
    private var queryTask: Task<Void, Never>?

    override init() {
        super.init()
        completer.delegate = self
        completer.resultTypes = [.pointOfInterest, .address]
    }

    /// Update the query fragment. Completions bias toward `region` when provided.
    func updateQuery(_ query: String, region: MKCoordinateRegion? = nil) {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        queryTask?.cancel()

        guard !trimmed.isEmpty else {
            completions = []
            isSearching = false
            completer.queryFragment = ""
            return
        }

        isSearching = true
        if let region {
            completer.region = region
        }
        // Small debounce so we don't thrash the completer on every keystroke.
        queryTask = Task {
            try? await Task.sleep(nanoseconds: 180_000_000)
            guard !Task.isCancelled else { return }
            completer.queryFragment = trimmed
        }
    }

    func clear() {
        queryTask?.cancel()
        completions = []
        isSearching = false
        completer.queryFragment = ""
    }

    /// Resolve a completion into coordinates via `MKLocalSearch`.
    func resolve(_ completion: MKLocalSearchCompletion) async throws -> ResolvedPlace {
        let request = MKLocalSearch.Request(completion: completion)
        let search = MKLocalSearch(request: request)
        let response = try await search.start()
        guard let item = response.mapItems.first else {
            throw PlaceSearchError.noResults
        }
        let coord = item.placemark.coordinate
        let name = item.name ?? completion.title
        let subtitle = [
            item.placemark.locality,
            item.placemark.administrativeArea,
            item.placemark.country,
        ]
        .compactMap { $0 }
        .filter { !$0.isEmpty }
        .joined(separator: ", ")

        return ResolvedPlace(
            name: name,
            subtitle: subtitle.isEmpty ? completion.subtitle : subtitle,
            latitude: coord.latitude,
            longitude: coord.longitude
        )
    }

    /// Reverse-geocode a coordinate into a friendly venue string.
    func reverseGeocode(latitude: Double, longitude: Double) async throws -> ResolvedPlace {
        let location = CLLocation(latitude: latitude, longitude: longitude)
        let geocoder = CLGeocoder()
        let placemarks = try await geocoder.reverseGeocodeLocation(location)
        guard let place = placemarks.first else {
            throw PlaceSearchError.noResults
        }

        let name = place.name
            ?? place.areasOfInterest?.first
            ?? place.locality
            ?? "Current location"
        let subtitle = [
            place.locality == name ? nil : place.locality,
            place.administrativeArea,
            place.country,
        ]
        .compactMap { $0 }
        .filter { !$0.isEmpty }
        .joined(separator: ", ")

        return ResolvedPlace(
            name: name,
            subtitle: subtitle,
            latitude: latitude,
            longitude: longitude
        )
    }
}

enum PlaceSearchError: LocalizedError {
    case noResults

    var errorDescription: String? {
        switch self {
        case .noResults:
            return "Couldn’t find that place."
        }
    }
}

extension PlaceSearchService: MKLocalSearchCompleterDelegate {
    nonisolated func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        let results = completer.results
        Task { @MainActor in
            completions = results
            isSearching = false
        }
    }

    nonisolated func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        Task { @MainActor in
            completions = []
            isSearching = false
        }
    }
}
