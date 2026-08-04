//
//  ContentView.swift
//  BrewBuddy
//

import SwiftUI

struct ContentView: View {
    @State private var showSplash = true

    var body: some View {
        ZStack {
            TabView {
                BeerListView()
                    .tabItem {
                        Label("Library", systemImage: "mug.fill")
                    }

                BeerMapView()
                    .tabItem {
                        Label("Map", systemImage: "globe.americas.fill")
                    }

                StatsView()
                    .tabItem {
                        Label("Stats", systemImage: "chart.bar.fill")
                    }

                SettingsView()
                    .tabItem {
                        Label("Settings", systemImage: "gearshape.fill")
                    }
            }
            .tint(BrewTheme.accent)
            .opacity(showSplash ? 0 : 1)

            if showSplash {
                SplashView()
                    .transition(.opacity)
                    .zIndex(1)
            }
        }
        .onAppear {
            // Brief branded moment after the system launch screen.
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.55) {
                withAnimation(.easeOut(duration: 0.45)) {
                    showSplash = false
                }
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Beer.self, CheckIn.self], inMemory: true)
}
