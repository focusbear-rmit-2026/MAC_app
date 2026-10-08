//
//  blockBlurVc.swift
//  Focus Bear
//
//  Created by Prashant Sawnani on 20/03/23.
//  Copyright © 2023 Focus Bear. All rights reserved.
//

import Cocoa

/// The frosted panel laid over a blocked app or site.
///
/// `NSVisualEffectView` alone is NOT enough to make what's underneath unreadable: its blur radius is fixed by
/// the material (the storyboard already asks for the strongest one, `fullScreenUI`), and against a light
/// document — an editor, a doc, a code window — large text stays legible through it. Reported by the user as
/// "it doesn't blur enough - you can still read text behind it".
///
/// So the frosting is combined with a scrim on top. The blur keeps the panel feeling like part of the desktop
/// rather than a flat rectangle; the scrim is what actually destroys legibility.
class blockBlurVc: NSViewController {

    @IBOutlet weak var visualEffectView: NSVisualEffectView!

    private static let cornerRadius: CGFloat = 12

    /// Sits above the effect view, filling it. Built in code rather than the storyboard so the whole
    /// treatment lives in one place.
    private let scrimView = BlockBlurScrimView()

    override func viewDidLoad() {
        super.viewDidLoad()
        visualEffectView.wantsLayer = true
        visualEffectView.layer?.cornerRadius = Self.cornerRadius

        scrimView.wantsLayer = true
        scrimView.layer?.cornerRadius = Self.cornerRadius
        scrimView.translatesAutoresizingMaskIntoConstraints = false
        visualEffectView.addSubview(scrimView)
        NSLayoutConstraint.activate([
            scrimView.topAnchor.constraint(equalTo: visualEffectView.topAnchor),
            scrimView.bottomAnchor.constraint(equalTo: visualEffectView.bottomAnchor),
            scrimView.leadingAnchor.constraint(equalTo: visualEffectView.leadingAnchor),
            scrimView.trailingAnchor.constraint(equalTo: visualEffectView.trailingAnchor)
        ])
    }
}

/// Draws the opaque wash over the frosted view. A layer-backed `NSView` subclass rather than a plain view with
/// a colour set once, because a CALayer background does not re-resolve a dynamic `NSColor` on its own — with
/// `wantsUpdateLayer`, AppKit calls `updateLayer()` again whenever the effective appearance changes, so the
/// scrim follows a light/dark switch instead of staying stuck on whichever side it was built under.
private final class BlockBlurScrimView: NSView {

    /// Opacity of the wash. High enough that text underneath can't be read, low enough that the panel still
    /// reads as translucent rather than a solid block.
    private static let scrimOpacity: CGFloat = 0.82

    override var wantsUpdateLayer: Bool { true }

    override func updateLayer() {
        super.updateLayer()
        layer?.backgroundColor = NSColor.windowBackgroundColor
            .withAlphaComponent(Self.scrimOpacity)
            .cgColor
    }
}
