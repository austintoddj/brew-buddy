//
//  BeerListView.swift
//  BrewBuddy
//

import SwiftUI
import SwiftData
import UIKit

enum BeerSortOption: String, CaseIterable, Identifiable {
    case recent = "Recent"
    case name = "Name"
    case rating = "Rating"
    case brewery = "Brewery"

    var id: String { rawValue }
}

enum BeerFilterOption: String, CaseIterable, Identifiable {
    case all = "All"
    case favorites = "Favorites"
    case rated = "Rated"
    case unrated = "Unrated"

    var id: String { rawValue }
}

struct BeerListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Beer.updatedAt, order: .reverse) private var beers: [Beer]

    @State private var searchText = ""
    @State private var sortOption: BeerSortOption = .recent
    @State private var filterOption: BeerFilterOption = .all
    @State private var isPresentingEditor = false
    @State private var beerToEdit: Beer?

    private var filteredBeers: [Beer] {
        var result = beers

        switch filterOption {
        case .all: break
        case .favorites: result = result.filter(\.isFavorite)
        case .rated: result = result.filter { $0.rating > 0 }
        case .unrated: result = result.filter { $0.rating == 0 }
        }

        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !query.isEmpty {
            result = result.filter { beer in
                beer.name.localizedCaseInsensitiveContains(query)
                    || beer.brewery.localizedCaseInsensitiveContains(query)
                    || beer.style.localizedCaseInsensitiveContains(query)
                    || beer.notes.localizedCaseInsensitiveContains(query)
            }
        }

        switch sortOption {
        case .recent:
            result.sort { $0.updatedAt > $1.updatedAt }
        case .name:
            result.sort { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        case .rating:
            result.sort {
                if $0.rating == $1.rating {
                    return $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
                }
                return $0.rating > $1.rating
            }
        case .brewery:
            result.sort {
                if $0.brewery.localizedCaseInsensitiveCompare($1.brewery) == .orderedSame {
                    return $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
                }
                return $0.brewery.localizedCaseInsensitiveCompare($1.brewery) == .orderedAscending
            }
        }

        return result
    }

    var body: some View {
        NavigationStack {
            Group {
                if beers.isEmpty {
                    EmptyStateView(
                        systemImage: "mug",
                        title: "No beers yet",
                        message: "Log your first pint and start building your personal beer journal.",
                        actionTitle: "Add Beer"
                    ) {
                        isPresentingEditor = true
                    }
                } else if filteredBeers.isEmpty {
                    EmptyStateView(
                        systemImage: "magnifyingglass",
                        title: "No matches",
                        message: "Try a different search or filter."
                    )
                } else {
                    List {
                        ForEach(filteredBeers) { beer in
                            NavigationLink(value: beer) {
                                BeerRowView(beer: beer)
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    delete(beer)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                            .swipeActions(edge: .leading, allowsFullSwipe: true) {
                                Button {
                                    toggleFavorite(beer)
                                } label: {
                                    Label(
                                        beer.isFavorite ? "Unfavorite" : "Favorite",
                                        systemImage: beer.isFavorite ? "heart.slash" : "heart.fill"
                                    )
                                }
                                .tint(BrewTheme.favorite)
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("BrewBuddy")
            .navigationDestination(for: Beer.self) { beer in
                BeerDetailView(beer: beer)
            }
            .searchable(text: $searchText, prompt: "Search name, brewery, style")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Menu {
                        Picker("Filter", selection: $filterOption) {
                            ForEach(BeerFilterOption.allCases) { option in
                                Text(option.rawValue).tag(option)
                            }
                        }
                        Picker("Sort", selection: $sortOption) {
                            ForEach(BeerSortOption.allCases) { option in
                                Text(option.rawValue).tag(option)
                            }
                        }
                    } label: {
                        Label("Filter & Sort", systemImage: "line.3.horizontal.decrease.circle")
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        isPresentingEditor = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("Add beer")
                }
            }
            .sheet(isPresented: $isPresentingEditor) {
                BeerEditorView(mode: .create)
            }
        }
    }

    private func delete(_ beer: Beer) {
        modelContext.delete(beer)
        try? modelContext.save()
    }

    private func toggleFavorite(_ beer: Beer) {
        beer.isFavorite.toggle()
        beer.touch()
        try? modelContext.save()
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }
}

#Preview {
    BeerListView()
        .modelContainer(for: [Beer.self, CheckIn.self], inMemory: true)
}
