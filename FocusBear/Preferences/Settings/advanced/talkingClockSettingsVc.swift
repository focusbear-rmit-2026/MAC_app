//
//  talkingClockSettingsVc.swift
//  Focus Bear
//
//  Copyright © 2025 Focus Bear. All rights reserved.
//
//  Thin host for the SwiftUI Talking Clock settings screen (#1771). The storyboard scene still
//  instantiates this VC, but its content is now SwiftUI (TalkingClockSettingsView) — new/modified UI
//  must be SwiftUI. All logic stays in TalkingClockManager / SettingsManager.
//

import Cocoa
import SwiftUI

var idTalkingClock = "talkingclock"

class talkingClockSettingsVc: NSViewController {

    // Kept only for storyboard KVC compliance (the scene still wires these); the UI is SwiftUI now.
    @IBOutlet weak var btnBack: NSButton!
    @IBOutlet weak var lblTitle: NSTextField!
    @IBOutlet weak var stackView: NSStackView!

    private let model = TalkingClockSettingsModel()

    override func viewDidLoad() {
        super.viewDidLoad()

        // Keep the storyboard's native back bar (btnBack + lblTitle + separator) — it's the same
        // bevel back button the other settings pages use (Privacy / Add-ons / Research) — and swap
        // only the content box below it for the SwiftUI view. Don't recreate the bar in SwiftUI.
        installSwiftUIContentBelowBackBar()

        // Keep the two toggles findable from settings search.
        arrForSearchFromSettings.append([
            "title": model.enableSearchTitle, "tabId": idTalkingClock, "object": view as Any
        ])
        arrForSearchFromSettings.append([
            "title": model.suppressSearchTitle, "tabId": idTalkingClock, "object": view as Any
        ])
    }

    @IBAction func btnBackClicked(_ sender: Any) {
        settingsContainerVcObj?.showAdvancedView()
    }

    // MARK: - SwiftUI hosting

    /// Remove the storyboard's old bordered content box (the ancestor of `stackView`) while keeping
    /// the back-bar box (the ancestor of `btnBack`), then pin the SwiftUI content directly beneath
    /// the back bar. Both boxes are siblings inside the scene's content container.
    private func installSwiftUIContentBelowBackBar() {
        guard let container = commonAncestor(btnBack, stackView),
              let backBarBox = topChild(of: container, containing: btnBack),
              let contentBox = topChild(of: container, containing: stackView) else {
            // Fallback: if the storyboard structure ever changes, host the full-screen view
            // (the SwiftUI content still renders, just without the shared back bar).
            hostFillingView()
            return
        }

        contentBox.removeFromSuperview()

        // Host on the VC's root `view` (which settingsContainerVc pins to the pane on all four
        // edges, so it's definitively height-bounded) rather than inside the NSBox content view —
        // an NSBox sizes its content view via autoresizing, which let the hosting view fall back to
        // its intrinsic SwiftUI height and grow past the pane. Only the top is tied to the back bar.
        let hosting = NSHostingView(rootView: TalkingClockSettingsView(model: model))
        hosting.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(hosting)
        NSLayoutConstraint.activate([
            hosting.topAnchor.constraint(equalTo: backBarBox.bottomAnchor),
            hosting.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hosting.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            hosting.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    /// Last-resort host that fills the whole VC view (used only if the storyboard back bar can't be found).
    private func hostFillingView() {
        view.subviews.forEach { $0.removeFromSuperview() }
        let hosting = NSHostingView(rootView: TalkingClockSettingsView(model: model))
        hosting.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(hosting)
        NSLayoutConstraint.activate([
            hosting.topAnchor.constraint(equalTo: view.topAnchor),
            hosting.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hosting.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            hosting.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    /// Deepest view that is an ancestor of both `a` and `b`.
    private func commonAncestor(_ a: NSView, _ b: NSView) -> NSView? {
        var ancestors = Set<ObjectIdentifier>()
        var node: NSView? = a
        while let n = node { ancestors.insert(ObjectIdentifier(n)); node = n.superview }
        node = b
        while let n = node { if ancestors.contains(ObjectIdentifier(n)) { return n }; node = n.superview }
        return nil
    }

    /// The direct child of `container` on the ancestry path to `descendant` (i.e. which top-level
    /// box inside the container holds this descendant).
    private func topChild(of container: NSView, containing descendant: NSView) -> NSView? {
        var node: NSView? = descendant
        while let n = node {
            if n.superview === container { return n }
            node = n.superview
        }
        return nil
    }
}
