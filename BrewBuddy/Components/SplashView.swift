//
//  SplashView.swift
//  BrewBuddy
//

import SwiftUI

/// Branded launch splash shown after the system launch screen.
struct SplashView: View {
    @State private var logoScale: CGFloat = 0.72
    @State private var logoOpacity: Double = 0
    @State private var titleOffset: CGFloat = 12
    @State private var titleOpacity: Double = 0
    @State private var foamPulse = false

    var body: some View {
        ZStack {
            // Deep charcoal → amber horizon
            LinearGradient(
                colors: [
                    Color(red: 0.08, green: 0.07, blue: 0.06),
                    Color(red: 0.16, green: 0.11, blue: 0.06),
                    Color(red: 0.28, green: 0.16, blue: 0.05),
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            // Soft amber glow behind the mug
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            BrewTheme.accent.opacity(0.45),
                            BrewTheme.accent.opacity(0.08),
                            .clear,
                        ],
                        center: .center,
                        startRadius: 10,
                        endRadius: 160
                    )
                )
                .frame(width: 320, height: 320)
                .scaleEffect(foamPulse ? 1.08 : 0.95)
                .blur(radius: 8)

            VStack(spacing: 20) {
                ZStack {
                    Circle()
                        .fill(BrewTheme.foam.opacity(0.12))
                        .frame(width: 120, height: 120)

                    Image(systemName: "mug.fill")
                        .font(.system(size: 56, weight: .medium))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [BrewTheme.accentSoft, BrewTheme.accent],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .symbolEffect(.pulse, options: .repeating, isActive: foamPulse)
                }
                .scaleEffect(logoScale)
                .opacity(logoOpacity)

                VStack(spacing: 8) {
                    Text("BrewBuddy")
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundStyle(BrewTheme.foam)

                    Text("Your personal beer journal")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(BrewTheme.foam.opacity(0.65))
                }
                .offset(y: titleOffset)
                .opacity(titleOpacity)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.55, dampingFraction: 0.72)) {
                logoScale = 1
                logoOpacity = 1
            }
            withAnimation(.easeOut(duration: 0.5).delay(0.15)) {
                titleOffset = 0
                titleOpacity = 1
            }
            withAnimation(.easeInOut(duration: 1.4).repeatForever(autoreverses: true)) {
                foamPulse = true
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("BrewBuddy")
    }
}

#Preview {
    SplashView()
}
