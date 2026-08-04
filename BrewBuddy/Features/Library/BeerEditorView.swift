//
//  BeerEditorView.swift
//  BrewBuddy
//

import SwiftUI
import SwiftData

struct BeerEditorView: View {
    enum Mode {
        case create
        case edit(Beer)
    }

    let mode: Mode

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var name: String = ""
    @State private var brewery: String = ""
    @State private var style: String = ""
    @State private var abvText: String = ""
    @State private var ibuText: String = ""
    @State private var rating: Int = 0
    @State private var notes: String = ""
    @State private var isFavorite: Bool = false
    @State private var photoData: Data?
    @State private var showValidationAlert = false

    private var navigationTitle: String {
        switch mode {
        case .create: return "New Beer"
        case .edit: return "Edit Beer"
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        Spacer()
                        PhotoPickerThumbnail(photoData: $photoData, size: 140)
                        Spacer()
                    }
                    .listRowBackground(Color.clear)
                }

                Section("Basics") {
                    TextField("Beer name", text: $name)
                        .textInputAutocapitalization(.words)
                    TextField("Brewery", text: $brewery)
                        .textInputAutocapitalization(.words)
                    TextField("Style", text: $style)
                        .textInputAutocapitalization(.words)

                    if !BeerStyle.suggestions.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack {
                                ForEach(BeerStyle.suggestions, id: \.self) { suggestion in
                                    Button(suggestion) {
                                        style = suggestion
                                    }
                                    .buttonStyle(.bordered)
                                    .controlSize(.small)
                                    .tint(style == suggestion ? BrewTheme.accent : .secondary)
                                }
                            }
                        }
                    }
                }

                Section("Details") {
                    HStack {
                        Text("ABV %")
                        Spacer()
                        TextField("e.g. 6.5", text: $abvText)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(maxWidth: 100)
                    }
                    HStack {
                        Text("IBU")
                        Spacer()
                        TextField("e.g. 55", text: $ibuText)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(maxWidth: 100)
                    }
                    Toggle("Favorite", isOn: $isFavorite)
                        .tint(BrewTheme.favorite)
                }

                Section("Your rating") {
                    StarRatingView(rating: $rating)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 4)
                }

                Section("Notes") {
                    TextField("Tasting notes, food pairings…", text: $notes, axis: .vertical)
                        .lineLimit(3...8)
                }
            }
            .navigationTitle(navigationTitle)
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
            .alert("Name required", isPresented: $showValidationAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Give this beer a name so you can find it later.")
            }
            .onAppear(perform: loadIfNeeded)
        }
    }

    private func loadIfNeeded() {
        guard case .edit(let beer) = mode else { return }
        name = beer.name
        brewery = beer.brewery
        style = beer.style
        abvText = beer.abv.map { String(format: "%g", $0) } ?? ""
        ibuText = beer.ibu.map(String.init) ?? ""
        rating = beer.rating
        notes = beer.notes
        isFavorite = beer.isFavorite
        photoData = beer.photoData
    }

    private func save() {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            showValidationAlert = true
            return
        }

        let abv = Double(abvText.replacingOccurrences(of: ",", with: "."))
        let ibu = Int(ibuText.trimmingCharacters(in: .whitespacesAndNewlines))

        switch mode {
        case .create:
            let beer = Beer(
                name: trimmedName,
                brewery: brewery.trimmingCharacters(in: .whitespacesAndNewlines),
                style: style.trimmingCharacters(in: .whitespacesAndNewlines),
                abv: abv,
                ibu: ibu,
                rating: rating,
                notes: notes.trimmingCharacters(in: .whitespacesAndNewlines),
                isFavorite: isFavorite,
                photoData: photoData
            )
            modelContext.insert(beer)
        case .edit(let beer):
            beer.name = trimmedName
            beer.brewery = brewery.trimmingCharacters(in: .whitespacesAndNewlines)
            beer.style = style.trimmingCharacters(in: .whitespacesAndNewlines)
            beer.abv = abv
            beer.ibu = ibu
            beer.rating = Beer.clampedRating(rating)
            beer.notes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
            beer.isFavorite = isFavorite
            beer.photoData = photoData
            beer.touch()
        }

        try? modelContext.save()
        dismiss()
    }
}
