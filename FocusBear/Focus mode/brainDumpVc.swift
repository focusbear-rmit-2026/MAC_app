//
//  brainDumpVc.swift
//  Focus Bear
//
//  Created by Prashant Sawnani on 06/09/22.
//  Copyright © 2022 Focus Bear. All rights reserved.
//
//  Hosts the native Notes / Brain Dump screen (FocusBear/Notes). It replaced the
//  dashboard.focusbear.io/webview/notes webview, which was too slow to open; the native view talks to
//  the same /note API the web page uses, so notes stay in sync with the dashboard and mobile app.
//

import Cocoa
import SwiftUI

class brainDumpVc: NSViewController {

    let notesStore = NotesStore(strings: NotesStrings.load())
    private var store: NotesStore { notesStore }

    /// Built in code (no storyboard scene) — new Mac UI is SwiftUI hosted in an NSHostingView.
    override func loadView() {
        let container = NSView()
        let screen = NotesScreen(store: store) { [weak self] in
            self?.view.window?.close()
        }
        let hosting = NSHostingView(rootView: screen)
        hosting.translatesAutoresizingMaskIntoConstraints = false
        // The hosting view's intrinsic (ideal) size is the whole note list; at the default 750
        // compression resistance it outranks the window's size (windowSizeStayPut = 500) and would grow
        // the main window to fit every row. Let the window size win so the list scrolls instead.
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
        store.screenAppeared()
    }

    /// Don't lose a brain-dump edit typed within the 2 s auto-save window before leaving the screen,
    /// and hand back an open project note's collaborative document. This controller and its hosting
    /// view outlive the window, so SwiftUI's `onDisappear` never fires here — without this, a note's
    /// realtime session would keep running behind a closed window.
    override func viewDidDisappear() {
        super.viewDidDisappear()
        store.screenDisappeared()
    }
}
