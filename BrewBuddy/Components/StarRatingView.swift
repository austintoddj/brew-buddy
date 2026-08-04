//
//  StarRatingView.swift
//  BrewBuddy
//

import SwiftUI
import UIKit

struct StarRatingView: View {
    @Binding var rating: Int
    var maxRating: Int = 5
    var starSize: CGFloat = 28
    var isInteractive: Bool = true

    var body: some View {
        HStack(spacing: 6) {
            ForEach(1...maxRating, id: \.self) { star in
                Image(systemName: star <= rating ? "star.fill" : "star")
                    .font(.system(size: starSize))
                    .foregroundStyle(star <= rating ? BrewTheme.accent : Color.secondary.opacity(0.4))
                    .symbolEffect(.bounce, value: rating == star)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        guard isInteractive else { return }
                        if rating == star {
                            rating = 0
                        } else {
                            rating = star
                        }
                        let generator = UIImpactFeedbackGenerator(style: .light)
                        generator.impactOccurred()
                    }
                    .accessibilityLabel("\(star) star\(star == 1 ? "" : "s")")
                    .accessibilityAddTraits(star <= rating ? .isSelected : [])
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(rating == 0 ? "Unrated" : "Rating: \(rating) of \(maxRating)")
        .accessibilityAdjustableAction { direction in
            guard isInteractive else { return }
            switch direction {
            case .increment:
                rating = min(rating + 1, maxRating)
            case .decrement:
                rating = max(rating - 1, 0)
            @unknown default:
                break
            }
        }
    }
}

struct StarRatingLabel: View {
    let rating: Int
    var maxRating: Int = 5

    var body: some View {
        HStack(spacing: 2) {
            ForEach(1...maxRating, id: \.self) { star in
                Image(systemName: star <= rating ? "star.fill" : "star")
                    .font(.caption)
                    .foregroundStyle(star <= rating ? BrewTheme.accent : Color.secondary.opacity(0.35))
            }
        }
        .accessibilityLabel(rating == 0 ? "Unrated" : "\(rating) of \(maxRating) stars")
    }
}

#Preview {
    VStack(spacing: 20) {
        StarRatingView(rating: .constant(3))
        StarRatingLabel(rating: 4)
    }
    .padding()
}
