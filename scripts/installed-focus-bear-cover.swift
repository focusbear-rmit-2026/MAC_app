#!/usr/bin/env swift
//
// Exits 3, naming the window, when the installed Focus Bear has a full-screen routine, break or
// session screen up; 0 otherwise. scripts/run-ui-tests.sh runs it before building, and again while it
// waits for the screen to step aside. (Not 1: that is also what a failed compile of this script exits
// with, which must not read as "covered".)
//
// That screen sits above every other window (layer 999 or 2147483631), so it takes every click the
// UI tests synthesize. A smoke run on 2026-10-04 spent its whole length behind a routine's
// "habit finished" screen: four tests failed with unrelated-looking messages ("the selected row has no
// Delete", "the popover-menu switch is missing"), and their clicks landed on the user's own routine.
// The suite's failIfCovered() names the cover once a test is running; this saves the build first.
//
// It only reads window metadata (CGWindowList) — it never activates, quits or talks to the app. A Debug
// build that has stepped its routine aside for the run's lease (scripts/ui-test-runner-lease.sh) has
// ordered the window out, so it isn't on screen and doesn't count; the suite's failIfCovered() sees the
// same.
//
//     swift scripts/installed-focus-bear-cover.swift
//
import AppKit

/// The user's own Focus Bear — a release or a development build, never the UI-test build.
let installedBundlePrefixes = ["com.focusbear.", "com.App.EarnYourScreentime"]
let testBuildBundleIdentifier = "com.App.EarnYourScreentime.uitests"
/// Above pop-up menus: where the shield screens sit. Same floor as SafeInteraction.swift.
let shieldLayerFloor = Int(CGWindowLevelForKey(.overlayWindow))
/// Smaller than this is a badge or an invisible helper, not something covering the screen.
let coverMinimumSide: CGFloat = 50
let exitCovered: Int32 = 3

func isInstalledFocusBear(_ pid: pid_t) -> Bool {
    guard let bundle = NSRunningApplication(processIdentifier: pid)?.bundleIdentifier,
          bundle != testBuildBundleIdentifier else { return false }
    return installedBundlePrefixes.contains { bundle.hasPrefix($0) }
}

func isShieldWindow(_ window: [String: Any]) -> Bool {
    guard let layer = window[kCGWindowLayer as String] as? Int, layer >= shieldLayerFloor,
          let owner = window[kCGWindowOwnerPID as String] as? pid_t, isInstalledFocusBear(owner),
          ((window[kCGWindowAlpha as String] as? Double) ?? 1) > 0,
          let bounds = window[kCGWindowBounds as String] as? NSDictionary,
          let frame = CGRect(dictionaryRepresentation: bounds as CFDictionary)
    else { return false }
    return frame.width > coverMinimumSide && frame.height > coverMinimumSide
}

let windows = CGWindowListCopyWindowInfo([.optionOnScreenOnly, .excludeDesktopElements], kCGNullWindowID) as? [[String: Any]] ?? []
guard let shield = windows.first(where: isShieldWindow) else { exit(0) }
let owner = shield[kCGWindowOwnerName as String] as? String ?? "Focus Bear"   // i18n-ignore: developer script output
let layer = shield[kCGWindowLayer as String] as? Int ?? shieldLayerFloor
print("\(owner) has a full-screen routine, break or session screen up (window layer \(layer)).")
exit(exitCovered)
