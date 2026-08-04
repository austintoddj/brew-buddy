//
//  StatsView.swift
//  BrewBuddy
//

import SwiftUI
import SwiftData
import Charts

struct StatsView: View {
    @Query(sort: \Beer.updatedAt, order: .reverse) private var beers: [Beer]

    private var stats: StatsComputer.Snapshot {
        StatsComputer.snapshot(from: beers)
    }

    var body: some View {
        NavigationStack {
            Group {
                if beers.isEmpty {
                    EmptyStateView(
                        systemImage: "chart.bar",
                        title: "No stats yet",
                        message: "Add a few beers to see ratings, styles, and tasting trends."
                    )
                } else {
                    ScrollView {
                        VStack(spacing: 16) {
                            summaryGrid
                            if stats.averageRating != nil {
                                ratingChart
                            }
                            if !stats.styleCounts.isEmpty {
                                styleChart
                            }
                            recentCheckIns
                        }
                        .padding()
                    }
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Stats")
        }
    }

    private var summaryGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            StatCard(title: "Beers", value: "\(stats.totalBeers)", systemImage: "mug.fill")
            StatCard(title: "Favorites", value: "\(stats.favorites)", systemImage: "heart.fill", tint: BrewTheme.favorite)
            StatCard(
                title: "Avg rating",
                value: stats.averageRating.map { String(format: "%.1f" , $0) } ?? "—",
                systemImage: "star.fill"
            )
            StatCard(title: "Tastings", value: "\(stats.totalCheckIns)", systemImage: "calendar")
            StatCard(title: "This month", value: "\(stats.checkInsThisMonth)", systemImage: "calendar.badge.clock")
            StatCard(title: "Rated", value: "\(stats.ratedCount)", systemImage: "checkmark.seal.fill")
        }
    }

    private var ratingChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Rating distribution")
                .font(.headline)

            Chart {
                ForEach(1...5, id: \.self) { rating in
                    let count = stats.ratingDistribution[rating] ?? 0
                    BarMark(
                        x: .value("Stars", "\(rating)★"),
                        y: .value("Count", count)
                    )
                    .foregroundStyle(BrewTheme.accent.gradient)
                    .cornerRadius(6)
                }
            }
            .frame(height: 180)
            .chartYAxis {
                AxisMarks(position: .leading)
            }
        }
        .padding()
        .background(.background, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private var styleChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("By style")
                .font(.headline)

            Chart {
                ForEach(stats.styleCounts.prefix(8), id: \.style) { item in
                    BarMark(
                        x: .value("Count", item.count),
                        y: .value("Style", item.style)
                    )
                    .foregroundStyle(BrewTheme.accentSoft.gradient)
                    .cornerRadius(4)
                }
            }
            .frame(height: CGFloat(min(stats.styleCounts.count, 8)) * 36 + 20)
        }
        .padding()
        .background(.background, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private var recentCheckIns: some View {
        let recent = beers
            .flatMap { beer in beer.checkIns.map { (beer: beer, checkIn: $0) } }
            .sorted { $0.checkIn.tastedAt > $1.checkIn.tastedAt }
            .prefix(8)

        return VStack(alignment: .leading, spacing: 12) {
            Text("Recent tastings")
                .font(.headline)

            if recent.isEmpty {
                Text("Log a tasting from any beer’s detail screen.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(Array(recent), id: \.checkIn.id) { item in
                    HStack(spacing: 12) {
                        BeerPhotoView(photoData: item.checkIn.photoData ?? item.beer.photoData, size: 44)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.beer.displayName)
                                .font(.subheadline.weight(.semibold))
                            Text("\(item.checkIn.displayVenue) · \(item.checkIn.tastedAt.formatted(date: .abbreviated, time: .omitted))")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.background, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let systemImage: String
    var tint: Color = BrewTheme.accent

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: systemImage)
                .font(.title3)
                .foregroundStyle(tint)
            Text(value)
                .font(.title.weight(.bold))
                .minimumScaleFactor(0.7)
                .lineLimit(1)
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.background, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

#Preview {
    StatsView()
        .modelContainer(for: [Beer.self, CheckIn.self], inMemory: true)
}
