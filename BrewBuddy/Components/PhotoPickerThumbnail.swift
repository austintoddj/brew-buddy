//
//  PhotoPickerThumbnail.swift
//  BrewBuddy
//

import SwiftUI
import PhotosUI
import UIKit

struct PhotoPickerThumbnail: View {
    @Binding var photoData: Data?
    var size: CGFloat = 120

    @State private var pickerItem: PhotosPickerItem?

    var body: some View {
        VStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(BrewTheme.cardGradient)
                    .frame(width: size, height: size)

                if let photoData, let image = UIImage(data: photoData) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: size, height: size)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                } else {
                    Image(systemName: "mug.fill")
                        .font(.system(size: size * 0.35))
                        .foregroundStyle(BrewTheme.accent.opacity(0.7))
                }
            }
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(Color.primary.opacity(0.08), lineWidth: 1)
            )

            HStack(spacing: 12) {
                PhotosPicker(selection: $pickerItem, matching: .images) {
                    Label(photoData == nil ? "Add Photo" : "Change", systemImage: "photo")
                        .font(.subheadline.weight(.medium))
                }
                .tint(BrewTheme.accent)

                if photoData != nil {
                    Button(role: .destructive) {
                        photoData = nil
                        pickerItem = nil
                    } label: {
                        Label("Remove", systemImage: "trash")
                            .font(.subheadline)
                            .labelStyle(.iconOnly)
                    }
                    .accessibilityLabel("Remove photo")
                }
            }
        }
        .onChange(of: pickerItem) { _, newItem in
            Task {
                guard let newItem else { return }
                if let data = try? await newItem.loadTransferable(type: Data.self) {
                    photoData = PhotoCompressor.compress(data)
                }
            }
        }
    }
}

struct BeerPhotoView: View {
    let photoData: Data?
    var size: CGFloat = 72
    var cornerRadius: CGFloat = 12

    var body: some View {
        Group {
            if let photoData, let image = UIImage(data: photoData) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                ZStack {
                    BrewTheme.cardGradient
                    Image(systemName: "mug.fill")
                        .foregroundStyle(BrewTheme.accent.opacity(0.65))
                }
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }
}
