//
//  MenuWc.swift
//  Focus Bear
//
//  Created by Manish Jain on 14/08/26.
//  Copyright © 2026 Focus Bear. All rights reserved.
//

import Cocoa

/// Window controller for the window-mode menu (used when isMenuPopoverEnabled is false). Its window is a
/// non-activating NSPanel (class set in the storyboard MenuWc scene) so opening the menu never activates
/// Focus Bear or switches Spaces — which also lets it float over another app's native full-screen space.
/// Configured in getMenuWindowObject(); shown from showPopover().
class MenuWc: NSWindowController {

    override func windowDidLoad() {
        super.windowDidLoad()
    }

}
