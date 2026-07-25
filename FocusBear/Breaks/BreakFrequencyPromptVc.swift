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

/// The break-frequency prompt (#1744). It's presented programmatically as an `NSAlert`
/// (see `showIfNeeded`) — there's no storyboard scene wired up, so there's no view-controller UI here.
final class BreakFrequencyPromptVc: NSObject {}

private final class _StepperFieldLink: NSObject {
    weak var field: NSTextField?

    init(field: NSTextField) {
        self.field = field
    }

    @objc func stepperChanged(_ sender: NSStepper) {
        field?.integerValue = sender.integerValue
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

        // User-facing text lives in config.json (breakFrequencyVcInfo) so it can be translated.
        var title = "Want to make breaks less frequent?"
        var currentFrequencyText = "Your current break frequency is every %d minutes"
        var buttonChangeText = "Change Break Frequency"
        var buttonKeepText = "Keep as is"
        var newFrequencyLabel = "New frequency (min):"
        if let info = configjson.value(forKey: "breakFrequencyVcInfo") as? NSDictionary {
            title = info.value(forKey: "title") as? String ?? title
            currentFrequencyText = info.value(forKey: "currentFrequencyText") as? String ?? currentFrequencyText
            buttonChangeText = info.value(forKey: "buttonChangeText") as? String ?? buttonChangeText
            buttonKeepText = info.value(forKey: "buttonKeepText") as? String ?? buttonKeepText
            newFrequencyLabel = info.value(forKey: "newFrequencyLabel") as? String ?? newFrequencyLabel
        }

        let alert = NSAlert()
        alert.setSharingType()
        alert.messageText     = title
        alert.informativeText = String(format: currentFrequencyText, currentFrequency)
        alert.addButton(withTitle: buttonChangeText)
        alert.addButton(withTitle: buttonKeepText)

        // Accessory: stepper + text field for the new frequency
        let accessory = NSView(frame: NSRect(x: 0, y: 0, width: 260, height: 36))

        let label = NSTextField(labelWithString: newFrequencyLabel)
        label.frame = NSRect(x: 0, y: 8, width: 160, height: 20)
        label.sizeToFit()   // shrink to the real text width so the field sits right next to it
        accessory.addSubview(label)

        let fieldX = label.frame.maxX + 6   // small fixed gap instead of the old ~30px of empty label
        let field = NSTextField(frame: NSRect(x: fieldX, y: 4, width: 50, height: 26))
        field.integerValue = proposedDefault
        accessory.addSubview(field)

        let stepper = NSStepper(frame: NSRect(x: fieldX + 52, y: 4, width: 22, height: 26))
        stepper.minValue  = 5
        stepper.maxValue  = 120
        stepper.increment = 5
        stepper.integerValue = proposedDefault

        let link = _StepperFieldLink(field: field)
        stepper.target = link
        stepper.action = #selector(_StepperFieldLink.stepperChanged(_:))

        accessory.addSubview(stepper)
        accessory.setFrameSize(NSSize(width: stepper.frame.maxX + 4, height: 36))   // fit the tightened layout

        alert.accessoryView = accessory

        let response = withExtendedLifetime(link) {
            alert.runModal()
        }

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
