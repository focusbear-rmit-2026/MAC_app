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

        // Replace the storyboard content with the SwiftUI settings view.
        view.subviews.forEach { $0.removeFromSuperview() }
        let hosting = NSHostingView(rootView: TalkingClockSettingsView(model: model, onBack: {
            settingsContainerVcObj?.showAdvancedView()
        }))
        hosting.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(hosting)
        NSLayoutConstraint.activate([
            hosting.topAnchor.constraint(equalTo: view.topAnchor),
            hosting.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hosting.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            hosting.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

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
}
