//
//  BeerMapView.swift
//  BrewBuddy
//

import SwiftUI
import SwiftData
import MapKit

/// Bird’s-eye map of tasting check-ins — spin, zoom, and tap pins worldwide.
struct BeerMapView: View {
    @Query(sort: \CheckIn.tastedAt, order: .reverse) private var checkIns: [CheckIn]

    @State private var position: MapCameraPosition = BeerMapView.globeCamera
    @State private var selectedID: UUID?
    @State private var mapMode: MapMode = .globe
    @State private var hasFittedPins = false

    private var plotted: [CheckIn] {
        checkIns.filter(\.hasCoordinates)
    }

    private var selectedCheckIn: CheckIn? {
        guard let selectedID else { return nil }
        return plotted.first { $0.id == selectedID }
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                mapLayer
                    .ignoresSafeArea(edges: .top)

                if plotted.isEmpty {
                    emptyOverlay
                } else {
                    VStack(spacing: 12) {
                        HStack {
                            Spacer()
                            mapChrome
                        }
                        .padding(.horizontal)
                        .padding(.top, 8)

                        Spacer()

                        if let selectedCheckIn {
                            selectedCard(selectedCheckIn)
                                .transition(.move(edge: .bottom).combined(with: .opacity))
                        }

                        bottomBar
                    }
                    .padding(.bottom, 8)
                }
            }
            .navigationTitle("Map")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
            .onAppear {
                fitPinsIfNeeded(animated: false)
            }
            .onChange(of: plotted.count) { _, _ in
                hasFittedPins = false
                fitPinsIfNeeded(animated: true)
            }
        }
    }

    // MARK: - Map

    private var mapLayer: some View {
        Map(position: $position, selection: $selectedID) {
            ForEach(plotted, id: \.id) { checkIn in
                if let coordinate = checkIn.coordinate {
                    Annotation(
                        checkIn.displayVenue,
                        coordinate: coordinate,
                        anchor: .bottom
                    ) {
                        MapBeerPin(
                            isSelected: selectedID == checkIn.id,
                            rating: checkIn.beer?.rating ?? 0
                        )
                        .onTapGesture {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                selectedID = checkIn.id
                            }
                        }
                    }
                    .tag(checkIn.id)
                }
            }
        }
        .mapStyle(mapMode.mapStyle)
        .mapControls {
            MapCompass()
            MapScaleView()
            MapPitchToggle()
        }
        .mapControlVisibility(.visible)
        .animation(.easeInOut(duration: 0.35), value: mapMode)
    }

    private var mapChrome: some View {
        VStack(alignment: .trailing, spacing: 6) {
            // Map style layers — same idea as Apple Maps (satellite / hybrid / standard).
            Picker("Map style", selection: $mapMode) {
                ForEach(MapMode.allCases) { mode in
                    Label(mode.title, systemImage: mode.systemImage)
                        .tag(mode)
                        .accessibilityLabel(mode.title)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .frame(width: 168)
            .padding(6)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .accessibilityHint("Switch between globe, hybrid, and standard map styles")
        }
    }

    private var bottomBar: some View {
        HStack(spacing: 12) {
            Label("\(plotted.count) place\(plotted.count == 1 ? "" : "s")", systemImage: "mappin.circle.fill")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.primary)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(.ultraThinMaterial, in: Capsule())

            Spacer()

            Button {
                fitPinsIfNeeded(animated: true, force: true)
            } label: {
                Label("Fit", systemImage: "arrow.up.left.and.arrow.down.right")
                    .labelStyle(.iconOnly)
                    .font(.body.weight(.semibold))
                    .frame(width: 44, height: 44)
                    .background(.ultraThinMaterial, in: Circle())
            }
            .accessibilityLabel("Fit all pins")

            Button {
                withAnimation(.easeInOut(duration: 0.8)) {
                    position = Self.globeCamera
                    selectedID = nil
                    mapMode = .globe
                }
            } label: {
                Label("Globe", systemImage: "globe.americas.fill")
                    .labelStyle(.iconOnly)
                    .font(.body.weight(.semibold))
                    .frame(width: 44, height: 44)
                    .background(.ultraThinMaterial, in: Circle())
            }
            .accessibilityLabel("Zoom out to globe")
        }
        .padding(.horizontal)
        .tint(BrewTheme.accent)
    }

    private func selectedCard(_ checkIn: CheckIn) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(checkIn.beer?.displayName ?? "Beer")
                        .font(.headline)
                    Text(checkIn.displayVenue)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text(checkIn.tastedAt.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                Spacer()
                Button {
                    withAnimation {
                        selectedID = nil
                    }
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title3)
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(.secondary)
                }
                .accessibilityLabel("Dismiss")
            }

            if let beer = checkIn.beer, beer.rating > 0 {
                HStack(spacing: 2) {
                    ForEach(1...5, id: \.self) { star in
                        Image(systemName: star <= beer.rating ? "star.fill" : "star")
                            .font(.caption)
                            .foregroundStyle(star <= beer.rating ? BrewTheme.accent : .secondary.opacity(0.35))
                    }
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(BrewTheme.accent.opacity(0.25), lineWidth: 1)
        )
        .padding(.horizontal)
        .shadow(color: .black.opacity(0.15), radius: 16, y: 6)
    }

    private var emptyOverlay: some View {
        VStack {
            Spacer()
            EmptyStateView(
                systemImage: "globe.americas.fill",
                title: "No pins yet",
                message: "Log a tasting and pick a venue from search (or Use my location). Your beer map fills in as you go."
            )
            .padding()
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
            .padding(24)
            Spacer()
        }
        .allowsHitTesting(false)
    }

    // MARK: - Camera

    private static var globeCamera: MapCameraPosition {
        .camera(
            MapCamera(
                centerCoordinate: CLLocationCoordinate2D(latitude: 18, longitude: -20),
                distance: 32_000_000,
                heading: 0,
                pitch: 0
            )
        )
    }

    private func fitPinsIfNeeded(animated: Bool, force: Bool = false) {
        guard !plotted.isEmpty else {
            position = Self.globeCamera
            return
        }
        guard force || !hasFittedPins else { return }
        hasFittedPins = true

        let coords = plotted.compactMap(\.coordinate)
        guard let region = Self.region(fitting: coords) else { return }

        let update = {
            // Far-apart pins: keep a bit of world context; single pin: local zoom.
            if coords.count == 1 {
                position = .camera(
                    MapCamera(
                        centerCoordinate: coords[0],
                        distance: 80_000,
                        heading: 0,
                        pitch: 45
                    )
                )
            } else {
                position = .region(region)
            }
        }

        if animated {
            withAnimation(.easeInOut(duration: 0.9)) { update() }
        } else {
            update()
        }
    }

    private static func region(fitting coordinates: [CLLocationCoordinate2D]) -> MKCoordinateRegion? {
        guard !coordinates.isEmpty else { return nil }

        var minLat = coordinates[0].latitude
        var maxLat = coordinates[0].latitude
        var minLon = coordinates[0].longitude
        var maxLon = coordinates[0].longitude

        for c in coordinates.dropFirst() {
            minLat = min(minLat, c.latitude)
            maxLat = max(maxLat, c.latitude)
            minLon = min(minLon, c.longitude)
            maxLon = max(maxLon, c.longitude)
        }

        let center = CLLocationCoordinate2D(
            latitude: (minLat + maxLat) / 2,
            longitude: (minLon + maxLon) / 2
        )
        // Pad so pins aren't on the edge; minimum span so clusters still zoom out a bit.
        let span = MKCoordinateSpan(
            latitudeDelta: max((maxLat - minLat) * 1.8, 0.5),
            longitudeDelta: max((maxLon - minLon) * 1.8, 0.5)
        )
        return MKCoordinateRegion(center: center, span: span)
    }
}

// MARK: - Map style modes

private enum MapMode: String, CaseIterable, Identifiable {
    case globe
    case hybrid
    case standard

    var id: String { rawValue }

    var title: String {
        switch self {
        case .globe: return "Globe"
        case .hybrid: return "Hybrid"
        case .standard: return "Map"
        }
    }

    var systemImage: String {
        switch self {
        case .globe: return "globe.americas.fill"
        case .hybrid: return "square.3.layers.3d.down.right"
        case .standard: return "map"
        }
    }

    var mapStyle: MapStyle {
        switch self {
        case .globe:
            // Satellite + realistic elevation → Earth-like spin/zoom when far out.
            return .imagery(elevation: .realistic)
        case .hybrid:
            return .hybrid(elevation: .realistic)
        case .standard:
            return .standard(elevation: .realistic)
        }
    }
}

// MARK: - Pin

private struct MapBeerPin: View {
    let isSelected: Bool
    let rating: Int

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                Circle()
                    .fill(BrewTheme.accent.gradient)
                    .frame(width: isSelected ? 44 : 36, height: isSelected ? 44 : 36)
                    .shadow(color: BrewTheme.accent.opacity(0.45), radius: isSelected ? 10 : 5, y: 3)

                Image(systemName: "mug.fill")
                    .font(isSelected ? .body.weight(.bold) : .subheadline.weight(.semibold))
                    .foregroundStyle(.white)
            }
            .overlay(alignment: .topTrailing) {
                if rating > 0 {
                    Text("\(rating)")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(BrewTheme.charcoal)
                        .padding(3)
                        .background(BrewTheme.foam, in: Circle())
                        .offset(x: 4, y: -4)
                }
            }

            // Stem / pointer
            Triangle()
                .fill(BrewTheme.accent)
                .frame(width: 12, height: 8)
                .offset(y: -2)
        }
        .scaleEffect(isSelected ? 1.08 : 1)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }
}

private struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.closeSubpath()
        return path
    }
}

#Preview {
    BeerMapView()
        .modelContainer(for: [Beer.self, CheckIn.self], inMemory: true)
}
