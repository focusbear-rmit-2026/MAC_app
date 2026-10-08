//
//  setUpVc.swift
//  Focus Bear
//
//  Created by Prashant Sawnani on 28/01/23.
//  Copyright © 2023 Focus Bear. All rights reserved.
//
//  Hosts the native Stats screen (FocusBear/Stats). It replaced the dashboard.focusbear.io/webview/stats
//  webview (slow to open, token bridge on every open); the native view calls the same stats APIs the
//  web page uses, so the numbers match the dashboard and mobile app. The class name is historical —
//  ViewController.showMotivationView() and getSetUpVcObject() still refer to it.
//

import Cocoa
import SwiftUI

class setUpVc: NSViewController {

    let statsStore = StatsStore(strings: StatsStrings.load())

    /// Built in code (no storyboard scene) — new Mac UI is SwiftUI hosted in an NSHostingView.
    override func loadView() {
        let container = NSView()
        let hosting = NSHostingView(rootView: StatsScreen(store: statsStore))
        hosting.translatesAutoresizingMaskIntoConstraints = false
        // The hosting view's intrinsic (ideal) size is the whole tab content; at the default 750
        // compression resistance it outranks the window's size (windowSizeStayPut = 500) and would grow
        // the main window to fit every row. Let the window size win so the content scrolls instead.
        if #available(macOS 13.0, *) {
            hosting.sizingOptions = []
        }
        hosting.setContentCompressionResistancePriority(.init(1), for: .vertical)
        hosting.setContentCompressionResistancePriority(.init(1), for: .horizontal)
        hosting.setContentHuggingPriority(.init(1), for: .vertical)
        hosting.setContentHuggingPriority(.init(1), for: .horizontal)
        container.addSubview(hosting)
        NSLayoutConstraint.activate([
            hosting.topAnchor.constraint(equalTo: container.topAnchor),
            hosting.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            hosting.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            hosting.bottomAnchor.constraint(equalTo: container.bottomAnchor),
        ])
        view = container
    }

    /// Reload every time the screen is shown (the webview reloaded the page on each open).
    override func viewWillAppear() {
        super.viewWillAppear()
        addLog(text: "statsVc viewWillAppear")
        statsStore.screenAppeared()
    }

    override func viewDidDisappear() {
        super.viewDidDisappear()
        statsStore.screenDisappeared()
    }
}
