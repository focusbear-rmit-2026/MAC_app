//
//  breakStartVc.swift
//  Focus Bear
//
//  Hosts the SwiftUI break start screen (`BreakStartView`). It takes over from the storyboard
//  `firstViewController` for micro breaks only: `habitsVc.showBreakActivityListView()` swaps this
//  view into `habitsView` instead. Routine habit lists (morning / evening / custom) still use
//  `firstViewController` and are untouched.
//
//  The AppKit alerts the office-mode switch puts up stay here rather than in the model, so the model
//  is testable and the sheet has a real window to attach to.
//

import Cocoa
import SwiftUI

class breakStartVc: NSViewController {

    let model = BreakStartModel()

    /// Built in code (no storyboard scene) — new Mac UI is SwiftUI hosted in an NSHostingView.
    override func loadView() {
        let container = NSView()
        let hosting = NSHostingView(rootView: BreakStartView(model: model))
        hosting.translatesAutoresizingMaskIntoConstraints = false
        // The hosting view's intrinsic size is the whole scrolling screen; at the default 750
        // compression resistance it outranks the window's own size and would grow the window to fit.
        // Let the window size win so the screen scrolls instead.
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

        model.confirmOfficeModeWithNoActivities = { [weak self] completion in
            self?.askToAddAnOfficeFriendlyActivity(completion: completion)
        }
        model.announceOfficeModeEnabled = { [weak self] in
            self?.announceOfficeModeEnabledOnce()
        }
    }

    // MARK: - Entry point

    /// Show the break start screen. `habitsVc` has already swapped this view in.
    func showBreakStart() {
        if !isViewLoaded { loadView() }
        model.screenAppeared()
    }

    /// Called when the screen is swapped out (the break started, or was skipped).
    func breakStartDismissed() {
        guard isViewLoaded else { return }
        model.screenDisappeared()
    }

    /// True when this screen is the one on show — used by the Return-key shortcut.
    var isLiveBreakStartScreen: Bool {
        guard currentState == ._MICRO_BREAK_, isViewLoaded else { return false }
        return habitsVcObj?.habitsView.subviews.contains(view) ?? false
    }

    /// The Return-key shortcut that started the break from the old list screen. Skipped while a text
    /// view has focus so Return still inserts a newline in the brain dump. Returns true when it acted.
    @discardableResult func startFromReturnKey() -> Bool {
        guard isLiveBreakStartScreen, !isTextInputFocused(in: view.window) else { return false }
        model.start()
        return true
    }

    // MARK: - Office-mode alerts (unchanged from firstViewController)

    /// Switching to chair exercises with nothing office-friendly to do: offer to add a stand-and-
    /// stretch activity, exactly as the segmented control did.
    private func askToAddAnOfficeFriendlyActivity(completion: @escaping (Bool) -> Void) {
        guard let window = view.window else { completion(false); return }
        let alert = NSAlert()
        alert.setSharingType()
        var noOfficeFriendlyActivityAlertText = "You don't have any office friendly break activities. Do you want me to add one for you to stand up and stretch for 20 seconds?"
        var noOfficeFriendlyActivityButtonFirstText = "Yeah sounds good"
        var noOfficeFriendlyActivityButtonSecondText = "No I'm a machine! I don't need breaks"
        if let menuInfo = configjson.value(forKey: "menuInfo") as? NSDictionary{
            noOfficeFriendlyActivityAlertText = menuInfo.value(forKey: "noOfficeFriendlyActivityAlertText") as? String ?? noOfficeFriendlyActivityAlertText
            noOfficeFriendlyActivityButtonFirstText = menuInfo.value(forKey: "noOfficeFriendlyActivityButtonFirstText") as? String ?? noOfficeFriendlyActivityButtonFirstText
            noOfficeFriendlyActivityButtonSecondText = menuInfo.value(forKey: "noOfficeFriendlyActivityButtonSecondText") as? String ?? noOfficeFriendlyActivityButtonSecondText
        }
        alert.messageText = noOfficeFriendlyActivityAlertText
        alert.addButton(withTitle: noOfficeFriendlyActivityButtonFirstText)
        alert.addButton(withTitle: noOfficeFriendlyActivityButtonSecondText)
        NSApplication.shared.activate(ignoringOtherApps: true)
        alert.beginSheetModal(for: window, completionHandler: { result in
            guard result == .alertFirstButtonReturn else { completion(false); return }
            menuViewControllerObj?.addOfficeFriendlyActivityInSettings()
            completion(true)
        })
    }

    /// The one-time "ok, office-appropriate activities only" confirmation.
    private func announceOfficeModeEnabledOnce() {
        guard UserDefaults.standard.object(forKey: "officeModeEnabledSuccessAlertShown") == nil,
              let window = view.window else { return }
        let alert = NSAlert()
        alert.setSharingType()
        var officeModeEnabledSuccessfullyText = "Ok! I'll just prompt you to do activities that won't weird other people out (doing handstand pushups in the office might raise a few eyebrows)."
        if let menuInfo = configjson.value(forKey: "menuInfo") as? NSDictionary{
            officeModeEnabledSuccessfullyText = menuInfo.value(forKey: "officeModeEnabledSuccessfullyText") as? String ?? officeModeEnabledSuccessfullyText
        }
        alert.messageText = officeModeEnabledSuccessfullyText
        alert.addButton(withTitle: buttonOkText)
        NSApplication.shared.activate(ignoringOtherApps: true)
        alert.beginSheetModal(for: window, completionHandler: nil)
        UserDefaults.standard.set(true, forKey: "officeModeEnabledSuccessAlertShown")
    }
}
