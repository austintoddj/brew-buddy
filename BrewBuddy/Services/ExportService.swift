//
//  ExportService.swift
//  BrewBuddy
//

import Foundation

enum ExportService {
    struct BeerExport: Codable, Equatable {
        var id: UUID
        var name: String
        var brewery: String
        var style: String
        var abv: Double?
        var ibu: Int?
        var rating: Int
        var notes: String
        var isFavorite: Bool
        var createdAt: Date
        var updatedAt: Date
        var checkIns: [CheckInExport]
    }

    struct CheckInExport: Codable, Equatable {
        var id: UUID
        var tastedAt: Date
        var venue: String?
        var note: String?
        var latitude: Double?
        var longitude: Double?
    }

    struct LibraryExport: Codable, Equatable {
        var version: Int
        var exportedAt: Date
        var beers: [BeerExport]
    }

    static func makeLibraryExport(from beers: [Beer]) -> LibraryExport {
        let exportedBeers = beers.map { beer in
            BeerExport(
                id: beer.id,
                name: beer.name,
                brewery: beer.brewery,
                style: beer.style,
                abv: beer.abv,
                ibu: beer.ibu,
                rating: beer.rating,
                notes: beer.notes,
                isFavorite: beer.isFavorite,
                createdAt: beer.createdAt,
                updatedAt: beer.updatedAt,
                checkIns: beer.checkIns.map {
                    CheckInExport(
                        id: $0.id,
                        tastedAt: $0.tastedAt,
                        venue: $0.venue,
                        note: $0.note,
                        latitude: $0.latitude,
                        longitude: $0.longitude
                    )
                }
            )
        }
        return LibraryExport(version: 1, exportedAt: .now, beers: exportedBeers)
    }

    static func jsonData(from beers: [Beer]) throws -> Data {
        let export = makeLibraryExport(from: beers)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return try encoder.encode(export)
    }

    static func csvString(from beers: [Beer]) -> String {
        var rows: [String] = [
            [
                "beer_id",
                "name",
                "brewery",
                "style",
                "abv",
                "ibu",
                "rating",
                "is_favorite",
                "notes",
                "created_at",
                "updated_at",
                "checkin_count",
            ].joined(separator: ",")
        ]

        let iso = ISO8601DateFormatter()

        for beer in beers.sorted(by: { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }) {
            let fields: [String] = [
                beer.id.uuidString,
                csvEscape(beer.name),
                csvEscape(beer.brewery),
                csvEscape(beer.style),
                beer.abv.map { String(format: "%.1f", $0) } ?? "",
                beer.ibu.map(String.init) ?? "",
                String(beer.rating),
                beer.isFavorite ? "true" : "false",
                csvEscape(beer.notes),
                iso.string(from: beer.createdAt),
                iso.string(from: beer.updatedAt),
                String(beer.checkIns.count),
            ]
            rows.append(fields.joined(separator: ","))
        }

        return rows.joined(separator: "\n") + "\n"
    }

    static func csvData(from beers: [Beer]) -> Data {
        Data(csvString(from: beers).utf8)
    }

    /// Escape a field for CSV (RFC 4180-ish).
    static func csvEscape(_ value: String) -> String {
        if value.contains(",") || value.contains("\"") || value.contains("\n") || value.contains("\r") {
            let escaped = value.replacingOccurrences(of: "\"", with: "\"\"")
            return "\"\(escaped)\""
        }
        return value
    }
}

enum StatsComputer {
    struct StyleCount: Equatable {
        var style: String
        var count: Int
    }

    struct Snapshot: Equatable {
        var totalBeers: Int
        var favorites: Int
        var ratedCount: Int
        var averageRating: Double?
        var totalCheckIns: Int
        var checkInsThisMonth: Int
        var styleCounts: [StyleCount]
        var ratingDistribution: [Int: Int] // rating 1...5 -> count
    }

    static func snapshot(from beers: [Beer], now: Date = .now) -> Snapshot {
        let favorites = beers.filter(\.isFavorite).count
        let rated = beers.filter { $0.rating > 0 }
        let average: Double? = rated.isEmpty
            ? nil
            : Double(rated.map(\.rating).reduce(0, +)) / Double(rated.count)

        let allCheckIns = beers.flatMap(\.checkIns)
        let calendar = Calendar.current
        let month = calendar.dateComponents([.year, .month], from: now)
        let checkInsThisMonth = allCheckIns.filter {
            let c = calendar.dateComponents([.year, .month], from: $0.tastedAt)
            return c.year == month.year && c.month == month.month
        }.count

        var styleMap: [String: Int] = [:]
        for beer in beers {
            let key = beer.style.trimmingCharacters(in: .whitespacesAndNewlines)
            let label = key.isEmpty ? "Unspecified" : key
            styleMap[label, default: 0] += 1
        }
        let styleCounts = styleMap
            .map { StyleCount(style: $0.key, count: $0.value) }
            .sorted {
                if $0.count == $1.count {
                    return $0.style.localizedCaseInsensitiveCompare($1.style) == .orderedAscending
                }
                return $0.count > $1.count
            }

        var ratingDist: [Int: Int] = [1: 0, 2: 0, 3: 0, 4: 0, 5: 0]
        for beer in rated {
            ratingDist[beer.rating, default: 0] += 1
        }

        return Snapshot(
            totalBeers: beers.count,
            favorites: favorites,
            ratedCount: rated.count,
            averageRating: average,
            totalCheckIns: allCheckIns.count,
            checkInsThisMonth: checkInsThisMonth,
            styleCounts: styleCounts,
            ratingDistribution: ratingDist
        )
    }
}
