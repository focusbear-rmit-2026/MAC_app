//
//  FocusGlowBorderView.swift
//  Focus Bear
//
//  Copyright © 2026 Focus Bear. All rights reserved.
//

import SwiftUI

/// A soft, colored glow hugging the edges of the screen — the visible content of each
/// FocusGlowBorderManager overlay window. Fully transparent inside so it never obscures
/// whatever the user is working on.
///
/// The full-brightness border is shown around the whole screen at all times. On top of it, a
/// short darker segment ("glow worm") sweeps once around the perimeter right when the border
/// appears — a brief moving cue to catch the eye — then settles into the plain, full-brightness
/// border so it isn't a distraction for the rest of the session.
struct FocusGlowBorderView: View {
    private let gradient = LinearGradient(
        colors: [Color.orange, Color.pink, Color.purple],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    /// 0...1 position of the leading edge of the glow worm around the border's perimeter.
    @SwiftUI.State private var wormStart: CGFloat = 0
    /// Whether the darker worm segment is still drawn — false once wormActiveDuration has elapsed.
    @SwiftUI.State private var showWorm = true

    /// Fraction of the perimeter the darker segment covers.
    private let wormLength: CGFloat = 0.14
    /// How long the worm takes to sweep once around the perimeter, and how long it stays visible.
    private let wormActiveDuration: Double = 5

    var body: some View {
        ZStack {
            // Full-brightness base border/glow around the whole screen at all times.
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .strokeBorder(gradient, lineWidth: 2)
                .shadow(color: Color.orange.opacity(0.85), radius: 5)
                .shadow(color: Color.pink.opacity(0.6), radius: 14)
                .shadow(color: Color.purple.opacity(0.45), radius: 28)
                .shadow(color: Color.purple.opacity(0.25), radius: 46)

            if showWorm {
                worm
            }
        }
        .allowsHitTesting(false)
        .ignoresSafeArea()
        .onAppear(perform: startWormSweep)
        .onReceive(NotificationCenter.default.publisher(for: .focusGlowBorderPulseWorm)) { _ in
            startWormSweep()
        }
    }

    /// Restarts the one-time sweep from the beginning of the perimeter — called on first appearance
    /// and again whenever FocusGlowBorderManager.pulseWorm() fires (see FocusGlowBorderManager.swift).
    private func startWormSweep() {
        wormStart = 0
        showWorm = true
        withAnimation(.linear(duration: wormActiveDuration)) {
            wormStart = 1
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + wormActiveDuration) {
            showWorm = false
        }
    }

    /// The darker segment, trimmed out of the same rounded-rect path as the base border and drawn
    /// on top of it — it stands out by dimming the bright base underneath as it passes, rather than
    /// glowing brighter. Drawn as up to two trims so it wraps the corner seamlessly if it's still
    /// crossing the 1.0 -> 0.0 seam when it reaches the end of its one-time sweep.
    @ViewBuilder
    private var worm: some View {
        let end = wormStart + wormLength
        RoundedRectangle(cornerRadius: 6, style: .continuous)
            .trim(from: wormStart, to: min(end, 1))
            .stroke(Color.black.opacity(0.55), style: StrokeStyle(lineWidth: 3, lineCap: .round))
        if end > 1 {
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .trim(from: 0, to: end - 1)
                .stroke(Color.black.opacity(0.55), style: StrokeStyle(lineWidth: 3, lineCap: .round))
        }
    }
}
