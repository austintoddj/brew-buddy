//
//  VenueSearchField.swift
//  BrewBuddy
//

import SwiftUI
import MapKit
import CoreLocation

/// Pure rules for when a venue field keeps vs clears map coordinates.
/// Kept free of SwiftUI so the pin race fix stays unit-testable.
enum VenuePinPolicy {
    /// Coordinates stay only while the field text still matches the last resolved pin label.
    static func shouldKeepCoordinates(pinnedLabel: String?, venueText: String) -> Bool {
        pinnedLabel == venueText
    }
}

/// Venue text field with Apple Maps autocomplete + optional “use my location”.
struct VenueSearchField: View {
    @Binding var venue: String
    @Binding var latitude: Double?
    @Binding var longitude: Double?

    @StateObject private var search = PlaceSearchService()
    @StateObject private var locationManager = LocationManager()

    @State private var showSuggestions = false
    @State private var isResolving = false
    /// Venue string last applied from search / current location. Coordinates are kept only while
    /// `venue` still matches this — avoids a SwiftUI `onChange` race that wiped pins after resolve.
    @State private var pinnedVenueName: String?
    @State private var statusMessage: String?
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                Image(systemName: "mappin.and.ellipse")
                    .foregroundStyle(BrewTheme.accent)

                TextField("Venue or city", text: $venue)
                    .textInputAutocapitalization(.words)
                    .autocorrectionDisabled()
                    .focused($isFocused)
                    .onChange(of: venue) { _, newValue in
                        // Manual edits clear pins so free-typed venues don’t keep a stale map point.
                        // Compare against the pinned label (not a transient flag) so deferred
                        // `onChange` after `apply` cannot wipe lat/lon that were just set.
                        if !VenuePinPolicy.shouldKeepCoordinates(
                            pinnedLabel: pinnedVenueName,
                            venueText: newValue
                        ) {
                            if latitude != nil || longitude != nil {
                                latitude = nil
                                longitude = nil
                            }
                            pinnedVenueName = nil
                        }
                        search.updateQuery(newValue, region: searchRegion)
                        showSuggestions = isFocused && !newValue.isEmpty
                    }
                    .onChange(of: isFocused) { _, focused in
                        showSuggestions = focused && !venue.isEmpty && !search.completions.isEmpty
                    }

                if isResolving {
                    ProgressView()
                        .controlSize(.small)
                } else if latitude != nil, longitude != nil {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                        .accessibilityLabel("Location pinned on map")
                }
            }

            if let statusMessage {
                Text(statusMessage)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if showSuggestions && !search.completions.isEmpty {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(Array(search.completions.prefix(6).enumerated()), id: \.offset) { index, completion in
                        Button {
                            select(completion)
                        } label: {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(completion.title)
                                    .font(.subheadline.weight(.medium))
                                    .foregroundStyle(.primary)
                                if !completion.subtitle.isEmpty {
                                    Text(completion.subtitle)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.vertical, 10)
                            .padding(.horizontal, 4)
                        }
                        .buttonStyle(.plain)

                        if index < min(5, search.completions.count - 1) {
                            Divider()
                        }
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            }

            Button {
                useCurrentLocation()
            } label: {
                Label("Use my location", systemImage: "location.fill")
                    .font(.subheadline.weight(.medium))
            }
            .tint(BrewTheme.accent)
            .disabled(isResolving)
        }
        .onAppear {
            locationManager.requestPermissionIfNeeded()
            // Restore pin bookkeeping if the editor is re-opened with existing coords.
            if latitude != nil, longitude != nil, pinnedVenueName == nil {
                pinnedVenueName = venue
            }
        }
    }

    private var searchRegion: MKCoordinateRegion? {
        if let lat = latitude, let lon = longitude {
            return MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: lat, longitude: lon),
                latitudinalMeters: 50_000,
                longitudinalMeters: 50_000
            )
        }
        if let loc = locationManager.location {
            return MKCoordinateRegion(
                center: loc.coordinate,
                latitudinalMeters: 50_000,
                longitudinalMeters: 50_000
            )
        }
        return nil
    }

    private func select(_ completion: MKLocalSearchCompletion) {
        isResolving = true
        statusMessage = nil
        showSuggestions = false
        isFocused = false

        Task {
            do {
                let place = try await search.resolve(completion)
                apply(place: place, status: "Pinned for the map")
            } catch {
                statusMessage = error.localizedDescription
            }
            isResolving = false
        }
    }

    private func useCurrentLocation() {
        isResolving = true
        statusMessage = nil
        locationManager.requestPermissionIfNeeded()
        locationManager.requestLocation()

        Task {
            // Wait briefly for a fix if we don't have one yet.
            var attempts = 0
            while locationManager.location == nil && attempts < 20 {
                try? await Task.sleep(nanoseconds: 150_000_000)
                attempts += 1
            }

            guard let loc = locationManager.location else {
                statusMessage = locationManager.isAuthorized
                    ? "Couldn’t get your location yet. Try again."
                    : "Enable Location for BrewBuddy in Settings."
                isResolving = false
                return
            }

            do {
                let place = try await search.reverseGeocode(
                    latitude: loc.coordinate.latitude,
                    longitude: loc.coordinate.longitude
                )
                apply(place: place, status: "Pinned for the map")
            } catch {
                // Still save coordinates even if reverse geocode fails.
                pin(
                    venueName: venue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                        ? "Current location"
                        : venue,
                    latitude: loc.coordinate.latitude,
                    longitude: loc.coordinate.longitude,
                    status: "Location saved (name unavailable)"
                )
            }
            isResolving = false
        }
    }

    private func apply(place: PlaceSearchService.ResolvedPlace, status: String) {
        pin(
            venueName: place.displayName,
            latitude: place.latitude,
            longitude: place.longitude,
            status: status
        )
        search.clear()
        showSuggestions = false
    }

    /// Sets venue + coordinates, recording the label so later `onChange` does not clear the pin.
    private func pin(venueName: String, latitude lat: Double, longitude lon: Double, status: String) {
        // Record the pinned label *before* updating `venue` so a deferred onChange still matches.
        pinnedVenueName = venueName
        latitude = lat
        longitude = lon
        venue = venueName
        statusMessage = status
    }
}
