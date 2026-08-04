//
//  SettingsView.swift
//  BrewBuddy
//

import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Beer.name) private var beers: [Beer]

    @State private var exportCSVURL: URL?
    @State private var exportJSONURL: URL?
    @State private var isSharingCSV = false
    @State private var isSharingJSON = false
    @State private var showDeleteAllConfirm = false
    @State private var statusMessage: String?
    @State private var showStatus = false

    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    LabeledContent("Beers in library", value: "\(beers.count)")
                    LabeledContent("Version", value: appVersion)
                } header: {
                    Text("Library")
                }

                Section {
                    Button {
                        exportCSV()
                    } label: {
                        Label("Export CSV", systemImage: "tablecells")
                    }
                    .disabled(beers.isEmpty)

                    Button {
                        exportJSON()
                    } label: {
                        Label("Export JSON backup", systemImage: "doc.badge.arrow.up")
                    }
                    .disabled(beers.isEmpty)
                } header: {
                    Text("Export")
                } footer: {
                    Text("Exports include beer details and tasting metadata (not photos). Data never leaves your device unless you share it.")
                }

                Section {
                    Button {
                        SampleData.insertSamples(into: modelContext)
                        try? modelContext.save()
                        flash("Sample beers added.")
                    } label: {
                        Label("Load sample beers", systemImage: "sparkles")
                    }

                    Button(role: .destructive) {
                        showDeleteAllConfirm = true
                    } label: {
                        Label("Delete all data", systemImage: "trash")
                    }
                    .disabled(beers.isEmpty)
                } header: {
                    Text("Demo data")
                }

                Section {
                    Label("On-device journal — no account required", systemImage: "lock.shield")
                    Label("Photos stay in this app’s storage", systemImage: "photo")
                    Label("No ads, no analytics SDKs, no tracking", systemImage: "hand.raised.fill")
                    Label("Maps & place search use Apple services", systemImage: "map")
                } header: {
                    Text("Privacy")
                } footer: {
                    Text("Your beers, ratings, notes, and photos are stored locally with SwiftData. Optional location is used only for venue suggestions and map pins. Map tiles and place autocomplete go through Apple Maps — journal data is never uploaded to a BrewBuddy server (there isn’t one).")
                }

                Section {
                    Text("BrewBuddy began as a 2017 iOS experiment. Rebuilt in 2026 with SwiftUI & SwiftData so it finally works.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                } header: {
                    Text("About")
                }
            }
            .navigationTitle("Settings")
            .confirmationDialog(
                "Delete all beers and tastings?",
                isPresented: $showDeleteAllConfirm,
                titleVisibility: .visible
            ) {
                Button("Delete everything", role: .destructive) {
                    do {
                        try SampleData.deleteAll(from: modelContext)
                        try modelContext.save()
                        flash("Library cleared.")
                    } catch {
                        flash("Could not delete: \(error.localizedDescription)")
                    }
                }
                Button("Cancel", role: .cancel) {}
            }
            .alert("BrewBuddy", isPresented: $showStatus) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(statusMessage ?? "")
            }
            .sheet(isPresented: $isSharingCSV) {
                if let exportCSVURL {
                    ShareSheet(items: [exportCSVURL])
                }
            }
            .sheet(isPresented: $isSharingJSON) {
                if let exportJSONURL {
                    ShareSheet(items: [exportJSONURL])
                }
            }
        }
    }

    private func flash(_ message: String) {
        statusMessage = message
        showStatus = true
    }

    private func exportCSV() {
        let data = ExportService.csvData(from: beers)
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("BrewBuddy-library.csv")
        do {
            try data.write(to: url, options: .atomic)
            exportCSVURL = url
            isSharingCSV = true
        } catch {
            flash("CSV export failed: \(error.localizedDescription)")
        }
    }

    private func exportJSON() {
        do {
            let data = try ExportService.jsonData(from: beers)
            let url = FileManager.default.temporaryDirectory
                .appendingPathComponent("BrewBuddy-backup.json")
            try data.write(to: url, options: .atomic)
            exportJSONURL = url
            isSharingJSON = true
        } catch {
            flash("JSON export failed: \(error.localizedDescription)")
        }
    }
}

/// Thin UIKit share wrapper for file URLs.
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    SettingsView()
        .modelContainer(for: [Beer.self, CheckIn.self], inMemory: true)
}
