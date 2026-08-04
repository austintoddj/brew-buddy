//
//  PhotoCompressor.swift
//  BrewBuddy
//

import UIKit

enum PhotoCompressor {
    /// Max edge length in points for stored photos.
    static let maxDimension: CGFloat = 1200
    static let jpegQuality: CGFloat = 0.72

    static func compress(_ data: Data) -> Data? {
        guard let image = UIImage(data: data) else { return nil }
        return compress(image)
    }

    static func compress(_ image: UIImage) -> Data? {
        let resized = resize(image, maxDimension: maxDimension)
        return resized.jpegData(compressionQuality: jpegQuality)
    }

    static func resize(_ image: UIImage, maxDimension: CGFloat) -> UIImage {
        // Work in pixel space so device screen scale does not inflate stored photos.
        let pixelWidth = image.size.width * image.scale
        let pixelHeight = image.size.height * image.scale
        let longest = max(pixelWidth, pixelHeight)
        guard longest > maxDimension, longest > 0 else {
            return normalizedForStorage(image)
        }

        let scaleFactor = maxDimension / longest
        let newSize = CGSize(width: pixelWidth * scaleFactor, height: pixelHeight * scaleFactor)

        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        format.opaque = false
        let renderer = UIGraphicsImageRenderer(size: newSize, format: format)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }

    /// Re-render at scale 1 so JPEG pixel dimensions match `image.size`.
    private static func normalizedForStorage(_ image: UIImage) -> UIImage {
        if image.scale == 1 { return image }
        let pixelSize = CGSize(
            width: image.size.width * image.scale,
            height: image.size.height * image.scale
        )
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        format.opaque = false
        let renderer = UIGraphicsImageRenderer(size: pixelSize, format: format)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: pixelSize))
        }
    }
}
