//
//  BeerRowView.swift
//  BrewBuddy
//

import SwiftUI

struct BeerRowView: View {
    let beer: Beer

    var body: some View {
        HStack(spacing: 14) {
            BeerPhotoView(photoData: beer.photoData, size: 56)

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(beer.displayName)
                        .font(.headline)
                        .lineLimit(1)
                    if beer.isFavorite {
                        Image(systemName: "heart.fill")
                            .font(.caption)
                            .foregroundStyle(BrewTheme.favorite)
                            .accessibilityLabel("Favorite")
                    }
                }

                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)

                HStack(spacing: 8) {
                    if beer.rating > 0 {
                        StarRatingLabel(rating: beer.rating)
                    } else {
                        Text("Unrated")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }

                    if !beer.checkIns.isEmpty {
                        Text("· \(beer.checkIns.count) tasting\(beer.checkIns.count == 1 ? "" : "s")")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
    }

    private var subtitle: String {
        let brewery = beer.brewery.trimmingCharacters(in: .whitespacesAndNewlines)
        let style = beer.style.trimmingCharacters(in: .whitespacesAndNewlines)
        switch (brewery.isEmpty, style.isEmpty) {
        case (false, false): return "\(brewery) · \(style)"
        case (false, true): return brewery
        case (true, false): return style
        case (true, true): return "Details TBD"
        }
    }
}
