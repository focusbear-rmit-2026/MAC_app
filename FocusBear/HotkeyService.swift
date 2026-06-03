//
//  HotkeyService.swift
//  Focus Bear
//
//  Manages system-wide keyboard shortcuts for:
//    - Brain Dump  (default: ⌥⌘B)
//    - Focus Music (default: ⌥⌘M)
//    - Task List   (default: ⌥⌘T)
//
//  Uses the existing Carbon-based HotKey infrastructure already present in the app.
//  Shortcuts are user-configurable and persist via UserDefaults (see SettingsManager).
//
//  NOTE: Global hotkeys via Carbon APIs work in sandboxed apps provided the app has
//  the Accessibility permission OR uses the RegisterEventHotKey approach (already in
//  use by this app for the Pomodoro shortcut – no extra entitlements needed).
//

import AppKit

// MARK: - Which shortcut is currently being recorded

enum ActiveShortcutRecorder {
    case none
    case brainDump
    case focusMusic
    case taskList
    case focusSession
}

var activeShortcutRecorder: ActiveShortcutRecorder = .none

// MARK: - HotkeyService

final class HotkeyService {

    // MARK: Singleton

    static let shared = HotkeyService()
    private init() {}

    // MARK: HotKey instances

    private var hotKeyBrainDump: HotKey?
    private var hotKeyFocusMusic: HotKey?
    private var hotKeyTaskList: HotKey?
    private var hotKeyStartFocusSession: HotKey?
    // MARK: - Registration

    /// Re-reads current settings and registers/re-registers all three shortcuts.
    func registerAll() {
        registerBrainDump()
        registerFocusMusic()
        registerTaskList()
        registerFocusSession()
    }

    func registerBrainDump() {
        hotKeyBrainDump = nil
        let keyChar   = SettingsManagerObject.brainDumpShortcutChar
        let flagInts  = SettingsManagerObject.brainDumpShortcutFlags
        guard !keyChar.isEmpty && !flagInts.isEmpty else { return }
        updateFlags(sflags: flagInts)
        let localFlags = flags
        hotKeyBrainDump = HotKey(keyCombo: KeyCombo(stkey: keyChar, modifiers: localFlags))
        hotKeyBrainDump?.keyDownHandler = {
            addLog(text: "[HotkeyService] Brain Dump shortcut triggered")
            showBrainDumpWindow()
        }
    }

    func unregisterBrainDump() {
        hotKeyBrainDump = nil
    }

    func registerFocusMusic() {
        hotKeyFocusMusic = nil
        let keyChar   = SettingsManagerObject.focusMusicShortcutChar
        let flagInts  = SettingsManagerObject.focusMusicShortcutFlags
        guard !keyChar.isEmpty && !flagInts.isEmpty else { return }
        updateFlags(sflags: flagInts)
        let localFlags = flags
        hotKeyFocusMusic = HotKey(keyCombo: KeyCombo(stkey: keyChar, modifiers: localFlags))
        hotKeyFocusMusic?.keyDownHandler = {
            addLog(text: "[HotkeyService] Focus Music shortcut triggered")
            showAllTracksWindow()
        }
    }

    func unregisterFocusMusic() {
        hotKeyFocusMusic = nil
    }

    func registerTaskList() {
        hotKeyTaskList = nil
        let keyChar   = SettingsManagerObject.taskListShortcutChar
        let flagInts  = SettingsManagerObject.taskListShortcutFlags
        guard !keyChar.isEmpty && !flagInts.isEmpty else { return }
        updateFlags(sflags: flagInts)
        let localFlags = flags
        hotKeyTaskList = HotKey(keyCombo: KeyCombo(stkey: keyChar, modifiers: localFlags))
        hotKeyTaskList?.keyDownHandler = {
            addLog(text: "[HotkeyService] Task List shortcut triggered")
            menuViewControllerObj?.openToDoListClicked()
        }
    }

    func unregisterTaskList() {
        hotKeyTaskList = nil
    }
    
    func registerFocusSession() {
        hotKeyStartFocusSession = nil
        let keyChar   = SettingsManagerObject.startPomodoroShortcutChar
        let flagInts  = SettingsManagerObject.startPomodoroShortcutFlags
        guard !keyChar.isEmpty && !flagInts.isEmpty else { return }
        updateFlags(sflags: flagInts)
        let localFlags = flags
        hotKeyStartFocusSession = HotKey(keyCombo: KeyCombo(stkey: keyChar, modifiers: localFlags))
        hotKeyStartFocusSession?.keyDownHandler = {
            addLog(text: "[HotkeyService] Task List shortcut triggered")
            addLog(text: "Shortcut start Pomodoro Pressed")
            let isFocusModeOnOrPaused = isFocusModeOnOrPaused()
            
            if isFocusModeOnOrPaused{
                addLog(text: "FocusMode is On Or Paused:- return")
                return;
            }else{
                if isHardCorePomodoroModeOn{
                    addLog(text: "HardCore Pomodoro Mode is On:- return")
                    return;
                }else{
                    if currentState == ._MORNING_HABIT_ || currentState == ._EVENING_HABIT_ || currentState == ._MICRO_BREAK_ || currentState == ._SPECIAL_ACTIVITY_ || currentState == ._CUSTOM_ROUTINE_{
                        
                        addLog(text: "Activity is running:- return")
                        return;
                    }
                }
            }
            appdelegate!.menuShowPomodoroModeView()
        }
    }

    func unregisterFocusSession() {
        hotKeyStartFocusSession = nil
    }

    // MARK: - Helpers

    /// Human-readable description of a shortcut combo for display in Settings.
    static func displayString(char: String, flagInts: [Int]) -> String {
        guard !char.isEmpty || !flagInts.isEmpty else { return "Not set" }
        var parts = ""
        if flagInts.contains(shortcutFlags._CONTROL_.rawValue) { parts += "⌃" }
        if flagInts.contains(shortcutFlags._OPTION_.rawValue)  { parts += "⌥" }
        if flagInts.contains(shortcutFlags._SHIFT_.rawValue)   { parts += "⇧" }
        if flagInts.contains(shortcutFlags._COMMAND_.rawValue) { parts += "⌘" }
        parts += char.uppercased()
        return parts
    }
}
