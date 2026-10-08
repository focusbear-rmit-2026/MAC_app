//
//  FocusSessionBearView.swift
//  Focus Bear
//
//  The focus bear from the design, plus the drop shadow the design draws under it.
//
//  The artwork is a Lottie animation authored in Lottielab, bundled as the `focusBearOngoing` data
//  set. It is bundled rather than fetched from cdn.lottielab.com so the bear still animates offline
//  and while a session is blocking the network — the one image the animation referenced remotely is
//  inlined into the JSON as a base64 data URI, so nothing is loaded at runtime.
//
//  `focusBearStatic` is the still fallback, drawn if the animation fails to load or decode.
//

import SwiftUI
import AppKit
import Lottie

/// The illustration and its shadow ellipse, in design pixels (Figma 4:79657).
///
/// Out here rather than private to the view so the compact layout can size the bear's column from the
/// artwork's own proportions instead of repeating them.
enum FocusSessionBearArtwork {
    static let width: CGFloat = 635
    static let height: CGFloat = 645
    static let shadowWidth: CGFloat = 629
    static let shadowHeight: CGFloat = 132
    /// How far down the group the shadow ellipse sits.
    static let shadowTopOffset: CGFloat = 523
    /// The whole group, illustration plus the shadow beneath it.
    static var groupHeight: CGFloat { shadowTopOffset + shadowHeight }
}

@available(macOS 11.0, *)
struct FocusSessionBear: SwiftUI.View {
    let scale: FocusSessionScale
    /// Draw the bear at this width instead of the design's, keeping the artwork's proportions.
    ///
    /// The compact layout gives the bear a share of one row rather than the full column, so it needs a
    /// size that comes from the row, not from the window. Left nil everywhere else, which reproduces
    /// the design size exactly (`designPixels * factor / 2` is what `scale.pt` computes).
    var width: CGFloat?

    /// Design pixels to points for this instance.
    private var pointsPerDesignPixel: CGFloat {
        guard let width = width else {
            return scale.factor / FocusSessionTokens.designPixelsPerPoint
        }
        return width / FocusSessionBearArtwork.width
    }

    var body: some SwiftUI.View {
        let k = pointsPerDesignPixel
        return ZStack(alignment: .top) {
            Ellipse()
                .fill(FocusSessionPalette.bearShadow)
                .frame(width: FocusSessionBearArtwork.shadowWidth * k,
                       height: FocusSessionBearArtwork.shadowHeight * k)
                .offset(y: FocusSessionBearArtwork.shadowTopOffset * k)
            FocusBearAnimationView(animationName: FocusBearAnimation.ongoingSession)
                .frame(width: FocusSessionBearArtwork.width * k,
                       height: FocusSessionBearArtwork.height * k)
        }
        .frame(width: FocusSessionBearArtwork.width * k,
               height: FocusSessionBearArtwork.groupHeight * k)
        // The hosted AppKit view can still lay itself out past the frame it is given (its intrinsic
        // size is the artwork's). Clipping keeps it inside its slot instead of drawing over the
        // countdown above it, which is what happened in a narrow window.
        .clipped()
    }
}

/// The bundled Lottie animations, by data-set name.
enum FocusBearAnimation {
    /// Plays behind the running focus session.
    static let ongoingSession = "focusBearOngoing"
    /// Plays on the session-ended screen (Figma 3 / 3.1), which is not built yet.
    static let sessionEnded = "focusBearSessionEnd"
    /// Still frame used when an animation can't be loaded.
    static let stillFallback = "focusBearStatic"
}

/// Plays one of the bundled Lottie animations, looping. Falls back to the still image if the data set
/// is missing or the JSON can't be decoded, so a bad asset degrades to a picture rather than a blank.
@available(macOS 11.0, *)
struct FocusBearAnimationView: NSViewRepresentable {
    let animationName: String

    func makeNSView(context: Context) -> NSView {
        let container = NSView()
        // A LottieAnimationView's (and NSImageView's) intrinsic size is the artwork's own size, which
        // at the default priorities outranks the SwiftUI frame around it — the bear then draws several
        // times too large and pushes the rest of the column off screen.
        container.setContentHuggingPriority(.init(1), for: .horizontal)
        container.setContentHuggingPriority(.init(1), for: .vertical)
        container.setContentCompressionResistancePriority(.init(1), for: .horizontal)
        container.setContentCompressionResistancePriority(.init(1), for: .vertical)

        let content = FocusBearAnimationView.makeContentView(named: animationName)
        content.translatesAutoresizingMaskIntoConstraints = false
        content.setContentHuggingPriority(.init(1), for: .horizontal)
        content.setContentHuggingPriority(.init(1), for: .vertical)
        content.setContentCompressionResistancePriority(.init(1), for: .horizontal)
        content.setContentCompressionResistancePriority(.init(1), for: .vertical)
        container.addSubview(content)
        NSLayoutConstraint.activate([
            content.topAnchor.constraint(equalTo: container.topAnchor),
            content.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            content.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            content.bottomAnchor.constraint(equalTo: container.bottomAnchor),
        ])
        return container
    }

    func updateNSView(_ nsView: NSView, context: Context) {}

#if DEBUG
    /// Invoked only by the opt-in XCTest capture after layout; production playback stays unchanged.
    static func freezeAnimationsForVisualFixture(in root: NSView) -> [[String: String]] {
        precondition(LogicTestHost.isEnabled)
        let environment = ProcessInfo.processInfo.environment
        precondition(environment["FOCUSBEAR_CAPTURE_ONGOING"] == "1"
            || environment["TEST_RUNNER_FOCUSBEAR_CAPTURE_ONGOING"] == "1")
        var renderers: [[String: String]] = []
        if let animation = root as? LottieAnimationView {
            let originalRenderer = animation.currentRenderingEngine?.rawValue ?? "unavailable"
            animation.pause()
            // Capture a synchronously rendered frame while checking missing layers in the
            // unordered window's bitmap cache. This exercises the same bundled animation;
            // the real screen continues to use the automatic renderer and normal playback.
            animation.configuration.renderingEngine = .mainThread
            animation.currentProgress = 0.35
            animation.layoutSubtreeIfNeeded()
            animation.forceDisplayUpdate()
            renderers.append(["production": originalRenderer,
                              "capture": animation.currentRenderingEngine?.rawValue ?? "unavailable"])
        }
        for child in root.subviews {
            renderers.append(contentsOf: freezeAnimationsForVisualFixture(in: child))
        }
        return renderers
    }
#endif

    private static func makeContentView(named name: String) -> NSView {
        if let animation = loadAnimation(named: name) {
            let view = LottieAnimationView(animation: animation)
            view.contentMode = .scaleAspectFit
            view.loopMode = .loop
            // Stop the timer when the window is hidden and pick it up again on return, rather than
            // burning CPU behind another Space for the length of a focus session.
            view.backgroundBehavior = .pauseAndRestore
            view.play()
            return view
        }
        addLog(text: "focus bear: falling back to the still image, \(name) could not be loaded")
        let fallback = NSImageView()
        fallback.imageScaling = .scaleProportionallyUpOrDown
        fallback.image = NSImage(named: FocusBearAnimation.stillFallback)
        return fallback
    }

    /// The animations ship as data sets, so they are read out of the asset catalogue rather than off
    /// disk — nothing touches the network.
    static func loadAnimation(named name: String) -> LottieAnimation? {
        guard let data = NSDataAsset(name: name)?.data else { return nil }
        return try? LottieAnimation.from(data: data)
    }
}
