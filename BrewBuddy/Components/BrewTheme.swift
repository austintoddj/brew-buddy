//
//  BrewTheme.swift
//  BrewBuddy
//

import SwiftUI

enum BrewTheme {
    /// Warm amber accent — hops & malt
    static let accent = Color(red: 0.85, green: 0.52, blue: 0.12)
    static let accentSoft = Color(red: 0.93, green: 0.72, blue: 0.35)
    static let foam = Color(red: 0.98, green: 0.95, blue: 0.88)
    static let charcoal = Color(red: 0.15, green: 0.12, blue: 0.10)
    static let favorite = Color(red: 0.90, green: 0.30, blue: 0.35)

    static let cardGradient = LinearGradient(
        colors: [
            Color(red: 0.95, green: 0.78, blue: 0.40).opacity(0.25),
            Color(red: 0.85, green: 0.52, blue: 0.12).opacity(0.08),
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}
