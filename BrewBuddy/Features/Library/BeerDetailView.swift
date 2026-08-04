//
//  BeerDetailView.swift
//  BrewBuddy
//

import SwiftUI
import SwiftData
import UIKit

struct BeerDetailView: View {
    @Bindable var beer: Beer

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var isEditing = false
    @State private var isLoggingCheckIn = false
    @State private var showDeleteConfirm = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header
                ratingCard
                detailsCard
                if !beer.notes.isEmpty {
                    notesCard
                }
                checkInsSection
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(beer.displayName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button {
                    beer.isFavorite.toggle()
                    beer.touch()
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                } label: {
                    Image(systemName: beer.isFavorite ? "heart.fill" : "heart")
                        .foregroundStyle(beer.isFavorite ? BrewTheme.favorite : .primary)
                }
                .accessibilityLabel(beer.isFavorite ? "Remove from favorites" : "Add to favorites")

                Menu {
                    Button {
                        isEditing = true
                    } label: {
                        Label("Edit", systemImage: "pencil")
                    }
                    Button {
                        isLoggingCheckIn = true
                    } label: {
                        Label("Log tasting", systemImage: "plus.circle")
                    }
                    Divider()
                    Button(role: .destructive) {
                        showDeleteConfirm = true
                    } label: {
                        Label("Delete beer", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $isEditing) {
            BeerEditorView(mode: .edit(beer))
        }
        .sheet(isPresented: $isLoggingCheckIn) {
            CheckInEditorView(beer: beer)
        }
        .confirmationDialog("Delete this beer?", isPresented: $showDeleteConfirm, titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                modelContext.delete(beer)
                try? modelContext.save()
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This also removes all tasting check-ins for \(beer.displayName).")
        }
    }

    private var header: some View {
        HStack(alignment: .top, spacing: 16) {
            BeerPhotoView(photoData: beer.photoData, size: 110, cornerRadius: 20)

            VStack(alignment: .leading, spacing: 8) {
                Text(beer.displayName)
                    .font(.title2.weight(.bold))

                if !beer.brewery.isEmpty {
                    Text(beer.brewery)
                        .font(.headline)
                        .foregroundStyle(.secondary)
                }

                if !beer.style.isEmpty {
                    Text(beer.style)
                        .font(.subheadline)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(BrewTheme.accent.opacity(0.15), in: Capsule())
                        .foregroundStyle(BrewTheme.accent)
                }

                metaRow
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.background, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private var metaRow: some View {
        HStack(spacing: 12) {
            if let abv = beer.abv {
                Label(String(format: "%.1f%% ABV", abv), systemImage: "percent")
            }
            if let ibu = beer.ibu {
                Label("\(ibu) IBU", systemImage: "leaf")
            }
        }
        .font(.caption)
        .foregroundStyle(.secondary)
    }

    private var ratingCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Your rating")
                .font(.headline)
            StarRatingView(rating: Binding(
                get: { beer.rating },
                set: { newValue in
                    beer.rating = Beer.clampedRating(newValue)
                    beer.touch()
                }
            ))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.background, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private var detailsCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            LabeledContent("Added", value: beer.createdAt.formatted(date: .abbreviated, time: .omitted))
            LabeledContent("Updated", value: beer.updatedAt.formatted(date: .abbreviated, time: .shortened))
            LabeledContent("Tastings", value: "\(beer.checkIns.count)")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.background, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private var notesCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Notes")
                .font(.headline)
            Text(beer.notes)
                .font(.body)
                .foregroundStyle(.primary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.background, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private var checkInsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Tastings")
                    .font(.headline)
                Spacer()
                Button {
                    isLoggingCheckIn = true
                } label: {
                    Label("Log", systemImage: "plus")
                        .font(.subheadline.weight(.semibold))
                }
                .tint(BrewTheme.accent)
            }

            if beer.sortedCheckIns.isEmpty {
                Text("No tastings logged yet. Tap Log when you crack one open.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 8)
            } else {
                ForEach(beer.sortedCheckIns) { checkIn in
                    CheckInRowView(checkIn: checkIn) {
                        modelContext.delete(checkIn)
                        beer.touch()
                        try? modelContext.save()
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.background, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}

struct CheckInRowView: View {
    let checkIn: CheckIn
    var onDelete: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            if checkIn.photoData != nil {
                BeerPhotoView(photoData: checkIn.photoData, size: 48, cornerRadius: 10)
            } else {
                Image(systemName: "calendar")
                    .frame(width: 48, height: 48)
                    .background(BrewTheme.cardGradient, in: RoundedRectangle(cornerRadius: 10))
                    .foregroundStyle(BrewTheme.accent)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(checkIn.tastedAt.formatted(date: .abbreviated, time: .shortened))
                    .font(.subheadline.weight(.semibold))
                HStack(spacing: 4) {
                    if checkIn.hasCoordinates {
                        Image(systemName: "mappin.circle.fill")
                            .foregroundStyle(BrewTheme.accent)
                            .accessibilityLabel("On map")
                    }
                    Text(checkIn.displayVenue)
                }
                .font(.caption)
                .foregroundStyle(.secondary)
                if let note = checkIn.note, !note.isEmpty {
                    Text(note)
                        .font(.caption)
                        .foregroundStyle(.primary)
                }
            }
            Spacer(minLength: 0)
            Button(role: .destructive, action: onDelete) {
                Image(systemName: "trash")
                    .font(.caption)
            }
            .buttonStyle(.borderless)
            .accessibilityLabel("Delete tasting")
        }
        .padding(.vertical, 6)
    }
}
