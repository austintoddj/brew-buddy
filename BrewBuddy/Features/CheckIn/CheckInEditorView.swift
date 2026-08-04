//
//  CheckInEditorView.swift
//  BrewBuddy
//

import SwiftUI
import SwiftData
import UIKit

struct CheckInEditorView: View {
    let beer: Beer

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var tastedAt: Date = .now
    @State private var venue: String = ""
    @State private var latitude: Double?
    @State private var longitude: Double?
    @State private var note: String = ""
    @State private var photoData: Data?

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        Spacer()
                        PhotoPickerThumbnail(photoData: $photoData, size: 120)
                        Spacer()
                    }
                    .listRowBackground(Color.clear)
                }

                Section {
                    DatePicker("Tasted", selection: $tastedAt)
                    VenueSearchField(
                        venue: $venue,
                        latitude: $latitude,
                        longitude: $longitude
                    )
                } header: {
                    Text("When & where")
                } footer: {
                    Text("Search picks a real place so the tasting appears on your Map. Or type a free-form name without pinning.")
                }

                Section("Note") {
                    TextField("How was it?", text: $note, axis: .vertical)
                        .lineLimit(2...6)
                }

                Section {
                    LabeledContent("Beer", value: beer.displayName)
                }
            }
            .navigationTitle("Log tasting")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .fontWeight(.semibold)
                }
            }
        }
    }

    private func save() {
        let trimmedVenue = venue.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedNote = note.trimmingCharacters(in: .whitespacesAndNewlines)

        let checkIn = CheckIn(
            tastedAt: tastedAt,
            venue: trimmedVenue.isEmpty ? nil : trimmedVenue,
            note: trimmedNote.isEmpty ? nil : trimmedNote,
            latitude: latitude,
            longitude: longitude,
            photoData: photoData,
            beer: beer
        )
        modelContext.insert(checkIn)
        beer.touch()
        try? modelContext.save()
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        dismiss()
    }
}
