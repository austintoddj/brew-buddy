//
//  BrewBuddyApp.swift
//  BrewBuddy
//
//  Created by Todd Austin on 5/16/17.
//  Modernized 2026.
//

import SwiftUI
import SwiftData

@main
struct BrewBuddyApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Beer.self,
            CheckIn.self,
        ])
        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false
        )
        do {
            return try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}
