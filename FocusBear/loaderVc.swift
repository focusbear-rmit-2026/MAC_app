//
//  loaderVc.swift
//  Focus Bear
//
//  Created by Prashant Sawnani on 19/07/23.
//  Copyright © 2023 Focus Bear. All rights reserved.
//

import Cocoa

class loaderVc: NSViewController {

    @IBOutlet weak var loader: NSProgressIndicator!

    /// Optional caption shown under the spinner. Empty (the default) shows just the spinner, so the
    /// many plain `showLoaderView()` callers are unaffected. Set it before showing the loader; it's
    /// a shared singleton, so reset it to "" when done.
    var message: String = ""
    private var messageLabel: NSTextField?

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
    }
    override func viewWillAppear() {
        loader.startAnimation(self)
        showMessageIfNeeded()
    }

    private func showMessageIfNeeded() {
        messageLabel?.removeFromSuperview()
        messageLabel = nil
        guard !message.isEmpty else { return }
        let label = NSTextField(labelWithString: message)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.alignment = .center
        label.font = NSFont.systemFont(ofSize: 14, weight: .medium)
        label.textColor = NSColor.labelColor
        label.maximumNumberOfLines = 2
        view.addSubview(label)
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: loader.centerXAnchor),
            label.topAnchor.constraint(equalTo: loader.bottomAnchor, constant: 14),
            label.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 20),
            label.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -20)
        ])
        messageLabel = label
    }
}
