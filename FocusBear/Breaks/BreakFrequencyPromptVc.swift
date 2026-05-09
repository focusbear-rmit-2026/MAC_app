//
//  BreakFrequencyPromptVc.swift
//  FocusBear
//
//  Created by Jose Vega on 2026-05-08.
//  Copyright © 2026 Focus Bear. All rights reserved.
//
//  Implements #1144 — Prompt user to increase break frequency when they turn
//  breaks off for two consecutive days.
//
//  Dialog spec:
//    Title:     "Want to make breaks less frequent?"
//    Body:      "Your current break frequency is every {N} minutes"
//    Input:     New break frequency (default: current + 10 min)
//    Primary:   "Change Break Frequency" → persist new value
//    Secondary: "Keep as is" → dismiss
//

import Cocoa

class BreakFrequencyPromptVc: NSViewController {

    // MARK: - Outlets
    @IBOutlet weak var lblTitle: NSTextField!
    @IBOutlet weak var lblCurrentFrequency: NSTextField!
    @IBOutlet weak var stepper: NSStepper!
    @IBOutlet weak var txtMinutes: NSTextField!
    @IBOutlet weak var btnChange: NSButton!
    @IBOutlet weak var btnKeep: NSButton!

    // MARK: - State
    /// The proposed new break frequency (minutes).  Initialised to current + 10.
    private var proposedMinutes: Int = 30

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        let currentFrequency = breakAfterMinutes > 0 ? breakAfterMinutes : 20
        proposedMinutes = currentFrequency + 10

        lblTitle.stringValue = "Want to make breaks less frequent?"
        lblCurrentFrequency.stringValue = "Your current break frequency is every \(currentFrequency) minutes"

        txtMinutes.integerValue = proposedMinutes
        stepper.minValue = 5
        stepper.maxValue = 120
        stepper.increment = 5
        stepper.integerValue = proposedMinutes

        btnChange.title = "Change Break Frequency"
        btnKeep.title = "Keep as is"

        addLog(text: "BreakFrequencyPromptVc: showing dialog — current=\(currentFrequency), proposed=\(proposedMinutes)")
    }

    // MARK: - Actions

    @IBAction func stepperChanged(_ sender: NSStepper) {
        proposedMinutes = sender.integerValue
        txtMinutes.integerValue = proposedMinutes
    }

    @IBAction func txtMinutesChanged(_ sender: NSTextField) {
        let val = max(5, min(120, sender.integerValue))
        proposedMinutes = val
        stepper.integerValue = val
        txtMinutes.integerValue = val
    }

    @IBAction func btnChangeClicked(_ sender: Any) {
        addLog(text: "BreakFrequencyPromptVc: user chose to change break frequency to \(proposedMinutes) min")
        allApiObject.capturePosthog(event: "break-frequency-increased-from-prompt", metadata: ["new_frequency_minutes": proposedMinutes])
        BreakFrequencyStreakTracker.shared.saveNewBreakFrequency(proposedMinutes)
        self.view.window?.close()
    }

    @IBAction func btnKeepClicked(_ sender: Any) {
        addLog(text: "BreakFrequencyPromptVc: user chose to keep current break frequency")
        allApiObject.capturePosthog(event: "break-frequency-prompt-dismissed", metadata: [:])
        self.view.window?.close()
    }
}

// MARK: - Programmatic NSAlert-style presentation
// Use this when there is no storyboard scene wired up yet.

extension BreakFrequencyPromptVc {

    /// Present the dialog as a standalone NSAlert (no storyboard required).
    /// Call on the main thread.
    static func showIfNeeded() {
        guard BreakFrequencyStreakTracker.shared.shouldShowPrompt() else { return }

        let currentFrequency = breakAfterMinutes > 0 ? breakAfterMinutes : 20
        let proposedDefault  = currentFrequency + 10

        let alert = NSAlert()
        alert.setSharingType()
        alert.messageText     = "Want to make breaks less frequent?"
        alert.informativeText = "Your current break frequency is every \(currentFrequency) minutes"
        alert.addButton(withTitle: "Change Break Frequency")
        alert.addButton(withTitle: "Keep as is")

        // Accessory: stepper + text field for the new frequency
        let accessory = NSView(frame: NSRect(x: 0, y: 0, width: 260, height: 36))

        let label = NSTextField(labelWithString: "New frequency (min):")
        label.frame = NSRect(x: 0, y: 8, width: 160, height: 20)
        accessory.addSubview(label)

        let field = NSTextField(frame: NSRect(x: 166, y: 4, width: 50, height: 26))
        field.integerValue = proposedDefault
        accessory.addSubview(field)

        let stepper = NSStepper(frame: NSRect(x: 216, y: 4, width: 22, height: 26))
        stepper.minValue  = 5
        stepper.maxValue  = 120
        stepper.increment = 5
        stepper.integerValue = proposedDefault
        accessory.addSubview(stepper)

        alert.accessoryView = accessory

        let response = alert.runModal()

        if response == .alertFirstButtonReturn {
            let newVal = max(5, min(120, field.integerValue))
            addLog(text: "BreakFrequencyPromptVc(alert): changing frequency to \(newVal) min")
            allApiObject.capturePosthog(
                event: "break-frequency-increased-from-prompt",
                metadata: ["new_frequency_minutes": newVal]
            )
            BreakFrequencyStreakTracker.shared.saveNewBreakFrequency(newVal)
        } else {
            addLog(text: "BreakFrequencyPromptVc(alert): user kept current frequency")
            allApiObject.capturePosthog(event: "break-frequency-prompt-dismissed", metadata: [:])
        }

        // Mark the streak as prompted so we don't fire again until the streak resets
        BreakFrequencyStreakTracker.shared.markPromptShown()
    }
}
