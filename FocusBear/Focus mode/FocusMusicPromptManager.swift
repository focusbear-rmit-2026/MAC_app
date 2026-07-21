//
//  FocusMusicPromptManager.swift
//  Focus Bear
//
//  Copyright © 2026 Focus Bear. All rights reserved.
//

import Cocoa

/// The user's saved answer to the post-session-start "play focus music?" prompt.
/// Persisted + account-synced via SettingsManager.focusMusicAutoStart; surfaced as a toggle in
/// Settings → Accessibility (on = .play, off = .off).
enum FocusMusicAutoStart: String {
    case ask   // show the prompt at the start of each focus session (default)
    case play  // auto-start focus music, no prompt
    case off   // never auto-start, no prompt
}

/// Shows a "Want to play some focus music?" prompt right after a focus session starts, with a
/// "Remember my choice" option. Once remembered, the Yes/No answer is saved (and synced to the
/// account) and re-applied automatically on later sessions — .play auto-starts music, .off stays
/// silent — until the user changes it via the toggle in Settings → Accessibility. Modeled on the
/// Geek Mode confirm alert (allSubclasses.swift).
enum FocusMusicPromptManager {
    static func maybeShowPrompt(isStartedByPusher: Bool) {
        guard !isStartedByPusher else { return }   // don't interrupt a remotely-started session
        // Playing music doesn't make sense while starting a Meetings-type focus block.
        guard currentRunningFocusType["isMeetings"] as? Bool != true else { return }
        // Nothing to offer (or auto-play) if the user hasn't downloaded any focus-music tracks — skip
        // the prompt entirely rather than offering music that can't play.
        guard arrAllTracks.contains(where: { $0["isFileDownloded"] as? Bool == true }) else { return }
        // The user is already listening to something (library track, Spotify or YouTube) — don't offer
        // to start music, and don't auto-start it either. Playing a library track stops Spotify/YouTube,
        // so prompting here would hijack the music they deliberately chose. Read via the optional global
        // so this never instantiates the Focus Music screen just to ask (if nothing is playing, there's
        // nothing to protect).
        guard !(allTracksVcObj?.isAnyMusicPlaying ?? false) else { return }

        // The saved preference decides whether to prompt at all. Only .ask shows the prompt.
        switch SettingsManagerObject.focusMusicAutoStart {
        case .play:
            // Auto-follow: just play music, nothing else — don't open the Focus Music screen.
            getAllTracksVcObj().playLastPlayedOrRandomTrack()
            isFocusMusicStartedFromPrompt = true
            return
        case .off:
            return
        case .ask:
            break
        }

        var title = "Want to play some focus music?"
        var buttonYesText = "Yes, play music"
        var buttonNoText = "No thanks"
        var buttonDontAskAgainText = "Remember my choice"
        if let info = configjson.value(forKey: "focusMusicPromptInfo") as? NSDictionary {
            title = info.value(forKey: "title") as? String ?? title
            buttonYesText = info.value(forKey: "buttonYesText") as? String ?? buttonYesText
            buttonNoText = info.value(forKey: "buttonNoText") as? String ?? buttonNoText
            buttonDontAskAgainText = info.value(forKey: "buttonDontAskAgainText") as? String ?? buttonDontAskAgainText
        }

        // Use the app's non-blocking custom alert instead of NSAlert.runModal() — the modal run loop
        // froze UI updates (e.g. the focus-start animations) while the prompt was up. Yes → OK button,
        // No → Cancel button, "Remember my choice" → the alert's checkbox (read from customAlertVcObj
        // in the completion, since the handler only reports which button was pressed).
        showCustomAlert(title: title, body: nil, buttonOkText: buttonYesText, buttonCancelText: buttonNoText, checkBoxText: buttonDontAskAgainText, autoClose: false, buttonLinkUrl: nil, buttonLinkText: nil, completionHandler: { isYes in
            // "Remember my choice" ticked → save the Yes/No answer and sync it to the account, so later
            // sessions auto-follow it and it shows up as the toggle in Settings → Accessibility. Left
            // unticked → the preference stays .ask and the prompt returns next session.
            if customAlertVcObj?.checkBox.state == .on {
                SettingsManagerObject.focusMusicAutoStart = isYes ? .play : .off
                SettingsManagerObject.isSettingsChanged = true
                SettingsManagerObject.putUserLocalDeviceSettings()
            }
            if isYes {
                // User opted in — just play music, don't open the Focus Music screen.
                getAllTracksVcObj().playLastPlayedOrRandomTrack()
                // Mark it as prompt-started so it gets stopped when this focus session ends
                // (see focusModeFinishedResetAllData).
                isFocusMusicStartedFromPrompt = true
            }
        })
        NSApplication.shared.activate(ignoringOtherApps: true)
    }
}
