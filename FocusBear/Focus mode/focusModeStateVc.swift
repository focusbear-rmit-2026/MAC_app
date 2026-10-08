//
//  focusModeStateVc.swift
//  Focus Bear
//
//  Created by Manish Jain on 18/08/25.
//  Copyright © 2025 Focus Bear. All rights reserved.
//
//  Hosts the ongoing-focus-session screen (FocusBear/FocusSession). It replaced the storyboard scene
//  of the same name — a stack of NSTextFields, an NSTextView for the focus goal and a searchable
//  combo box for the current task — with the SwiftUI design in Figma "Sid Focus Bear → 1. Ongoing
//  Session". Per this repo's "new/modified Mac UI is SwiftUI" convention the view tree is built in
//  code and hosted in an NSHostingView; the controller keeps its class name and `reloadData()` entry
//  point so AppDelegate's pause/resume refresh hooks are unchanged.
//

import Cocoa
import SwiftUI

class focusModeStateVc: NSViewController {

    var isViewVisible = false

    /// Held as AnyObject because FocusSessionStore is macOS 11+; stored properties can't be
    /// `@available`-guarded.
    private var sessionStore: AnyObject?

    @available(macOS 11.0, *)
    private var store: FocusSessionStore {
        if let existing = sessionStore as? FocusSessionStore { return existing }
        let created = FocusSessionStore()
        sessionStore = created
        return created
    }

    /// Built in code (no storyboard scene) — new Mac UI is SwiftUI hosted in an NSHostingView.
    override func loadView() {
        let container = NSView()
        guard #available(macOS 11.0, *) else {
            view = container
            return
        }
        let hosting = NSHostingView(rootView: FocusSessionScreen(store: store))
        hosting.translatesAutoresizingMaskIntoConstraints = false
        // The hosting view's intrinsic (ideal) size is the whole task list; at the default 750
        // compression resistance it outranks the window's size (windowSizeStayPut = 500) and would
        // grow the main window to fit every row. Let the window size win so the screen scrolls.
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

    override func viewWillAppear() {
        super.viewWillAppear()
        isViewVisible = true
        if #available(macOS 11.0, *) {
            store.screenAppeared()
        }
    }

    override func viewWillDisappear() {
        super.viewWillDisappear()
        isViewVisible = false
        if #available(macOS 11.0, *) {
            store.screenDisappeared()
        }
    }

    /// Called by AppDelegate whenever the session is paused or resumed elsewhere (menu bar, another
    /// device via Pusher, the Focus Button). Kept as the same method name the old screen exposed.
    func reloadData() {
        guard #available(macOS 11.0, *) else { return }
        store.refreshFromGlobals()
    }
}
